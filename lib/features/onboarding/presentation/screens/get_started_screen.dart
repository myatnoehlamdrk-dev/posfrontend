import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:posfrontend/features/auth/presentation/screens/login_screen.dart';

/// Design tokens for the welcome page.
///
/// The values are fixed rather than pulled from the app theme: this screen is a
/// piece of brand artwork that has to look the same wherever it is opened, and
/// the palette here is the lavender/purple one from the product design rather
/// than the app's violet.
class _Spec {
  static const pageBg = Color(0xFFFCFBFE);

  static const purple = Color(0xFF7952DB);
  static const purpleSoft = Color(0xFF9D7AD6);
  static const gradientFrom = Color(0xFFA17BEF);
  static const gradientTo = Color(0xFF7752DF);

  static const ink = Color(0xFF292536);
  static const muted = Color(0xFF81798C);
  static const labelInk = Color(0xFF75628F);

  static const panel = Color(0xFFF0EAFA);
  static const panelCore = Color(0xFFDED0F1);
  static const panelMid = Color(0xFFECE3F9);
  static const panelEdge = Color(0xFFF4EFFB);

  static const border = Color(0xFFEAE5F1);
  static const greenBg = Color(0xFFE7F3EA);
  static const green = Color(0xFF2E7D4F);
  static const peachBg = Color(0xFFFBEDE2);

  static const phoneBody = Color(0xFF302B3C);
  static const phoneEdge = Color(0xFF49414F);
  static const phoneScreen = Color(0xFFFAF9FD);
}

/// Which of the product states the preview is showing.
enum _PreviewMode { checkout, inventory, reports, receipt }

/// Which of the four page layouts is in play.
///
/// Resolved from the viewport width rather than scattered across `if`s, because
/// the rules interact: the hero splits at one width, the feature section at
/// another, and the actions change shape with both.
enum _PageLayout { mobile, compact, medium, desktop }

_PageLayout _resolveLayout(double width) {
  if (width > 1100) return _PageLayout.desktop;
  if (width > 800) return _PageLayout.medium;
  if (width > 600) return _PageLayout.compact;
  return _PageLayout.mobile;
}

/// Phone dimensions, kept together so a caller cannot set a width without the
/// bezel and radius that belong with it.
typedef _PhoneGeometry = ({
  double width,
  double height,
  double bezel,
  double radius,
  double tilt,
});

const _PhoneGeometry _mobilePhone = (
  width: 200.0,
  height: 370.0,
  bezel: 6.0,
  radius: 32.0,
  tilt: -6.0,
);

const _PhoneGeometry _desktopPhone = (
  width: 242.0,
  height: 464.0,
  bezel: 8.0,
  radius: 38.0,
  tilt: -7.0,
);

class GetStartedScreen extends StatefulWidget {
  const GetStartedScreen({super.key});

  @override
  State<GetStartedScreen> createState() => _GetStartedScreenState();
}

class _GetStartedScreenState extends State<GetStartedScreen> {
  _PreviewMode _mode = _PreviewMode.checkout;

  /// Anchor for the nav links in the desktop header, so `Features` scrolls to
  /// the section instead of being a dead control.
  final GlobalKey _featureKey = GlobalKey();

  void _showMode(_PreviewMode mode) {
    if (_mode == mode) return;
    setState(() => _mode = mode);
  }

  /// `Get started` goes to sign-in. There is no backend behind this screen, so
  /// there is no account to create here: the app's own login is the real next
  /// step and pretending otherwise would be a dead end.
  void _goToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _openDemo() {
    showDialog<void>(
      context: context,
      builder: (context) => _DemoDialog(mode: _mode, onChanged: _showMode),
    );
  }

