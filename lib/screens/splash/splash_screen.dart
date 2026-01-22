import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/neumorphic_widgets.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _rippleController;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // Defer initialization until after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  @override
  void dispose() {
    _rippleController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    // Start fetching settings in background
    Future.microtask(() {
      Provider.of<SettingsProvider>(context, listen: false).fetchSettings();
    });

    await _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Give time for the splash animation to show
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isAuthenticated = await authProvider.checkAuthStatus();

      if (!mounted) return;

      if (isAuthenticated) {
        if (authProvider.isPrivileged) {
          Navigator.of(context).pushReplacementNamed('/admin');
        } else {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } else {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Rippling Logo Treatment
                AnimatedBuilder(
                  animation: _rippleController,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        _buildRippleCircle(1.0, 220),
                        _buildRippleCircle(0.7, 180),
                        _buildRippleCircle(0.4, 140),
                        NeumorphicContainer(
                          shape: BoxShape.circle,
                          padding: const EdgeInsets.all(30),
                          child: const Icon(
                            Icons.watch_rounded,
                            size: 60,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 60),
                Text(
                  'WatchHub',
                  style: GoogleFonts.montserrat(
                    fontSize: 42,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'PREMIUM TIMEPIECES',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.goldColor,
                    letterSpacing: 5,
                  ),
                ),
                const SizedBox(height: 80),

                // Custom Neumorphic Progress Indicator
                _buildNeumorphicLoader(),
              ],
            ),
          ),
          // Version info at bottom
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'v1.0.4 Premium Edition',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: AppTheme.textTertiaryColor,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRippleCircle(double delay, double size) {
    final value = (_rippleController.value + delay) % 1.0;
    return Opacity(
      opacity: (1.0 - value).clamp(0.0, 1.0),
      child: Container(
        width: size * (1.0 + value * 0.2),
        height: size * (1.0 + value * 0.2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.backgroundColor,
          boxShadow: [
            BoxShadow(
              color: AppTheme.softUiShadowDark.withOpacity(0.3 * (1.0 - value)),
              offset: Offset(8 * (1.0 - value), 8 * (1.0 - value)),
              blurRadius: 16 * (1.0 - value),
            ),
            BoxShadow(
              color:
                  AppTheme.softUiShadowLight.withOpacity(0.3 * (1.0 - value)),
              offset: Offset(-8 * (1.0 - value), -8 * (1.0 - value)),
              blurRadius: 16 * (1.0 - value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNeumorphicLoader() {
    return Container(
      width: 200,
      height: 10,
      padding: const EdgeInsets.all(2),
      child: NeumorphicContainer(
        isConcave: true,
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: _rippleController,
              builder: (context, child) {
                return FractionallySizedBox(
                  widthFactor: (_rippleController.value * 0.8) +
                      0.1, // Simulates loading
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.goldColor, AppTheme.roseGoldColor],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.goldColor.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(2, 0),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
