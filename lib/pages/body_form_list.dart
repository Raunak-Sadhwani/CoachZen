import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:slimtrap/pages/body_form_cust.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../components/ui/appbar.dart';
import 'body_form.dart';
import 'cust_order_form.dart';

class BodyFormList extends StatefulWidget {
  const BodyFormList({super.key});

  @override
  State<BodyFormList> createState() => _BodyFormListState();
}

class _BodyFormListState extends State<BodyFormList> {
  bool _hasInternet = true;
  bool _sortAscending = false; // Flag to track the sort order
  bool _showExpiredPlans = true; // Flag to track whether to show expired plans
  bool isSearching = false;
  String searchQuery = '';
  FocusNode searchFocusNode = FocusNode();
  double opacity = 0.0;
  DateFormat formatter = DateFormat('dd MMM yyyy');
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filteredData = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
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
  void initState() {
    super.initState();
    checkInternetConnection();
  }

  @override
  void dispose() {
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
                  _buildDrawerHeader('Sort by Created Date'),
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
    Navigator.pop(context);
  }

  void _updatePlanStatus(bool showExpired, BuildContext context) {
    setState(() {
      _showExpiredPlans = showExpired;
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
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
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection("Users")
              .where('cid', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
              final filteredData = snapshot.data!.docs.where((doc) {
                final name = doc.data()['name'].toString().toLowerCase();
                final city = doc.data()['city'].toString().toLowerCase();
                final phone = doc.data()['phone'].toString().toLowerCase();
                final email = doc.data()['email'].toString().toLowerCase();
                final searchLower = searchQuery.toLowerCase();
                return name.contains(searchLower) ||
                    city.contains(searchLower) ||
                    phone.contains(searchLower) ||
                    email.contains(searchLower);
              }).toList();

              // filteredData.sort((a, b) {
              //   final dateA = a.data()['created'];
              //   final dateB = b.data()['created'];
              //   return dateB
              //       .toDate()
              //       .compareTo(dateA.toDate()); // Compare in reverse order
              // });

              filteredData.sort((a, b) {
                final dateA = a.data()['created'];
                final dateB = b.data()['created'];
                final compareResult = dateA
                    .toDate()
                    .compareTo(dateB.toDate()); // Compare in ascending order

                return _sortAscending ? compareResult : -compareResult;
              });

              // show only active plans
              if (!_showExpiredPlans) {
                filteredData.removeWhere((doc) {
                  final plans = doc.data()['plans'];
                  if (plans == null) {
                    return true;
                  }
                  final activePlans = plans.where((plan) {
                    final daysSinceStarted = DateTime.now()
                            .difference(plan['started'].toDate())
                            .inDays +
                        1;
                    return daysSinceStarted <= plan['days'];
                  }).toList();
                  return activePlans.isEmpty;
                });
              }

              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() {
                  _filteredData = filteredData;
                });
              });
              return ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: _filteredData.length,
                itemBuilder: (context, index) {
                  final userInfo = _filteredData[index].data();
                  final phone = "+91${userInfo['phone']}";
                  final timeStamp = userInfo['created'].toDate();
                  final time = DateFormat('h:mm a').format(timeStamp);
                  final name = userInfo['name'];
                  DateTime selectedDate =
                      DateTime.parse(userInfo['dob'].toDate().toString());
                  DateTime currentDate = DateTime.now();
                  int age = currentDate.year - selectedDate.year;
                  if (currentDate.month < selectedDate.month ||
                      (currentDate.month == selectedDate.month &&
                          currentDate.day < selectedDate.day)) {
                    age--;
                  }
                  if (userInfo['measurements'] != null) {
                    userInfo['measurements'] =
                        (userInfo['measurements'] as List)
                            .cast<Map<String, dynamic>>()
                            .toList();
                  } else {
                    userInfo['measurements'] =
                        ([]).cast<Map<String, dynamic>>().toList();
                  }
                  if (userInfo['productsHistory'] != null) {
                    userInfo['productsHistory'] =
                        (userInfo['productsHistory'] as List)
                            .cast<Map<String, dynamic>>()
                            .toList();
                  } else {
                    userInfo['productsHistory'] =
                        ([]).cast<Map<String, dynamic>>().toList();
                  }
                  List<Map<String, dynamic>> plans = [];
                  // Map<String, dynamic> plan = {};
                  String planName = '';
                  String planStatus = '';
                  Color planColor = Colors.grey;

                  if (userInfo['plans'] != null &&
                      userInfo['plans'].isNotEmpty) {
                    plans = List<Map<String, dynamic>>.from(userInfo['plans']);
                    plans.sort((a, b) => b['started'].compareTo(a['started']));
                    Map<String, dynamic> plan = plans[0];
                    planName = plan['name'];
                    final daysSinceStarted = DateTime.now()
                            .difference(plan['started'].toDate())
                            .inDays +
                        1;
                    final daysLeft = plan['days'] - daysSinceStarted;
                    planStatus = daysLeft < 0
                        ? 'Expired'
                        : daysLeft > 0
                            ? '$daysLeft days left'
                            : 'Expires today';
                    if (daysLeft > 7) {
                      planColor = Colors.green;
                    } else if (daysLeft > 0) {
                      planColor = Colors.orange;
                    } else {
                      planColor = Colors.red;
                    }
                  }
                  // var age = filteredData[index].data()['age'];

                  String? image = userInfo['image'];
                  final uid = _filteredData[index].id;

                  // String uid = _filteredData[index].id;
                  String gender = userInfo['gender'];
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
                    // remove
                    endActionPane: ActionPane(
                      motion: const BehindMotion(),
                      // key: const ValueKey(1),
                      children: [
                        SlidableAction(
                          backgroundColor:
                              const Color.fromARGB(255, 125, 3, 207),
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
                                  heightx: double.parse(
                                      userInfo['height'].toString()),
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
                                  productsHistory: userInfo['productsHistory'],
                                  name: name,
                                  popIndex: 1,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    child: OpenContainerWrapper(
                      page: BodyFormCustomerWrap(uid: uid),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                          "Plan: $planName",
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
              );
            }
            if (snapshot.data != null && snapshot.data!.docs.isEmpty) {
              return Center(
                  child: Text('Please add a customer to get started',
                      style: selStyle));
            } else if (snapshot.hasError) {
              return const Text('Error');
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        ));
  }
}