  void _scrollToFeatures() {
    final target = _featureKey.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      alignment: 0.05,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Spec.pageBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final layout = _resolveLayout(width);
            final pagePadding = switch (layout) {
              _PageLayout.desktop => 72.0,
              _PageLayout.medium => 40.0,
              _PageLayout.compact => 24.0,
              _PageLayout.mobile => 21.0,
            };
            final pageMaxWidth = switch (layout) {
              // Capped and centred so the page is a wide canvas rather than a
              // narrow column with margins on both sides.
              _PageLayout.desktop => 1440.0,
              _PageLayout.compact || _PageLayout.medium => double.infinity,
              _PageLayout.mobile => 480.0,
            };
            final headlineSize = switch (layout) {
              _PageLayout.desktop => (width * 0.045).clamp(44.0, 58.0),
              _PageLayout.medium => (width * 0.055).clamp(38.0, 50.0),
              _PageLayout.compact || _PageLayout.mobile =>
                (width * 0.105).clamp(30.0, 42.0),
            };

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                pagePadding,
                layout == _PageLayout.desktop ? 0 : 4,
                pagePadding,
                28,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: pageMaxWidth),
                  child: switch (layout) {
                    _PageLayout.mobile => _mobilePage(headlineSize),
                    _PageLayout.compact => _compactPage(headlineSize),
                    _PageLayout.medium ||
                    _PageLayout.desktop => _widePage(headlineSize, layout),
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Phone: one screen, buttons below the illustration, full-width primary.
  Widget _mobilePage(double headlineSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _BrandRow(),
        const SizedBox(height: 20),
        _copyBlock(
          headlineSize: headlineSize,
          align: CrossAxisAlignment.center,
        ),
        const SizedBox(height: 24),
        _IllustrationPanel(mode: _mode, desktop: false),
        const SizedBox(height: 23),
        _PrimaryButton(onPressed: _goToLogin),
        const SizedBox(height: 6),
        _SecondaryAction(onPressed: _openDemo),
        const SizedBox(height: 5),
        const _SupportLine(),
        const SizedBox(height: 32),
        const Divider(color: _Spec.border, height: 1),
        const SizedBox(height: 30),
        _FeatureSection(
          key: _featureKey,
          mode: _mode,
          layout: _FeatureLayout.mobile,
          onSelect: (mode) => setState(() => _mode = mode),
        ),
        const SizedBox(height: 34),
        const _TrustBlock(),
        const SizedBox(height: 30),
        const _Footer(),
      ],
    );
  }

  /// Tablet: the mobile order is kept, but the feature cards go horizontal
  /// because there is finally room for three of them side by side.
  Widget _compactPage(double headlineSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _BrandRow(),
        const SizedBox(height: 20),
        _copyBlock(headlineSize: headlineSize, align: CrossAxisAlignment.center),
        const SizedBox(height: 24),
        _IllustrationPanel(mode: _mode, desktop: false),
        const SizedBox(height: 23),
        _PrimaryButton(onPressed: _goToLogin),
        const SizedBox(height: 6),
        _SecondaryAction(onPressed: _openDemo),
        const SizedBox(height: 5),
        const _SupportLine(),
        const SizedBox(height: 32),
        const Divider(color: _Spec.border, height: 1),
        const SizedBox(height: 30),
        _FeatureSection(
          key: _featureKey,
          mode: _mode,
          layout: _FeatureLayout.introAbove,
          onSelect: (mode) => setState(() => _mode = mode),
        ),
        const SizedBox(height: 34),
        const _TrustRow(),
        const SizedBox(height: 30),
        const _FooterRow(),
      ],
    );
  }

  /// 801px and up: a real two-column hero with the header navigation. Above
  /// 1100px the illustration panel and the feature section also go wide.
  Widget _widePage(double headlineSize, _PageLayout layout) {
    final big = layout == _PageLayout.desktop;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DesktopHeader(
          onGetStarted: _goToLogin,
          onNavigate: _scrollToFeatures,
        ),
        const Divider(color: _Spec.border, height: 1),
        const SizedBox(height: 65),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _copyBlock(
                    headlineSize: headlineSize,
                    align: CrossAxisAlignment.start,
                    wide: true,
                  ),
                  // Actions sit inside the copy column on this layout, never
                  // under the illustration.
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      _PrimaryButton(
                        onPressed: _goToLogin,
                        width: 170,
                        height: 53,
                        radius: 10,
                      ),
                      const SizedBox(width: 23),
                      _SecondaryAction(onPressed: _openDemo, height: 53),
                    ],
                  ),
                  const SizedBox(height: 17),
                  const _SupportLine(alignment: MainAxisAlignment.start),
                ],
              ),
            ),
            const SizedBox(width: 36),
            Expanded(
              child: _IllustrationPanel(mode: _mode, desktop: big),
            ),
          ],
        ),
        SizedBox(height: big ? 63 : 40),
        const Divider(color: _Spec.border, height: 1),
        SizedBox(height: big ? 35 : 28),
        _FeatureSection(
          key: _featureKey,
          mode: _mode,
          layout: big ? _FeatureLayout.introBeside : _FeatureLayout.introAbove,
          onSelect: (mode) => setState(() => _mode = mode),
        ),
        SizedBox(height: big ? 34 : 30),
        const _TrustRow(),
        const SizedBox(height: 30),
        const _FooterRow(),
      ],
    );
  }

  /// Tagline, headline and description. Shared by every layout so the copy and
  /// its spacing cannot drift between them.
  Widget _copyBlock({
    required double headlineSize,
    required CrossAxisAlignment align,
    bool wide = false,
  }) {
    return Column(
      crossAxisAlignment: align,
      children: [
        const _EyebrowLabel(),
        const SizedBox(height: 16),
        _Headline(
          size: headlineSize,
          align: align,
          tight: wide,
        ),
        SizedBox(height: wide ? 23 : 17),
        _Description(wide: wide),
        if (wide) const SizedBox(height: 28),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Step 2 — brand row
// -----------------------------------------------------------------------------

class _BrandRow extends StatelessWidget {
  const _BrandRow();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_Spec.gradientFrom, _Spec.gradientTo],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _Spec.purple.withValues(alpha: 0.28),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.storefront_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 8),
            const _Wordmark(size: 23),
          ],
        ),
      ),
    );
  }
}

/// Desktop header: brand on the left, the two links in the middle, the action
/// on the right, and a hairline under the whole thing. On mobile this is
/// replaced by [_BrandRow], which is a centred mark with no navigation.
class _DesktopHeader extends StatelessWidget {
  const _DesktopHeader({
    required this.onGetStarted,
    required this.onNavigate,
  });

  final VoidCallback onGetStarted;
  final VoidCallback onNavigate;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 112,
      child: Row(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_Spec.gradientFrom, _Spec.gradientTo],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _Spec.purple.withValues(alpha: 0.28),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 11),
              const _Wordmark(size: 26),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _HeaderLink(label: 'Features', onTap: onNavigate),
              const SizedBox(width: 34),
              _HeaderLink(label: 'How it works', onTap: onNavigate),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: 140,
            height: 42,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: onGetStarted,
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _Spec.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Get started',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _Spec.purple,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 15,
                        color: _Spec.purple,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One header link. 44px tall so it stays a comfortable target even though the
/// text itself is 13px.
class _HeaderLink extends StatelessWidget {
  const _HeaderLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _Spec.ink,
            ),
          ),
        ),
      ),
    );
  }
}

/// `smartpos.` with the final dot in purple and the two halves at different
/// weights, which is what makes it read as a brand rather than as a sentence.
class _Wordmark extends StatelessWidget {
  const _Wordmark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'smart',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: _Spec.ink,
              ),
            ),
            TextSpan(
              text: 'pos',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: _Spec.ink,
              ),
            ),
            const TextSpan(
              text: '.',
              style: TextStyle(color: _Spec.purple),
            ),
          ],
        ),
        style: GoogleFonts.manrope(
          fontSize: size,
          letterSpacing: -1,
          height: 1,
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Steps 3-5 — copy
// -----------------------------------------------------------------------------

/// `SMALL BUSINESS. BIG POSSIBILITIES.` with a haloed dot in front of it.
class _EyebrowLabel extends StatelessWidget {
  const _EyebrowLabel();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Small business. Big possibilities.',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _Spec.purpleSoft.withValues(alpha: 0.18),
            ),
            alignment: Alignment.center,
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: _Spec.purpleSoft,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              'SMALL BUSINESS. BIG POSSIBILITIES.',
              maxLines: 2,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.3,
                height: 1.5,
                color: _Spec.labelInk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Three fixed lines. The break points are part of the design, so they are
/// written as three children rather than left to wrap.
class _Headline extends StatelessWidget {
  const _Headline({
    required this.size,
    required this.align,
    this.tight = false,
  });

  final double size;
  final CrossAxisAlignment align;

  /// Wider layouts get the tighter tracking and the slightly taller leading;
  /// the mobile numbers are already at the limit of legibility.
  final bool tight;

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.manrope(
      fontSize: size,
      fontWeight: FontWeight.w700,
      letterSpacing: tight ? -3 : -2,
      height: tight ? 1.14 : 1.15,
    );

    return Semantics(
      header: true,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: align,
        children: [
          Text('Your business.', style: style.copyWith(color: _Spec.ink)),
          Text('In your pocket.', style: style.copyWith(color: _Spec.ink)),
          Text('Under control.', style: style.copyWith(color: _Spec.purple)),
        ],
      ),
    );
  }
}

