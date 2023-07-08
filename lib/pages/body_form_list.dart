import 'dart:async';
import 'dart:io';

import 'package:animations/animations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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

  bool isSearching = false;
  String searchQuery = '';
  FocusNode searchFocusNode = FocusNode();
  double opacity = 0.0;
  DateFormat formatter = DateFormat('dd MMM yyyy');
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filteredData = [];

  @override
  void initState() {
    super.initState();
    checkInternetConnection();
  }

  @override
  void dispose() {
    super.dispose();
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
            IconButton(
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
          ],
        ),
        // appBar: buildAppBar(),
        // listview from firestore collection
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

              filteredData.sort((a, b) {
                final dateA = a.data()['created'];
                final dateB = b.data()['created'];
                return dateB
                    .toDate()
                    .compareTo(dateA.toDate()); // Compare in reverse order
              });

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
                  // // final isMale = filteredData[index].data()['gender'] == 'male';
                  final timeStamp = userInfo['created'].toDate().toString();
                  final name = userInfo['name'];
                  // // final city = filteredData[index].data()['city'];
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
                  }
                  if (userInfo['productsHistory'] != null) {
                    userInfo['productsHistory'] =
                        (userInfo['productsHistory'] as List)
                            .cast<Map<String, dynamic>>()
                            .toList();
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
                            // debugPrint('call');
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
                    child: openCont(
                      page: BodyFormCustomerWrap(uid: uid),
                      child: Container(
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Color.fromARGB(52, 158, 158, 158),
                              width: .5,
                            ),
                          ),
                        ),
                        child: ListTile(
                          leading: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // male.png from assets
                              SizedBox(
                                width: 44,
                                height: 44,
                                child: ClipOval(
                                    child: image != null && image.isNotEmpty
                                        ? FadeInImage.assetNetwork(
                                            fit: BoxFit.cover,
                                            placeholder:
                                                'lib/assets/$gender.png',
                                            image: image)
                                        : Image.asset(
                                            fit: BoxFit.cover,
                                            'lib/assets/$gender.png')),
                              ),
                            ],
                          ),
                          title: Text(name),
                          subtitle: Text("+91 ${phone.substring(3)}"),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // date
                              Text(
                                formatter.format(_filteredData[index]
                                    .data()['created']
                                    .toDate()),
                                style: const TextStyle(color: Colors.black),
                              ),
                              // time
                              Text(
                                timeStamp.substring(11, 16),
                                style: const TextStyle(color: Colors.black26),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }
            if (snapshot.data != null && snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text('No Data'),
              );
            } else if (snapshot.hasError) {
              return const Text('Error');
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        ));
  }

  openCont({required Widget child, required Widget page}) {
    return OpenContainer<bool>(
      transitionType: ContainerTransitionType.fade,
      openBuilder: (BuildContext _, VoidCallback openContainer) {
        return page;
      },
      tappable: false,
      closedShape: const RoundedRectangleBorder(),
      closedElevation: 0.0,
      closedBuilder: (BuildContext _, VoidCallback openContainer) {
        return GestureDetector(onTap: openContainer, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
