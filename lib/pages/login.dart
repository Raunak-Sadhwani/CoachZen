import 'package:another_flushbar/flushbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'get_start.dart';
import 'home.dart';
import 'register.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  final Color? _color = Colors.grey[100];
  bool _obscureText = true;
  bool pressed = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        body: Align(
            alignment: Alignment.topCenter,
            child: Column(children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.05,
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height * 0.12,
                child: Center(
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const GetStarted())),
                    child: AutoSizeText(
                      "CoachUp",
                      style: GoogleFonts.luckiestGuy(
                        color: Colors.blue,
                        fontSize: 45,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(40),
                          topRight: Radius.circular(40))),
                  child: SingleChildScrollView(
                    padding:
                        const EdgeInsets.only(left: 20.0, right: 20.0, top: 15),
                    child: Column(children: [
                      Text(
                        'Log In',
                        style: GoogleFonts.notoSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 32,
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.01,
                      ),
                      Text('Please login to continue using our app',
                          style: TextStyle(color: Colors.grey[100])),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.1,
                      ),
                      Form(
                          autovalidateMode: pressed
                              ? AutovalidateMode.onUserInteraction
                              : AutovalidateMode.disabled,
                          key: _formKey,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  controller: email,
                                  validator: (email) => email!.isValidEmail()
                                      ? null
                                      : "Check your email",
                                  decoration: InputDecoration(
                                    prefixIcon: const Padding(
                                      padding: EdgeInsets.only(left: 10.0),
                                      child: Icon(
                                        Icons.email,
                                        size: 18,
                                      ),
                                    ),
                                    hintText: "   Your Email",
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(25.0),
                                      borderSide: const BorderSide(
                                        color: Colors.blue,
                                        width: 2,
                                      ),
                                    ),
                                    errorStyle:
                                        const TextStyle(color: Colors.black),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(25.0),
                                      borderSide: const BorderSide(
                                        color: Color.fromARGB(255, 0, 0, 0),
                                        width: 2,
                                      ),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(25.0),
                                      borderSide: const BorderSide(
                                        color: Colors.blue,
                                        width: 2,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: _color,
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(25.0),
                                      borderSide: const BorderSide(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                TextFormField(
                                  validator: (password) =>
                                      password != null && password.length < 6
                                          ? "Invalid Password"
                                          : null,
                                  controller: password,
                                  decoration: InputDecoration(
                                    prefixIcon: const Padding(
                                      padding: EdgeInsets.only(left: 10.0),
                                      child: Icon(
                                        Icons.vpn_key,
                                        size: 18,
                                      ),
                                    ),
                                    suffixIcon: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _obscureText = !_obscureText;
                                        });
                                      },
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(right: 10.0),
                                        child: Icon(
                                          _obscureText
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                    hintText: "   Enter Password",
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(25.0),
                                      borderSide: const BorderSide(
                                        color: Colors.blue,
                                        width: 2,
                                      ),
                                    ),
                                    errorStyle:
                                        const TextStyle(color: Colors.black),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(25.0),
                                      borderSide: const BorderSide(
                                        color: Colors.black,
                                        width: 2,
                                      ),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(25.0),
                                      borderSide: const BorderSide(
                                        color: Colors.blue,
                                        width: 2,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: _color,
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(25.0),
                                      borderSide: const BorderSide(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  obscureText: _obscureText,
                                ),
                                const SizedBox(
                                  height: 60,
                                ),
                                Center(
                                  child: Column(
                                    children: [
                                      ElevatedButton(
                                        onPressed: signIn,
                                        style: ElevatedButton.styleFrom(
                                          minimumSize:
                                              const Size.fromHeight(50),
                                          backgroundColor: Colors.white,
                                          padding: EdgeInsets.symmetric(
                                            vertical: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.02,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(40),
                                          ),
                                        ),
                                        child: Text(
                                          'Log In',
                                          style: GoogleFonts.montserrat(
                                            color: Colors.blue,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 20,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.03,
                                      ),
                                      RichText(
                                          text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: "Don't have an account? ",
                                            style: GoogleFonts.notoSans(
                                              color: Colors.grey[200],
                                              fontSize: 14,
                                            ),
                                          ),
                                          TextSpan(
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          const Register())),
                                            text: ' Sign Up',
                                            // underline
                                            style: GoogleFonts.notoSans(
                                              decoration:
                                                  TextDecoration.underline,
                                              color: const Color.fromARGB(
                                                  255, 226, 255, 82),
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      )),
                                    ],
                                  ),
                                ),
                              ]))
                    ]),
                  ),
                ),
              ),
            ])));
  }

  Future signIn() async {
    final isValform = _formKey.currentState?.validate();
    if (!isValform!) return;
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      return Flushbar(
        message: 'No Internet Connection, Login Failed',
        icon: Icon(
          Icons.info_outline,
          size: 28.0,
          color: Colors.blue[300],
        ),
        duration: const Duration(milliseconds: 1500),
        leftBarIndicatorColor: Colors.blue[300],
      )..show(_scaffoldKey.currentContext!);
    }

    var emailT = email.text.trim().toLowerCase();

    showDialog(
        context: _scaffoldKey.currentContext!,
        barrierDismissible: false,
        builder: (context) => const Center(
              child: CircularProgressIndicator(),
            ));

    // Check if the email belongs to a coach
    // var coachSnapshot = await FirebaseFirestore.instance
    //     .collection('Coaches')
    //     .where('email', isEqualTo: emailT)
    //     .limit(1)
    //     .get();

    // if (coachSnapshot.docs.isEmpty) {
    //   Navigator.of(_scaffoldKey.currentContext!, rootNavigator: true)
    //       .pop('dialog');
    //   return Flushbar(
    //     message:
    //         'Unauthorized User or User not found. Please check your credentials',
    //     icon: Icon(
    //       Icons.info_outline,
    //       size: 28.0,
    //       color: Colors.blue[300],
    //     ),
    //     duration: const Duration(milliseconds: 3000),
    //     leftBarIndicatorColor: Colors.blue[300],
    //   )..show(_scaffoldKey.currentContext!);
    // }

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailT, password: password.text.trim());
      Navigator.of(_scaffoldKey.currentContext!, rootNavigator: true)
          .pop('dialog');

      Navigator.pushAndRemoveUntil(
        _scaffoldKey.currentContext!,
        MaterialPageRoute(builder: (context) => const HomePage()),
        (Route<dynamic> route) => false,
      );
    } on FirebaseAuthException catch (e) {
      Navigator.of(_scaffoldKey.currentContext!, rootNavigator: true)
          .pop('dialog');
      if (e.code == 'user-not-found') {
        return Flushbar(
          message: 'User not found. Please check your credentials',
          icon: Icon(
            Icons.info_outline,
            size: 28.0,
            color: Colors.blue[300],
          ),
          duration: const Duration(milliseconds: 3000),
          leftBarIndicatorColor: Colors.blue[300],
        )..show(_scaffoldKey.currentContext!);
      } else if (e.code == 'wrong-password') {
        return Flushbar(
          message: 'Incorrect email or password. Please check your credentials',
          icon: Icon(
            Icons.info_outline,
            size: 28.0,
            color: Colors.blue[300],
          ),
          duration: const Duration(milliseconds: 3000),
          leftBarIndicatorColor: Colors.blue[300],
        )..show(_scaffoldKey.currentContext!);
      }
    }
  }
}
