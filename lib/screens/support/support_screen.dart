import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import 'faq_screen.dart';
import 'tickets_screen.dart';
import 'contact_screen.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const kBackgroundColor = AppTheme.softUiBackground;
    const kTextColor = AppTheme.softUiTextColor;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: _NeumorphicContainer(
              borderRadius: BorderRadius.circular(20),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _NeumorphicButton(
                    onTap: () => Navigator.of(context).pop(),
                    padding: const EdgeInsets.all(10),
                    shape: BoxShape.circle,
                    child: const Icon(Icons.arrow_back,
                        color: kTextColor, size: 20),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Customer Support',
                        style: TextStyle(
                          color: kTextColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSupportCard(
            context,
            icon: Icons.help_outline_rounded,
            title: 'FAQ',
            subtitle: 'Frequently Asked Questions',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const FAQScreen()),
              );
            },
          ),
          const SizedBox(height: 24),
          _buildSupportCard(
            context,
            icon: Icons.message_rounded,
            title: 'Contact Us',
            subtitle: 'Send us a message',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ContactScreen()),
              );
            },
          ),
          const SizedBox(height: 24),
          _buildSupportCard(
            context,
            icon: Icons.receipt_long_rounded,
            title: 'My Tickets',
            subtitle: 'View your support tickets',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const TicketsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSupportCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    const kTextColor = AppTheme.softUiTextColor;

    return _NeumorphicButton(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Icon Well (Concave)
          _NeumorphicContainer(
            isConcave: true,
            shape: BoxShape.circle,
            padding: const EdgeInsets.all(16),
            child: Icon(
              icon,
              size: 28,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 20),

          // Text Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: kTextColor.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),

          // Action Indicator
          _NeumorphicContainer(
            borderRadius: BorderRadius.circular(12),
            padding: const EdgeInsets.all(8),
            child: const Icon(
              Icons.chevron_right_rounded,
              color: kTextColor,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

// --- Neumorphic Components ---

class _NeumorphicContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry? borderRadius;
  final BoxShape shape;
  final bool isConcave;

  const _NeumorphicContainer({
    required this.child,
    this.padding = EdgeInsets.zero,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
    this.isConcave = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppTheme.softUiBackground,
        shape: shape,
        borderRadius: shape == BoxShape.rectangle ? borderRadius : null,
        boxShadow: isConcave
            ? [
                BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    offset: const Offset(4, 4),
                    blurRadius: 4,
                    spreadRadius: 1),
                BoxShadow(
                    color: Colors.white.withOpacity(0.8),
                    offset: const Offset(-4, -4),
                    blurRadius: 4,
                    spreadRadius: 1),
              ]
            : [
                const BoxShadow(
                    color: AppTheme.softUiShadowDark,
                    offset: Offset(6, 6),
                    blurRadius: 16),
                const BoxShadow(
                    color: AppTheme.softUiShadowLight,
                    offset: Offset(-6, -6),
                    blurRadius: 16),
              ],
      ),
      child: child,
    );
  }
}

class _NeumorphicButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry? borderRadius;
  final BoxShape shape;

  const _NeumorphicButton({
    required this.child,
    required this.onTap,
    this.padding = EdgeInsets.zero,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
  });

  @override
  State<_NeumorphicButton> createState() => _NeumorphicButtonState();
}

class _NeumorphicButtonState extends State<_NeumorphicButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: widget.padding,
        decoration: BoxDecoration(
          color: AppTheme.softUiBackground,
          shape: widget.shape,
          borderRadius:
              widget.shape == BoxShape.rectangle ? widget.borderRadius : null,
          boxShadow: _isPressed
              ? [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      offset: const Offset(2, 2),
                      blurRadius: 2,
                      spreadRadius: 1),
                  const BoxShadow(
                      color: Colors.white,
                      offset: Offset(-2, -2),
                      blurRadius: 2,
                      spreadRadius: 1),
                ]
              : [
                  const BoxShadow(
                      color: AppTheme.softUiShadowDark,
                      offset: Offset(4, 4),
                      blurRadius: 10),
                  const BoxShadow(
                      color: AppTheme.softUiShadowLight,
                      offset: Offset(-4, -4),
                      blurRadius: 10),
                ],
        ),
        child: widget.child,
      ),
    );
  }
}
