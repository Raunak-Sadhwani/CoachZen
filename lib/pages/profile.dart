import 'dart:io';
// import '../ui/app_ui.dart';
// import 'package:angelwellness/pages/login.dart';
import 'package:another_flushbar/flushbar.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../components/ui/appbar.dart';
import 'login.dart';

class ProfilePg extends StatefulWidget {
  final Map<String, dynamic> userData;
  const ProfilePg({Key? key, required this.userData}) : super(key: key);

  @override
  State<ProfilePg> createState() => _ProfilePgState();
}

class _ProfilePgState extends State<ProfilePg> {
  bool _hasInternet = true;

  @override
  void initState() {
    super.initState();
    checkInternetConnection();
  }

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

  String formatDate(DateTime dateTime) {
    DateFormat formatter = DateFormat('dd MMM yyyy - hh:mm a');
    // make date from london timezone to local timezone
    dateTime = dateTime.add(const Duration(hours: 5, minutes: 30));
    final String formatted = formatter.format(dateTime);
    return formatted;
  }

  // CollectionReference<Map<String, dynamic>> coaches =
  //     FirebaseFirestore.instance.collection('Coaches');
  String uImage = FirebaseAuth.instance.currentUser?.photoURL ?? '';
  User? user = FirebaseAuth.instance.currentUser;
  Color backG = const Color.fromARGB(255, 100, 176, 238);
// Colors.lightBlue[300]
  void editImage() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      // ignore: use_build_context_synchronously
      return Flushbar(
        margin: const EdgeInsets.all(7),
        borderRadius: BorderRadius.circular(15),
        flushbarStyle: FlushbarStyle.FLOATING,
        flushbarPosition: FlushbarPosition.TOP,
        message: "No internet connection",
        icon: Icon(
          Icons.wifi_off,
          size: 28.0,
          color: Colors.blue[300],
        ),
        duration: const Duration(milliseconds: 1500),
        leftBarIndicatorColor: Colors.blue[300],
      ).show(context);
    }

    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 512,
      maxHeight: 512,
    );

    if (image != null) {
      Reference ref = FirebaseStorage.instance.ref().child('${user!.uid}.jpg');
      await ref.putFile(File(image.path));
      String url = await ref.getDownloadURL();

      // await coaches.doc(user!.uid).update({
      //   'image': url,
      // });

      await user!.updatePhotoURL(url);

      setState(() {
        uImage = url;
      });
    }
  }

  Widget textfield({required hintText}) {
    return Material(
      elevation: 7,
      shadowColor: Colors.grey,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.mali(
              // letterSpacing: 2,
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
            fillColor: Colors.white30,
            filled: true,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide.none)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasInternet) {
      // Show appropriate UI or display an error message
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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: Colors.cyanAccent,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.logout,
              color: Colors.white,
              // size: 34,
            ),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              // ignore: use_build_context_synchronously
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (Route<dynamic> route) => false,
              );
            },
            padding: const EdgeInsets.only(right: 20),
          ),
        ],
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                height: MediaQuery.of(context).size.height * 0.6,
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    textfield(
                      hintText: user!.displayName ??
                          widget.userData['name'] ??
                          '- - -',
                    ),
                    textfield(
                      hintText: user!.phoneNumber != null &&
                              user!.phoneNumber!.isNotEmpty
                          ? user!.phoneNumber
                          : (widget.userData['phone'].toString().isNotEmpty)
                              ? widget.userData['phone'].toString()
                              : '- - -',
                    ),
                    textfield(
                      hintText:
                          user!.email ?? widget.userData['email'] ?? '- - -',
                    ),
                    textfield(
                      hintText: user!.metadata.creationTime == null
                          ? '- - -'
                          : formatDate(user!.metadata.creationTime!),
                    ),
                  ],
                ),
              )
            ],
          ),
          CustomPaint(
            painter: HeaderCurvedContainer(),
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(2),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.3,
                  height: MediaQuery.of(context).size.width * 0.3,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: (uImage == '' || user!.photoURL == null)
                          ? DecorationImage(
                              image: Image.asset('lib/assets/male.png').image,
                              fit: BoxFit.cover,
                            )
                          : DecorationImage(
                              image: NetworkImage(uImage),
                              fit: BoxFit.cover,
                            ),
                    ),
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: Container(
                        decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(100)),
                        child: SizedBox(
                          height: MediaQuery.of(context).size.width * 0.1,
                          width: MediaQuery.of(context).size.width * 0.1,
                          child: IconButton(
                            icon: const Icon(
                              Icons.edit,
                              size: 19,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              editImage();
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class HeaderCurvedContainer extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // flouroscent orange
    Paint paint = Paint()..color = Colors.cyanAccent;
    Path path = Path()
      ..relativeLineTo(0, 90)
      ..quadraticBezierTo(size.width / 2, 200, size.width, 90)
      ..relativeLineTo(0, -150)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