class _Description extends StatelessWidget {
  const _Description({this.wide = false});

  /// Wider layouts get a longer measure and more leading: the measure grows
  /// with the column, not with the viewport.
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: wide ? 370 : 320),
      child: Text(
        'Manage ,print sales, track inventory, and understand your business — all from '
        'one simple app.',
        textAlign: wide ? TextAlign.start : TextAlign.center,
        style: GoogleFonts.dmSans(
          fontSize: wide ? 15 : 13,
          height: wide ? 1.9 : 1.75,
          color: _Spec.muted,
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Steps 6-9 — illustration panel
// -----------------------------------------------------------------------------

class _IllustrationPanel extends StatelessWidget {
  const _IllustrationPanel({required this.mode, required this.desktop});

  final _PreviewMode mode;

  /// Desktop gets a bigger panel, a bigger phone and a third notification:
  /// there is room for it, and one card on a panel this size looks sparse.
  final bool desktop;

  @override
  Widget build(BuildContext context) {
    final geometry = desktop ? _desktopPhone : _mobilePhone;

    return SizedBox(
      height: desktop ? 533 : 400,
      width: double.infinity,
      child: Stack(
        // The notification cards overhang the panel on desktop, so nothing in
        // here may clip. Only the background's own texture is clipped, by its
        // rounded corners, in [_PanelBackground].
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: _PanelBackground(radius: desktop ? 28 : 24, ringScale: desktop ? 1.3 : 1.0),
          ),
          // Rotation only: the phone and everything inside it turn as one
          // group, which is what makes it read as a tilted object rather than
          // a straight device holding a tilted picture.
          Center(
            child: Transform.rotate(
              angle: geometry.tilt * math.pi / 180,
              child: _PhoneMock(mode: mode, geometry: geometry),
            ),
          ),
          if (desktop) ...[
            const Positioned(top: 102, left: -24, child: _SaleNotification()),
            const Positioned(top: 172, right: -15, child: _GrowthNotification()),
            const Positioned(bottom: 106, right: -23, child: _StockNotification()),
          ] else ...[
            const Positioned(top: 10, left: 3, child: _SaleNotification()),
            const Positioned(bottom: 12, right: 3, child: _StockNotification()),
          ],
          Positioned(
            left: 0,
            right: 0,
            bottom: desktop ? 14 : 8,
            child: const _PanelCaption(),
          ),
        ],
      ),
    );
  }
}

/// Lavender base with a radial lift, a dotted texture that fades out at the top
/// and bottom edges, and the two concentric rings the phone sits inside.
class _PanelBackground extends StatelessWidget {
  const _PanelBackground({required this.radius, required this.ringScale});

  final double radius;

