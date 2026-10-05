import 'package:flutter/material.dart';
import 'package:posfrontend/shared/l10n/l10n_x.dart';
import 'package:posfrontend/core/di/injection.dart';
import 'package:posfrontend/features/auth/domain/usecases/login.dart';
import 'package:posfrontend/features/auth/presentation/viewmodels/login_view_model.dart';
import 'package:posfrontend/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:posfrontend/features/auth/presentation/screens/verify_account_screen.dart';
import 'package:posfrontend/features/auth/data/models/login_response.dart';
import 'package:posfrontend/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:posfrontend/features/shop/presentation/screens/shop_screen.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/theme/app_palette.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/app_input_decoration.dart';
import 'package:posfrontend/shared/widgets/auth_scope.dart';
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
    if (result != null && mounted) {
      final loginResponse = LoginResponse(
        id: result.user.id,
        fullName: result.user.fullName,
        email: result.user.email,
        accessToken: result.accessToken,
        tokenType: 'Bearer',
        shopId: result.user.shopId,
        role: result.user.role,
      );
      AuthScope.updateUserOf(context, loginResponse);
      ShopScope.loadShop(context, shopId: result.user.shopId);
      showSuccessSnackBar(context, 'Login successful');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
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
    return _centeredScroll(
      maxWidth: _LoginLayout.formMaxWidth,
      padding: const EdgeInsets.symmetric(
        horizontal: _LoginLayout.gutter,
        vertical: 32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: logoSize,
            width: logoSize,
            child: _buildHeaderIcon(),
          ),
          const SizedBox(height: 20),
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
      child: child,
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
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.t('Please login to your account'),
          style: TextStyle(color: p.textMuted, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Left pane of the split layout: copy at the top, logo filling the rest.
  ///
  /// Painted with the shared [AppColors.brandRamp] rather than a private pair of
  /// purples, so the pane and the Get Started hero the user just came from are
  /// visibly the same brand and the screen does not read as a different app on
  /// arrival.
  ///
  /// The gradient and the white-on-violet text are fixed rather than
  /// palette-driven because this is the one surface where the brand hue *is* the
  /// background, so it has to hold its own contrast in both brightnesses instead
  /// of inheriting the page's.
  Widget _buildBrandPane() {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.brandRamp,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(right: -80, top: -60, child: _blob(220, 0.07)),
          Positioned(left: -110, bottom: -90, child: _blob(260, 0.05)),
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
        final cramped = c.maxHeight < 460;
        return Padding(
          padding: EdgeInsets.fromLTRB(48, cramped ? 32 : 48, 48, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.t('Welcome Back!'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  height: 1.2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                context.l10n.t('Please login to your account'),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              if (!cramped) ...[
                const SizedBox(height: 30),
                _featureRow(Icons.dashboard_outlined, 'Dashboard'),
                const SizedBox(height: 14),
                _featureRow(Icons.inventory_2_outlined, 'Inventory'),
                const SizedBox(height: 14),
                _featureRow(Icons.receipt_long_outlined, 'Sale Item'),
              ],
              const SizedBox(height: 24),
              const Expanded(child: _BrandMark()),
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

  Widget _featureRow(IconData icon, String key) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 14),
        Flexible(
          child: Text(
            context.l10n.t(key),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
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
                MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
              ),
              child: Text(
                context.l10n.t('Forgot Password?'),
                style: TextStyle(
                  color: p.accentText,
                  fontSize: 13,
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
            style: TextStyle(color: p.dangerFg, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          if (message.contains('verify'))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        VerifyAccountScreen(email: _emailController.text),
                  ),
                ),
                child: Text(
                  context.l10n.t('Verify Email'),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
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
            style: TextStyle(color: p.textMuted, fontSize: 13),
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
            style: TextStyle(color: p.textMuted, fontSize: 14),
            textAlign: TextAlign.right,
          ),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ShopScreen()),
          ),
          child: Text(
            context.l10n.t('Register'),
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 14,
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

  Widget _buildHeaderIcon() {
    return const _BrandMark();
  }
}

/// The shop logo, held in its own widget so both the hero and the brand pane
/// can sit in a `const` subtree.
class _BrandMark extends StatelessWidget {
  const _BrandMark();

  /// Decode size for [Image.asset], in physical pixels.
  ///
  /// Sized for the hero rather than the pane: the mark can now render at up to
  /// 320 logical px, which is 960 physical on a 3x phone, so the previous 600
  /// would have shown a visibly soft edge on exactly the screens it was
  /// enlarged for. Above the 1000px source there is nothing left to resolve, so
  /// this costs nothing extra.
  static const int _decodeSize = 1200;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/shop.png',
      fit: BoxFit.contain,
      cacheWidth: _decodeSize,
      cacheHeight: _decodeSize,
    );
  }
}
