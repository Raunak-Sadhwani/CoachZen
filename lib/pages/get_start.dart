import 'login.dart';
import 'register.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:auto_size_text/auto_size_text.dart';

class GetStarted extends StatelessWidget {
  const GetStarted({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Align(
          alignment: Alignment.topCenter,
          child: Column(
            children: [
              Container(
                height: MediaQuery.of(context).size.height * 0.05,
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height * 0.12,
                child: Center(
                  child: AutoSizeText(
                    "CoachUp",
                    style: GoogleFonts.luckiestGuy(
                      color: Colors.blue,
                      fontSize: 45,
                    ),
                  ),
                ),
              ),
              Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height * 0.42,
                padding: const EdgeInsets.only(bottom: 5.0),
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("lib/assets/splash_bg.png"),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Container(
                height: MediaQuery.of(context).size.height * 0.02,
              ),
              SizedBox(
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: MediaQuery.of(context).size.height * 0.3,
                  // padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Welcome',
                        style: GoogleFonts.notoSans(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                          fontSize: 35,
                        ),
                      ),
                      const Text('Create an account to talk with your coach ',
                          style: TextStyle(color: Colors.grey)),
                      Container(
                        height: MediaQuery.of(context).size.height * 0.075,
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const Register()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          backgroundColor: Colors.blue,
                          padding: EdgeInsets.symmetric(
                              horizontal:
                                  MediaQuery.of(context).size.width * 0.25,
                              vertical:
                                  MediaQuery.of(context).size.height * 0.015),
                          textStyle: GoogleFonts.montserrat(
                            color: Colors.black,
                            fontSize: 20,
                          ),
                        ),
                        child: const AutoSizeText(
                          'Get Started',
                          minFontSize: 14,
                          softWrap: false,
                          maxLines: 1,
                        ),
                      ),
                      Container(
                        height: MediaQuery.of(context).size.height * 0.03,
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
                                      builder: (context) => const LoginPage())),
                            text: 'Sign In',
                            style: GoogleFonts.notoSans(
                              color: Colors.blue,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      )),
                    ],
                  ))
            ],
          ),
        ),
      ),
    );
  }
}