  /// Rings scale with the panel rather than staying at their mobile size, which
  /// would leave them hidden behind the phone on a 533px panel.
  final double ringScale;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _Spec.panel,
        borderRadius: BorderRadius.circular(radius),
        gradient: const RadialGradient(
          center: Alignment.center,
          radius: 0.78,
          colors: [_Spec.panelCore, _Spec.panelMid, _Spec.panelEdge],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      // Clipped so the dots and rings stop at the rounded corners; the panel's
      // gradient already follows the shape through its own decoration.
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _DotPainter())),
            Center(
              child: SizedBox(
                width: 320 * ringScale,
                height: 320 * ringScale,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _Spec.purple.withValues(alpha: 0.13),
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: SizedBox(
                width: 260 * ringScale,
                height: 260 * ringScale,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _Spec.purple.withValues(alpha: 0.17),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dot grid at roughly 17px. The dots thin out towards the top and bottom so
/// the texture never competes with the phone or the panel edge.
class _DotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const step = 17.0;
    final paint = Paint();
    for (var y = step / 2; y < size.height; y += step) {
      // 1 in the middle of the panel, 0 at both edges.
      final distanceToEdge =
          math.min(y, size.height - y) / (size.height / 2);
      final fade = (distanceToEdge * 1.6).clamp(0.0, 1.0);
      if (fade == 0) continue;
      for (var x = step / 2; x < size.width; x += step) {
        paint.color = _Spec.purpleSoft.withValues(alpha: 0.32 * fade);
        canvas.drawCircle(Offset(x, y), 0.9, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PanelCaption extends StatelessWidget {
  const _PanelCaption();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: _Spec.purpleSoft,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'A little app. A big difference.',
              style: GoogleFonts.dmSans(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: _Spec.labelInk,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The miniature device, drawn at the size it appears on the page.
///
/// The screen fills the frame apart from a 6px bezel and the dashboard is laid
/// out straight into it — no transform, no `FittedBox`. Scaling a finished
/// dashboard is what produced the earlier "screenshot inside a phone" look,
/// because the type ended up at a third of its design size with empty space
/// around it.
class _PhoneMock extends StatelessWidget {
  const _PhoneMock({required this.mode, required this.geometry});

  final _PreviewMode mode;
  final _PhoneGeometry geometry;

  @override
  Widget build(BuildContext context) {
    // The screen padding grows with the device so the dashboard's own type does
    // not end up touching the frame on the larger one.
    final horizontal = geometry.width >= 220 ? 14.0 : 12.0;
    final vertical = geometry.width >= 220 ? 14.0 : 12.0;

    return Container(
      width: geometry.width,
      height: geometry.height,
      decoration: BoxDecoration(
        color: _Spec.phoneBody,
        borderRadius: BorderRadius.circular(geometry.radius),
        border: Border.all(color: _Spec.phoneEdge, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 20,
            offset: const Offset(8, 14),
          ),
        ],
      ),
      padding: EdgeInsets.all(geometry.bezel),
      child: Container(
        decoration: BoxDecoration(
          color: _Spec.phoneScreen,
          borderRadius: BorderRadius.circular(geometry.radius - geometry.bezel),
        ),
        padding: EdgeInsets.fromLTRB(horizontal, vertical, horizontal, 8),
        clipBehavior: Clip.antiAlias,
        child: _MiniDashboard(mode: mode, roomy: geometry.width >= 220),
      ),
    );
  }
}

/// Everything inside the phone, at pre-scale size.
class _MiniDashboard extends StatelessWidget {
  const _MiniDashboard({required this.mode, required this.roomy});

  final _PreviewMode mode;

  /// The desktop phone has ~100px more screen than the mobile one. Left empty
  /// it would all go to the chart, so the taller device gets one more real
  /// block instead.
  final bool roomy;

  @override
  Widget build(BuildContext context) {
    // Checkout preview is a different screen, not another card on the
    // dashboard, so it replaces the body rather than being swapped into it.
    if (mode == _PreviewMode.receipt) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MiniHeader(),
          SizedBox(height: 7),
          Expanded(child: _MiniReceipt()),
        ],
      );
    }

    final copy = switch (mode) {
      _PreviewMode.checkout => const (
        title: "Today's sales",
        amount: r'$1,284.00',
        trend: '18.6% vs. previous period',
        labelA: 'Transactions',
        valueA: '32',
        subA: '+8 today',
        labelB: 'Items sold',
        valueB: '86',
        subB: '+12 today',
      ),
      _PreviewMode.inventory => const (
        title: 'Products in stock',
        amount: '1,248',
        trend: '7 low on hand today',
        labelA: 'Items tracked',
        valueA: '1,248',
        subA: 'across 4 stores',
        labelB: 'Low stock',
        valueB: '7',
        subB: 'needs reorder',
      ),
      _PreviewMode.reports => const (
        title: 'Monthly sales',
        amount: r'$24,860.00',
        trend: '12.4% vs. last month',
        labelA: 'Transactions',
        valueA: '412',
        subA: '+34 this month',
        labelB: 'Avg. order',
        valueB: r'$60.34',
        subB: 'steady',
      ),
      // Unreachable: the receipt path returns above. Listed so the switch stays
      // exhaustive instead of quietly falling through with no copy at all.
      _PreviewMode.receipt => const (
        title: '',
        amount: '',
        trend: '',
        labelA: '',
        valueA: '',
        subA: '',
        labelB: '',
        valueB: '',
        subB: '',
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _MiniHeader(),
        const SizedBox(height: 7),
        Text(
          'Your store, at a glance',
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _Spec.ink,
          ),
        ),
        const SizedBox(height: 7),
        // The sales card is the flex slot: it takes whatever height is left so
        // the chart grows into it and the dashboard always ends flush with the
        // bottom of the screen instead of stopping short of it.
        Expanded(
          child: _SalesCard(
            title: copy.title,
            amount: copy.amount,
            trend: copy.trend,
          ),
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: copy.labelA,
                value: copy.valueA,
                sub: copy.subA,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                label: copy.labelB,
                value: copy.valueB,
                sub: copy.subB,
              ),
            ),
          ],
        ),
        if (roomy) ...[
          const SizedBox(height: 7),
          Row(
            children: [
              Text(
                'Top products',
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _Spec.ink,
                ),
              ),
              const Spacer(),
              Text(
                'Units',
                style: GoogleFonts.dmSans(fontSize: 8, color: _Spec.muted),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const _ProductRow(
            name: 'Espresso beans',
            units: '24',
            amount: r'$312',
          ),
          const _ProductRow(
            name: 'Paper cups · 12oz',
            units: '18',
            amount: r'$90',
          ),
        ],
        const SizedBox(height: 7),
        Row(
          children: [
            Text(
              'Recent activity',
              style: GoogleFonts.dmSans(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _Spec.ink,
              ),
            ),
            const Spacer(),
            Text(
              'View all',
              style: GoogleFonts.dmSans(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: _Spec.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        _TransactionRow(
          order: 'Order #1042',
          meta: '3 items · Just now',
          amount: r'$48.00',
        ),
        _TransactionRow(
          order: 'Order #1041',
          meta: '2 items · 12 min ago',
          amount: r'$32.50',
        ),
        const SizedBox(height: 5),
        const _NewSaleBar(),
        const SizedBox(height: 5),
        const _MiniNav(),
      ],
    );
  }
}

/// Brand mark and profile badge at the top of every screen in the preview.
class _MiniHeader extends StatelessWidget {
  const _MiniHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_Spec.gradientFrom, _Spec.gradientTo],
            ),
          ),
          child: const Icon(
            Icons.storefront_rounded,
            color: Colors.white,
            size: 12,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          'smart',
          style: GoogleFonts.manrope(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: _Spec.ink,
          ),
        ),
        Text(
          'pos',
          style: GoogleFonts.manrope(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: _Spec.ink,
          ),
        ),
        const Spacer(),
        Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: _Spec.panel,
          ),
          child: Text(
            'JD',
            style: GoogleFonts.dmSans(
              fontSize: 7,
              fontWeight: FontWeight.w700,
              color: _Spec.labelInk,
            ),
          ),
        ),
      ],
    );
  }
}

/// The print-checkout screen: a receipt on paper-white with a print action, so
/// the fourth feature reads as its own screen rather than as more dashboard.
class _MiniReceipt extends StatelessWidget {
  const _MiniReceipt();

