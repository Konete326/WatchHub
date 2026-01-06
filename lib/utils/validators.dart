class InputSanitizer {
  /// Basic sanitization: trim whitespace and remove common script/HTML tags
  static String sanitize(String input) {
    if (input.isEmpty) return input;

    // Trim whitespace
    String sanitized = input.trim();

    // Remove HTML tags to prevent simple XSS if the data is viewed in admin dashboards or elsewhere
    sanitized = sanitized.replaceAll(RegExp(r'<[^>]*>'), '');

    // Remove common script-related keywords/dangerous characters if needed
    // For now, removing < > " ' & is a good baseline to prevent breaking UI or injection
    // sanitized = sanitized.replaceAll(RegExp(r'[<>"&]'), '');

    return sanitized;
  }

  /// Sanitizes numeric inputs (allows only numbers and a single decimal point)
  static String sanitizeNumeric(String input) {
    String sanitized = input.replaceAll(RegExp(r'[^0-9.]'), '');
    // Ensure only one decimal point
    final parts = sanitized.split('.');
    if (parts.length > 2) {
      sanitized = '${parts[0]}.${parts.sublist(1).join('')}';
    }
    return sanitized;
  }

  /// Sanitizes phone numbers (allows only numbers and +)
  static String sanitizePhone(String input) {
    return input.replaceAll(RegExp(r'[^0-9+]'), '');
  }
}

class Validators {
  static String? required(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    final phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  static String? price(String? value) {
    if (value == null || value.isEmpty) {
      return 'Price is required';
    }
    final priceRegex = RegExp(r'^\d+(\.\d{1,2})?$');
    if (!priceRegex.hasMatch(value)) {
      return 'Enter a valid price';
    }
    if (double.tryParse(value) == null || double.parse(value) <= 0) {
      return 'Price must be greater than zero';
    }
    return null;
  }

  static String? stock(String? value) {
    if (value == null || value.isEmpty) {
      return 'Stock is required';
    }
    final stockRegex = RegExp(r'^\d+$');
    if (!stockRegex.hasMatch(value)) {
      return 'Enter a valid stock number';
    }
    if (int.tryParse(value) == null || int.parse(value) < 0) {
      return 'Stock cannot be negative';
    }
    return null;
  }
}
