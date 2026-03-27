import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../auth/auth_controller.dart';

/// Splash screen that checks auth and navigates. Uses StatefulWidget so the
/// first frame paints immediately without waiting on any GetX controller or storage.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  bool _animateIn = false;
  late final AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndNavigate());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _animateIn = true);
    });
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  Future<void> _checkAndNavigate() async {
    Timer? forceLoginTimer;
    forceLoginTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      forceLoginTimer?.cancel();
      Get.offAllNamed('/login');
    });

    try {
      final authController = Get.find<AuthController>();

      final hasSession = await authController.checkAuth().timeout(
        const Duration(seconds: 8),
        onTimeout: () => false,
      );

      forceLoginTimer.cancel();
      if (!mounted) return;

      if (hasSession) {
        Get.offAllNamed('/main');
      } else {
        Get.offAllNamed('/login');
      }
    } catch (e, st) {
      debugPrint('Splash auth check error: $e $st');
      forceLoginTimer.cancel();
      if (mounted) {
        Get.offAllNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final shortest = MediaQuery.sizeOf(context).shortestSide;
    final isSmall = shortest < 360;
    final logoSize = isSmall ? 92.0 : 116.0;
    final titleStyle = theme.textTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: -0.4,
      color: cs.onSurface,
    );
    final taglineStyle = theme.textTheme.bodyMedium?.copyWith(
      height: 1.35,
      color: cs.onSurface.withOpacity(0.62),
    );
    final subtitleStyle = theme.textTheme.labelLarge?.copyWith(
      letterSpacing: 0.2,
      color: cs.primary.withOpacity(0.95),
      fontWeight: FontWeight.w600,
    );

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: theme.brightness == Brightness.dark
                      ? [
                          cs.surface,
                          cs.surface,
                        ]
                      : [
                          const Color(0xFFFFFFFF),
                          cs.primary.withOpacity(0.06),
                          cs.surface,
                        ],
                  stops: theme.brightness == Brightness.dark ? null : const [0.0, 0.42, 1.0],
                ),
              ),
              child: const SizedBox.expand(),
            ),
          ),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bgController,
              builder: (context, _) {
                final t = _bgController.value;
                final dx = (t - 0.5) * 40;
                final dy = (0.5 - t) * 26;
                return Stack(
                  children: [
                    _AccentBlob(
                      alignment: Alignment(-0.9 + t * 0.15, -0.75),
                      color: cs.secondary.withOpacity(theme.brightness == Brightness.dark ? 0.10 : 0.18),
                      diameter: 240,
                      blurSigma: 40,
                      offset: Offset(dx, dy),
                    ),
                    _AccentBlob(
                      alignment: Alignment(0.95, 0.85 - t * 0.15),
                      color: cs.primary.withOpacity(theme.brightness == Brightness.dark ? 0.12 : 0.20),
                      diameter: 280,
                      blurSigma: 44,
                      offset: Offset(-dx, -dy),
                    ),
                  ],
                );
              },
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 560),
                        curve: Curves.easeOutCubic,
                        opacity: _animateIn ? 1 : 0,
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.easeOutBack,
                          scale: _animateIn ? 1 : 0.92,
                          child: _SplashLogo(size: logoSize),
                        ),
                      ),
                      SizedBox(height: isSmall ? 18 : 22),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: theme.brightness == Brightness.dark
                              ? cs.surfaceContainerHighest.withOpacity(0.20)
                              : Colors.white.withOpacity(0.74),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: cs.onSurface.withOpacity(theme.brightness == Brightness.dark ? 0.08 : 0.06),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.22 : 0.06),
                              blurRadius: 22,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmall ? 18 : 22,
                            vertical: isSmall ? 16 : 18,
                          ),
                          child: AnimatedSlide(
                            duration: const Duration(milliseconds: 700),
                            curve: Curves.easeOutCubic,
                            offset: _animateIn ? Offset.zero : const Offset(0, 0.06),
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 650),
                              curve: Curves.easeOutCubic,
                              opacity: _animateIn ? 1 : 0,
                              child: Column(
                                children: [
                                  Text('Tebita Equb', textAlign: TextAlign.center, style: titleStyle),
                                  const SizedBox(height: 8),
                                  Text('Smart Group Savings', textAlign: TextAlign.center, style: subtitleStyle),
                                  const SizedBox(height: 10),
                                  Text(
                                    'የነገ ህልምዎን በዛሬ ጠብታ',
                                    textAlign: TextAlign.center,
                                    style: taglineStyle,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: isSmall ? 34 : 44),
                      SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          strokeCap: StrokeCap.round,
                          strokeWidth: 2.6,
                          valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                        ),
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

class _SplashLogo extends StatelessWidget {
  const _SplashLogo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.25 : 0.12),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: cs.primary.withOpacity(theme.brightness == Brightness.dark ? 0.10 : 0.14),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.28),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark ? cs.surfaceContainerHighest.withOpacity(0.22) : Colors.white,
            gradient: theme.brightness == Brightness.dark
                ? null
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      cs.primary.withOpacity(0.06),
                      Colors.white,
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
          ),
          alignment: Alignment.center,
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/logo/app_logo.jpeg',
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return Center(
                      child: Icon(
                        Icons.savings_rounded,
                        size: size * 0.55,
                        color: cs.primary,
                      ),
                    );
                  },
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: const Alignment(-0.8, -1),
                        end: const Alignment(0.9, 1),
                        colors: [
                          Colors.white.withOpacity(0.26),
                          Colors.white.withOpacity(0.06),
                          Colors.white.withOpacity(0.0),
                        ],
                        stops: const [0.0, 0.25, 0.72],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: cs.onSurface.withOpacity(theme.brightness == Brightness.dark ? 0.10 : 0.08),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(size * 0.28),
                    ),
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

class _AccentBlob extends StatelessWidget {
  const _AccentBlob({
    required this.alignment,
    required this.color,
    required this.diameter,
    required this.blurSigma,
    required this.offset,
  });

  final Alignment alignment;
  final Color color;
  final double diameter;
  final double blurSigma;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Transform.translate(
        offset: offset,
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            width: diameter,
            height: diameter,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassLogo extends StatelessWidget {
  const _GlassLogo({
    required this.size,
    required this.colorScheme,
  });

  final double size;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final cs = colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary.withOpacity(0.20),
            cs.secondary.withOpacity(0.12),
            cs.primary.withOpacity(0.08),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withOpacity(0.18),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: cs.onSurface.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.savings_rounded,
            size: size * 0.48,
            color: cs.primary,
          ),
          IgnorePointer(
            child: Align(
              alignment: const Alignment(-0.35, -0.45),
              child: Container(
                width: size * 0.78,
                height: size * 0.78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.20),
                      Colors.white.withOpacity(0.0),
                    ],
                    stops: const [0.0, 0.72],
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