  static const _lines = <(String, String, String)>[
    ('Espresso beans', '×2', r'$24.00'),
    ('Paper cups 12oz', '×1', r'$5.00'),
    ('Sugar sachets', '×3', r'$3.00'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _Spec.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              'SMART POS STORE',
              style: GoogleFonts.manrope(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: _Spec.ink,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Center(
            child: Text(
              '12 Market Street · +95 123 456',
              style: GoogleFonts.dmSans(fontSize: 7, color: _Spec.muted),
            ),
          ),
          const SizedBox(height: 1),
          Center(
            child: Text(
              'Receipt #1042 · Today, 09:42',
              style: GoogleFonts.dmSans(fontSize: 7, color: _Spec.muted),
            ),
          ),
          const SizedBox(height: 7),
          const Divider(color: _Spec.border, height: 1),
          const SizedBox(height: 4),
          for (final line in _lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${line.$1} ${line.$2}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(fontSize: 8, color: _Spec.ink),
                    ),
                  ),
                  Text(
                    line.$3,
                    style: GoogleFonts.dmSans(fontSize: 8, color: _Spec.ink),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          const Divider(color: _Spec.border, height: 1),
          const SizedBox(height: 5),
          _ReceiptTotal(label: 'Subtotal', value: r'$32.00'),
          _ReceiptTotal(label: 'Tax', value: r'$1.60'),
          const SizedBox(height: 3),
          _ReceiptTotal(label: 'Total', value: r'$33.60', emphasise: true),
          const SizedBox(height: 5),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: _Spec.green,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                'Paid · Visa •••• 4242',
                style: GoogleFonts.dmSans(fontSize: 7.5, color: _Spec.green),
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: double.infinity,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _Spec.purple,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.receipt_long_rounded,
                  size: 11,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  'Print receipt',
                  style: GoogleFonts.dmSans(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Center(
            child: Text(
              '80mm · Bluetooth printer ready',
              style: GoogleFonts.dmSans(fontSize: 6.5, color: _Spec.muted),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptTotal extends StatelessWidget {
  const _ReceiptTotal({
    required this.label,
    required this.value,
    this.emphasise = false,
  });

  final String label;
  final String value;
  final bool emphasise;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: emphasise ? 9.5 : 8,
                fontWeight: emphasise ? FontWeight.w700 : FontWeight.w400,
                color: emphasise ? _Spec.ink : _Spec.muted,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: emphasise ? 9.5 : 8,
              fontWeight: emphasise ? FontWeight.w700 : FontWeight.w500,
              color: _Spec.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _SalesCard extends StatelessWidget {
  const _SalesCard({
    required this.title,
    required this.amount,
    required this.trend,
  });

  final String title;
  final String amount;
  final String trend;

  /// Sample heights for the twelve bars. The last two are the ones that got
  /// highlighted, which is what makes the chart read as a chart and not as a
  /// row of identical blocks.
  static const List<double> _bars = [
    0.34, 0.52, 0.41, 0.66, 0.48, 0.72,
    0.58, 0.83, 0.62, 0.75, 0.88, 1.0,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8560DE), Color(0xFFA081E4)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.dmSans(
              fontSize: 9,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            amount,
            maxLines: 1,
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              const Icon(
                Icons.trending_up_rounded,
                size: 10,
                color: Color(0xFFBFF3D2),
              ),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  trend,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontSize: 8,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // The chart takes the rest of the card, so it grows with the space
          // the card has rather than sitting at a fixed height under empty
          // purple.
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < _bars.length; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.6),
                      child: FractionallySizedBox(
                        heightFactor: _bars[i],
                        alignment: Alignment.bottomCenter,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: i >= _bars.length - 2
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.38),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
  });

  final String label;
  final String value;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _Spec.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.dmSans(fontSize: 8, color: _Spec.muted),
          ),
          const SizedBox(height: 1),
          Text(
            value,
            maxLines: 1,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _Spec.ink,
              height: 1.1,
            ),
          ),
          Text(
            sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.dmSans(fontSize: 7.5, color: _Spec.green),
          ),
        ],
      ),
    );
  }
}

/// One line of the desktop phone's `Top products` block.
class _ProductRow extends StatelessWidget {
  const _ProductRow({
    required this.name,
    required this.units,
    required this.amount,
  });

  final String name;
  final String units;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: _Spec.border.withValues(alpha: 0.7)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSans(fontSize: 8.5, color: _Spec.ink),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            units,
            style: GoogleFonts.dmSans(
              fontSize: 8,
              fontWeight: FontWeight.w600,
              color: _Spec.purple,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            amount,
            style: GoogleFonts.dmSans(
              fontSize: 8.5,
              fontWeight: FontWeight.w600,
              color: _Spec.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({
    required this.order,
    required this.meta,
    required this.amount,
  });

  final String order;
  final String meta;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: _Spec.border.withValues(alpha: 0.7)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 15,
            height: 15,
            decoration: BoxDecoration(
              color: _Spec.panel,
              borderRadius: BorderRadius.circular(5),
            ),
            child: const Icon(
              Icons.shopping_bag_rounded,
              size: 9,
              color: _Spec.purple,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  order,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: _Spec.ink,
                  ),
                ),
                Text(
                  meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(fontSize: 7, color: _Spec.muted),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: GoogleFonts.dmSans(
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              color: _Spec.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _NewSaleBar extends StatelessWidget {
  const _NewSaleBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _Spec.purple,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.add_rounded, size: 11, color: Colors.white),
          const SizedBox(width: 3),
          Text(
            'New sale',
            style: GoogleFonts.dmSans(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniNav extends StatelessWidget {
  const _MiniNav();

  static const _items = <(IconData, String)>[
    (Icons.home_rounded, 'Home'),
    (Icons.inventory_2_rounded, 'Inventory'),
    (Icons.bar_chart_rounded, 'Reports'),
    (Icons.settings_rounded, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        for (final (index, item) in _items.indexed)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                item.$1,
                size: 13,
                color: index == 0 ? _Spec.purple : _Spec.muted,
              ),
              const SizedBox(height: 2),
              Text(
                item.$2,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                  fontSize: 7,
                  fontWeight: index == 0 ? FontWeight.w700 : FontWeight.w500,
                  color: index == 0 ? _Spec.purple : _Spec.muted,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// Notification 1 — sale completed, straddling the phone's upper-left edge.
class _SaleNotification extends StatelessWidget {
  const _SaleNotification();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -3 * math.pi / 180,
      child: _NotificationCard(
        icon: Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: _Spec.greenBg,
          ),
          child: const Icon(
            Icons.check_rounded,
            size: 13,
            color: _Spec.green,
          ),
        ),
        title: 'Another happy customer.',
        subtitle: 'Sale completed · \$48.00',
      ),
    );
  }
}

/// Notification 2 — inventory in sync, straddling the phone's lower-right edge.
class _StockNotification extends StatelessWidget {
  const _StockNotification();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 4 * math.pi / 180,
      child: _NotificationCard(
        trailing: Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: _Spec.green,
          ),
        ),
        icon: Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _Spec.panel,
            borderRadius: BorderRadius.circular(7),
          ),
          child: const Icon(
            Icons.inventory_2_rounded,
            size: 12,
            color: _Spec.purple,
          ),
        ),
        title: 'All stocked up',
        subtitle: 'Your inventory is in sync',
      ),
    );
  }
}

