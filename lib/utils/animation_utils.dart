import 'package:flutter/material.dart';
import 'package:animations/animations.dart';

/// Utility class for creating animated route transitions
class AnimationUtils {
  /// Creates a container transform route for card-to-detail transitions
  /// Perfect for: Card -> Product Detail, List Item -> Detail Page
  /// Note: For true container transform, use OpenContainer widget in the UI
  /// This provides a shared axis transition as an alternative
  static PageRoute<T> containerTransformRoute<T extends Object?>(
    Widget page, {
    String? transitionName,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          transitionType: SharedAxisTransitionType.scaled,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 250),
    );
  }

  /// Creates a shared axis route for related screens
  /// Perfect for: Navigation flows, steppers, onboarding
  static PageRoute<T> sharedAxisRoute<T extends Object?>(
    Widget page, {
    SharedAxisTransitionType transitionType = SharedAxisTransitionType.horizontal,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          transitionType: transitionType,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 250),
    );
  }

  /// Creates a fade through route for unrelated screens
  /// Perfect for: Bottom nav bar transitions, unrelated screens
  static PageRoute<T> fadeThroughRoute<T extends Object?>(
    Widget page,
  ) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeThroughTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 250),
    );
  }

  /// Creates a fade route for dialogs and overlays
  /// Perfect for: Dialogs, menus, snackbars
  static PageRoute<T> fadeRoute<T extends Object?>(
    Widget page,
  ) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 200),
      reverseTransitionDuration: const Duration(milliseconds: 150),
      opaque: false,
    );
  }

  /// Opens a dialog with fade animation
  static Future<T?> showAnimatedDialog<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = true,
    Color? barrierColor,
  }) {
    return showGeneralDialog<T>(
      context: context,
      pageBuilder: (context, animation, secondaryAnimation) {
        return builder(context);
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 200),
      barrierDismissible: barrierDismissible,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: barrierColor ?? Colors.black54,
    );
  }

  /// Opens a modal bottom sheet with slide animation
  static Future<T?> showAnimatedBottomSheet<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      builder: builder,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
    );
  }

  /// Navigate with container transform (for card to detail)
  static Future<T?> pushContainerTransform<T extends Object?>(
    BuildContext context,
    Widget page, {
    String? transitionName,
  }) {
    return Navigator.of(context).push<T>(
      containerTransformRoute<T>(page, transitionName: transitionName),
    );
  }

  /// Navigate with shared axis (for related screens)
  static Future<T?> pushSharedAxis<T extends Object?>(
    BuildContext context,
    Widget page, {
    SharedAxisTransitionType transitionType = SharedAxisTransitionType.horizontal,
  }) {
    return Navigator.of(context).push<T>(
      sharedAxisRoute<T>(page, transitionType: transitionType),
    );
  }

  /// Navigate with fade through (for unrelated screens)
  static Future<T?> pushFadeThrough<T extends Object?>(
    BuildContext context,
    Widget page,
  ) {
    return Navigator.of(context).push<T>(
      fadeThroughRoute<T>(page),
    );
  }

  /// Navigate with fade (for overlays)
  static Future<T?> pushFade<T extends Object?>(
    BuildContext context,
    Widget page,
  ) {
    return Navigator.of(context).push<T>(
      fadeRoute<T>(page),
    );
  }
}

