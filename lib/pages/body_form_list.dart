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

class BodyFormList extends StatefulWidget {
  const BodyFormList({super.key});

  @override
  State<BodyFormList> createState() => _BodyFormListState();
}

class _BodyFormListState extends State<BodyFormList> {
  bool isSearching = false;
  String searchQuery = '';
  FocusNode searchFocusNode = FocusNode();
  double opacity = 0.0;
  DateFormat formatter = DateFormat('dd MMM yyyy');
  @override
  Widget build(BuildContext context) {
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

              return ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: filteredData.length,
                itemBuilder: (context, index) {
                  final phone = "+91${filteredData[index].data()['phone']}";
                  final isMale = filteredData[index].data()['gender'] == 'male';
                  final timeStamp =
                      filteredData[index].data()['created'].toDate().toString();
                  final name = filteredData[index].data()['name'];
                  // final city = filteredData[index].data()['city'];

                  var age = filteredData[index].data()['dob'];
                  // calculate age
                  if (age != null) {
                    age = DateTime.now().year -
                        DateTime.parse(age.toDate().toString()).year;
                  }
                  String? image = filteredData[index].data()['image'];
                  // final weight = filteredData[index].data()['Weight'] ?? '';
                  // final height = filteredData[index].data()['height'];
                  // final medicalHistory =
                  //     filteredData[index].data()['Medical History'] ?? '';
                  // final email = filteredData[index].data()['email'] ?? '';
                  // final id = filteredData[index].id;

                  Map<String, dynamic> userData = {};
                  // remove any list dataytype from filteredData and any exceptionList keys, add to userData
                  List exceptionList = ["cid", "reg", "cname", "image"];
                  filteredData[index].data().forEach((key, value) {
                    if (value.runtimeType != List &&
                        !exceptionList.contains(key)) {
                      userData[key] = value;
                    }
                    // if its last key, add id
                    if (key == filteredData[index].data().keys.last &&
                        userData[key] != 'created') {
                      Timestamp cr = userData['created'];
                      userData.remove('created');
                      userData['created'] = cr;
                    }
                  });
                  List toBeOnTop = ["name", "phone", "city", "dob"];
                  userData = Map.fromEntries([
                    ...toBeOnTop.map((key) => MapEntry(key, userData[key])),
                    ...userData.entries
                        .where((entry) => !toBeOnTop.contains(entry.key))
                  ]);

                  debugPrint(userData.toString());
                  String uid = filteredData[index].id;
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
                          },
                        ),
                        SlidableAction(
                          backgroundColor:
                              const Color.fromARGB(255, 244, 155, 54),
                          foregroundColor: Colors.black,
                          icon: Icons.history,
                          label: 'Products',
                          onPressed: (context) {
                            // debugPrint('call');
                          },
                        ),
                        // SlidableAction(
                        //   backgroundColor: Colors.red,
                        //   foregroundColor: Colors.white,
                        //   icon: Icons.delete,
                        //   label: 'Delete',
                        //   onPressed: (context) {
                        //     showDialog(
                        //       context: context,
                        //       builder: (context) {
                        //         return AlertDialog(
                        //           title: const Text('Delete'),
                        //           content: Text(
                        //               'Are you sure you want to remove $name?'),
                        //           actions: [
                        //             TextButton(
                        //               onPressed: () {
                        //                 Navigator.pop(context);
                        //               },
                        //               child: const Text('Cancel'),
                        //             ),
                        //             TextButton(
                        //               onPressed: () {
                        //                 FirebaseFirestore.instance
                        //                     .collection('body_form')
                        //                     .doc(id)
                        //                     .delete();
                        //                 Navigator.pop(context);
                        //               },
                        //               child: const Text('Delete'),
                        //             ),
                        //           ],
                        //         );
                        //       },
                        //     );
                        //   },
                        // ),
                      ],
                    ),
                    child: openCont(
                      page: BodyFormCustomer(
                          userData: userData, uid: uid, image: image ?? ''),
                      child: Container(
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey,
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
                                                'lib/assets/${filteredData[index].data()['gender']}.png',
                                            image: image)
                                        : Image.asset(
                                            fit: BoxFit.cover,
                                            'lib/assets/${filteredData[index].data()['gender']}.png')),
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
                                formatter.format(filteredData[index]
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
