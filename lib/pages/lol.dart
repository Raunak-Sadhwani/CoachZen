import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:coach_zen/components/ui/appbar.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:coach_zen/pages/cust_med_hist.dart';
import 'package:coach_zen/pages/cust_plan_hist.dart';
import 'package:coach_zen/pages/cust_product_hist.dart';
import 'package:coach_zen/pages/cust_weight_hist.dart';

class BodyFormCustomerWrap extends StatefulWidget {
  final String uid;
  const BodyFormCustomerWrap({Key? key, required this.uid}) : super(key: key);

  @override
  State<BodyFormCustomerWrap> createState() => _BodyFormCustomerWrapState();
}

String formatDate(Timestamp timestamp) {
  DateTime dateTime = timestamp.toDate();
  String formattedDate = DateFormat('dd MMM yyyy').format(dateTime);
  return formattedDate;
}

class _BodyFormCustomerWrapState extends State<BodyFormCustomerWrap> {
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

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection("Users")
            .doc(widget.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.exists) {
            final user = snapshot.data!.data();
            // Map<String, dynamic> updateFields = {};
            // Map<String, dynamic> editedData = {};
            // Map<String, dynamic> originalData = {};
            Map<String, dynamic> userData = {};
            // remove any list dataytype from filteredData and any exceptionList keys, add to userData
            List exceptionList = ["cid", "reg", "cname", "image"];
            user!.forEach((key, value) {
              if (value.runtimeType != List && !exceptionList.contains(key)) {
                userData[key] = value;
              }
              // if its last key, add id
              if (key == user.keys.last && userData[key] != 'created') {
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
            List<Map<String, dynamic>> measurements = [];
            List<Map<String, dynamic>> products = [];
            List<Map<String, dynamic>> plans = [];
            List medicalHistory = user['medicalHistory'] ?? [];
            String? image = user['image'];

            if (user['measurements'] != null) {
              measurements = (user['measurements'] as List)
                  .cast<Map<String, dynamic>>()
                  .toList()
                ..forEach((e) {
                  final weight = {'weight': e['weight']};
                  e.remove('weight');
                  e.addAll(weight);
                });
            }
            if (user['productsHistory'] != null) {
              products = (user['productsHistory'] as List)
                  .cast<Map<String, dynamic>>()
                  .toList();
              products.sort((a, b) => b['date'].compareTo(a['date']));
            }
            if (user['plans'] != null && user['plans'].isNotEmpty) {
              plans =
                  (user['plans'] as List).cast<Map<String, dynamic>>().toList();
              plans.sort((a, b) => b['started'].compareTo(a['started']));
              // if userdata does not have plan, add it
              if (userData['plan'] == null) {
                String plan = plans[0]['name'];
                // make plan before 'created' key in userData
                userData = Map.fromEntries([
                  ...userData.entries.where((entry) => entry.key != 'created'),
                  MapEntry('plan', plan),
                  MapEntry('created', userData['created']),
                ]);
              }
            }
            return BodyFormCustomer(
                userData: userData,
                measurements: measurements,
                products: products,
                plans: plans,
                medicalHistory: medicalHistory,
                uid: widget.uid,
                image: image);
          } else {
            // Handle loading or empty state...
            return const CircularProgressIndicator();
          }
        });
  }
}

class BodyFormCustomer extends StatefulWidget {
  final Map<String, dynamic> userData;
  final List<Map<String, dynamic>> measurements;
  final List<Map<String, dynamic>> products;
  final List<Map<String, dynamic>> plans;
  final List medicalHistory;
  final String? image;
  final String uid;
  const BodyFormCustomer({
    Key? key,
    required this.userData,
    required this.measurements,
    required this.plans,
    required this.products,
    required this.uid,
    required this.image,
    required this.medicalHistory,
  }) : super(key: key);

  @override
  State<BodyFormCustomer> createState() => _BodyFormCustomerState();
}

class _BodyFormCustomerState extends State<BodyFormCustomer> {
  bool isFabVisible = false;
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  DateFormat formatter = DateFormat('dd MMM yyyy');

