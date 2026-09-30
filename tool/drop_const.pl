#!/usr/bin/env perl
# Removes the `const` keyword from the widget constructor that encloses a given
# line. Dart rejects a const expression that contains a method call, and
# wrapping a literal in `context.l10n.t(...)` introduces exactly that.
#
# Driven by the analyzer rather than guessed at, because the enclosing `const`
# is often several lines above the reported position and is not always on the
# same line:
#
#   flutter analyze | grep const_eval_method_invocation
#   perl tool/drop_const.pl lib/foo.dart:1081
#
# Candidates are searched nearest-first, so an inner `const TextStyle(...)` is
# considered before the `const SizedBox(...)` around it. A candidate only
# counts if the target line still sits inside its parentheses, which rules the
# inner one out and picks the outermost enclosing constructor.
use strict;
use warnings;

sub depth_delta {
    my ($line) = @_;
    my $delta = 0;
    for my $ch (split //, $line) {
        $delta++ if $ch eq '(' || $ch eq '[' || $ch eq '{';
        $delta-- if $ch eq ')' || $ch eq ']' || $ch eq '}';
    }
    return $delta;
}

for my $spec (@ARGV) {
    my ($file, $lineno) = $spec =~ /^(.+):(\d+)$/ or die "bad spec: $spec\n";
    open my $in, '<', $file or die "open $file: $!";
    my @lines = <$in>;
    close $in;

    my $target = $lineno - 1;
    die "$file:$lineno out of range\n" if $target > $#lines;

    my $fixed = 0;
    for (my $j = $target; $j >= 0 && $j > $target - 40; $j--) {
        # `const` is not always at the start of the line: it is routinely
        # preceded by `return `, a `? ` ternary branch, or a named argument
        # such as `child: const `. Anchor on a word boundary, not on the
        # indent. Also matches a bare `items: const [`.
        next unless $lines[$j] =~ /^\s*.*?\bconst (?:[A-Z_]|\[)/;

        # A const expression can only enclose the target if it is still open at
        # the end of its own line. A self-terminated `const Foo({...});` ends on
        # the same line and cannot possibly contain the target, so skip it --
        # otherwise the cumulative file-wide depth below will wrongly adopt it
        # and strip a class constructor's `const`.
        next unless depth_delta($lines[$j]) > 0 || $j == $target;

        # Walk forward accumulating depth. The target must be strictly inside.
        my $depth = 0;
        my $inside = 0;
        for my $k ($j .. $target) {
            $depth += depth_delta($lines[$k]);
            $inside = ($depth > 0) ? 1 : 0;
        }
        next unless $inside || $j == $target;

        $lines[$j] =~ s/^(\s*.*?)\bconst /$1/;
        $fixed = 1;
        last;
    }

    next unless $fixed;
    open my $out, '>', $file or die "write $file: $!";
    print $out @lines;
    close $out;
    print "dropped const in $file near line $lineno\n";
}
