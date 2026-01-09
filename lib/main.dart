import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:nainkart_user/epooja/get_epooja.dart';
import 'package:nainkart_user/firebase_methods/fcm_service.dart';
import 'package:nainkart_user/home_page.dart';
import 'package:nainkart_user/kundli/generate_kundali.dart';
import 'package:nainkart_user/login_screen.dart';
import 'package:nainkart_user/products/product_page.dart';
import 'package:nainkart_user/provider/wallet_provider.dart';
import 'package:provider/provider.dart'; // ✅ Add Provider import
import 'package:shared_preferences/shared_preferences.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FCMService.initialize();

  InAppWebViewController.setWebContentsDebuggingEnabled(true);
  await CookieManager.instance().deleteAllCookies();
  await WebStorageManager.instance().deleteAllData();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final prefs = await SharedPreferences.getInstance();
  final authToken = prefs.getString('auth_token');

  runApp(MyApp(initialToken: authToken));
}

class MyApp extends StatelessWidget {
  final String? initialToken;

  const MyApp({Key? key, this.initialToken}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WalletProvider()),
      ],
      child: MaterialApp(
        // title: 'Astrologer App',
        navigatorKey: navigatorKey,
        theme: ThemeData(primarySwatch: Colors.purple),
        debugShowCheckedModeBanner: false,
        home: initialToken != null
            ? HomePage(token: initialToken!)
            : const LoginScreen(),
        routes: {
          '/home': (context) {
            final token = ModalRoute.of(context)!.settings.arguments as String;
            return HomePage(token: token);
          },
          '/pooja': (context) {
            final token = ModalRoute.of(context)!.settings.arguments as String;
            return EPoojaScreen(token: token);
          },
          '/products': (context) {
            final token = ModalRoute.of(context)!.settings.arguments as String;
            return ProductPage(token: token);
          },
          '/generate-kundli': (context) {
            final token = ModalRoute.of(context)!.settings.arguments as String;
            return GenerateKundli(token: token);
          },
        },
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => initialToken != null
                ? HomePage(token: initialToken!)
                : const LoginScreen(),
          );
        },
      ),
    );
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling background message: ${message.messageId}");
}
