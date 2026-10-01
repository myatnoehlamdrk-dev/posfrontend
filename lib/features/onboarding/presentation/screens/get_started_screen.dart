import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:posfrontend/shared/l10n/l10n_x.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/features/auth/presentation/screens/login_screen.dart';

/// Layout thresholds for this screen.
///
/// It was authored for a portrait phone. On a desktop window the content would
/// otherwise float as a postage stamp, so the hero scales up to a ceiling and
/// the wordmark is capped at a readable measure.
class _OnboardingLayout {
  /// Above this the viewport is treated as tablet or desktop. Below it the
  /// scattered-cards-over-illustration layout is kept, because that is what it
  /// was drawn for and a phone has nowhere else to put the art.
  static const double wideFrom = 700;

  static const double heroTextMaxWidth = 760;

  /// Measure for the feature list on wide viewports. Wide enough for the
  /// longest label in any language without the row stretching.
  static const double listMaxWidth = 420;

  static const double listItemGap = 12;

  static const double heroCeiling = 1.5;

  /// Keeps the button off the middle group when the window is short and the
  /// two gaps collapse to nothing.
  static const double ctaGap = 14;

  static const double buttonHeight = 56;
  static const double bottomPadding = 32;
}

class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.scaffoldBg,
      body: Stack(
        children: [
          // Radial wash behind everything. A gradient has no intrinsic size, so
          // filling the screen costs nothing visually here.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.95, -0.95),
                  radius: 0.7,
                  colors: [
                    context.palette.primary.withValues(alpha: 0.22),
                    context.palette.primary.withValues(alpha: 0.12),
                    context.palette.primary.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),
          // Content flow
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= _OnboardingLayout.wideFrom;

                return ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                    maxHeight: constraints.maxHeight,
                    maxWidth: constraints.maxWidth,
                  ),
                  child: Column(
                    // Three bands: wordmark at the top, illustration and cards
                    // in the middle, CTA at the bottom. `spaceBetween` puts the
                    // slack in the two gaps between them rather than splitting
                    // it by a flex ratio, which left the middle group high.
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    // The default is `center`, which hands the CTA loose width
                    // constraints and lets it shrink to its label instead of
                    // spanning the window. The hero and the middle band are both
                    // unaffected: they centre their own content internally.
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeroSection(
                        context,
                        maxWidth: MediaQuery.of(context).size.width,
                      ),
                      // Takes all the slack between the two fixed-height bands
                      // and centres the group in it. Also what bounds the stack:
                      // a Column child that is not a flex slot gets unbounded
                      // height, and RenderStack would fall back to
                      // `constraints.biggest` and come out infinite.
                      Expanded(
                        child: wide
                            ? _buildFeatureList(context)
                            : _buildFeatures(context),
                      ),
                      // Button and its padding are one child, so `spaceBetween`
                      // sees three bands and not four. As separate children the
                      // padding became a third gap and lifted the button.
                      Padding(
                        padding: const EdgeInsets.only(
                          top: _OnboardingLayout.ctaGap,
                          bottom: _OnboardingLayout.bottomPadding,
                        ),
                        child: _GetStartedButton(
                          onPressed: () => _navigateToLogin(context),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Typography-forward hero: a single vector brand mark over clean wordmark
  /// text. The old version stacked a 300pt 3D illustration and a gradient wash
  /// here, which read as stock art; a flat mark on the page background is both
  /// cheaper to paint and unmistakably this app.
  Widget _buildHeroSection(BuildContext context, {required double maxWidth}) {
    final p = context.palette;

    // Grows with the window but stops at a ceiling, so a wide monitor does not
    // render the wordmark at billboard size. Below the floor it stays at 1.0
    // and the phone layout is untouched.
    final raw = maxWidth / 600;
    final scale = raw < 1.0
        ? 1.0
        : (raw > _OnboardingLayout.heroCeiling
              ? _OnboardingLayout.heroCeiling
              : raw);

    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 18.0),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: _OnboardingLayout.heroTextMaxWidth,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildBrandMark(context, scale),
                  const SizedBox(height: 20),
                  Text(
                    context.l10n.t('SMART POS'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 34 * scale,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      height: 1.1,
                      color: p.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.t('INVENTORY MANAGEMENT'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12 * scale,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3,
                      color: p.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.l10n.t(
                      'Manage sales, stock, and reports from your pocket.',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15 * scale,
                      color: p.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// A sleek vector mark: one accent, one glyph, a soft accent shadow. No 3D
  /// asset and no second hue.
  Widget _buildBrandMark(BuildContext context, double scale) {
    final p = context.palette;
    final size = 88 * scale;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Soft gradient bloom sitting just behind the mark. It gives the logo
          // its own light source so it does not look pasted onto the page, and
          // ties it to the same ramp the wordmark accent uses.
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  p.primary.withValues(alpha: 0.30),
                  p.primary.withValues(alpha: 0.10),
                  p.primary.withValues(alpha: 0.0),
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.brandRamp,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: p.primary.withValues(alpha: 0.28),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              Icons.storefront_rounded,
              color: Colors.white,
              size: 44 * scale,
            ),
          ),
        ],
      ),
    );
  }

  /// The feature items, as `(icon, label)` pairs.
  ///
  /// Shared by both layouts so the set and its order cannot drift between them.
  /// Labels go through `t` here rather than at each call site for the same
  /// reason.
  List<(IconData, String)> _featureItems(BuildContext context) {
    final s = context.l10n;
    return [
      (Icons.bolt_rounded, s.t('Fast checkout')),
      (Icons.inventory_2_outlined, s.t('Live inventory tracking')),
      (Icons.bar_chart_rounded, s.t('Daily sales reports')),
    ];
  }

  /// Three separate floating cards over the illustration, for a phone.
  ///
  /// Cards read as distinct, tappable surfaces and the shadow gives them a
  /// physical lift off the page; a single bordered box reads as a form the user
  /// is meant to fill in. They sit in three different corners on purpose, so
  /// the eye moves around the illustration rather than down one column.
  Widget _buildFeatures(BuildContext context) {
    final items = _featureItems(context);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // The illustration fills the middle band rather than sitting inside a
        // centred square. The source is square, so a square box would cap it at
        // the band's width and leave the sides empty; `cover` uses the whole
        // band instead. It bleeds past the slot, which is what a backdrop wants
        // — the cards float on top of it and clip none of it away.
        const Positioned.fill(child: _BackdropImage()),
        Positioned(
          top: 16,
          left: 16,
          child: _FloatingCard(icon: items[0].$1, label: items[0].$2),
        ),
        Positioned(
          top: 0,
          bottom: 0,
          right: 16,
          child: Align(
            alignment: Alignment.centerRight,
            child: _FloatingCard(icon: items[1].$1, label: items[1].$2),
          ),
        ),
        Positioned(
          bottom: 16,
          left: 16,
          child: _FloatingCard(icon: items[2].$1, label: items[2].$2),
        ),
      ],
    );
  }

  /// The same three features as a plain stacked list, for tablet and desktop.
  ///
  /// Without the illustration there is nothing to scatter cards around, and a
  /// wide window has room to read them top to bottom. Each row is its own
  /// raised surface here rather than a transparent overlay, since there is no
  /// artwork behind it to lift off.
  Widget _buildFeatureList(BuildContext context) {
    final items = _featureItems(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: _OnboardingLayout.listMaxWidth,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (index, item) in items.indexed) ...[
              if (index > 0)
                const SizedBox(height: _OnboardingLayout.listItemGap),
              _FeatureRow(icon: item.$1, label: item.$2, filled: true),
            ],
          ],
        ),
      ),
    );
  }

  void _navigateToLogin(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}

