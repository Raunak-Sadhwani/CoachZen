import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:slimtrap/components/ui/appbar.dart';
import 'package:another_flushbar/flushbar.dart';

class BodyFormCustomer extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String? image;
  final String uid;
  const BodyFormCustomer({
    Key? key,
    required this.userData,
    required this.uid,
    required this.image,
  }) : super(key: key);

  @override
  State<BodyFormCustomer> createState() => _BodyFormCustomerState();
}

class _BodyFormCustomerState extends State<BodyFormCustomer> {
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

  @override
  Widget build(BuildContext context) {
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
              vertical: height * 0.01, horizontal: width * 0.035),
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
                              onPressed: () {},
                              imgPath: 'lib/assets/weights.png',
                              label: 'Weight',
                              page: Container(),
                            ),
                            CustButton(
                              height: height,
                              width: width,
                              onPressed: () {},
                              imgPath: 'lib/assets/focus.png',
                              label: 'Orders',
                              page: Container(),
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
                          imgPath: 'lib/assets/focus.png',
                          label: 'Plan',
                          page: Container(),
                        ),
                        CustButton(
                          height: height,
                          width: width,
                          onPressed: () {},
                          imgPath: 'lib/assets/focus.png',
                          label: 'Meds',
                          page: Container(),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              ...editedData.entries.map(
                (entry) {
                  var key = entry.key;
                  var value = entry.value;
                  late dynamic age;
                  if (key == 'dob') {
                    DateTime selectedDate =
                        DateTime.parse(value.toDate().toString());
                    DateTime currentDate = DateTime.now();
                    age = currentDate.year - selectedDate.year;
                    if (currentDate.month < selectedDate.month ||
                        (currentDate.month == selectedDate.month &&
                            currentDate.day < selectedDate.day)) {
                      age--;
                    }
                  }

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
                                        _editData(entry.key, dialogTempValue);
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
                                    debugPrint(updateFields.toString());
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
        floatingActionButton: updateFields.isNotEmpty
            ? FloatingActionButton(
                onPressed: () async {
                  try {
                    final userRef = FirebaseFirestore.instance
                        .collection('Users')
                        .doc(widget.uid);

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
                  }
                  // updateUserProperties(userId, updatedData);
                  // updateUser();
                },
                child: const Icon(Icons.save),
              )
            : null,
      ),
    );
  }

  IconData _getIcon(String key) {
    switch (key) {
      case 'created':
        return Icons.calendar_today;
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
      case 'city':
        return Icons.location_city;
      default:
        if (key.contains('dob')) {
          return Icons.cake;
        }
        return Icons.error;
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

  const CustButton({
    Key? key,
    required this.height,
    required this.width,
    this.onPressed,
    required this.imgPath,
    required this.label,
    required this.page,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        bottom: height * 0.01,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Card(
        elevation: 8.5,
        child: OpenContainerWrapper(
            page: page,
            content: Container(
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
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(0, 255, 139, 139),
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: SizedBox(
                  height: height * 0.1,
                  width: width * 0.3,
                  child: Row(
                    children: [
                      Text(label),
                    ],
                  ),
                ),
              ),
            )),
      ),
    );
  }
}
