import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';
import '../../utils/validators.dart';
import '../../widgets/neumorphic_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.register(
      email: InputSanitizer.sanitize(_emailController.text),
      password: _passwordController.text,
      name: InputSanitizer.sanitize(_nameController.text),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : InputSanitizer.sanitizePhone(_phoneController.text),
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
          content: Text(authProvider.errorMessage ?? 'Registration failed'),
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
      backgroundColor: AppTheme.softUiBackground,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: NeumorphicTopBar(
          title: 'Create Account',
          onBackTap: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Join WatchHub',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.softUiTextColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Discover luxury timepieces today',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.softUiTextColor.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 48),
                _buildInputField(
                  controller: _nameController,
                  label: 'Full Name',
                  icon: Icons.person_outline_rounded,
                  validator: (value) => Validators.required(value, 'Full Name'),
                ),
                const SizedBox(height: 24),
                _buildInputField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.alternate_email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                ),
                const SizedBox(height: 24),
                _buildInputField(
                  controller: _phoneController,
                  label: 'Phone (Optional)',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: Validators.phone,
                ),
                const SizedBox(height: 24),
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
                  validator: Validators.password,
                ),
                const SizedBox(height: 24),
                _buildInputField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  icon: Icons.lock_clock_outlined,
                  isPassword: true,
                  obscureText: _obscureConfirmPassword,
                  onTogglePassword: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40),
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return NeumorphicButton(
                      onTap: authProvider.isLoading ? () {} : _register,
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
                            : const Text(
                                'Register',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                      backgroundColor: AppTheme.primaryColor,
                    );
                  },
                ),
                const SizedBox(height: 32),
              ],
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
}
