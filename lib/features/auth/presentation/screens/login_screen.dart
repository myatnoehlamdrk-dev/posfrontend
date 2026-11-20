import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:posfrontend/shared/l10n/l10n_x.dart';
import 'package:posfrontend/core/di/injection.dart';
import 'package:posfrontend/core/auth/session_store.dart';
import 'package:posfrontend/features/auth/domain/usecases/login.dart';
import 'package:posfrontend/features/auth/presentation/viewmodels/login_view_model.dart';
import 'package:posfrontend/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:posfrontend/features/auth/presentation/screens/verify_account_screen.dart';
import 'package:posfrontend/features/auth/data/models/login_response.dart';
import 'package:posfrontend/features/shop/presentation/screens/shop_screen.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/theme/app_palette.dart';
import 'package:posfrontend/shared/theme/app_typography.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/app_drawer.dart';
import 'package:posfrontend/shared/widgets/app_page_transitions.dart';
import 'package:posfrontend/shared/widgets/app_input_decoration.dart';
import 'package:posfrontend/shared/widgets/auth_scope.dart';
import 'package:posfrontend/shared/widgets/brand_avatar_badge.dart';
import 'package:posfrontend/shared/widgets/shop_scope.dart';
import 'package:posfrontend/shared/widgets/gradient_button.dart';
import 'package:posfrontend/shared/widgets/required_label.dart';
import 'package:posfrontend/shared/widgets/snackbar_helper.dart';

/// Layout thresholds for the login screen, collected here because it has three
/// shapes rather than one that merely stretches:
///
///  * phone   (< [cardFrom])  — single column, edge to edge, no surface.
///  * tablet  (< [splitFrom]) — single column, but the form is lifted onto a
///    card so it stops reading as a form stretched across a slab of page.
///  * desktop (>= [splitFrom]) — brand pane on the left, carded form on the
///    right. Without it the 220px logo and 26px title sit marooned in the
///    middle of a 1900px window.
///
/// The 768 "wide" threshold the rest of the app uses is deliberately not
/// reused: it would put a tablet in landscape into the split layout, where the
/// form column lands near 320px and its labels start to wrap.
class _LoginLayout {
  static const double cardFrom = 600;
  static const double splitFrom = 900;

  /// The form never grows past this on a phone, which is what stops the inputs
  /// from becoming 900px-wide underlines in a desktop browser.
  static const double formMaxWidth = 440;
  static const double cardMaxWidth = 460;

  static const double gutter = 24;
  static const double cardPadding = 32;
  static const double panePadding = 40;

  /// Hero image bounds on the stacked layouts.
  ///
  /// [logoMax] is the point of the design — on a phone the mark is the first
  /// thing on screen and should read as a mark, not as a 24px favicon in the
  /// middle of a mostly empty column. [logoMin] keeps it from collapsing into a
  /// thumbnail on a very short window, where the layout falls back to scrolling
  /// rather than to an unusable image.
  static const double logoMax = 320;
  static const double logoMin = 150;

  /// The logo's share of the window width.
  ///
  /// 0.78 of the width is deliberate: full-bleed looks like a splash screen,
  /// and anything much under half starts reading as an icon again.
  static const double logoWidthShare = 0.78;

  /// Vertical space the stacked layout needs for everything that is *not* the
  /// logo: heading, two labelled inputs, forgot-password link, button, divider,
  /// register prompt, and the gaps and page padding between them. Measured off
  /// the widget sizes above rather than guessed, because the logo's size is
  /// whatever is left of the window after this.
  static const double formReserve = 520;

  /// Extra reserve for the carded layout, where the form additionally sits
  /// inside a surface with its own padding all round.
  static const double cardReserve = 64;
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late final LoginViewModel _viewModel;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _viewModel = LoginViewModel(loginUseCase: getIt<LoginUseCase>());