/// The illustration filling the band between the wordmark and the CTA.
///
/// `cover` so it occupies the whole band rather than the largest square that
/// fits inside it, which is what a backdrop wants — a square source in a wide
/// slot would leave both sides empty. The cards sit on top of it, so the parts
/// that reach past the edges are decoration and not something being read.
class _BackdropImage extends StatelessWidget {
  const _BackdropImage();

  /// Source is 1000x1000. The band can be wider than that on a desktop window,
  /// so this is not raised past it: upscaling would only add memory and no
  /// detail.
  static const int _decodeSize = 1000;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/shop_rotated.png',
      fit: BoxFit.cover,
      cacheWidth: _decodeSize,
      cacheHeight: _decodeSize,
    );
  }
}

class _FloatingCard extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FloatingCard({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return _FeatureRow(icon: icon, label: label, filled: false);
  }
}

/// One feature line: an icon chip and its label.
///
/// [filled] is the difference between the two layouts. Over the illustration the
/// row is transparent so it does not punch a hole in the artwork; in the wide
/// list there is no artwork behind it, so it takes a surface colour and reads as
/// its own card.
class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool filled;

  const _FeatureRow({
    required this.icon,
    required this.label,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: filled ? p.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: p.primary.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: p.selectionTint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: p.primary),
          ),
          const SizedBox(width: 10),
          // Stretched to the row's width so a long label wraps instead of
          // overflowing it.
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: p.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The primary call to action: a full pill with a thick border painted in the
/// login brand ramp. The fill stays on the page surface so the gradient reads
/// as an outline rather than a wash.
class _GetStartedButton extends StatelessWidget {
  const _GetStartedButton({required this.onPressed});