/// Notification 3 — desktop only. A growth stat rather than a message, which is
/// what fills the middle-right of the larger panel without crowding the phone.
class _GrowthNotification extends StatelessWidget {
  const _GrowthNotification();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 3 * math.pi / 180,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(11),
          boxShadow: [
            BoxShadow(
              color: _Spec.ink.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Looking good!',
              style: GoogleFonts.dmSans(
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                color: _Spec.ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '+18.6%',
              style: GoogleFonts.manrope(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: _Spec.green,
                height: 1.1,
              ),
            ),
            Text(
              'Sales are on the rise',
              style: GoogleFonts.dmSans(fontSize: 7.5, color: _Spec.muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kept deliberately compact: it has to overlap the phone by only a sliver so
/// the sales amount and the chart underneath stay readable.
class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final Widget icon;
  final Widget? trailing;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 130),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        boxShadow: [
          BoxShadow(
            color: _Spec.ink.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 7),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    color: _Spec.ink,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontSize: 7.5,
                    color: _Spec.muted,
                  ),
                ),
              ],
            ),
          ),
          if (trailing case final Widget dot) ...[
            const SizedBox(width: 6),
            dot,
          ],
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Step 10 — actions
// -----------------------------------------------------------------------------

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.onPressed,
    this.width,
    this.height,
    this.radius,
  });

  final VoidCallback onPressed;

  /// Left null on mobile, where the button is full width and 52 tall. On
  /// desktop it is a fixed 170x53: a button that spans the whole text column
  /// is the mobile arrangement and reads as a form, not as a call to action.
  final double? width;
  final double? height;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final buttonRadius = radius ?? 13;

    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? 52,
      child: Material(
        color: _Spec.purple,
        borderRadius: BorderRadius.circular(buttonRadius),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(buttonRadius),
          onTap: onPressed,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(buttonRadius),
              boxShadow: [
                BoxShadow(
                  color: _Spec.purple.withValues(alpha: 0.32),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Get started',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  // A fixed gap rather than a space-between row: on a fixed
                  // 170px button the arrow has to stay next to the label.
                  const SizedBox(width: 23),
                  _SparkArrow(
                    animated: !MediaQuery.disableAnimationsOf(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The arrow on the primary button — the only coloured control on the page, so
/// it is the only one that moves.
///
/// Two motions on one loop: a small left-right nudge so the eye follows the
/// glyph, and a highlight travelling across it. The highlight is a `ShaderMask`
/// rather than an opacity fade on the icon, because the sweep can dim the arrow
/// as it passes instead of only brightening it, which is what makes it read as
/// light crossing a surface. The glyph itself is built once and reused as the
/// shader's alpha source, so each frame only rebuilds the gradient.
///
/// [animated] is false when the platform asks for reduced motion, and the arrow
/// is then a plain icon.
class _SparkArrow extends StatefulWidget {
  const _SparkArrow({this.animated = true});

  /// Fixed to white: the arrow only ever sits on the purple primary button,
  /// and a colour parameter nothing sets is a parameter to get wrong later.
  final bool animated;

  @override
  State<_SparkArrow> createState() => _SparkArrowState();
}

class _SparkArrowState extends State<_SparkArrow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animated) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant _SparkArrow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The reduced-motion setting can change while this is mounted.
    if (widget.animated == oldWidget.animated) return;
    if (widget.animated) {
      _controller.repeat();
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final arrow = const Icon(
      Icons.arrow_forward_rounded,
      color: Colors.white,
      size: 18,
    );

    if (!widget.animated) return arrow;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        child: arrow,
        builder: (context, child) {
          final t = _controller.value;
          return Transform.translate(
            // One full left-right cycle per loop, peak around 2.5pt.
            offset: Offset(math.sin(t * math.pi * 2) * 2.5, 0),
            child: ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (rect) => LinearGradient(
                // Dimmer outside the peak, not a different hue: the sweep has
                // to read against the glyph itself.
                colors: [
                  Colors.white.withValues(alpha: 0.5),
                  Colors.white,
                  Colors.white.withValues(alpha: 0.5),
                ],
                stops: const [0.32, 0.5, 0.68],
                // Slides fully off the left edge at t=0 and off the right at
                // t=1, so the loop has no visible seam.
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

class _SecondaryAction extends StatelessWidget {
  const _SecondaryAction({required this.onPressed, this.height = 44});

  final VoidCallback onPressed;

  /// Matched to the primary button's height on desktop so the pair reads as one
  /// row of actions.
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _Spec.border, width: 1.2),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    size: 12,
                    color: _Spec.ink,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'See it in action',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _Spec.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SupportLine extends StatelessWidget {
  const _SupportLine({
    this.alignment = MainAxisAlignment.center,
  });

  /// Left-packed inside the desktop hero column, centred everywhere else.
  final MainAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    return Row(
      // Centred rather than left-packed on mobile: the parent hands this a
      // full-width slot, and `mainAxisSize.min` alone would leave it at the
      // left edge.
      mainAxisAlignment: alignment,
      children: [
        const Icon(Icons.check_rounded, size: 11, color: _Spec.muted),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            'Simple to set up · Made to grow with you',
            style: GoogleFonts.dmSans(fontSize: 9, color: _Spec.muted),
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Step 11 — feature cards
// -----------------------------------------------------------------------------

/// How the feature section arranges itself at this breakpoint.
enum _FeatureLayout {
  /// Centred heading with three cards stacked: the phone layout.
  mobile,

  /// Centred heading with three cards in a row: tablet.
  introAbove,

  /// Intro column on the left, three cards in a row beside it: desktop.
  introBeside,
}

class _FeatureSection extends StatelessWidget {
  const _FeatureSection({
    super.key,
    required this.mode,
    required this.layout,
    required this.onSelect,
  });

  final _PreviewMode mode;
  final _FeatureLayout layout;
  final ValueChanged<_PreviewMode> onSelect;

  @override
  Widget build(BuildContext context) {
    return switch (layout) {
      _FeatureLayout.mobile => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeading(compact: false),
          const SizedBox(height: 20),
          for (final (index, card) in _stackedCards().indexed) ...[
            if (index > 0) const SizedBox(height: 11),
            card,
          ],
        ],
      ),
      _FeatureLayout.introAbove => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeading(compact: true),
          const SizedBox(height: 22),
          _CardRow(cards: _wideCards()),
        ],
      ),
      _FeatureLayout.introBeside => LayoutBuilder(
        builder: (context, constraints) {
          // 24/76 split with a fixed 32px gutter, as designed: the intro is a
          // label for the cards beside it, not a fourth column.
          final introWidth = constraints.maxWidth * 0.24;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: introWidth,
                child: _SectionIntro(align: CrossAxisAlignment.start),
              ),
              const SizedBox(width: 32),
              Expanded(child: _CardRow(cards: _wideCards())),
            ],
          );
        },
      ),
    };
  }

  /// The phone arrangement: icon beside the text, full width.
  List<Widget> _stackedCards() {
    return [
      _FeatureCard(
        icon: Icons.bolt_rounded,
        iconBackground: _Spec.panel,
        title: 'Checkout in a flash',
        description:
            'Less waiting. More selling. Make every checkout quick and '
            'effortless.',
        label: 'Fast checkout',
        selected: mode == _PreviewMode.checkout,
        onTap: () => onSelect(_PreviewMode.checkout),
      ),
      _FeatureCard(
        icon: Icons.inventory_2_rounded,
        iconBackground: _Spec.greenBg,
        title: 'Stock, always in sync',
        description:
            'Know what’s on your shelves, with inventory that updates in real '
            'time.',
        label: 'Live inventory',
        selected: mode == _PreviewMode.inventory,
        onTap: () => onSelect(_PreviewMode.inventory),
      ),
      _FeatureCard(
        icon: Icons.bar_chart_rounded,
        iconBackground: _Spec.peachBg,
        title: 'See the bigger picture',
        description:
            'Turn your daily sales into clear insights and smarter decisions.',
        label: 'Daily reports',
        selected: mode == _PreviewMode.reports,
        onTap: () => onSelect(_PreviewMode.reports),
      ),
    ];
  }

  /// The tablet and desktop arrangement: icon on top, so three of them fit
  /// across the page.
  List<Widget> _wideCards() {
    return [
      _FeatureCardWide(
        icon: Icons.bolt_rounded,
        iconBackground: _Spec.panel,
        title: 'Checkout in a flash',
        description:
            'Less waiting. More selling. Make every checkout quick and '
            'effortless.',
        label: 'Fast checkout',
        selected: mode == _PreviewMode.checkout,
        onTap: () => onSelect(_PreviewMode.checkout),
      ),
      _FeatureCardWide(
        icon: Icons.inventory_2_rounded,
        iconBackground: _Spec.greenBg,
        title: 'Stock, always in sync',
        description:
            'Know what’s on your shelves, with inventory that updates in real '
            'time.',
        label: 'Live inventory',
        selected: mode == _PreviewMode.inventory,
        onTap: () => onSelect(_PreviewMode.inventory),
      ),
      _FeatureCardWide(
        icon: Icons.bar_chart_rounded,
        iconBackground: _Spec.peachBg,
        title: 'See the bigger picture',
        description:
            'Turn your daily sales into clear insights and smarter decisions.',
        label: 'Daily reports',
        selected: mode == _PreviewMode.reports,
        onTap: () => onSelect(_PreviewMode.reports),
      ),
    ];
  }
}

/// Three equal cards with a 16px gutter, stretched to whatever width it is
/// given.
class _CardRow extends StatelessWidget {
  const _CardRow({required this.cards});

  final List<Widget> cards;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, card) in cards.indexed) ...[
            if (index > 0) const SizedBox(width: 16),
            Expanded(child: card),
          ],
        ],
      ),
    );
  }
}

