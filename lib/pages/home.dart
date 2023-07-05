import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:slimtrap/pages/body_form.dart';
import 'package:slimtrap/pages/body_form_list.dart';

import '../components/ui/appbar.dart';
import 'login.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  void checkAuth() async {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (Route<dynamic> route) => false);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    checkAuth();
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: MyAppBar(
          // avatar
          rightIcons: [
            GestureDetector(
              onTap: () {
                debugPrint('Avatar tapped');
              },
              child: Container(
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
                            text: 'Rohit!',
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
                      'Good Morning, welcome back!',
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
                      label1: 'Customer',
                      label2: 'Check-up'),
                  HomeButton(
                      height: height,
                      width: width,
                      imgPath: 'lib/assets/focus.png',
                      page: const BodyFormList(),
                      label1: 'My',
                      label2: 'Customers'),
                  HomeButton(
                      height: height,
                      width: width,
                      page: const FormPage(),
                      imgPath: 'lib/assets/meas.jpg',
                      label1: 'New',
                      label2: 'Customers'),
                  HomeButton(
                      height: height,
                      width: width,
                      page: const BodyFormList(),
                      imgPath: 'lib/assets/focus.png',
                      label1: 'My',
                      label2: 'Customers'),
                ],
              )
            ],
          ),
        ),
      ),
      // floatingActionButton: OpenContainer(
      //   transitionType: ContainerTransitionType.fade,
      //   openBuilder: (BuildContext context, VoidCallback _) {
      //     return const FormPage();
      //   },
      //   closedElevation: 6.0,
      //   closedColor: Theme.of(context).colorScheme.secondary,
      //   closedBuilder: (BuildContext context, VoidCallback openContainer) {
      //     return SizedBox(
      //       height: 30,
      //       width: 30,
      //       child: Center(
      //         child: Icon(
      //           Icons.add,
      //           color: Theme.of(context).colorScheme.onSecondary,
      //         ),
      //       ),
      //     );
      //   },
      // ),
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

  const HomeButton({
    Key? key,
    required this.height,
    required this.width,
    required this.imgPath,
    required this.label1,
    required this.label2,
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
          page: page,
          content: Container(
            width: double.infinity,
            padding: EdgeInsets.only(left: width * 0.08),
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(imgPath),
                fit: BoxFit.cover,
                colorFilter: const ColorFilter.mode(
                  Colors.black38,
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