  final VoidCallback onPressed;

  /// Large enough that the corners are fully round at any button height.
  static const double _radius = 999;

  /// "Weight" of the gradient ring, in logical pixels.
  static const double _borderWeight = 3;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      height: _OnboardingLayout.buttonHeight,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.brandRamp,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(_radius),
        boxShadow: [
          BoxShadow(
            color: p.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(_borderWeight),
      child: Material(
        color: p.surface,
        borderRadius: BorderRadius.circular(_radius - _borderWeight),
        child: InkWell(
          borderRadius: BorderRadius.circular(_radius - _borderWeight),
          onTap: onPressed,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.l10n.t('Get Started'),
                  style: TextStyle(
                    color: p.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(width: 8),
                _SparkArrow(color: p.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The forward arrow on the Get Started button.
///
/// Two motions on one loop: a small left-right nudge so the eye follows it, and
/// a specular sweep travelling across the glyph. The sweep is a `ShaderMask`
/// rather than an opacity fade because a fade only dims the arrow, whereas a
/// gradient sliding across it reads as light catching a shiny edge.
class _SparkArrow extends StatefulWidget {
  const _SparkArrow({this.color = Colors.white});

  /// Colour of the glyph and of the sweeping glint.
  final Color color;

  @override
  State<_SparkArrow> createState() => _SparkArrowState();
}

class _SparkArrowState extends State<_SparkArrow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        // The icon is built once and reused as the shader's alpha source, so
        // the animation only rebuilds the gradient, never the glyph.
        child: Icon(Icons.arrow_forward_rounded, color: widget.color, size: 20),
        builder: (context, child) {
          final t = _controller.value;
          return Transform.translate(
            // One full left-right cycle per loop, peak around 3pt.
            offset: Offset(math.sin(t * math.pi * 2) * 3, 0),
            child: ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (rect) => LinearGradient(
                // The outer stops are dimmer than the peak, not a different
                // hue: the glint has to read against the glyph, so it works by
                // brightening through full opacity and dimming back.
                colors: [
                  widget.color.withValues(alpha: 0.55),
                  widget.color,
                  widget.color.withValues(alpha: 0.55),
                ],
                stops: const [0.34, 0.5, 0.66],
                // Slides fully off the left edge at t=0 and fully off the right
                // at t=1, so the loop has no visible seam.
                begin: Alignment(-1.8 + 3.6 * t, 0),
                end: Alignment(-0.8 + 3.6 * t, 0),
              ).createShader(rect),
              child: child,
            ),
          );
        },
      ),
    );
  }
}
