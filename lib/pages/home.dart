import 'dart:convert';
import 'dart:io';
import 'package:auto_size_text/auto_size_text.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coach_zen/pages/daily_attendance.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:coach_zen/pages/body_form.dart';
import 'package:coach_zen/pages/body_form_list.dart';
import 'package:coach_zen/pages/cust_new_form.dart';
import 'package:coach_zen/pages/profile.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../components/ui/appbar.dart';
import 'login.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool correctVersion = true;
  bool internet = true;
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final screenHeight = WidgetsBinding
      .instance.platformDispatcher.views.first.physicalSize.height;
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
      FirebaseAuth.instance.authStateChanges().listen((User? user) async {
        if (user == null) {
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
              (Route<dynamic> route) => false);
          return;
        }
        await getVersion();
        if (correctVersion) {
          requestNotificationPermission();
          updateText();
        }
      });
    }
  }

  Future<void> requestNotificationPermission() async {
    if (!await Permission.storage.isGranted) {
      await Permission.storage.request();
    }

    if (!await Permission.notification.isGranted) {
      await Permission.notification.request();
      // await NotificationManager().initNotification();
      await Future.delayed(const Duration(milliseconds: 2000));
      if (!await Permission.notification.isGranted) {
        await openAppSettingsAndNavigateToPermissions();
      } else {
        fetchUserPlans();
      }
    } else {
      fetchUserPlans();
    }
  }

  User? user = FirebaseAuth.instance.currentUser;

  Future<void> getVersion() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final String version = packageInfo.version;

    // get 'version' node from firebase
    final DatabaseReference db = FirebaseDatabase.instance.ref();
    await db.child('Version').once().then((DatabaseEvent event) {
      final String fVerision = event.snapshot.value.toString();
      if (fVerision != version) {
        setState(() {
          correctVersion = false;
        });
        showDialog(
          barrierDismissible: false,
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Update Available'),
            content: const Text(
                'A new version of the app is available. Please update to continue using the app.'),
            actions: [
              TextButton(
                onPressed: () async {
                  // final Uri uri = Uri.parse(
                  //     'https://play.google.com/store/apps/details?id=com.coach_zen');

                  // if (await canLaunchUrl(uri)) {
                  //   await launchUrl(uri);
                  // } else {
                  showDialog(
                    barrierDismissible: false,
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Error'),
                      content: const Text(
                          'Could not open the link. Please update the app manually from the Play Store.'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                  // }
                },
                child: const Text('Update'),
              ),
            ],
          ),
        );
      }
    });
    await db
        .child('Coaches')
        .child(user!.uid)
        .child('password')
        .once()
        .then((DatabaseEvent event) {
      final bool isPassword = event.snapshot.value != null;
      if (isPassword) {
        // save preference
        SharedPreferences.getInstance().then((prefs) {
          prefs.setBool('isPassword', true);
        });
      } else {
        SharedPreferences.getInstance().then((prefs) {
          prefs.setBool('isPassword', false);
        });
      }
    });
  }

  Future<void> openAppSettingsAndNavigateToPermissions() async {
    await showDialog(
        context: context,
        barrierDismissible:
            false, // set to false to make dialog non-dismissable
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Notification Permission'),
            content: const Text(
                'Please allow notification permission to get notified about your plans.'),
            actions: [
              TextButton(
                  onPressed: () async {
                    await openAppSettings();
                    Navigator.pop(scaffoldKey.currentContext!);
                    fetchUserPlans();
                  },
                  child: const Text('Open Settings'))
            ],
          );
        });
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

  String capitalize(String value) {
    return value
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  void fetchUserPlans() async {
    if (!await Method.checkInternetConnection(context)) {
      return;
    }

    // await NotificationManager().scheduleAllNotifications();
    // await NotificationManager()
    //     .getPendingNotifications()
    //     .then(
    //       (value) => value.forEach((element) {
    //         print(element.id);
    //         print(element.payload);
    //       }),
    //     )
    //     .catchError((e) {
    //   print(e);
    // });

    Map<String, dynamic> remindUsers = {};
    // get from shared preferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? reminderListJSON = prefs.getString('reminderList');
    if (reminderListJSON != null) {
      remindUsers = jsonDecode(reminderListJSON);
    }

    // show dialog if there are users to remind
    if (remindUsers.isNotEmpty) {
      Color getColorFromString(String colorName) {
        Map<String, Color> colorMap = {
          'red': Colors.red,
          'orange': Colors.orange,
        };

        return colorMap[colorName.toLowerCase()] ??
            Colors.grey; // Default to grey if color not found
      }

      showDialog(
        context: scaffoldKey.currentContext!,
        builder: (context) => AlertDialog(
          // remove all padding
          contentPadding: EdgeInsets.zero,
          // dialog width to 95% of screen
          insetPadding: EdgeInsets.zero,
          title: Text(
            'Plan Ending',
            style: GoogleFonts.montserrat(),
          ),
          content: Padding(
            padding: EdgeInsets.only(
              top: screenHeight * 0.02,
            ),
            child: SizedBox(
              height: screenHeight * 0.175,
              width: MediaQuery.of(context).size.width * 0.9,
              child: ListView.builder(
                itemCount: remindUsers.length,
                physics: const BouncingScrollPhysics(),
                // shrinkWrap: true,
                itemBuilder: (context, index) {
                  double width = MediaQuery.of(context).size.width;
                  final String uid = remindUsers.keys.elementAt(index);
                  final values = remindUsers[uid];
                  final String phone = values['phone'];
                  final name = values['name'];
                  final planName = values['planName'];
                  final planStatus = values['planStatus'];
                  final image = values['image'];
                  final gender = values['gender'];

                  final String planColor = values['planColor'];
                  // convert string to color
                  final Color color = getColorFromString(planColor);
                  return Slidable(
                    startActionPane: ActionPane(
                      motion: const BehindMotion(),
                      // key: const ValueKey(2),
                      children: [
                        SlidableAction(
                          backgroundColor: const Color(0xFF0392CF),
                          foregroundColor: Colors.white,
                          icon: Icons.phone,
                          // label: 'Call',
                          onPressed: (context) async {
                            Future<void> makePhoneCall(
                                String phoneNumber) async {
                              final Uri launchUri = Uri(
                                scheme: 'tel',
                                path: phoneNumber,
                              );
                              await launchUrl(launchUri);
                            }

                            // call
                            await makePhoneCall(phone);
                          },
                        ),
                        SlidableAction(
                          backgroundColor: const Color(0xFF7BC043),
                          foregroundColor: Colors.white,
                          // whatsapp
                          icon: FontAwesomeIcons.whatsapp,
                          // label: 'WhatsApp',
                          onPressed: (context) {
                            Future<void> launchWhatsApp({
                              required String phone,
                              String? message,
                            }) async {
                              String url() {
                                if (message != null) {
                                  return "whatsapp://send?phone=$phone&text=${Uri.parse(message)}";
                                } else {
                                  return "whatsapp://send?phone=$phone";
                                }
                              }

                              final Uri uri = Uri.parse(url());

                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri);
                              } else {
                                await launchUrl(Uri.parse(
                                    "https://play.google.com/store/apps/details?id=com.whatsapp"));
                              }
                            }

                            // whatsapp
                            launchWhatsApp(phone: phone);
                          },
                        ),
                      ],
                    ),
                    // remove
                    // remove
                    child: Container(
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Color.fromARGB(52, 158, 158, 158),
                              width: .8,
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(width * 0.04),
                          child: Row(
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: width * 0.13,
                                    height: width * 0.13,
                                    child: ClipOval(
                                      child: image != null && image.isNotEmpty
                                          ? FadeInImage.assetNetwork(
                                              fit: BoxFit.cover,
                                              placeholder:
                                                  'lib/assets/$gender.png',
                                              image: image,
                                            )
                                          : Image.asset(
                                              'lib/assets/$gender.png',
                                              fit: BoxFit.cover,
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(width: width * 0.03),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: GoogleFonts.raleway(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      phone,
                                      style: GoogleFonts.montserrat(
                                          color: Colors.grey,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13),
                                    ),
                                    Text(
                                      "Plan: $planName",
                                      style: GoogleFonts.montserrat(
                                          color: Colors.grey,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: width * 0.175,
                                child: Wrap(
                                  alignment: WrapAlignment.end,
                                  textDirection: TextDirection.rtl,
                                  crossAxisAlignment: WrapCrossAlignment.end,
                                  runAlignment: WrapAlignment.end,
                                  children: [
                                    AutoSizeText(
                                      planStatus,
                                      maxLines: 2,
                                      minFontSize: 10,
                                      maxFontSize: 13,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.montserrat(
                                          color: color,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )),
                  );

                  // ListTile(
                  //   title: Text(remindUsers[index]['name']),
                  //   subtitle: Text(
                  //     'Remaining Days: ${remindUsers[index]['remainingDays']}',
                  //   ),
                  //   trailing: IconButton(
                  //     onPressed: () async {
                  //       await FirebaseFirestore.instance
                  //           .collection('Users')
                  //           .doc(remindUsers[index]['uid'])
                  //           .update({
                  //         'plans': FieldValue.arrayRemove([
                  //           {
                  //             'name': remindUsers[index]['plan'],
                  //             'started': DateTime.now(),
                  //             'days': 30,
                  //           }
                  //         ])
                  //       });
                  //       Navigator.pop(scaffoldKey.currentContext!);
                  //     },
                  //     icon: const Icon(Icons.check),
                  //   ),
                  // );
                },
              ),
            ),
          ),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    checkInternetAndAuth();
  }

  // get userdata from firestore

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
    } else if (!correctVersion) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Colors.white,
      // backgroundColor: const Color.fromARGB(255, 83, 98, 210),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            left: width * 0.035,
            right: width * 0.035,
            bottom: height * 0.02,
            top: height * 0.07,
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfilePg(),
                        ),
                      );
                    },
                    child: Container(
                        width: width * 0.175,
                        height: width * 0.175,
                        margin: EdgeInsets.only(
                            bottom: width * 0.06, right: width * 0.032),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: user!.photoURL != null &&
                                  user!.photoURL!.isNotEmpty
                              ? FadeInImage(
                                  placeholder: const AssetImage(
                                      // 'lib/assets/${coachData["gender"]}.png'),
                                      'lib/assets/male.png'),
                                  image: NetworkImage(user!.photoURL!),
                                  fit: BoxFit
                                      .cover, // Adjust the fit as per your requirement
                                )
                              : Image.asset(
                                  fit: BoxFit.cover,
                                  'lib/assets/male.png',
                                ),
                        )),
                  )
                ],
              ),
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
                            text: capitalize(user!.displayName!.split(' ')[0]),
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
                      page: const DailyAttendance(),
                      openColor: Colors.yellow.shade800,
                      label1: 'Daily',
                      label2: 'Attendance'),
                  // HomeButton(
                  //     height: height,
                  //     width: width,
                  //     imgPath: 'lib/assets/meas.jpg',
                  //     page: const FormPage(),
                  //     openColor: Colors.yellow.shade800,
                  //     label1: 'Customer',
                  //     label2: 'Check-up'),
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
                      page: const NewCustWrapper(),
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

class NewCustWrapper extends StatefulWidget {
  final bool? attendance;
  final DateTime? created;

  const NewCustWrapper({
    Key? key,
    this.created,
    this.attendance,
  }) : super(key: key);

  @override
  State<NewCustWrapper> createState() => _NewCustWrapperState();
}

class _NewCustWrapperState extends State<NewCustWrapper> {
  @override
  void initState() {
    super.initState();
    if (widget.attendance != null) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  @override
  void dispose() {
    if (widget.attendance != null) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: MyAppBar(
        // avatar
        leftIcon: Container(
          margin: const EdgeInsets.only(left: 10),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            color: Colors.black26,
            onPressed: () async {
              Navigator.pop(context);
            },
          ),
        ),
        title: 'Select An Option',
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(width * 0.1),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              HomeButton(
                  height: height,
                  width: width,
                  imgPath: 'lib/assets/meas.jpg',
                  page: const FormPage(),
                  openColor: Colors.yellow.shade800,
                  label1: 'New Body',
                  label2: 'Check-up'),
              HomeButton(
                  height: height,
                  width: width,
                  page: CustNewForm(
                    created: widget.created,
                  ),
                  imgPath: 'lib/assets/new_cust.png',
                  openColor: Colors.green.shade800,
                  label1: 'Simple',
                  label2: 'Details'),
            ],
          ),
        ),
      ),
    );
  }
}
