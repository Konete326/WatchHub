class Constants {
  // Stripe Configuration
  // Get your test key from https://dashboard.stripe.com/test/apikeys
  static const String stripePublishableKey =
      'pk_test_51Shp5ZItPqN42Px74Rbut3LjLVfsWxtuLxZej8X42CwkTb5ZrKJTloxtpTuaWbHg7Jr5LaSwkR5zzgLTzIUp8SHQ00zi9czpkY';
  static const String stripeSecretKey =
      ''; // DO NOT HARDCODE SECRETS. Use environment variables.

  // Toggle for Fake vs Real Payment
  static const bool useFakePayment =
      true; // Use true for testing with fake data

  // Pagination
  static const int pageSize = 10;
  static const int maxProductImages = 5;

  // NOTE: Categories are now dynamic and fetched from Firestore.
  // Admin can manage categories via the Manage Categories screen.

  // Order Status
  static const Map<String, String> orderStatus = {
    'PENDING': 'Pending',
    'PROCESSING': 'Processing',
    'SHIPPED': 'Shipped',
    'DELIVERED': 'Delivered',
    'CANCELLED': 'Cancelled',
  };

  // Support Ticket Status
  static const Map<String, String> ticketStatus = {
    'OPEN': 'Open',
    'IN_PROGRESS': 'In Progress',
    'RESOLVED': 'Resolved',
    'CLOSED': 'Closed',
  };
}
