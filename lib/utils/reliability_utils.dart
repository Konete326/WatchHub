import 'dart:async';
import 'package:flutter/material.dart';

class ReliabilityUtils {
  /// Retries a future [fn] up to [maxRetries] times with exponential backoff.
  static Future<T> retry<T>(
    Future<T> Function() fn, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
  }) async {
    int attempts = 0;
    while (true) {
      try {
        return await fn();
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) rethrow;

        final delay = initialDelay * attempts;
        debugPrint(
            'Retry attempt $attempts after ${delay.inSeconds}s due to: $e');
        await Future.delayed(delay);
      }
    }
  }
}

class ReliabilityView extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onRetry;
  final String? actionLabel;

  const ReliabilityView({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.error_outline,
    this.onRetry,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (onRetry != null)
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: Text(actionLabel ?? 'Try Again'),
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
