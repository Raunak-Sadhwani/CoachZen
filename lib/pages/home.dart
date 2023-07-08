import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:slimtrap/pages/body_form.dart';
import 'package:slimtrap/pages/body_form_list.dart';
import 'package:slimtrap/pages/cust_new_form.dart';
import 'package:slimtrap/pages/profile.dart';

import '../components/ui/appbar.dart';
import 'login.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool internet = true;
  Future<void> checkInternetAndAuth() async {
    bool hasInternet = await Method.checkInternetConnection(context);

    if (!hasInternet) {
      setState(() {
        internet = false;
      });
    } else {
      setState(() {
        internet = true;
      });
      try {
        final result =
            await InternetAddress.lookup('firebasestorage.googleapis.com');
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          setState(() {
            internet = true;
          });
        }
      } on SocketException catch (_) {
        setState(() {
          internet = false;
        });
      }
      user = FirebaseAuth.instance.currentUser;
      FirebaseAuth.instance.authStateChanges().listen((User? user) {
        if (user == null) {
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
              (Route<dynamic> route) => false);
          return;
        }
        getUserData();
        updateText();
      });
    }
  }

  void updateText() {
    final now = DateTime.now();
    final hour = now.hour;

    if (hour >= 6 && hour < 12) {
      setState(() {
        day = 'Morning';
      });
    } else if (hour >= 12 && hour < 18) {
      setState(() {
        day = 'Afternoon';
      });
    } else if (hour >= 18 && hour < 24) {
      setState(() {
        day = 'Evening';
      });
    } else {
      setState(() {
        day = 'Night';
      });
    }
  }

  String day = '';

  User? user = FirebaseAuth.instance.currentUser;
  String capitalize(String value) {
    return value
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  @override
  void initState() {
    super.initState();
    checkInternetAndAuth();
  }

  Map<String, dynamic> coachData = {};
  // get userdata from firestore
  Future<void> getUserData() async {
    await FirebaseFirestore.instance
        .collection('Coaches')
        .doc(user!.uid)
        .get()
        .then((DocumentSnapshot<Map<String, dynamic>> documentSnapshot) {
      if (documentSnapshot.exists) {
        setState(() {
          coachData = documentSnapshot.data()!;
        });
        debugPrint('Document data: ${documentSnapshot.data()}');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    if (!internet) {
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
                  checkInternetAndAuth();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: MyAppBar(
          // avatar
          rightIcons: [
            OpenContainerWrapper(
              page: ProfilePg(
                userData: coachData,
              ),
              content: Container(
                margin: EdgeInsets.only(right: width * 0.06),
                child: Image.asset('lib/assets/male.png',
                    height: 40, fit: BoxFit.cover),
              ),
            ),
          ]

          // title: 'Home',
          ),
      // backgroundColor: const Color.fromARGB(255, 83, 98, 210),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: width * 0.035,
            vertical: height * 0.02,
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.only(left: width * 0.04),
                margin: EdgeInsets.only(bottom: height * 0.03),
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          const TextSpan(
                            text: 'Hello, ',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 24,
                            ),
                          ),
                          TextSpan(
                            text: capitalize('${user!.displayName}!'),
                            style: GoogleFonts.raleway(
                              color: Colors.black,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: height * 0.01),
                    Text(
                      'Good $day, welcome back!',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  HomeButton(
                      height: height,
                      width: width,
                      imgPath: 'lib/assets/meas.jpg',
                      page: const FormPage(),
                      openColor: Colors.yellow.shade800,
                      label1: 'Customer',
                      label2: 'Check-up'),
                  HomeButton(
                      height: height,
                      width: width,
                      imgPath: 'lib/assets/focus.png',
                      page: const BodyFormList(),
                      openColor: Colors.blue.shade800,
                      label1: 'My',
                      label2: 'Customers'),
                  HomeButton(
                      height: height,
                      width: width,
                      page: const CustNewForm(),
                      imgPath: 'lib/assets/new_cust.png',
                      openColor: Colors.green.shade800,
                      label1: 'New',
                      label2: 'Customer'),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class HomeButton extends StatelessWidget {
  final double height;
  final double width;
  final String imgPath;
  final String label1;
  final String label2;
  final Widget page;
  final Color? openColor;

  const HomeButton({
    Key? key,
    required this.height,
    required this.width,
    required this.imgPath,
    required this.label1,
    required this.label2,
    this.openColor,
    required this.page,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: height * 0.02),
      height: height * 0.2,
      child: Card(
        elevation: 10,
        child: OpenContainerWrapper(
          openColor: openColor ?? Colors.white,
          page: page,
          content: Container(
            width: double.infinity,
            padding: EdgeInsets.only(left: width * 0.08),
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(imgPath),
                fit: BoxFit.cover,
                colorFilter: const ColorFilter.mode(
                  Colors.black26,
                  BlendMode.darken,
                ),
                alignment: Alignment.centerRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label1,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label2,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
