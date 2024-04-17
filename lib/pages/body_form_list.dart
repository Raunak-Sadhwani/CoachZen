import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:another_flushbar/flushbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:coach_zen/pages/body_form_cust.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
// shared preferences
import 'package:shared_preferences/shared_preferences.dart';
import '../components/ui/appbar.dart';
import 'body_form.dart';
import 'cust_order_form.dart';

class BodyFormList extends StatefulWidget {
  const BodyFormList({super.key});

  @override
  State<BodyFormList> createState() => _BodyFormListState();
}

String capitalize(String value) {
  return value
      .split(' ')
      .map((word) => word[0].toUpperCase() + word.substring(1))
      .join(' ');
}

class _BodyFormListState extends State<BodyFormList>
    with SingleTickerProviderStateMixin {
  StreamSubscription? _streamSubscription;
  DateTime? lastRefreshTime;
  late Future<Map<dynamic, dynamic>> userDataFuture;
  late AnimationController controller;
  late Stream mystream;
  bool _hasInternet = true;
  bool _sortAscending = false; // Flag to track the sort order
  bool _showExpiredPlans = true; // Flag to track whether to show expired plans
  bool isSearching = false;
  String searchQuery = '';
  FocusNode searchFocusNode = FocusNode();
  double opacity = 0.0;
  DateFormat formatter = DateFormat('dd MMM yyyy');
  List<MapEntry<dynamic, dynamic>> filteredData = [];
  Map<dynamic, dynamic> reminderList = {};
  Map<dynamic, dynamic> userData = {};
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final double width = (WidgetsBinding
          .instance.platformDispatcher.views.first.physicalSize.width) /
      2.65;
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
        await setupDataListener();
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

  void getFilteredData() {
    debugPrint('getFilteredData');
    final curFilteredData = userData.entries.where((entry) {
      final Map<dynamic, dynamic> userData = entry.value;
      final name = userData['name'].toString().toLowerCase();
      final city = userData['city'].toString().toLowerCase();
      final phone = userData['phone'].toString().toLowerCase();
      final email = userData['email'].toString().toLowerCase();
      final searchLower = searchQuery.toLowerCase();
      return name.contains(searchLower) ||
          city.contains(searchLower) ||
          phone.contains(searchLower) ||
          email.contains(searchLower);
    }).toList();

    curFilteredData.sort((a, b) {
      final dateA = a.value['created'];
      final dateB = b.value['created'];
      final compareResult = dateA.compareTo(dateB);

      return _sortAscending ? compareResult : -compareResult;
    });

    // show only active plans
    // if (!_showExpiredPlans) {
    //   filteredData.removeWhere((doc) {
    //     final plans = doc.value['plans'];
    //     if (plans == null) {
    //       return true;
    //     }
    //     final activePlans = plans.where((plan) {
    //       final daysSinceStarted = DateTime.now()
    //               .difference(
    //                   DateTime.fromMillisecondsSinceEpoch(plan['started']))
    //               .inDays +
    //           1;
    //       return daysSinceStarted <= plan['days'];
    //     }).toList();
    //     return activePlans.isEmpty;
    //   });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        filteredData = curFilteredData;
      });
    });
  }

  Future<void> setupDataListener() async {
    _streamSubscription?.cancel();

    setState(() {
      userData = {};
    });

    final completer = Completer<void>();
    try {
      mystream = FirebaseDatabase.instance
          .ref()
          .child('Coaches')
          .child(FirebaseAuth.instance.currentUser!.uid)
          .child('users')
          .onValue;
      final event = await mystream.first;
      userData = event.snapshot.value as Map<dynamic, dynamic>;
      filteredData = userData.entries.toList();
      getFilteredData();
      if (!completer.isCompleted) {
        completer.complete();
      }
    } catch (e) {
      Flushbar(
        message: 'Error fetching data. Please try again later.',
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(8),
        icon: const Icon(
          Icons.error_outline_rounded,
          size: 20,
          color: Colors.red,
        ),
      ).show(_scaffoldKey.currentContext!);
      if (!completer.isCompleted) {
        completer.complete();
      }
    }
    await completer.future;
  }

  @override
  void initState() {
    super.initState();
    checkInternetConnection();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    searchFocusNode.dispose();
    _streamSubscription?.cancel();
    super.dispose();
  }

  TextStyle selStyle = GoogleFonts.montserrat(
      color: Colors.black, fontWeight: FontWeight.w500, fontSize: 16);
  TextStyle unSelStyle = GoogleFonts.montserrat(
      color: Colors.grey, fontWeight: FontWeight.w500, fontSize: 14);

  void _openBottomDrawer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return IntrinsicHeight(
          child: Drawer(
            child: Column(
              children: [
                if (_showExpiredPlans)
                  _buildDrawerHeader('Sort by Created Date')
                else
                  _buildDrawerHeader('Sort by Remaining Days'),
                _buildDrawerItem(Icons.arrow_upward, 'Ascending',
                    _sortAscending, true, () => _updateSortOrder(true, context),
                    color: Colors.blue),
                _buildDrawerItem(
                    Icons.arrow_downward,
                    'Descending',
                    !_sortAscending,
                    false,
                    () => _updateSortOrder(false, context),
                    color: Colors.red),
                const Divider(),
                _buildDrawerHeader('Plans'),
                _buildDrawerItem(
                    Icons.verified,
                    'Active Plans',
                    !_showExpiredPlans,
                    false,
                    () => _updatePlanStatus(false, context),
                    color: Colors.blue),
                _buildDrawerItem(
                    Icons.all_inclusive,
                    'All Plans',
                    _showExpiredPlans,
                    true,
                    () => _updatePlanStatus(true, context),
                    color: Colors.blueGrey),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawerHeader(String title) {
    return ListTile(
      title: Text(
        title,
        style: GoogleFonts.raleway(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, bool isSelected,
      bool isAscending, VoidCallback onTap,
      {Color? color}) {
    return ListTile(
      leading: Icon(icon,
          color: isSelected
              ? (color ?? const Color.fromARGB(148, 0, 0, 0))
              : Colors.grey,
          size: isSelected ? 26 : 22),
      title: Text(title, style: isSelected ? selStyle : unSelStyle),
      trailing: isSelected
          ? const Icon(Icons.check, color: Colors.green, size: 26)
          : const SizedBox.shrink(),
      onTap: onTap,
    );
  }

  void _updateSortOrder(bool ascending, BuildContext context) {
    setState(() {
      _sortAscending = ascending;
    });
    getFilteredData();
    Navigator.pop(context);
  }

  void _updatePlanStatus(bool showExpired, BuildContext context) {
    setState(() {
      _showExpiredPlans = showExpired;
    });
    getFilteredData();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // double height = MediaQuery.of(context).size.height;
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
      key: _scaffoldKey,
      appBar: MyAppBar(
        leftIcon: Container(
          margin: const EdgeInsets.only(left: 10),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            color: Colors.black26,
            onPressed: () {
              if (!isSearching) {
                Navigator.pop(context);
              } else {
                setState(() {
                  isSearching = false;
                  searchQuery = '';
                });
              }
            },
          ),
        ),
        ftitle: isSearching
            ? AnimatedOpacity(
                opacity: opacity,
                duration: const Duration(milliseconds: 1000),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Name, City, Phone, Email',
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value.toLowerCase();
                    });
                    getFilteredData();
                  },
                  focusNode: searchFocusNode,
                ),
              )
            : const Text(
                'My Customers',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
        rightIcons: [
          Container(
            margin: isSearching ? EdgeInsets.only(right: width * 0.04) : null,
            width: width * 0.085,
            child: IconButton(
              splashRadius: 30,
              icon: !isSearching
                  ? const Icon(Icons.search_rounded)
                  : const Icon(Icons.close_rounded),
              color: Colors.black26,
              onPressed: () {
                setState(() {
                  isSearching = !isSearching;
                  opacity = 1.0;

                  if (isSearching) {
                    // set interval to wait for animation to complete

                    return searchFocusNode.requestFocus();
                  }
                  searchQuery = '';
                  opacity = 0.0;
                });
              },
            ),
          ),
          if (!isSearching)
            SizedBox(
              child: IconButton(
                splashRadius: 25,
                icon: const Icon(Icons.sort_rounded),
                color: Colors.black26,
                onPressed: () =>
                    _openBottomDrawer(_scaffoldKey.currentContext!),
              ),
            ),
        ],
      ),
      body: filteredData.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.person_add_disabled_rounded,
                    size: 50,
                    color: Colors.black26,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'No Customers Found',
                    style: GoogleFonts.raleway(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: filteredData.length,
              itemBuilder: (context, index) {
                // final userInfo = _filteredData[index].data();
                final userInfo = filteredData[index].value;
                final phone = "+91${userInfo['phone']}";
                final DateTime timeStamp =
                    DateTime.fromMillisecondsSinceEpoch(userInfo['created']);
                // final timeStamp = userInfo['created'].toDate();
                final time = DateFormat('h:mm a').format(timeStamp);
                final name = userInfo['name'];
                DateTime selectedDate =
                    DateTime.fromMillisecondsSinceEpoch(userInfo['dob']);
                DateTime currentDate = DateTime.now();
                int age = currentDate.year - selectedDate.year;
                if (currentDate.month < selectedDate.month ||
                    (currentDate.month == selectedDate.month &&
                        currentDate.day < selectedDate.day)) {
                  age--;
                }
                if (userInfo['measurements'] != null) {
                  userInfo['measurements'] = List<Map<dynamic, dynamic>>.from(
                      userInfo['measurements']);
                } else {
                  userInfo['measurements'] =
                      List<Map<dynamic, dynamic>>.from([])
                          .cast<Map<dynamic, dynamic>>();
                }

                // List<Map<dynamic, dynamic>> plans = [];
                String planName = '';
                String planStatus = '';
                Color planColor = Colors.grey;
                String? image = userInfo['image'];
                final String uid = filteredData[index].key;
                String gender = userInfo['gender'];

                final int userDays = userInfo['days'].keys.length;

                if (userInfo['existed'] != null) {
                  planName = 'Not Started';
                  planStatus = 'No Plans';
                  planColor = Colors.red;
                }

                if (userInfo['plans'] != null) {
                  bool existingPlan = false;
                  int tempAllPlanDays = 4;
                  List sortAllKeys = userInfo['plans'].keys.toList();
                  sortAllKeys.sort((a, b) => a.compareTo(b));
                  // final allDaysMap = user['days'];
                  // check if today's date comes in between any plan
                  for (String key in sortAllKeys) {
                    final plan = userInfo['plans'][key];
                    planName = plan['program'];
                    // final planDate = DateTime.parse(key);
                    final int planDays = plan['days'] as int;
                    tempAllPlanDays += planDays;
                    // debugPrint('Existing Plan: $existingPlan');
                    if (userDays <= tempAllPlanDays) {
                      existingPlan = true;
                      final int daysLeft = tempAllPlanDays - userDays;
                      planStatus = daysLeft > 0
                          ? '$daysLeft days left'
                          : 'Expires today';
                      if (daysLeft > 7) {
                        planColor = Colors.green;
                      } else {
                        planColor = Colors.orange;
                        reminderList[uid] = {
                          'name': name,
                          'phone': phone,
                          'planName': planName,
                          'planColor': 'orange',
                          'planStatus': planStatus,
                          'gender': gender,
                          'image': image,
                        };
                      }
                      break;
                    }
                  }
                  if (!existingPlan) {
                    planStatus = 'Expired';
                    planColor = Colors.red;
                    reminderList[uid] = {
                      'name': name,
                      'phone': phone,
                      'planName': planName,
                      'planColor': 'red',
                      'planStatus': planStatus,
                      'gender': gender,
                      'image': image,
                    };
                  }
                }
                debugPrint('reminderList: $reminderList');
                // if last index save reminderList to shared preferences
                if (index == filteredData.length - 1) {
                  SharedPreferences.getInstance().then((prefs) {
                    final reminderListJSON = jsonEncode(reminderList);
                    prefs.setString('reminderList', reminderListJSON);
                  });
                }

                return Slidable(
                  startActionPane: ActionPane(
                    motion: const BehindMotion(),
                    // key: const ValueKey(2),
                    children: [
                      SlidableAction(
                        backgroundColor: const Color(0xFF0392CF),
                        foregroundColor: Colors.white,
                        icon: Icons.phone,
                        label: 'Call',
                        onPressed: (context) async {
                          Future<void> makePhoneCall(String phoneNumber) async {
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
                        label: 'WhatsApp',
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
                  endActionPane: ActionPane(
                    motion: const BehindMotion(),
                    // key: const ValueKey(1),
                    children: [
                      SlidableAction(
                        backgroundColor: const Color.fromARGB(255, 125, 3, 207),
                        foregroundColor: Colors.white,
                        icon: Icons.add,
                        label: 'Check-up',
                        onPressed: (context) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FormPageWrapper(
                                uid: uid,
                                age: age.toString(),
                                measurements: userInfo['measurements'],
                                heightx:
                                    double.parse(userInfo['height'].toString()),
                                popIndex: 2,
                                gender: gender == 'male',
                                name: name,
                              ),
                            ),
                          );
                        },
                      ),
                      SlidableAction(
                        backgroundColor:
                            const Color.fromARGB(255, 244, 155, 54),
                        foregroundColor: Colors.black,
                        icon: Icons.add,
                        label: 'Order',
                        onPressed: (context) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CustOrderForm(
                                uid: uid,
                                name: name,
                                popIndex: 2,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  child: OpenContainerWrapper(
                    page: BodyFormCustomerWrap(
                        uid: uid,
                        callback: () => handleRefresh(fromPage: true)),
                    content: Container(
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
                                      "+91 ${phone.substring(3)}",
                                      style: GoogleFonts.montserrat(
                                          color: Colors.grey,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13),
                                    ),
                                    if (planName.isNotEmpty)
                                      Text(
                                        capitalize("Plan: $planName".trim()),
                                        style: GoogleFonts.montserrat(
                                            color: Colors.grey,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 13),
                                      ),
                                  ],
                                ),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    formatter.format(
                                      timeStamp,
                                    ),
                                    style: GoogleFonts.montserrat(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12.5),
                                  ),
                                  Text(
                                    time,
                                    style: GoogleFonts.montserrat(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12),
                                  ),
                                  if (planName.isNotEmpty)
                                    Text(
                                      planStatus,
                                      style: GoogleFonts.montserrat(
                                          color: planColor,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        )),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: handleRefresh,
        tooltip: 'Refresh',
        child: RotationTransition(
            turns: Tween(begin: 0.0, end: 3.0).animate(controller),
            child: const Icon(Icons.refresh_rounded, color: Colors.white)),
      ),
    );
  }

  void handleRefresh({bool? fromPage}) async {
    final bool fromPagex = fromPage ?? false;
    if (fromPagex ||
        (lastRefreshTime == null ||
            DateTime.now().difference(lastRefreshTime!).inSeconds > 30)) {
      controller.reset();
      await setupDataListener();
      lastRefreshTime = DateTime.now();
      controller.forward(from: 0.0);
    } else {
      final secondsLeft =
          30 - DateTime.now().difference(lastRefreshTime!).inSeconds;
      Flushbar(
        message:
            'Please wait for $secondsLeft seconds before refreshing again.',
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(8),
        icon: const Icon(
          Icons.error_outline_rounded,
          size: 20,
          color: Colors.red,
        ),
      ).show(_scaffoldKey.currentContext!);
    }
  }
}
