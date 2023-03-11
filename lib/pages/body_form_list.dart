import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:slimtrap/pages/body_form_cust.dart';
import 'package:url_launcher/url_launcher.dart';

import '../components/ui/appbar.dart';

class BodyFormList extends StatelessWidget {
  const BodyFormList({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: MyAppBar(
          leftIcon: IconButton(
            icon: const Icon(Icons.menu_rounded),
            color: Colors.black26,
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: 'Body Form Customers',
          rightIcons: [
            IconButton(
              icon: const Icon(Icons.search_rounded),
              color: Colors.black26,
              onPressed: () {},
            ),
          ],
        ),
        // listview from firestore collection
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream:
              FirebaseFirestore.instance.collection("body_form").snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
              return ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  String phone =
                      "+91${snapshot.data!.docs[index].data()['Phone (+91)']}";
                  bool isMale =
                      snapshot.data!.docs[index].data()['Gender'] == 'Male';
                  String timeStamp = snapshot.data!.docs[index]
                      .data()['timestamp']
                      .toDate()
                      .toString();
                  String name = snapshot.data!.docs[index].data()['Name'];
                  String city = snapshot.data!.docs[index].data()['City'];

                  int age = snapshot.data!.docs[index].data()['Age'];
                  double weight = snapshot.data!.docs[index].data()['Weight'];
                  int height = snapshot.data!.docs[index].data()['Height'];
                  String medicalHistory =
                      snapshot.data!.docs[index].data()['Medical History'] ??
                          '';
                  String email =
                      snapshot.data!.docs[index].data()['Email'] ?? '';
                  String id = snapshot.data!.docs[index].id;

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
                    child: openCont(
                      page: BodyFormCustomer(
                        name: name,
                        phone: phone.toString(),
                        isMale: isMale,
                        timeStamp: timeStamp,
                        age: age.toString(),
                        email: email,
                        medicalHistory: medicalHistory,
                        weight: weight.toString(),
                        height: height.toString(),
                        id: id,
                        city: city,
                      ),
                      child: ListTile(
                        leading: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // male.png from assets
                            isMale
                                ? Image.asset('lib/assets/male.png',
                                    width: 44, height: 44, fit: BoxFit.cover)
                                : Image.asset('lib/assets/female.png',
                                    width: 44, height: 44, fit: BoxFit.cover)
                          ],
                        ),
                        title: Text(name),
                        subtitle: Text(phone.substring(3)),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // date
                            Text(timeStamp.substring(0, 10)),
                            // time
                            Text(
                              timeStamp.substring(11, 16),
                              style: const TextStyle(color: Colors.black26),
                            ),
                          ],
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
