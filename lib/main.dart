import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:slimtrap/pages/get_start.dart';
import 'package:slimtrap/pages/home.dart';

import 'components/ui/appbar.dart';
// import 'pages/home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  static GlobalKey mtAppKey = GlobalKey();
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _hasInternet = true;
  Future<void> checkInternetConnection() async {
    if (!await Method.checkInternetConnection(context)) {
      setState(() {
        _hasInternet = false;
      });
      return;
    } else {
      setState(() {
        _hasInternet = true;
      });
    }
    try {
      final result =
          await InternetAddress.lookup('firebasestorage.googleapis.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        setState(() {
          _hasInternet = true;
        });
      }
    } on SocketException catch (_) {
      setState(() {
        _hasInternet = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasInternet) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'No Internet Connection',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  checkInternetConnection();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    User? user = FirebaseAuth.instance.currentUser;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: user == null ? const GetStarted() : const HomePage(),
    );
  }
}
