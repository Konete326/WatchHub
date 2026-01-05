import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
import 'utils/theme.dart';
import 'utils/constants.dart';
import 'utils/animation_utils.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/main_navigation.dart';
import 'screens/admin/admin_dashboard_screen.dart';

import 'services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Note: Cloudinary credentials are currently hardcoded in CloudinaryService
  // TODO: Implement environment variable loading once flutter_dotenv path issue is resolved

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Notifications
  if (!kIsWeb) {
    await NotificationService.initialize();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // Initialize Stripe only on mobile platforms (not web)
  if (!kIsWeb) {
    Stripe.publishableKey = Constants.stripePublishableKey;
  }

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
      ],
      child: MaterialApp(
        title: 'WatchHub',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const MainNavigation(),
          '/admin': (context) => const AdminDashboardScreen(),
        },
        onGenerateRoute: (settings) {
          // Use fade through for route transitions (unrelated screens)
          Widget page;
          switch (settings.name) {
            case '/login':
              page = const LoginScreen();
              break;
            case '/home':
              page = const MainNavigation();
              break;
            case '/admin':
              page = const AdminDashboardScreen();
              break;
            default:
              page = const SplashScreen();
          }
          return AnimationUtils.fadeThroughRoute(page);
        },
      ),
    );
  }
}
