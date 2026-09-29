import 'dart:async';

import 'package:flutter/material.dart';
import 'package:posfrontend/features/onboarding/presentation/screens/get_started_screen.dart';

/// The single splash. Carries the logo, the wordmark and the credit, then hands
/// off to [GetStartedScreen].
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
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _hold = Duration(milliseconds: 2000);

  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  Timer? _handoff;

  @override
  void initState() {
    super.initState();
    _handoff = Timer(_hold, _go);
  }

  Future<void> _go() async {
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 420),
        pageBuilder: (_, _, _) => const GetStartedScreen(),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

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
                    CurvedAnimation(
                      parent: _intro,
                      curve: Curves.easeOutCubic,
                    ),
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
                child: const Text(
                  'MDRK POS',
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
                  'Powered by MDRK',
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
