import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'providers/auth_provider.dart';
import 'providers/watch_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/wishlist_provider.dart';
import 'providers/order_provider.dart';
import 'providers/user_provider.dart';
import 'providers/review_provider.dart';
import 'providers/admin_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/notification_provider.dart';
import 'utils/theme.dart';
import 'utils/constants.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_navigation.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/manage_products_screen.dart';
import 'screens/admin/manage_orders_screen.dart';
import 'screens/admin/manage_users_screen.dart';
import 'screens/admin/manage_categories_screen.dart';
import 'screens/admin/manage_brands_screen.dart';
import 'screens/admin/manage_reviews_screen.dart';
import 'screens/admin/manage_banners_screen.dart';
import 'screens/admin/manage_promotion_screen.dart';
import 'screens/admin/manage_coupons_screen.dart';
import 'screens/admin/shipping_settings_screen.dart';
import 'screens/admin/manage_faqs_screen.dart';
import 'screens/admin/manage_tickets_screen.dart';
import 'screens/admin/send_notification_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // TODO: Fix path issue - currently not loading properly
  // await dotenv.load(fileName: ".env");

  // Initialize Stripe (skip on web as it's not supported)
  if (!kIsWeb) {
    Stripe.publishableKey = Constants.stripePublishableKey;
  }

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WatchProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, _) {
          return MaterialApp(
            title: 'WatchHub',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settingsProvider.themeMode,
            home: const SplashScreen(),
            routes: {
              '/login': (context) => const LoginScreen(),
              '/home': (context) => const MainNavigation(),
              '/admin': (context) => const AdminDashboardScreen(),
              '/admin/products': (context) => const ManageProductsScreen(),
              '/admin/orders': (context) => const ManageOrdersScreen(),
              '/admin/users': (context) => const ManageUsersScreen(),
              '/admin/categories': (context) => const ManageCategoriesScreen(),
              '/admin/brands': (context) => const ManageBrandsScreen(),
              '/admin/reviews': (context) => const ManageReviewsScreen(),
              '/admin/banners': (context) => const ManageBannersScreen(),
              '/admin/promotions': (context) => const ManagePromotionScreen(),
              '/admin/coupons': (context) => const ManageCouponsScreen(),
              '/admin/shipping': (context) => const ShippingSettingsScreen(),
              '/admin/faqs': (context) => const ManageFAQsScreen(),
              '/admin/tickets': (context) => const ManageTicketsScreen(),
              '/admin/notifications': (context) =>
                  const SendNotificationScreen(),
            },
          );
        },
      ),
    );
  }
}
