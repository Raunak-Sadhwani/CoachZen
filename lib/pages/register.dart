import 'package:another_flushbar/flushbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:flutter/gestures.dart';
import 'get_start.dart';
import 'home.dart';
import 'login.dart';
import 'package:auto_size_text/auto_size_text.dart';

extension EmailValidator on String {
  bool isValidEmail() {
    return RegExp(
            r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$')
        .hasMatch(this);
  }
}

class Register extends StatefulWidget {
  const Register({Key? key}) : super(key: key);

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final name = TextEditingController();
  final phone = TextEditingController();
  var cphone = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final Color? _color = Colors.grey[100];
  bool _obscureText = true;
  final _formKey = GlobalKey<FormState>();
  bool _autoValidate = false;

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height * .04;
    return Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.blue,
        body: Center(
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
                    color: Colors.white,
                    fontSize: 45,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(40),
                  topLeft: Radius.circular(40),
                ),
              ),
              width: MediaQuery.of(context).size.width,
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 12),
                child: Column(
                  children: [
                    Text(
                      'Sign Up',
                      style: GoogleFonts.notoSans(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                        fontSize: 32,
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.01,
                    ),
                    const Text(
                        'Please fill the details to continue using our app',
                        style: TextStyle(color: Colors.grey)),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.05,
                    ),
                    Form(
                      key: _formKey,
                      autovalidateMode: _autoValidate
                          ? AutovalidateMode.always
                          : AutovalidateMode.disabled,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: name,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter name';
                              } else if (value.length < 3 ||
                                  !value.contains(RegExp(
                                      r'^((\b[a-zA-Z]{2,40}\b)\s*){2,3}$'))) {
                                return 'Please enter a valid full name';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              // contentPadding: 20,
                              prefixIcon: const Padding(
                                padding: EdgeInsets.only(left: 10.0),
                                child: Icon(
                                  Icons.person,
                                  size: 18,
                                ),
                              ),
                              labelText: "   Your Full Name",
                              labelStyle: const TextStyle(
                                color: Colors.grey,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25.0),
                                borderSide: const BorderSide(
                                  color: Colors.blue,
                                  width: 1.65,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25.0),
                                borderSide: const BorderSide(
                                  color: Colors.red,
                                  width: 1.65,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25.0),
                                borderSide: const BorderSide(
                                  color: Colors.blue,
                                  width: 1.65,
                                ),
                              ),
                              filled: true,
                              fillColor: _color,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25.0),
                                borderSide: const BorderSide(
                                  color: Colors.white,
                                  width: 0,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: height),
                          IntlPhoneField(
                            autovalidateMode: _autoValidate
                                ? AutovalidateMode.always
                                : AutovalidateMode.disabled,
                            controller: phone,
                            decoration: InputDecoration(
                              counter: const Offstage(),
                              prefixIcon: const Padding(
                                padding: EdgeInsets.only(left: 10.0),
                                child: Icon(
                                  Icons.person,
                                  size: 18,
                                ),
                              ),
                              labelText: "   Your Phone",
                              labelStyle: const TextStyle(
                                color: Colors.grey,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25.0),
                                borderSide: const BorderSide(
                                  color: Colors.blue,
                                  width: 1.65,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25.0),
                                borderSide: const BorderSide(
                                  color: Colors.red,
                                  width: 1.65,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25.0),
                                borderSide: const BorderSide(
                                  color: Colors.blue,
                                  width: 1.65,
                                ),
                              ),
                              filled: true,
                              fillColor: _color,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25.0),
                                borderSide: const BorderSide(
                                  color: Colors.white,
                                  width: 1.65,
                                ),
                              ),
                            ),
                            initialCountryCode: 'IN',
                          ),
                          SizedBox(height: height - 5),
                          TextFormField(
                            controller: email,
                            validator: (email) =>
                                email!.isValidEmail() ? null : "Invalid email",
                            decoration: InputDecoration(
                              prefixIcon: const Padding(
                                padding: EdgeInsets.only(left: 10.0),
                                child: Icon(
                                  Icons.email,
                                  size: 18,
                                ),
                              ),
                              labelText: "   Your Email",
                              labelStyle: const TextStyle(
                                color: Colors.grey,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25.0),
                                borderSide: const BorderSide(
                                  color: Colors.blue,
                                  width: 1.65,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25.0),
                                borderSide: const BorderSide(
                                  color: Colors.red,
                                  width: 1.65,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25.0),
                                borderSide: const BorderSide(
                                  color: Colors.blue,
                                  width: 1.65,
                                ),
                              ),
                              filled: true,
                              fillColor: _color,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25.0),
                                borderSide: const BorderSide(
                                  color: Colors.white,
                                  width: 1.65,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: height),
                          TextFormField(
                            controller: password,
                            validator: (password) => password != null &&
                                    password.length < 6
                                ? "Password Should Have Atleast 6 Characters"
                                : null,
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
                                  padding: const EdgeInsets.only(right: 10.0),
                                  child: Icon(
                                    _obscureText
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    size: 18,
                                  ),
                                ),
                              ),
                              labelText: "   Enter Password",
                              labelStyle: const TextStyle(
                                color: Colors.grey,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25.0),
                                borderSide: const BorderSide(
                                  color: Colors.blue,
                                  width: 1.65,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25.0),
                                borderSide: const BorderSide(
                                  color: Colors.red,
                                  width: 1.65,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25.0),
                                borderSide: const BorderSide(
                                  color: Colors.blue,
                                  width: 1.65,
                                ),
                              ),
                              filled: true,
                              fillColor: _color,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25.0),
                                borderSide: const BorderSide(
                                  color: Colors.white,
                                  width: 1.65,
                                ),
                              ),
                            ),
                            obscureText: _obscureText,
                          ),
                          const SizedBox(
                            height: 30,
                          ),
                          Center(
                            child: Column(
                              children: [
                                ElevatedButton(
                                  onPressed: signUp,
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(50),
                                    backgroundColor: Colors.blue,
                                    padding: EdgeInsets.symmetric(
                                      vertical:
                                          MediaQuery.of(context).size.height *
                                              0.02,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(40),
                                    ),
                                    textStyle: GoogleFonts.montserrat(
                                      color: Colors.black,
                                      fontSize: 20,
                                    ),
                                  ),
                                  child: const Text('Sign Up'),
                                ),
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.02,
                                ),
                                RichText(
                                    text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Already have an account? ',
                                      style: GoogleFonts.notoSans(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                    TextSpan(
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    const LoginPage())),
                                      text: 'Log In',
                                      style: GoogleFonts.notoSans(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                )),
                                Container(
                                  height: MediaQuery.of(context).size.height *
                                      0.032,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ])));
  }

  Future signUp() async {
    setState(() {
      _autoValidate = true;
    });
    final isValform = _formKey.currentState?.validate();
    if (!isValform!) return;
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      return Flushbar(
        margin: const EdgeInsets.all(7),
        borderRadius: BorderRadius.circular(15),
        flushbarStyle: FlushbarStyle.FLOATING,
        message: 'No Internet Connection, Register Failed',
        icon: Icon(
          Icons.wifi_off,
          size: 28.0,
          color: Colors.blue[300],
        ),
        duration: const Duration(milliseconds: 1500),
        leftBarIndicatorColor: Colors.blue[300],
      )..show(scaffoldKey.currentContext!);
    }
    var emailT = email.text.trim();
    List lists = [];
    await FirebaseFirestore.instance
        .collection('Users')
        .get()
        .then((QuerySnapshot? snapshot) {
      for (var doc in snapshot!.docs) {
        lists.add(doc.data());
      }
    });
    if ((lists.any((element) =>
            (element['email'] == emailT) ||
            (element['phone'] == phone.text.trim()))) ==
        true) {
      return Flushbar(
        message: 'Unauthorized User',
        icon: Icon(
          Icons.person_add_disabled,
          size: 28.0,
          color: Colors.blue[300],
        ),
        duration: const Duration(milliseconds: 1500),
        leftBarIndicatorColor: Colors.blue[300],
      )..show(scaffoldKey.currentContext!);
    }
    if (phone.text.isNotEmpty) {
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .where('phone', isEqualTo: phone.text.trim())
          .get();

      QuerySnapshot coachSnapshot = await FirebaseFirestore.instance
          .collection('Coaches')
          .where('phone', isEqualTo: phone.text.trim())
          .get();
      if (userSnapshot.docs.isNotEmpty || coachSnapshot.docs.isNotEmpty) {
        return Flushbar(
          margin: const EdgeInsets.all(7),
          borderRadius: BorderRadius.circular(15),
          flushbarStyle: FlushbarStyle.FLOATING,
          flushbarPosition: FlushbarPosition.BOTTOM,
          message: "User with this phone number already exists!",
          icon: Icon(
            Icons.error_outline,
            size: 28.0,
            color: Colors.red[300],
          ),
          duration: const Duration(milliseconds: 4000),
          leftBarIndicatorColor: Colors.red[300],
        ).show(scaffoldKey.currentContext!);
      }
    }
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
              child: CircularProgressIndicator(),
            ));
    try {
      await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: emailT, password: password.text.trim())
          .then((user) async {
        User? user = FirebaseAuth.instance.currentUser;
        // updateDisplayName
        await user?.updateDisplayName(name.text.trim());
        FieldValue serverTimestamp = FieldValue.serverTimestamp();
        // update phoneNumber
        await FirebaseFirestore.instance
            .collection('Coaches')
            .doc(user!.uid)
            .set({
          'name': name.text.trim(),
          'phone': phone.text.trim(),
          'email': email.text.trim(),
          'created': serverTimestamp,
        });
        Navigator.of(context, rootNavigator: true).pop('dialog');
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
          (Route<dynamic> route) => false,
        );
      });
    } on FirebaseAuthException catch (e) {
      Navigator.of(context, rootNavigator: true).pop('dialog');
      return Flushbar(
        message: '${e.message}',
        icon: Icon(
          Icons.info_outline,
          size: 28.0,
          color: Colors.blue[300],
        ),
        duration: const Duration(milliseconds: 1500),
        leftBarIndicatorColor: Colors.blue[300],
      )..show(scaffoldKey.currentContext!);
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}