    _emailController.addListener(
      () => _viewModel.setEmail(_emailController.text),
    );
    _passwordController.addListener(
      () => _viewModel.setPassword(_passwordController.text),
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final result = await _viewModel.login();
    if (result == null || !mounted) return;

    final loginResponse = LoginResponse(
      id: result.user.id,
      fullName: result.user.fullName,
      email: result.user.email,
      accessToken: result.accessToken,
      tokenType: 'Bearer',
      shopId: result.user.shopId,
      role: result.user.role,
    );

    // Cache the five profile fields and start the idle clock, so the next
    // cold start can reach the dashboard without a round trip — and so the
    // session expires if the app is left alone for five days.
    await SessionStore.save({
      'id': result.user.id,
      'fullName': result.user.fullName,
      'email': result.user.email,
      'shopId': result.user.shopId,
      'role': result.user.role,
    }, result.accessToken);

    if (!mounted) return;

    AuthScope.updateUserOf(context, loginResponse);
    ShopScope.loadShop(context, shopId: result.user.shopId);
    showSuccessSnackBar(context, 'Login successful');
    // Replaces this login route rather than stacking: the tracker then knows
    // the dashboard by name, so Back and the drawer can return to *this*
    // instance later instead of building a second one.
    navigateToDestination(context, DrawerDestination.dashboard, replace: true);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: p.scaffoldBg,
          body: Stack(
            children: [
              // Violet bloom anchored to the top-right corner. It sits behind
              // the layout rather than inside either branch, so the split
              // desktop layout and the stacked phone one get the same light
              // without a breakpoint deciding anything. The corner is pulled in
              // from the true edge (0.85 / -0.9) because a radial centred on the
              // exact corner puts half its falloff off-screen and reads as a
              // flat tint rather than a glow.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.85, -0.9),
                      radius: 1.0,
                      colors: [
                        p.primary.withValues(alpha: 0.26),
                        p.primary.withValues(alpha: 0.12),
                        p.primary.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),
              // `Positioned.fill` rather than a plain child: a non-positioned
              // Stack child is laid out loosely, which would hand the Row in
              // [_buildSplit] and the LayoutBuilder below unbounded-by-intent
              // constraints and change how the pane sizes itself.
              Positioned.fill(
                child: SafeArea(
                  child: LayoutBuilder(
                    builder: (ctx, constraints) {
                      if (constraints.maxWidth >= _LoginLayout.splitFrom) {
                        return _buildSplit();
                      }
                      return _buildStacked(
                        carded: constraints.maxWidth >= _LoginLayout.cardFrom,
                        logoSize: _logoSize(
                          constraints.maxWidth,
                          constraints.maxHeight,
                          carded: constraints.maxWidth >= _LoginLayout.cardFrom,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Desktop: brand on the left, the form as a card on the right.
  Widget _buildSplit() {
    return Row(
      children: [
        Expanded(flex: 5, child: _buildBrandPane()),
        Expanded(
          flex: 4,
          child: _centeredScroll(
            maxWidth: _LoginLayout.cardMaxWidth,
            padding: const EdgeInsets.all(_LoginLayout.panePadding),
            child: _card(
              child: _buildFields(),
              padding: _LoginLayout.panePadding,
            ),
          ),
        ),
      ],
    );
  }

  /// Phone and tablet: one column, centred and width-capped. `carded` lifts the
  /// form onto a surface on tablet so it no longer bleeds to both edges.
  Widget _buildStacked({required bool carded, required double logoSize}) {
    final p = context.palette;
    return _centeredScroll(
      maxWidth: _LoginLayout.formMaxWidth,
      padding: const EdgeInsets.symmetric(
        horizontal: _LoginLayout.gutter,
        vertical: 32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Brand lockup: the cart mark + wordmark.
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/login1.png',
                width: 34,
                height: 34,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 9),
              Text(
                context.l10n.t('Smart POS'),
                style: TextStyle(
                  color: p.textPrimary,
                  fontSize: AppTypography.titleSmallSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          SizedBox(
            height: logoSize,
            width: double.infinity,
            child: const _HeroIllustration(asset: 'assets/shop.png'),
          ),
          const SizedBox(height: 8),
          _buildHeading(),
          const SizedBox(height: 28),
          if (carded)
            _card(child: _buildFields(), padding: _LoginLayout.cardPadding)
          else
            _buildFields(),
        ],
      ),
    );
  }

  /// Scrolls when the content is taller than the window, centres when it is
  /// not. The `minHeight` floor is what makes those two agree.
  Widget _centeredScroll({
    required Widget child,
    required double maxWidth,
    required EdgeInsets padding,
  }) {
    return LayoutBuilder(
      builder: (ctx, c) => SingleChildScrollView(
        padding: padding,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: c.maxHeight - padding.vertical,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  Widget _card({required Widget child, required double padding}) {
    final p = context.palette;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: p.border),
        boxShadow: [
          BoxShadow(
            color: p.cardShadow,
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // The shop artwork stays, but as a compact avatar rather than a
          // 150dp circular crop: same brand moment, without the weight of a
          // profile photo on a screen where there is no profile yet.
          Center(
            child: BrandAvatarBadge(
              image: 'assets/login2.png',
              semanticLabel: context.l10n.t('Secure sign in'),
              size: BrandAvatarBadge.standardSize,
              imageScale: 1.7,
              imageAlignment: const Alignment(0.13, -0.4),
            ),
          ),
          const SizedBox(height: 26),
          child,
        ],
      ),
    );
  }

  Widget _buildHeading() {
    final p = context.palette;
    return Column(
      children: [
        Text(
          context.l10n.t('Welcome Back!'),
          style: TextStyle(
            color: p.textPrimary,
            fontSize: AppTypography.displaySmallSize,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.t('Please login to your account'),
          style: TextStyle(
            color: p.textMuted,
            fontSize: AppTypography.bodySmallSize,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Left pane of the split layout: copy at the top, logo filling the rest.
  ///
  /// Painted with [AppColors.brandPaneRamp] — the brand hue's deep stage
  /// variant — rather than [AppColors.brandRamp]. The interactive ramp is tuned
  /// for small fills; across half the window its 500 stop was bright enough to
  /// fight the form for attention. Same hue, same ordering, much lower
  /// lightness, so the pane reads as a backdrop rather than a violet poster.
  ///
  /// The gradient and the white-on-violet text are fixed rather than
  /// palette-driven because this is the one surface where the brand hue *is* the
  /// background, so it has to hold its own contrast in both brightnesses instead
  /// of inheriting the page's.
  Widget _buildBrandPane() {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.brandPaneRamp,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // A single soft violet halo, kept low-alpha. It restores a little of
          // the brand's luminosity at the top corner without lifting the whole
          // pane back to the brightness the flat ramp had.
          Positioned(
            right: -160,
            top: -180,
            child: _glow(460, AppColors.violet400, 0.16),
          ),
          Positioned(right: -80, top: -60, child: _blob(220, 0.04)),
          Positioned(left: -110, bottom: -90, child: _blob(260, 0.03)),
          Positioned.fill(child: _buildBrandContent()),
        ],
      ),
    );
  }

  /// Copy sits at the top of the pane, the logo takes every pixel left over
  /// below it.
  ///
  /// Deliberately *not* a scroll view. The pane is a fixed slot in the split
  /// `Row`, so its height is already bounded, and wrapping it in a
  /// `SingleChildScrollView` would hand the `Column` an infinite height — which
  /// then cannot host an `Expanded` logo. Instead the feature list is the first
  /// thing to go when the window is short, so the logo keeps its space.
  Widget _buildBrandContent() {
    return LayoutBuilder(
      builder: (ctx, c) {
        // The feature list is a column now, so it needs roughly four chip
        // heights plus gaps instead of one row's worth. The threshold is
        // raised by that difference so a short pane still drops the list
        // rather than squeezing the logo down to a thumbnail.
        final cramped = c.maxHeight < 580;
        return Padding(
          padding: EdgeInsets.fromLTRB(48, cramped ? 20 : 36, 48, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Brand lockup: the cart mark + wordmark.
              Row(
                children: [
                  Image.asset(
                    'assets/login1.png',
                    width: 46,
                    height: 46,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    context.l10n.t('Smart POS'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: AppTypography.titleSmallSize,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                context.l10n.t('Everything your shop\nneeds, in one place.'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: AppTypography.displayMediumSize,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                context.l10n.t(
                  'Sell fast, track stock, and keep every sale organised — on the counter and on the go.',
                ),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: AppTypography.bodyMediumSize,
                  height: 1.45,
                ),
              ),
              // The hero artwork: shop.png with the float motion.
              Expanded(
                child: Center(
                  child: _HeroIllustration(asset: 'assets/shop.png'),
                ),
              ),
              if (!cramped) ...[
                const SizedBox(height: 4),
                // Four tinted rows, not one tinted block: each feature gets its
                // own hint of the old glass fill, so the list still reads as
                // four separate buttons. There is no `Border`, no rounded panel
                // and no shadow — those drew left and right edges around the
                // list. Each row's tint is a horizontal gradient instead,
                // slightly stronger on the left and fading to nothing on the
                // right, so no row ever draws a side edge.
                const _FeatureList(),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _blob(double size, double opacity) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: opacity),
        shape: BoxShape.circle,
      ),
    );
  }

  /// A soft radial light source. Unlike [_blob] it has no edge, so it can sit
  /// partly off the pane without drawing a hard rim where the circle is cut.
  Widget _glow(double size, Color color, double opacity) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: opacity * 0.35),
            color.withValues(alpha: 0),
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
      ),
    );
  }

  Widget _buildFields() {
    final p = context.palette;
    final errors = _viewModel.fieldErrors;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: RequiredLabel('Email'),
          ),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: appInputDecoration(
              context,
              icon: Icons.email_outlined,
              hint: context.l10n.t('Enter your email'),
              errorText: errors['email'],
            ),
          ),
          const SizedBox(height: 18),
          const Align(
            alignment: Alignment.centerLeft,
            child: RequiredLabel('Password'),
          ),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            decoration: appInputDecoration(
              context,
              icon: Icons.lock_outline,
              hint: context.l10n.t('Enter your password'),
              errorText: errors['password'],
              suffixIcon: IconButton(
                tooltip: 'Toggle password visibility',
                onPressed: () => setState(() {
                  _obscurePassword = !_obscurePassword;
                }),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: p.textMuted,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                AppPageTransitions.authSmooth<void>(
                  const ForgotPasswordScreen(),
                ),
              ),
              child: Text(
                context.l10n.t('Forgot Password?'),
                style: TextStyle(
                  color: p.accentText,
                  fontSize: AppTypography.labelMediumSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          GradientButton(
            label: context.l10n.t('Login'),
            loading: _viewModel.isLoading,
            onPressed: _submit,
          ),
          if (_viewModel.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _buildError(p),
            ),
          const SizedBox(height: 22),
          _buildDivider(),
          const SizedBox(height: 18),
          _buildRegisterPrompt(),
        ],
      ),
    );
  }

  Widget _buildError(AppPalette p) {
    final message = _viewModel.errorMessage!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: p.dangerBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            message,
            style: TextStyle(
              color: p.dangerFg,
              fontSize: AppTypography.labelMediumSize,
            ),
            textAlign: TextAlign.center,
          ),
          if (message.contains('verify'))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  AppPageTransitions.authSmooth<void>(
                    VerifyAccountScreen(email: _emailController.text),
                  ),
                ),
                child: Text(
                  context.l10n.t('Verify Email'),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: AppTypography.labelMediumSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    final p = context.palette;
    return Row(
      children: [
        Expanded(child: Divider(color: p.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            context.l10n.t('OR'),
            style: TextStyle(
              color: p.textMuted,
              fontSize: AppTypography.labelMediumSize,
            ),
          ),
        ),
        Expanded(child: Divider(color: p.border)),
      ],
    );
  }

  Widget _buildRegisterPrompt() {
    final p = context.palette;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            context.l10n.t("Don't have an account?"),
            style: TextStyle(
              color: p.textMuted,
              fontSize: AppTypography.bodySmallSize,
            ),
            textAlign: TextAlign.right,
          ),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            AppPageTransitions.authRegister<void>(const ShopScreen()),
          ),
          child: Text(
            context.l10n.t('Register'),
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: AppTypography.bodySmallSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  /// Sizes the hero mark for the stacked layouts.
  ///
  /// Bounded by width and by height, and the height bound is the one that
  /// matters. A tall phone can give the logo several hundred pixels and the
  /// sign-in button still lands above the fold; a short one cannot, and a logo
  /// that ignores that pushes the button below it. The login form is the whole
  /// point of this screen, so it gets first claim on the height and the image
  /// takes the remainder, floored at [logoMin].
  double _logoSize(double maxWidth, double maxHeight, {required bool carded}) {
    final byWidth = maxWidth * _LoginLayout.logoWidthShare;
    final byHeight =
        maxHeight -
        _LoginLayout.formReserve -
        (carded ? _LoginLayout.cardReserve : 0);

    final size = byWidth < byHeight ? byWidth : byHeight;

    return size.clamp(_LoginLayout.logoMin, _LoginLayout.logoMax);
  }
}

/// The hero illustration for brand panes and the phone hero.
///
/// It fades and slides up on first mount, then floats gently — a small,
/// always-on motion cue that keeps the pane feeling alive without distracting
/// from the form.
class _HeroIllustration extends StatefulWidget {
  const _HeroIllustration({this.asset = 'assets/shop.png'});

  /// Which artwork to show.
  final String asset;

  @override
  State<_HeroIllustration> createState() => _HeroIllustrationState();
}

class _HeroIllustrationState extends State<_HeroIllustration>
    with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  late final AnimationController _bob;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = CurvedAnimation(parent: _entrance, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entrance, curve: Curves.easeOutCubic));
    _bob = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
    _entrance.forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        // FittedBox guarantees the artwork scales to whatever height the
        // Expanded actually leaves, instead of overflowing on a short pane.
        child: FittedBox(
          fit: BoxFit.contain,
          child: AnimatedBuilder(
            animation: _bob,
            builder: (context, child) {
              final bob = math.sin(_bob.value * math.pi * 2) * 10;
              return Transform.translate(offset: Offset(0, bob), child: child);
            },
            child: Image.asset(
              widget.asset,
              fit: BoxFit.contain,
              cacheWidth: 900,
              cacheHeight: 900,
            ),
          ),
        ),
      ),
    );
  }
}

/// The four-feature list on the login brand pane.
///
/// It fades and lifts in row by row on first mount, so it continues the same
/// entrance motion as [_HeroIllustration] instead of appearing fully formed
/// beside it. Each row is animated together with the rule above it, so the
/// tint and its hairlines stay aligned while they move.
class _FeatureList extends StatefulWidget {
  const _FeatureList();

  @override
  State<_FeatureList> createState() => _FeatureListState();
}

class _FeatureListState extends State<_FeatureList>
    with SingleTickerProviderStateMixin {
  static const List<(IconData, String)> _rows = [
    (Icons.dashboard_outlined, 'Dashboard'),
    (Icons.inventory_2_outlined, 'Inventory'),
    (Icons.receipt_long_outlined, 'Sales'),
    (Icons.print_outlined, 'Print'),
  ];

  /// Hairline that separates the rows. Fixed white rather than palette-driven
  /// because the list sits on the brand gradient in both brightnesses. Kept
  /// low-alpha: on the deep pane a stronger white rule reads as a drawn border
  /// rather than a separation.
  static final Color _divider = Colors.white.withValues(alpha: 0.14);

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// The fade profile shared by the row tint and its rules, so the colour and
  /// the lines start and end together and neither begins hard at the left edge.
  LinearGradient _fade(Color color) {
    return LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        color.withValues(alpha: 0),
        color,
        color,
        color.withValues(alpha: 0),
      ],
      stops: const [0.0, 0.10, 0.55, 1.0],
    );
  }

  Widget _hairline() {
    return Container(
      height: 1,
      decoration: BoxDecoration(gradient: _fade(_divider)),
    );
  }

  Widget _row(IconData icon, String key) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: _fade(Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.l10n.t(key),
              style: TextStyle(
                color: Colors.white,
                fontSize: AppTypography.labelMediumSize,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// One staggered pair: the rule above a row and the row itself. The final
  /// row also carries the list's bottom rule, so it travels with that row.
  Widget _animatedGroup(int index, {required bool withBottomRule}) {
    final start = index * 0.12;
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, start + 0.55, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.18),
          end: Offset.zero,
        ).animate(curve),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _hairline(),
            _row(_rows[index].$1, _rows[index].$2),
            if (withBottomRule) _hairline(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Respect the platform's reduce-motion setting: the rows are content, not
    // decoration, so they should not stagger in for a user who asked for no
    // animation.
    if (MediaQuery.disableAnimationsOf(context)) {
      return _staticList();
    }
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < _rows.length; i++)
            _animatedGroup(i, withBottomRule: i == _rows.length - 1),
        ],
      ),
    );
  }

  Widget _staticList() {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _hairline(),
          _row(_rows[0].$1, _rows[0].$2),
          _hairline(),
          _row(_rows[1].$1, _rows[1].$2),
          _hairline(),
          _row(_rows[2].$1, _rows[2].$2),
          _hairline(),
          _row(_rows[3].$1, _rows[3].$2),
          _hairline(),
        ],
      ),
    );
  }
}
