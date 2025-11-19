import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:video_gen_app/Screens/Splash/splash_screen.dart';
import 'package:video_gen_app/Config/environment.dart';
import 'package:video_gen_app/Services/payment_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize in-app purchase
  await PaymentService.initializeInAppPurchase();
  PaymentService.initializePurchaseStream();

  // Recover any incomplete purchases
  await PaymentService.recoverPurchases();

  // Print environment info for debugging
  Environment.printEnvironmentInfo();

  runApp(const MyApp());
}

late Size mq;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;
    return MaterialApp(
      title: 'CloneX - AI Avatar Video Generator',
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}

// Add app lifecycle handling for proper cleanup
class AppLifecycleHandler extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      PaymentService.dispose();
    }
  }
}
