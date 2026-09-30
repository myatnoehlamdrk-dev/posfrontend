import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:posfrontend/shared/l10n/l10n_x.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/gradient_button.dart';
import 'package:posfrontend/features/auth/presentation/screens/login_screen.dart';

/// Layout thresholds, matching the login screen's so the two agree on what
/// "wide" means.
///
/// This screen was authored for a portrait phone: the hero holds a 300pt logo
/// and a 34pt wordmark, and the bottom section runs edge to edge. On a desktop
/// window that leaves a postage stamp floating in a sea of gradient. The hero
/// scales up to a ceiling and the bottom section is capped and centred.
class _OnboardingLayout {
  static const double wideFrom = 900;

  /// The primary action is a thumb-sized control. Letting it span a desktop
  /// window makes a 1900pt-wide button.
  static const double bottomMaxWidth = 620;

  /// Stops the tagline from stretching into a single 1900pt line.
  static const double heroTextMaxWidth = 760;

  static const double heroCeiling = 1.5;

  // Bottom section metrics. These are named because [bottomMinHeight] is
  // computed from them: a hardcoded minimum next to separately hardcoded widget
  // sizes drifts the moment either one is tweaked, and the symptom is a feature
  // row quietly clipped off the bottom of a short phone.
  static const double badge = 36;
  static const double rowPadX = 18;
  static const double rowPadY = 12;
  static const double cardPadY = 8;
  static const double rule = 1;
  static const double labelGap = 10;
  static const double labelLineHeight = 22;

  /// The gap between the feature card and the button. Fixed, because the space
  /// above the card is taken by the card itself.
  static const double ctaGap = 12;
  static const double buttonHeight = 56;
  static const double bottomPadding = 32;

  /// Ceiling on the card's height. Past this the rows stop growing and the
  /// extra is better spent on the hero, otherwise a tall window turns the card
  /// into three badges drifting in an empty box.
  static const double cardMaxHeight = 340;

  /// Slack for the parts that are not exactly one of the above: a second line
  /// of label text, a text-scale bump, a device rounding error.
  static const double slack = 8;

  /// Natural height of the feature card, which is also its floor. Three rows on
  /// a phone; three badge-over-label cells side by side on a wide window.
  static double cardMinHeight({required bool wide}) => wide
      ? badge + labelGap + labelLineHeight + cardPadY * 2
      : (badge + rowPadY * 2) * 3 + rule * 2 + cardPadY * 2;

  /// Height the bottom section needs before the feature card has to shrink.
  ///
  /// The 58/42 hero split cannot promise that on its own — 42% of a 568pt-tall
  /// phone is 238pt, which is less than the card plus the button needs. When
  /// that happens the hero gives up the difference, because it has a
  /// `FittedBox` that scales down for free while the card does not.
  static double bottomMinHeight({required bool wide}) =>
      cardMinHeight(wide: wide) + slack + ctaGap + buttonHeight + bottomPadding;
}

class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.scaffoldBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (ctx, constraints) {
            final wide = constraints.maxWidth >= _OnboardingLayout.wideFrom;
            final available = constraints.maxHeight;

            // 42% is the proportion this screen has always used, kept as the
            // comfortable case. The floor is what stops a short window from
            // clipping the last feature row, and the cap keeps the hero from
            // going negative on a very short one.
            final bottomHeight = math.min(
              math.max(
                available * 0.42,
                _OnboardingLayout.bottomMinHeight(wide: wide),
              ),
              available,
            );

