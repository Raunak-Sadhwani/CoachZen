import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:coach_zen/pages/get_start.dart';
import 'package:coach_zen/pages/home.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/services.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  // future delayed for splash screen
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  if (!await Permission.notification.isGranted) {
    await Permission.notification.request();
  }
  tz.initializeTimeZones();
  await Firebase.initializeApp();
  Future.delayed(const Duration(seconds: 3), () {
    FlutterNativeSplash.remove();
  });
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  static GlobalKey mtAppKey = GlobalKey();
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: user == null ? const GetStarted() : const HomePage(),
    );
  }
}
