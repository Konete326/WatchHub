import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme.dart';

class PremiumDialogs {
  static void showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.network(
                'https://lottie.host/5753907c-95b0-469b-8911-09439f0ed27b/8EwXvT1V5e.json',
                width: 150,
                height: 150,
                repeat: false,
              ),
              const SizedBox(height: 16),
              Text(
                'Success!',
                style: GoogleFonts.montserrat(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: AppTheme.goldButtonStyle.copyWith(
                  minimumSize:
                      WidgetStateProperty.all(const Size(double.infinity, 50)),
                ),
                child: const Text('Great'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget loadingAnimation() {
    return Center(
      child: Lottie.network(
        'https://lottie.host/d275753b-e0c1-4b71-97ed-d8677c77f300/fU3P0q5sFj.json', // Premium loading
        width: 200,
        height: 200,
      ),
    );
  }
}
