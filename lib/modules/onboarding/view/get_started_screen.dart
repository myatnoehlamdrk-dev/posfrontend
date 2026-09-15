import 'package:flutter/material.dart';
import 'package:posfrontend/modules/login/view/login_screen.dart';

class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 58,
              child: _buildHeroSection(context),
            ),
            Expanded(
              flex: 42,
              child: _buildBottomSection(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF7C3AED),
            Color(0xFF8B5CF6),
            Color(0xFF6366F1),
            Color(0xFF3B82F6),
            Color(0xFF0EA5E9),
          ],
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
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: _buildAppIcon(),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Smart POS',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const Text(
                  '& Inventory',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Manage sales, stock, and reports from your pocket.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withValues(alpha: 0.8),
                      height: 1.5,
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

  Widget _buildAppIcon() {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 5,
      crossAxisSpacing: 5,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildIconSquare(const Color(0xFFE9D5FF)),
        _buildIconSquare(const Color(0xFFA7F3D0)),
        _buildIconSquare(const Color(0xFFDDD6FE)),
        _buildIconSquare(const Color(0xFFC4B5FD)),
      ],
    );
  }

  Widget _buildIconSquare(Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }

  Widget _buildBottomSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const Spacer(),
          _buildFeatureItem(Icons.bolt_rounded, 'Fast checkout'),
          const SizedBox(height: 20),
          _buildFeatureItem(Icons.inventory_2_outlined, 'Live inventory tracking'),
          const SizedBox(height: 20),
          _buildFeatureItem(Icons.bar_chart_rounded, 'Daily sales reports'),
          const Spacer(),
          SwipeToUnlock(onComplete: () => _navigateToLogin(context)),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: Color(0xFFF3F4F6),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 22, color: const Color(0xFF6D28D9)),
        ),
        const SizedBox(width: 16),
        Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  void _navigateToLogin(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final slideTween = Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOutCubic));
          return SlideTransition(
            position: animation.drive(slideTween),
            child: child,
          );
        },
      ),
      (route) => false,
    );
  }
}

class SwipeToUnlock extends StatefulWidget {
  final VoidCallback onComplete;
  const SwipeToUnlock({super.key, required this.onComplete});

  @override
  State<SwipeToUnlock> createState() => _SwipeToUnlockState();
}

class _SwipeToUnlockState extends State<SwipeToUnlock>
    with SingleTickerProviderStateMixin {
  double _dragPercent = 0.0;
  bool _completed = false;
  late AnimationController _pulseController;

  static const double _thumbSize = 64;
  static const double _trackHeight = 68;
  static const double _trackRadius = 18;
  static const double _padding = 4;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: double.infinity,
        height: _trackHeight + 8,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final trackWidth = constraints.maxWidth;
            final usableTrackWidth = trackWidth - _padding * 2;
            final thumbLeft = _padding + _dragPercent * (usableTrackWidth - _thumbSize);

            return GestureDetector(
              onHorizontalDragUpdate: (d) {
                if (_completed) return;
                final md = usableTrackWidth - _thumbSize;
                setState(() {
                  _dragPercent =
                      (_dragPercent + d.delta.dx / md).clamp(0.0, 1.0);
                });
              },
              onHorizontalDragEnd: (d) {
                if (_completed) return;
                if (_dragPercent >= 0.82) {
                  setState(() {
                    _completed = true;
                    _dragPercent = 1.0;
                  });
                  widget.onComplete();
                } else {
                  setState(() => _dragPercent = 0.0);
                }
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Track
                  Positioned(
                    left: _padding,
                    top: 4,
                    right: _padding,
                    bottom: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F0FF),
                        borderRadius: BorderRadius.circular(_trackRadius),
                        border: Border.all(
                          color: const Color(0xFFE9D5FF),
                          width: 1.5,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Filled portion
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 80),
                              width: thumbLeft + _thumbSize / 2,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF7C3AED)
                                        .withValues(alpha: 0.12),
                                    const Color(0xFF7C3AED)
                                        .withValues(alpha: 0.25),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(_trackRadius),
                              ),
                            ),
                          ),
                          // Hint text
                          AnimatedOpacity(
                            opacity: _dragPercent > 0.1 ? 0.0 : 1.0,
                            duration: const Duration(milliseconds: 200),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      size: 16,
                                      color: const Color(0xFF7C3AED)
                                          .withValues(alpha: 0.3),
                                    ),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      size: 16,
                                      color: const Color(0xFF7C3AED)
                                          .withValues(alpha: 0.55),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Swipe to get started',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.3,
                                        color: const Color(0xFF7C3AED)
                                            .withValues(alpha: 0.55),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      size: 16,
                                      color: const Color(0xFF7C3AED)
                                          .withValues(alpha: 0.55),
                                    ),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      size: 16,
                                      color: const Color(0xFF7C3AED)
                                          .withValues(alpha: 0.3),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Thumb
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 80),
                    curve: Curves.easeOut,
                    left: _padding + _dragPercent * (usableTrackWidth - _thumbSize),
                    child: Container(
                      width: _thumbSize,
                      height: _thumbSize,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                        ),
                        borderRadius: BorderRadius.circular(_trackRadius - 2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          final glow = 0.3 + _pulseController.value * 0.2;
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(_trackRadius - 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Color.fromRGBO(124, 58, 237,
                                      _completed ? 0.6 : glow),
                                  blurRadius: _completed ? 24 : 18,
                                  spreadRadius: _completed ? 4 : 0,
                                ),
                              ],
                            ),
                            child: child,
                          );
                        },
                        child: const Icon(
                          Icons.swipe_right_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