/// Centred heading for the stacked and tablet arrangements.
class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.compact});

  /// Tablet and desktop carry the small label above the heading; the phone
  /// does not have room for it.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 21.0 : 24.0;
    return Column(
      children: [
        if (compact) ...[
          Text(
            'LESS FRICTION. MORE FLOW.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: _Spec.labelInk,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Semantics(
          header: true,
          excludeSemantics: true,
          child: Column(
            children: [
              Text(
                'Everything you need.',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: size,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.8,
                  color: _Spec.ink,
                ),
              ),
              Text(
                'Nothing you don’t.',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: size,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.8,
                  color: _Spec.muted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your everyday essentials, working better together.',
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
            fontSize: compact ? 10 : 12,
            color: _Spec.muted,
          ),
        ),
      ],
    );
  }
}

/// Left-aligned intro for the desktop arrangement: label, heading, one short
/// supporting line.
class _SectionIntro extends StatelessWidget {
  const _SectionIntro({required this.align});

  final CrossAxisAlignment align;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          'LESS FRICTION. MORE FLOW.',
          textAlign: align == CrossAxisAlignment.start
              ? TextAlign.start
              : TextAlign.center,
          style: GoogleFonts.dmSans(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: _Spec.labelInk,
          ),
        ),
        const SizedBox(height: 10),
        Semantics(
          header: true,
          excludeSemantics: true,
          child: Column(
            crossAxisAlignment: align,
            children: [
              Text(
                'Everything you need.',
                textAlign: align == CrossAxisAlignment.start
                    ? TextAlign.start
                    : TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.8,
                  color: _Spec.ink,
                ),
              ),
              Text(
                'Nothing you don’t.',
                textAlign: align == CrossAxisAlignment.start
                    ? TextAlign.start
                    : TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.8,
                  color: _Spec.muted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 165),
          child: Text(
            'Your everyday essentials, working better together.',
            textAlign: align == CrossAxisAlignment.start
                ? TextAlign.start
                : TextAlign.center,
            style: GoogleFonts.dmSans(fontSize: 10, color: _Spec.muted),
          ),
        ),
      ],
    );
  }
}

