import 'package:flutter/material.dart';
import '../utils/theme.dart';

class NeumorphicContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry? borderRadius;
  final BoxShape shape;
  final bool isConcave;
  final Color backgroundColor;

  const NeumorphicContainer({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
    this.isConcave = false,
    this.backgroundColor = AppTheme.softUiBackground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: shape,
        borderRadius: shape == BoxShape.rectangle ? borderRadius : null,
        boxShadow: isConcave
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  offset: const Offset(4, 4),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.8),
                  offset: const Offset(-4, -4),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ]
            : [
                const BoxShadow(
                  color: AppTheme.softUiShadowDark,
                  offset: Offset(6, 6),
                  blurRadius: 16,
                ),
                const BoxShadow(
                  color: AppTheme.softUiShadowLight,
                  offset: Offset(-6, -6),
                  blurRadius: 16,
                ),
              ],
      ),
      child: child,
    );
  }
}

class NeumorphicButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry? borderRadius;
  final BoxShape shape;
  final bool isPressed;
  final Color backgroundColor;

  const NeumorphicButton({
    super.key,
    required this.child,
    required this.onTap,
    this.padding = EdgeInsets.zero,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
    this.isPressed = false,
    this.backgroundColor = AppTheme.softUiBackground,
  });

  @override
  State<NeumorphicButton> createState() => _NeumorphicButtonState();
}

class _NeumorphicButtonState extends State<NeumorphicButton> {
  bool _isGesturePressed = false;

  @override
  Widget build(BuildContext context) {
    final bool effectivePressed = widget.isPressed || _isGesturePressed;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isGesturePressed = true),
      onTapUp: (_) => setState(() => _isGesturePressed = false),
      onTapCancel: () => setState(() => _isGesturePressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: widget.padding,
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          shape: widget.shape,
          borderRadius:
              widget.shape == BoxShape.rectangle ? widget.borderRadius : null,
          boxShadow: effectivePressed
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    offset: const Offset(2, 2),
                    blurRadius: 2,
                    spreadRadius: 1,
                  ),
                  const BoxShadow(
                    color: Colors.white,
                    offset: Offset(-2, -2),
                    blurRadius: 2,
                    spreadRadius: 1,
                  ),
                ]
              : [
                  const BoxShadow(
                    color: AppTheme.softUiShadowDark,
                    offset: Offset(4, 4),
                    blurRadius: 10,
                  ),
                  const BoxShadow(
                    color: AppTheme.softUiShadowLight,
                    offset: Offset(-4, -4),
                    blurRadius: 10,
                  ),
                ],
        ),
        child: widget.child,
      ),
    );
  }
}

class NeumorphicTopBar extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final VoidCallback? onBackTap;
  final Color backgroundColor;
  final Color textColor;

  const NeumorphicTopBar({
    super.key,
    required this.title,
    this.actions,
    this.onBackTap,
    this.backgroundColor = AppTheme.softUiBackground,
    this.textColor = AppTheme.softUiTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        child: NeumorphicContainer(
          borderRadius: BorderRadius.circular(20),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              if (onBackTap != null)
                NeumorphicButton(
                  onTap: onBackTap!,
                  padding: const EdgeInsets.all(10),
                  shape: BoxShape.circle,
                  child: Icon(Icons.arrow_back, color: textColor, size: 20),
                )
              else
                const SizedBox(width: 40),
              Expanded(
                child: Center(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              if (actions != null) ...actions! else const SizedBox(width: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class NeumorphicDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmLabel;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final Color confirmColor;

  const NeumorphicDialog({
    super.key,
    required this.title,
    required this.content,
    required this.confirmLabel,
    required this.onConfirm,
    required this.onCancel,
    this.confirmColor = AppTheme.errorColor,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: NeumorphicContainer(
        borderRadius: BorderRadius.circular(30),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: double.infinity),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.softUiTextColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              content,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.softUiTextColor.withOpacity(0.7),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: NeumorphicButton(
                    onTap: onCancel,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    borderRadius: BorderRadius.circular(15),
                    child: const Center(
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: AppTheme.softUiTextColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: NeumorphicButton(
                    onTap: onConfirm,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    borderRadius: BorderRadius.circular(15),
                    child: Center(
                      child: Text(
                        confirmLabel,
                        style: TextStyle(
                          color: confirmColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class NeumorphicPill extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry? borderRadius;

  const NeumorphicPill({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return NeumorphicContainer(
      isConcave: true,
      padding: padding,
      borderRadius: borderRadius ?? BorderRadius.circular(20),
      child: child,
    );
  }
}
