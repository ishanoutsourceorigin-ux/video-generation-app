import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:video_gen_app/Screens/Splash/splash_screen.dart';
import 'package:video_gen_app/Config/environment.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
      title: 'CloneX',
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
