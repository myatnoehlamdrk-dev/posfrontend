#!/usr/bin/env perl
# Wraps user-facing English literals in `context.l10n.t(...)`.
#
# Only for the presentation layer. Domain, data and view-model files are left
# alone on purpose: they have no BuildContext, and their strings are usually
# data (variant sizes, JSON keys, request payloads) rather than copy.
#
# Run per feature, then review the diff and format:
#   find lib/features/category/presentation -name '*.dart' | xargs perl tool/apply_l10n.pl
#   dart format lib/features/category
#   flutter analyze lib/features/category
#
# Files are passed in explicitly rather than globbed here: Perl's plain glob()
# does not treat `**` as recursive, so doing it internally silently matched one
# directory level and rewrote nothing.
use strict;
use warnings;

# Values that must never be treated as translatable copy. Every entry is
# something that *looks* like UI text but is really data: a product attribute,
# a font family, an API value. Wrapping one of these would put it in the
# translation files, where a translator would dutifully change it and the app
# would then show a translated product size.
my @DENY = (
    # Variant / product attributes
    'Regular', 'Small', 'Medium', 'Large', 'Black', 'White', 'Red', 'Blue',
    'Green', 'Yellow', 'XL', 'XXL', 'Uncategorized',
    # Language names, stored as API values
    'Myanmar', 'English', 'Thai', 'Japanese', 'Korean',
    # Platform / infra
    'MaterialIcons', 'monospace', 'sans-serif', 'Roboto', 'Poppins',
    # API values and units
    'self', 'public', 'draft', 'MMK', 'USD',
    # Drawer destinations, matched by identity not copy
    'Dashboard', 'Inventory', 'Product', 'Add Product', 'Add to Cart',
    'Sale Item', 'Purchase Item', 'Setting',
);

my $deny_re = join('|', map { quotemeta } @DENY);

sub is_denylisted { return $_[0] =~ /^($deny_re)$/ }

# Separator breadcrumbs, bullet glyphs and stray whitespace are layout, not
# copy. Wrapping them just adds noise to the translation file.
sub looks_like_copy {
    my ($s) = @_;
    return 0 unless $s =~ /[A-Za-z]/;
    return 0 if $s !~ /[A-Za-z]{2}/;
    return 0 if $s =~ /^[\s>\/<|·•\-_=+*]+$/;
    return 0 if is_denylisted($s);
    return 1;
}

# Turns a Dart string literal into `context.l10n.t('KEY')` plus a replaceAll
# chain for any interpolation.
#
# Interpolated literals need this treatment specifically: `t('Delete ${c.name}?')`
# would build a key containing a runtime value, so no translation could ever
# match it and a translator would see unresolvable text. The braces become
# `{v1}`, `{v2}` so the English template stays a fixed, translatable string and
# the values are substituted afterwards.
sub wrap_literal {
    my ($inner, $context_name) = @_;
    return undef unless looks_like_copy($inner);

    # A Dart single-quoted string may itself contain single quotes inside an
    # interpolation: '{n} item${n == 1 ? '' : 's'}'. The single-quote regex
    # below cannot span those, so the match stops at the first internal quote
    # and yields a truncated fragment ending in an unclosed `${`. Brace depth
    # catches exactly that case, and costs nothing on the strings that are
    # fine.
    my $depth = 0;
    for my $ch (split //, $inner) {
        $depth++ if $ch eq '{';
        $depth-- if $ch eq '}';
    }
    return undef if $depth != 0;

    my $key = $inner;
    my @args;

    my $n = 0;
    $key =~ s/\$\{([^{}]*)\}/do { $n++; push @args, $1; "{v$n}" }/ge;
    $key =~ s/\$([A-Za-z_][A-Za-z0-9_]*)/do { $n++; push @args, $1; "{v$n}" }/ge;

    my $out = "$context_name.l10n.t('" . $key . "')";
    for my $i (0 .. $#args) {
        my $expr = $args[$i];
        $out .= ".replaceAll('{v" . ($i + 1) . "}', ($expr).toString())";
    }
    return $out;
}

my @files = grep { -f } @ARGV;

for my $file (@files) {
    open my $in, '<', $file or die "open $file: $!";
    local $/;
    my $src = <$in>;
    close $in;
    my $orig = $src;

    # Single-quoted literal only. Double-quoted literals are used for strings
    # containing an apostrophe, which this does not handle.
    my $L = qr/'([^'\\]*)'/;

    # 1. `const Text('X'` -> `Text(context.l10n.t('X')`.
    #    `const` has to go: the argument is no longer a constant expression.
    $src =~ s{\bconst(\s+)Text\(\s*$L}{
        my $sp = $1; my $v = $2;
        my $w = wrap_literal($v, 'context');
        defined $w ? "${sp}Text($w" : "${sp}Text('$v'"
    }ge;

    # 2. Plain `Text('X'`. Does not re-match step 1, because that now has
    #    `context` where the quote is expected.
    $src =~ s{(?<![\w.])Text\(\s*$L}{
        my $v = $1;
        my $w = wrap_literal($v, 'context');
        defined $w ? "Text($w" : "Text('$v'"
    }ge;

    # 3. Named text parameters.
    $src =~ s{\b(title|label|hint|helper|subtitle|hintText|placeholder|labelText|snackMessage):(\s*)$L}{
        my ($k, $sp, $v) = ($1, $2, $3);
        my $w = wrap_literal($v, 'context');
        defined $w ? "$k:$sp$w" : "$k:$sp'$v'"
    }ge;

    # 4. Toast helpers. The first argument is a context, which some call sites
    #    name something other than `context`.
    $src =~ s{\b(showErrorMessage|showSuccessMessage|showWarningMessage|showInfoMessage)\((\w+),\s*$L}{
        my ($fn, $ctx, $v) = ($1, $2, $3);
        my $w = wrap_literal($v, 'context');
        defined $w ? "$fn($ctx, $w" : "$fn($ctx, '$v'"
    }ge;

    next if $src eq $orig;

    # Make sure the extension is imported.
    if ($src =~ /context\.l10n/ && $src !~ m{^import 'package:posfrontend/shared/l10n/l10n_x\.dart';}m) {
        $src =~ s{^(import 'package:flutter/material\.dart';\n)}{$1import 'package:posfrontend/shared/l10n/l10n_x.dart';\n}m
            or $src = "import 'package:posfrontend/shared/l10n/l10n_x.dart';\n" . $src;
    }

    open my $out, '>', $file or die "write $file: $!";
    print $out $src;
    close $out;
    print "rewrote $file\n";
}