/// Tablet and desktop card: icon on top, title under it, label pinned to the
/// bottom so the three cards line up however the copy wraps.
class _FeatureCardWide extends StatelessWidget {
  const _FeatureCardWide({
    required this.icon,
    required this.iconBackground,
    required this.title,
    required this.description,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBackground;
  final String title;
  final String description;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFF6F2FB) : Colors.white,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
          decoration: BoxDecoration(
            // A lavender tint rather than a purple outline: three outlined
            // cards in a row compete with the primary button for attention.
            color: selected ? const Color(0xFFF6F2FB) : Colors.white,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: selected ? const Color(0xFFE4D8F4) : _Spec.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 35,
                height: 35,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 17, color: _Spec.purple),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _Spec.ink,
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Text(
                  description,
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    height: 1.8,
                    color: _Spec.muted,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    label,
                    style: GoogleFonts.dmSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: _Spec.purple,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 11,
                    color: _Spec.purple,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.iconBackground,
    required this.title,
    required this.description,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBackground;
  final String title;
  final String description;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: selected ? _Spec.purple : _Spec.border,
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: _Spec.purple.withValues(alpha: 0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: _Spec.purple),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _Spec.ink,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        height: 1.8,
                        color: _Spec.muted,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        Text(
                          label,
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _Spec.purple,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 13,
                          color: _Spec.purple,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Step 12 — trust line and footer
// -----------------------------------------------------------------------------

/// Stacked trust line for the phone, where there is no room for a single row.
class _TrustBlock extends StatelessWidget {
  const _TrustBlock();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(
          Icons.verified_user_rounded,
          size: 18,
          color: _Spec.purpleSoft,
        ),
        const SizedBox(height: 8),
        Text(
          'Your business is personal. We keep it that way.',
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: _Spec.ink,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Secure by design. Simple by choice.',
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(fontSize: 10, color: _Spec.muted),
        ),
      ],
    );
  }
}

/// One centred row for tablet and desktop: shield, first line, hairline
/// separator, second line.
class _TrustRow extends StatelessWidget {
  const _TrustRow();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 8,
        children: [
          const Icon(
            Icons.verified_user_rounded,
            size: 17,
            color: _Spec.purpleSoft,
          ),
          Text(
            'Your business is personal. We keep it that way.',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _Spec.ink,
            ),
          ),
          Container(width: 1, height: 14, color: _Spec.border),
          Text(
            'Secure by design. Simple by choice.',
            style: GoogleFonts.dmSans(fontSize: 11, color: _Spec.muted),
          ),
        ],
      ),
    );
  }
}

/// Phone footer: brand, tagline and copyright stacked and centred.
class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(color: _Spec.border, height: 1),
        const SizedBox(height: 22),
        const _Wordmark(size: 19),
        const SizedBox(height: 6),
        Text(
          'A smarter way to run your everyday.',
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(fontSize: 10, color: _Spec.muted),
        ),
        const SizedBox(height: 12),
        Text(
          '© ${DateTime.now().year} Smart POS',
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(fontSize: 9, color: _Spec.labelInk),
        ),
      ],
    );
  }
}

/// Desktop footer: brand and tagline on the left, copyright hard right.
class _FooterRow extends StatelessWidget {
  const _FooterRow();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(color: _Spec.border, height: 1),
        const SizedBox(height: 22),
        Row(
          children: [
            const _Wordmark(size: 19),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                'A smarter way to run your everyday.',
                style: GoogleFonts.dmSans(fontSize: 11, color: _Spec.muted),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              '© ${DateTime.now().year} Smart POS',
              style: GoogleFonts.dmSans(fontSize: 11, color: _Spec.labelInk),
            ),
          ],
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Step 13 — demo dialog
// -----------------------------------------------------------------------------

/// Demo behind `See it in action`.
///
/// Stateful so the selection can be shown here and applied to the page preview
/// at the same time, rather than closing the dialog and leaving the user to
/// guess what changed.
class _DemoDialog extends StatefulWidget {
  const _DemoDialog({required this.mode, required this.onChanged});

  final _PreviewMode mode;
  final ValueChanged<_PreviewMode> onChanged;

  @override
  State<_DemoDialog> createState() => _DemoDialogState();
}

class _DemoDialogState extends State<_DemoDialog> {
  static const _features = <(String, String, IconData)>[
    ('Fast checkout', r'Sales: $1,284.00', Icons.bolt_rounded),
    ('Live inventory', 'Inventory: 1,248 products', Icons.inventory_2_rounded),
    ('Daily reports', r'Monthly sales: $24,860.00', Icons.bar_chart_rounded),
    (
      'Print checkout',
      'Receipts: 80mm printer ready',
      Icons.receipt_long_rounded,
    ),
  ];

  late _PreviewMode _selected = widget.mode;

  void _select(_PreviewMode mode) {
    if (_selected == mode) return;
    setState(() => _selected = mode);
    widget.onChanged(mode);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _Spec.pageBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Row(
        children: [
          Expanded(
            child: Text(
              'See it in action',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _Spec.ink,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Close',
            icon: const Icon(Icons.close_rounded, color: _Spec.muted),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pick a feature to see how the app handles it.',
              style: GoogleFonts.dmSans(fontSize: 12, color: _Spec.muted),
            ),
            const SizedBox(height: 14),
            for (final (index, feature) in _features.indexed)
              Padding(
                padding: EdgeInsets.only(
                  bottom: index == _features.length - 1 ? 0 : 8,
                ),
                child: _FeatureChoice(
                  title: feature.$1,
                  value: feature.$2,
                  icon: feature.$3,
                  selected: _selected == _PreviewMode.values[index],
                  onTap: () => _select(_PreviewMode.values[index]),
                ),
              ),
            const SizedBox(height: 14),
            Text(
              'Here are — your professional functionality.',
              style: GoogleFonts.dmSans(fontSize: 11, color: _Spec.muted),
            ),
          ],
        ),
      ),
actions: [
        TextButton(
          onPressed: () {
            // Captured before the pop: after it this context is defunct, and
            // the same navigator is what has to push the login page.
            final navigator = Navigator.of(context);
            navigator.pop();
            navigator.pushAndRemoveUntil(
              MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          },
          style: TextButton.styleFrom(foregroundColor: _Spec.purple),
          child: Text(
            'Continue to login',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _Spec.purple,
            ),
          ),
        ),
      ],
    );
  }
}

class _FeatureChoice extends StatelessWidget {
  const _FeatureChoice({
    required this.title,
    required this.value,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _Spec.panel : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? _Spec.purple : _Spec.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: _Spec.purple),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _Spec.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: _Spec.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 18,
                color: selected ? _Spec.purple : _Spec.border,
              ),
            ],
          ),
        ),
      ),
    );
  }
}