            return Column(
              children: [
                SizedBox(
                  height: available - bottomHeight,
                  child: _buildHeroSection(ctx, maxWidth: constraints.maxWidth),
                ),
                SizedBox(
                  height: bottomHeight,
                  child: _buildBottomSection(ctx, wide: wide),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, {required double maxWidth}) {
    // Grows with the window but stops at a ceiling, so a wide monitor does not
    // render the wordmark at billboard size. Below the floor it stays at 1.0
    // and the phone layout is untouched.
    final raw = maxWidth / 600;
    final scale = raw < 1.0
        ? 1.0
        : (raw > _OnboardingLayout.heroCeiling
              ? _OnboardingLayout.heroCeiling
              : raw);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: AppColors.brandRamp,
          stops: [0.0, 0.25, 0.5, 0.75, 1.0],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
              child: Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 60,
            left: -40,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            right: 20,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left: 40,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Align(
            // Lift the whole block so the title and inventory line sit higher
            // in the hero, clear of the bottom section.
            alignment: const Alignment(0, -0.2),
            child: FittedBox(
              // On short screens the logo plus wordmark would outgrow the hero
              // area; scale the whole block down as one so it never overflows.
              // On tall screens it renders at natural size.
              fit: BoxFit.scaleDown,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: _OnboardingLayout.heroTextMaxWidth,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildAppIcon(scale),
                    const SizedBox(height: 12),
                    _wordmark(context, 'SMART POS', 34 * scale),
                    _wordmark(context, '&', 34 * scale),
                    _wordmark(context, 'INVENTORY MANAGEMENT', 34 * scale),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        context.l10n.t(
                          'Manage sales, stock, and reports from your pocket.',
                        ),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15 * scale,
                          fontStyle: FontStyle.italic,
                          color: Colors.white.withValues(alpha: 0.8),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _wordmark(BuildContext context, String key, double fontSize) {
    return Text(
      context.l10n.t(key),
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: 'Broadway',
        fontSize: fontSize,
        color: Colors.white,
        height: 1.15,
      ),
    );
  }

  Widget _buildAppIcon(double scale) {
    final size = 300 * scale;
    return Image.asset(
      'assets/shop.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      // 300pt at DPR 3. The source is 2500px square, so decoding it whole for
      // a 300pt box would allocate roughly 72MB of RGBA. The decode target
      // tracks the rendered size, floored at the old fixed target so a resized
      // window never decodes less than the phone layout needs.
      cacheWidth: _decodeTarget(size),
      cacheHeight: _decodeTarget(size),
    );
  }

  /// Decode target in device pixels for a [logicalSize] box, at roughly DPR 3.
  int _decodeTarget(double logicalSize) {
    final px = (logicalSize * 3).round();
    if (px < 900) return 900;
    if (px > 1350) return 1350;
    return px;
  }

  Widget _buildBottomSection(BuildContext context, {required bool wide}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: _OnboardingLayout.bottomMaxWidth,
          ),
          child: Column(
            children: [
              // The card absorbs everything left over rather than sitting at a
              // fixed size, so it grows with the window and the three rows stay
              // on screen without the page ever scrolling. The explicit SizedBox
              // is what hands the card a tight height inside the ceiling;
              // without it the card would collapse back to its content height.
              Expanded(
                child: LayoutBuilder(
                  builder: (ctx, c) => Center(
                    child: SizedBox(
                      height: math.min(
                        c.maxHeight,
                        _OnboardingLayout.cardMaxHeight,
                      ),
                      width: double.infinity,
                      child: _buildFeatures(context, wide: wide),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: _OnboardingLayout.ctaGap),
              GradientButton(
                label: context.l10n.t('Get Started'),
                floating: true,
                gradientColors: AppColors.brandRamp,
                trailing: const _SparkArrow(),
                onPressed: () => _navigateToLogin(context),
              ),
              const SizedBox(height: _OnboardingLayout.bottomPadding),
            ],
          ),
        ),
      ),
    );
  }

  /// The feature list, as one bordered card.
  ///
  /// Three loose rows floating on the page read as an unfinished list. One
  /// surface with a rule between the rows reads as a single block, and it is
  /// the same card idiom the login screen uses, so the two screens feel related.
  ///
  /// The card takes a tight height from the bottom section, so [spaceEvenly]
  /// spends whatever is left over on the gaps between rows. That is what makes
  /// the card grow with the window and the three rows stay on screen without
  /// the page ever scrolling. Rows are deliberately *not* flexed: a tight
  /// `Expanded` row clips its label the moment the text wraps or the system
  /// text scale rises, whereas a naturally sized row just takes the space it
  /// needs and lets the gaps take the rest.
  Widget _buildFeatures(BuildContext context, {required bool wide}) {
    const items = <(IconData, String)>[
      (Icons.bolt_rounded, 'Fast checkout'),
      (Icons.inventory_2_outlined, 'Live inventory tracking'),
      (Icons.bar_chart_rounded, 'Daily sales reports'),
    ];
    final p = context.palette;

    Widget rule({required bool vertical}) {
      if (vertical) {
        return VerticalDivider(
          width: _OnboardingLayout.rule,
          thickness: _OnboardingLayout.rule,
          color: p.border,
        );
      }
      return Divider(
        height: _OnboardingLayout.rule,
        thickness: _OnboardingLayout.rule,
        color: p.border,
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: _OnboardingLayout.cardPadY),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
      ),
      child: wide
          ? Row(
              // Stretch, not start: the cells have to reach the card's edges or
              // the rules stop short of the top and bottom borders.
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) rule(vertical: true),
                  Expanded(
                    child: _featureItem(
                      context,
                      items[i].$1,
                      items[i].$2,
                      stacked: true,
                    ),
                  ),
                ],
              ],
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) rule(vertical: false),
                  _featureItem(context, items[i].$1, items[i].$2),
                ],
              ],
            ),
    );
  }

  /// [stacked] puts the badge above the label, which is the only arrangement
  /// that survives a three-across cell on a narrow column.
  Widget _featureItem(
    BuildContext context,
    IconData icon,
    String key, {
    bool stacked = false,
  }) {
    final p = context.palette;
    final padding = EdgeInsets.symmetric(
      horizontal: _OnboardingLayout.rowPadX,
      vertical: _OnboardingLayout.rowPadY,
    );

    final badge = Container(
      width: _OnboardingLayout.badge,
      height: _OnboardingLayout.badge,
      decoration: BoxDecoration(color: p.chipBg, shape: BoxShape.circle),
      child: Icon(icon, size: 22, color: p.primary),
    );

    final label = Text(
      context.l10n.t(key),
      textAlign: stacked ? TextAlign.center : TextAlign.start,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: p.textPrimary,
        height: 1.35,
      ),
    );

    if (stacked) {
      return Padding(
        padding: padding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            badge,
            const SizedBox(height: _OnboardingLayout.labelGap),
            label,
          ],
        ),
      );
    }

    return Padding(
      padding: padding,
      child: Row(
        children: [
          badge,
          const SizedBox(width: 14),
          Expanded(child: label),
        ],
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

/// The forward arrow on the Get Started button.
///
/// Two motions on one loop: a small left-right nudge so the eye follows it, and
/// a specular sweep travelling across the glyph. The sweep is a `ShaderMask`
/// rather than an opacity fade because a fade only dims the arrow, whereas a
/// gradient sliding across it reads as light catching a shiny edge.
class _SparkArrow extends StatefulWidget {
  const _SparkArrow();

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
        child: const Icon(
          Icons.arrow_forward_rounded,
          color: Colors.white,
          size: 20,
        ),
        builder: (context, child) {
          final t = _controller.value;
          return Transform.translate(
            // One full left-right cycle per loop, peak around 3pt.
            offset: Offset(math.sin(t * math.pi * 2) * 3, 0),
            child: ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (rect) => LinearGradient(
                // The outer stops are dimmer than the peak, not a different
                // hue: the glint has to read against a white arrow, so it works
                // by brightening through full opacity and dimming back.
                colors: [
                  Colors.white.withValues(alpha: 0.55),
                  Colors.white,
                  Colors.white.withValues(alpha: 0.55),
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
