import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';
import '../../utils/validators.dart';
import '../../widgets/neumorphic_widgets.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.login(
      email: InputSanitizer.sanitize(_emailController.text),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      if (authProvider.isPrivileged) {
        Navigator.of(context).pushReplacementNamed('/admin');
      } else {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Login failed'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  // Logo Section
                  Center(
                    child: NeumorphicContainer(
                      shape: BoxShape.circle,
                      padding: const EdgeInsets.all(30),
                      child: Icon(
                        Icons.watch_rounded,
                        size: 60,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Header Text
                  Text(
                    'Welcome Back',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 34,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Login to your exclusive account',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 56),

                  // Email Field
                  _buildInputField(
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.alternate_email_rounded,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 24),

                  // Password Field
                  _buildInputField(
                    controller: _passwordController,
                    label: 'Password',
                    icon: Icons.lock_outline_rounded,
                    isPassword: true,
                    obscureText: _obscurePassword,
                    onTogglePassword: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    validator: (value) =>
                        Validators.required(value, 'Password'),
                  ),
                  const SizedBox(height: 40),

                  // Login Button
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      return NeumorphicButton(
                        onTap: authProvider.isLoading ? () {} : _login,
                        isPressed: authProvider.isLoading,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        borderRadius: BorderRadius.circular(15),
                        child: Center(
                          child: authProvider.isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Login',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                        backgroundColor: AppTheme.primaryColor,
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Google Sign-In
                  NeumorphicButton(
                    onTap: () async {
                      final authProvider =
                          Provider.of<AuthProvider>(context, listen: false);
                      final success = await authProvider.signInWithGoogle();
                      if (success && mounted) {
                        if (authProvider.isPrivileged) {
                          Navigator.of(context).pushReplacementNamed('/admin');
                        } else {
                          Navigator.of(context).pushReplacementNamed('/home');
                        }
                      } else if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(authProvider.errorMessage ??
                                'Google login failed'),
                            backgroundColor: AppTheme.errorColor,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
                            margin: const EdgeInsets.all(16),
                          ),
                        );
                      }
                    },
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    borderRadius: BorderRadius.circular(15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.network(
                          'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
                          height: 24,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.g_mobiledata),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Continue with Google',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Register Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const RegisterScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Register',
                          style: GoogleFonts.inter(
                            color: AppTheme.goldColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),

                  // Test Credentials Section
                  _buildTestCredentialsSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onTogglePassword,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.softUiTextColor,
            ),
          ),
        ),
        NeumorphicContainer(
          isConcave: true,
          borderRadius: BorderRadius.circular(15),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            validator: validator,
            style: const TextStyle(
                color: AppTheme.softUiTextColor, fontWeight: FontWeight.w600),
            cursorColor: AppTheme.primaryColor,
            decoration: InputDecoration(
              prefixIcon:
                  Icon(icon, color: AppTheme.softUiTextColor.withOpacity(0.4)),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        obscureText
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                        color: AppTheme.softUiTextColor.withOpacity(0.4),
                      ),
                      onPressed: onTogglePassword,
                    )
                  : null,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorStyle: const TextStyle(height: 0, color: Colors.transparent),
              hintText: 'Enter your $label',
              hintStyle:
                  TextStyle(color: AppTheme.softUiTextColor.withOpacity(0.2)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTestCredentialsSection() {
    return NeumorphicContainer(
      isConcave: true,
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 20, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              const Text(
                'Quick Test Access',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.softUiTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _CredentialRow(
            label: 'User',
            email: 'user@watchhub.com',
            password: 'user123',
            onTap: () {
              _emailController.text = 'user@watchhub.com';
              _passwordController.text = 'user123';
            },
          ),
          const SizedBox(height: 12),
          _CredentialRow(
            label: 'Admin',
            email: 'admin@watchhub.com',
            password: 'admin123',
            onTap: () {
              _emailController.text = 'admin@watchhub.com';
              _passwordController.text = 'admin123';
            },
          ),
        ],
      ),
    );
  }
}

class _CredentialRow extends StatelessWidget {
  final String label;
  final String email;
  final String password;
  final VoidCallback onTap;

  const _CredentialRow({
    required this.label,
    required this.email,
    required this.password,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NeumorphicButton(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          NeumorphicPill(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            borderRadius: BorderRadius.circular(6),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  email,
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.softUiTextColor),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Password: $password',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.softUiTextColor.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.touch_app_rounded,
              size: 16, color: AppTheme.softUiTextColor.withOpacity(0.3)),
        ],
      ),
    );
  }
}
