import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:posfrontend/core/auth/session_store.dart';
import 'package:posfrontend/core/auth/token_storage.dart';
import 'package:posfrontend/core/di/injection.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/features/auth/data/models/login_response.dart';
import 'package:posfrontend/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:posfrontend/features/onboarding/presentation/screens/get_started_screen.dart';
import 'package:posfrontend/shared/l10n/l10n_x.dart';
import 'package:posfrontend/shared/services/fcm_service.dart';
import 'package:posfrontend/shared/widgets/auth_scope.dart';
import 'package:posfrontend/shared/widgets/shop_scope.dart';

/// The single splash. Carries the logo, the wordmark and the credit, then hands
/// off to [DashboardScreen] when a live session exists and to
/// [GetStartedScreen] when it does not.
///
/// This is the only place a splash is drawn. The native window underneath is a
/// flat colour with no logo and no text, so it reads as a backdrop rather than
/// a second splash — and it has to stay, because Android requires a window
/// background before the first frame and omitting it flashes white on every
/// cold start.
///
/// Drawing here rather than natively is what makes the wordmark possible at
/// all: Android 12+ discards a custom native splash and shows only the app
/// icon, so any text baked into `launch_background` would be silently dropped.
///
/// The session probe runs underneath that logo, so restoring is invisible: the
/// user either sees the splash and lands on a dashboard that is already signed
/// in, or sees it and lands where a first-time visitor always has.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _hold = Duration(milliseconds: 2000);

  /// How long the probe may keep us here once the hold has elapsed.
  ///
  /// The probe starts in [initState], so [_hold] already covers its first two
  /// seconds and this only bounds what is left afterwards. Worst case the
  /// splash shows for hold + this.
  ///
  /// It exists because the backend talks to TiDB Cloud over the public
  /// internet, where opening a connection regularly costs several seconds —
  /// `select 1` in a fresh process measured 2.6s, 5.3s and 11.0s here. A
  /// deadline that waited for that would be the difference between a splash
  /// and a hang.
  static const Duration _probeDeadline = Duration(seconds: 3);

  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  Timer? _handoff;

  /// Started in [initState] rather than when the hold expires, so the round
  /// trip happens *underneath* the logo instead of after it.
  Future<_Probe>? _probe;

  @override
  void initState() {
    super.initState();
    _probe = _startProbe();
    _handoff = Timer(_hold, _go);
  }

  /// Hand off to whichever screen the session state calls for.
  ///
  /// Everything that can throw is caught here rather than in the helpers: a
  /// failure during startup would otherwise leave the user staring at a splash
  /// that never transitions, which is the one outcome worse than signing them
  /// out.
  Future<void> _go() async {
    if (!mounted) return;

    var signedIn = false;
    try {
      signedIn = await _restoreSession();
    } catch (_) {
      // Drop the session rather than retry a path that has already thrown, so
      // the next launch starts clean from sign-in instead of repeating this.
      await _discardSession();
      signedIn = false;
    }

    if (!mounted) return;

    await Navigator.of(context).pushReplacement(
      _route(signedIn ? const DashboardScreen() : const GetStartedScreen()),
    );
  }

  /// Decide whether a stored session is still worth using.
  ///
  /// Returns true only once [AuthScope] and [ShopScope] have been populated,
  /// because that is what the dashboard reads on its first frame.
  Future<bool> _restoreSession() async {
    final token = await TokenStorage.getToken();
    if (token == null || token.isEmpty) return false;

    // The idle check runs before any network call. A session abandoned for
    // longer than the window has to be dropped even when the device is
    // offline — otherwise a till that sat unattended for a month would keep
    // working on a token the server had already refused.
    if (await SessionStore.isIdleExpired()) {
      await _discardSession();
      return false;
    }

    var probe = const _Probe(_ProbeOutcome.unreachable);
    try {
      probe = await (_probe ?? _startProbe()).timeout(_probeDeadline);
    } on TimeoutException {
      // Out of budget: go from the cache. Dashboard's own GET /auth/profile
      // still fires a moment later and will surface a genuine 401, which
      // redirectToLogin() handles — so a slow answer cannot strand a signed
      // out user on the dashboard, it only moves the sign-out one step later.
    }

    if (probe.outcome == _ProbeOutcome.rejected) {
      // The server has said this session is over. The cache must not
      // resurrect it, so this is the one outcome that always signs out.
      await _discardSession();
      return false;
    }

    final LoginResponse? user = probe.me != null
        ? await SessionStore.save(probe.me!, token)
        : await SessionStore.restore(token);

    if (user == null) {
      // No live server answer and no cached identity to fall back on. A
      // nameless, shop-less dashboard is worse than asking for a sign-in.
      await _discardSession();
      return false;
    }

    if (!mounted) return false;

    AuthScope.updateUserOf(context, user);
    ShopScope.loadShop(context, shopId: user.shopId);
    // Registration normally happens only on a successful login, and runs on
    // both paths here: a restored session whose Firebase token had since
    // rotated would otherwise go on pushing to an id the server no longer
    // recognises. It self-swallows failures, so an offline launch is safe.
    getIt<FcmService>().registerTokenAfterLogin();

    return true;
  }

  /// Kicks off the probe from [initState].
  ///
  /// Must never complete with an error. It is started before anything awaits
  /// it, so an error here would surface as an unhandled async failure during
  /// startup rather than as the handled fallback it actually is.
  Future<_Probe> _startProbe() async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null || token.isEmpty) {
        return const _Probe(_ProbeOutcome.unreachable);
      }
      return await _probeMe(token);
    } catch (_) {
      return const _Probe(_ProbeOutcome.unreachable);
    }
  }

  /// Ask the server whether this session is still good.
  ///
  /// Uses [ApiClient.bare] on purpose: the regular client reacts to a 401 by
  /// pushing the login screen, which would race this screen's own decision
  /// and skip the get-started route on a cold start.
  Future<_Probe> _probeMe(String token) async {
    try {
      final response = await ApiClient.bare().get(
        '/auth/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final body = response.data;
      if (body is! Map<String, dynamic>) {
        return const _Probe(_ProbeOutcome.unreachable);
      }
      return _Probe(_ProbeOutcome.ok, body);
    } on DioException catch (e) {
      // 401/403 is different in kind from every other failure: the server
      // has ended the session, so there is nothing to fall back to. No
      // network, DNS, 5xx and timeouts all mean "asked but could not hear",
      // which the cache can answer.
      final status = e.response?.statusCode;
      if (status == 401 || status == 403) {
        return const _Probe(_ProbeOutcome.rejected);
      }
      return const _Probe(_ProbeOutcome.unreachable);
    } catch (_) {
      return const _Probe(_ProbeOutcome.unreachable);
    }
  }

  Future<void> _discardSession() async {
    await TokenStorage.clearToken();
    await SessionStore.clear();
  }

  PageRouteBuilder<void> _route(Widget screen) => PageRouteBuilder<void>(
    transitionDuration: const Duration(milliseconds: 420),
    pageBuilder: (_, _, _) => screen,
    transitionsBuilder: (_, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
  );

  @override
  void dispose() {
    _handoff?.cancel();
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Matches @color/splash_background, so the hand-off from the system
      // window into this frame is a colour match rather than a flash.
      backgroundColor: const Color(0xFF0A1631),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A1631), Color(0xFF0E2A4D)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FadeTransition(
                opacity: _intro,
                child: ScaleTransition(
                  scale: Tween(begin: 0.86, end: 1.0).animate(
                    CurvedAnimation(parent: _intro, curve: Curves.easeOutCubic),
                  ),
                  child: Image.asset(
                    'assets/launcher.png',
                    width: 128,
                    height: 128,
                    // The asset is 512px square, covering even a 5x display at
                    // this box size, so it decodes at its native resolution.
                    cacheWidth: 512,
                    cacheHeight: 512,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Set in the logo's own dominant colour: #007AFC covers 52% of
              // the non-background pixels in the artwork.
              FadeTransition(
                opacity: CurvedAnimation(
                  parent: _intro,
                  curve: const Interval(0.35, 1.0, curve: Curves.easeOut),
                ),
                child: Text(
                  context.l10n.t('MDRK POS'),
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF007AFC),
                    letterSpacing: 6,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Sits with the wordmark rather than the app name: the launcher
              // and the recents list both say Inventory, so the credit has to
              // live here to be seen at all.
              FadeTransition(
                opacity: CurvedAnimation(
                  parent: _intro,
                  curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
                ),
                child: Text(
                  context.l10n.t('Powered by MDRK'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.4,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// What `GET /auth/me` answered, if it answered within the deadline.
enum _ProbeOutcome {
  /// 2xx with a usable body: the session is live and [_Probe.me] is fresh.
  ok,

  /// 401/403: the server has ended this session. Never answer from cache.
  rejected,

  /// No answer — offline, too slow, or a body that made no sense. The cache
  /// is all we have, and all we need.
  unreachable,
}

class _Probe {
  final _ProbeOutcome outcome;

  /// The raw `UserResource` body, present only when [outcome] is
  /// [_ProbeOutcome.ok].
  final Map<String, dynamic>? me;

  const _Probe(this.outcome, [this.me]);
}