  // capitalize first letter of each word
  String capitalize(String value) {
    return value
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  Map<String, dynamic> updateFields = {};
  late Map<String, dynamic> editedData = Map.from(widget.userData);
  late Map<String, dynamic> originalData = Map.from(widget.userData);
  String tempValue = '';
  String dialogTempValue = '';
  void _editData(String key, dynamic value) {
    setState(() {
      editedData[key] = value;
    });
  }

  int idealweight = 0;
  @override
  Widget build(BuildContext context) {
    if (originalData['height'].runtimeType != int) {
      idealweight = originalData['gender'] == 'm'
          ? (int.tryParse(originalData['height'])! - 104)
          : (int.tryParse(originalData['height'])! - 106);
    } else {
      idealweight = originalData['gender'] == 'm'
          ? (originalData['height'] - 104)
          : (originalData['height'] - 106);
    }
    DateTime selectedDate =
        DateTime.parse(widget.userData['dob'].toDate().toString());
    DateTime currentDate = DateTime.now();
    int age = currentDate.year - selectedDate.year;
    if (currentDate.month < selectedDate.month ||
        (currentDate.month == selectedDate.month &&
            currentDate.day < selectedDate.day)) {
      age--;
    }
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        appBar: MyAppBar(
          title: widget.userData['name'],
          leftIcon: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            color: Colors.black26,
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Container(
          padding: EdgeInsets.symmetric(
              vertical: height * 0.0, horizontal: width * 0.035),
          child: ListView(
            physics: const BouncingScrollPhysics(),
            children: [
              Container(
                margin: EdgeInsets.symmetric(
                    vertical: height * 0.025, horizontal: width * 0.05),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                            width: width * 0.3,
                            height: width * 0.3,
                            child: ClipOval(
                                child: widget.image != null &&
                                        widget.image!.isNotEmpty
                                    ? FadeInImage(
                                        placeholder: AssetImage(
                                            'lib/assets/${widget.userData["gender"]}.png'),
                                        image: NetworkImage(widget.image ?? ''),
                                        fit: BoxFit
                                            .cover, // Adjust the fit as per your requirement
                                      )
                                    : Image.asset(
                                        fit: BoxFit.cover,
                                        'lib/assets/${widget.userData["gender"]}.png'))),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 2 gradient buttons
                            CustButton(
                              height: height,
                              width: width,
                              openColor: Colors.orange[800],
                              onPressed: () {},
                              imgPath: 'lib/assets/weights.png',
                              label: 'Weight',
                              page: WHistory(
                                age: age.toString(),
                                gender: widget.userData['gender'],
                                height: double.parse(
                                    widget.userData['height'].toString()),
                                name: widget.userData['name'].split(' ')[0],
                                colors: [
                                  const Color(0xff5fbffa),
                                  Colors.cyanAccent.shade700,
                                  const Color(0xffe9c333),
                                  const Color(0xffff4d62),
                                ],
                                measurements: widget.measurements,
                                idealweight: idealweight,
                                uid: widget.uid,
                              ),
                            ),
                            CustButton(
                              openColor: Colors.green[800],
                              height: height,
                              width: width,
                              onPressed: () {},
                              imgPath: 'lib/assets/orders.png',
                              label: 'Orders',
                              page: ProductsHistory(
                                uid: widget.uid,
                                products: widget.products,
                                name: widget.userData['name'].split(' ')[0],
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                    Row(
                      // crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 2 gradient buttons
                        CustButton(
                            height: height,
                            width: width,
                            onPressed: () {},
                            imgPath: 'lib/assets/meds.png',
                            label: 'Meds',
                            page: CustMedHist(
                              name: widget.userData['name'].split(' ')[0],
                              uid: widget.uid,
                              medicalhistory: widget.medicalHistory,
                            )),
                        CustButton(
                            height: height,
                            width: width,
                            onPressed: () {},
                            imgPath: 'lib/assets/plans.png',
                            label: 'Plans',
                            page: CustPlanHist(
                              name: widget.userData['name'],
                              uid: widget.uid,
                              plans: widget.plans,
                            )),
                      ],
                    )
                  ],
                ),
              ),
              ...editedData.entries.map(
                (entry) {
                  // var key = entry.key;
                  // var value = entry.value;
                  // if (key == 'dob') {}

                  return GestureDetector(
                    child: Card(
                      elevation: 10,
                      key: ValueKey(entry.key),
                      margin: const EdgeInsets.all(10),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            vertical: height * 0.02, horizontal: width * 0.05),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Icon(
                              _getIcon(entry.key),
                              color: Colors.black,
                              size: height * 0.03,
                            ),
                            SizedBox(
                              width: width * 0.07,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.key == 'dob'
                                      ? capitalize('dob ($age years)')
                                      : capitalize(entry.key),
                                  style: GoogleFonts.poppins(
                                      color: Colors.grey, fontSize: 14),
                                ),
                                SizedBox(
                                  height: height * 0.01,
                                ),
                                Text(
                                  entry.value.runtimeType == Timestamp
                                      ? formatter
                                          .format(entry.value.toDate())
                                          .toString()
                                      : entry.value.toString(),
                                  style: GoogleFonts.dmSans(
                                      color: Colors.black, fontSize: 16),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                    onLongPress: () {
                      if (entry.key == 'phone') {
                        // copy phone number to clipboard
                        Clipboard.setData(
                            ClipboardData(text: entry.value.toString()));
                        Flushbar(
                          margin: const EdgeInsets.all(7),
                          borderRadius: BorderRadius.circular(15),
                          flushbarStyle: FlushbarStyle.FLOATING,
                          flushbarPosition: FlushbarPosition.BOTTOM,
                          message: "Phone number copied to clipboard",
                          icon: Icon(
                            Icons.phone_android_rounded,
                            size: 28.0,
                            color: Colors.green[300],
                          ),
                          duration: const Duration(milliseconds: 1500),
                          leftBarIndicatorColor: Colors.green[300],
                        ).show(scaffoldKey.currentContext!);
                        return;
                      }
                    },
                    onTap: () {
                      if (entry.key == 'created' || entry.key == 'plan') {
                        return;
                      }
                      showDialog(
                        context: context,
                        builder: (context) {
                          String dialogTempValue =
                              entry.value.runtimeType == Timestamp
                                  ? formatter
                                      .format(entry.value.toDate())
                                      .toString()
                                  : entry.value.toString();
                          return StatefulBuilder(
                              builder: (context, StateSetter setState) {
                            return AlertDialog(
                              title: Text(capitalize(entry.key)),
                              content: Form(
                                key: _formKey,
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                child: entry.key.toLowerCase().contains('dob')
                                    ? InkWell(
                                        onTap: () {
                                          showDatePicker(
                                                  context: context,
                                                  initialDate:
                                                      entry.value.toDate() ??
                                                          DateTime.now(),
                                                  firstDate: DateTime(1930),
                                                  lastDate: DateTime(2011))
                                              .then((selectedDate) {
                                            if (selectedDate != null) {
                                              String formattedDate =
                                                  DateFormat('dd MMM yyyy')
                                                      .format(selectedDate);
                                              setState(() {
                                                dialogTempValue = formattedDate;
                                              });
                                            }
                                          });
                                        },
                                        child: InputDecorator(
                                          decoration: const InputDecoration(
                                            border: OutlineInputBorder(),
                                            labelText: 'Select Date',
                                          ),
                                          child: Text(dialogTempValue),
                                        ),
                                      )
                                    : entry.key.toLowerCase() == 'gender'
                                        ? DropdownButton<String>(
                                            value: dialogTempValue,
                                            items: <String>['male', 'female']
                                                .map<DropdownMenuItem<String>>(
                                                    (String value) {
                                              return DropdownMenuItem<String>(
                                                value: value,
                                                child: Text(value),
                                              );
                                            }).toList(),
                                            onChanged: (String? newValue) {
                                              setState(() {
                                                dialogTempValue = newValue!;
                                              });
                                            },
                                          )
                                        : TextFormField(
                                            onChanged: (value) {
                                              setState(() {
                                                dialogTempValue = value;
                                              });
                                            },
                                            initialValue: dialogTempValue,
                                            maxLength: entry.key == 'phone'
                                                ? 10
                                                : entry.key == 'height'
                                                    ? 3
                                                    : null,
                                            decoration: const InputDecoration(
                                              counterText: '',
                                            ),
                                            validator: (value) {
                                              if (entry.key == 'name') {
                                                if (value!.length < 3 ||
                                                    !value.trim().contains(RegExp(
                                                        r'^((\b[a-zA-Z]{2,40}\b)\s*){2,3}$'))) {
                                                  return 'Please enter a valid name';
                                                }
                                              } else if (entry.key == 'phone') {
                                                if (!RegExp(r'^[6-9]\d{9}$')
                                                    .hasMatch(value!)) {
                                                  return 'Please enter a valid Indian phone number';
                                                }
                                                // You can add additional phone number validation logic here
                                              } else if (entry.key == 'city') {
                                                if (value!.trim().length < 3 ||
                                                    !RegExp(r'^[a-zA-Z\s]+$')
                                                        .hasMatch(value)) {
                                                  return 'Please enter a city';
                                                }
                                              } else if (entry.key == 'email') {
                                                if (value!.isNotEmpty &&
                                                    (!RegExp(
                                                            r'^.+@[a-zA-Z]+\.{1}[a-zA-Z]+(\.{0,1}[a-zA-Z]+)$')
                                                        .hasMatch(value))) {
                                                  return 'Please enter a valid email address';
                                                }
                                              } else if (entry.key ==
                                                  'height') {
                                                if (int.tryParse(value!) ==
                                                    null) {
                                                  return 'Please enter a valid height';
                                                } else if (int.parse(value) <
                                                        50 ||
                                                    int.parse(value) > 250) {
                                                  return 'Please enter a valid height';
                                                }
                                              }
                                              // Return null if there are no validation errors
                                              return null;
                                            },
                                          ),
                              ),
                              actions: [
                                TextButton(
                                  child: const Text('Save'),
                                  onPressed: () {
                                    if (_formKey.currentState!.validate()) {
                                      if (entry.key == 'dob') {
                                        // convert to Timestamp
                                        DateTime selectedDateTime =
                                            DateFormat('dd MMM yyyy')
                                                .parse(dialogTempValue);
                                        Timestamp selectedTimestamp =
                                            Timestamp.fromDate(
                                                selectedDateTime);
                                        if (selectedTimestamp !=
                                            originalData[entry.key]) {
                                          _editData(
                                              entry.key, selectedTimestamp);
                                          updateFields[entry.key] =
                                              selectedTimestamp;
                                        } else {
                                          _editData(
                                              entry.key, selectedTimestamp);
                                          updateFields.remove(entry.key);
                                        }
                                      } else {
                                        _editData(
                                            entry.key, dialogTempValue.trim());
                                        if (dialogTempValue !=
                                            originalData[entry.key]) {
                                          updateFields[entry.key] =
                                              dialogTempValue;
                                        } else {
                                          updateFields.remove(entry.key);
                                        }
                                      }
                                      Navigator.of(context).pop();
                                    }
                                  },
                                ),
                              ],
                            );
                          });
                        },
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
        floatingActionButton: updateFields.isNotEmpty && isFabVisible
            ? FloatingActionButton(
                onPressed: () async {
                  setState(() {
                    isFabVisible = false;
                  });
                  try {
                    if (!await Method.checkInternetConnection(context)) {
                      setState(() {
                        isFabVisible = true;
                      });
                      return;
                    }
                    final users =
                        FirebaseFirestore.instance.collection('Users');
                    if (updateFields.containsKey('phone')) {
                      final coaches =
                          FirebaseFirestore.instance.collection('Coaches');
                      // check if phone number already exists
                      final phoneExistsInUsers = await users
                          .where('phone', isEqualTo: updateFields['phone'])
                          .get();
                      final phoneExistsInCoaches = await coaches
                          .where('phone', isEqualTo: updateFields['phone'])
                          .get();
                      if (phoneExistsInUsers.docs.isNotEmpty ||
                          phoneExistsInCoaches.docs.isNotEmpty) {
                        return Flushbar(
                          margin: const EdgeInsets.all(7),
                          borderRadius: BorderRadius.circular(15),
                          flushbarStyle: FlushbarStyle.FLOATING,
                          flushbarPosition: FlushbarPosition.BOTTOM,
                          message: "Phone number already exists, please change",
                          icon: Icon(
                            Icons.phone_android_rounded,
                            size: 28.0,
                            color: Colors.red[300],
                          ),
                          duration: const Duration(milliseconds: 1500),
                          leftBarIndicatorColor: Colors.red[300],
                        ).show(scaffoldKey.currentContext!);
                      }
                    }

                    final userRef = users.doc(widget.uid);

                    await userRef.update(updateFields);
                    setState(() {
                      originalData = Map.from(editedData);
                      updateFields.clear();
                    });

                    return Flushbar(
                      margin: const EdgeInsets.all(7),
                      borderRadius: BorderRadius.circular(15),
                      flushbarStyle: FlushbarStyle.FLOATING,
                      flushbarPosition: FlushbarPosition.BOTTOM,
                      message: "User data updated successfully",
                      icon: Icon(
                        Icons.check_circle_outline_rounded,
                        size: 28.0,
                        color: Colors.green[300],
                      ),
                      duration: const Duration(milliseconds: 1500),
                      leftBarIndicatorColor: Colors.green[300],
                    ).show(scaffoldKey.currentContext!);
                  } catch (error) {
                    debugPrint('Error updating user properties: $error');
                    setState(() {
                      isFabVisible = true;
                    });
                    return Flushbar(
                      margin: const EdgeInsets.all(7),
                      borderRadius: BorderRadius.circular(15),
                      flushbarStyle: FlushbarStyle.FLOATING,
                      flushbarPosition: FlushbarPosition.BOTTOM,
                      message: "Something went wrong",
                      icon: Icon(
                        Icons.check_circle_outline_rounded,
                        size: 28.0,
                        color: Colors.red[300],
                      ),
                      duration: const Duration(milliseconds: 1500),
                      leftBarIndicatorColor: Colors.red[300],
                    ).show(scaffoldKey.currentContext!);
                  }
                },
                child: const Icon(Icons.save),
              )
            : null,
      ),
    );
  }

  IconData _getIcon(String key) {
    switch (key) {
      case 'city':
        return Icons.location_city;
      case 'created':
        return Icons.calendar_today;
      case 'dob':
        return Icons.cake;
      case 'email':
        return Icons.email;
      case 'gender':
        return Icons.male;
      case 'height':
        return Icons.height;
      case 'image':
        return Icons.photo;
      case 'name':
        return Icons.person;
      case 'phone':
        return Icons.phone;
      case 'plan':
        return Icons.map;
      default:
        return Icons.new_releases;
    }
  }
}

class CustButton extends StatelessWidget {
  final double height;
  final double width;
  final VoidCallback? onPressed;
  final String imgPath;
  final String label;
  final Widget page;
  final Color? openColor;

  const CustButton({
    Key? key,
    required this.height,
    required this.width,
    this.onPressed,
    required this.imgPath,
    required this.label,
    required this.page,
    this.openColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width * 0.4,
      margin: EdgeInsets.only(
        bottom: height * 0.01,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Card(
        elevation: 8.5,
        child: OpenContainerWrapper(
            openColor: openColor ?? Colors.white,
            page: page,
            content: Container(
              padding: EdgeInsets.symmetric(horizontal: width * 0.02),
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
              child: SizedBox(
                height: height * 0.1,
                width: width * 0.3,
                child: Row(
                  children: [
                    Text(label,
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            )),
      ),
    );
  }
}
