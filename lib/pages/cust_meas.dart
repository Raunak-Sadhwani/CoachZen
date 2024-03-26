import 'package:another_flushbar/flushbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../components/ui/appbar.dart';

final GlobalKey<FormState> formKey = GlobalKey<FormState>();

class Meas extends StatefulWidget {
  final Map<dynamic, dynamic> measurements;
  final Widget Function(Widget child) card;
  final String uid;
  final List<Map<dynamic, dynamic>> allmeasurements;
  final int index;
  const Meas({
    Key? key,
    required this.measurements,
    required this.card,
    required this.uid,
    required this.allmeasurements,
    required this.index,
  }) : super(key: key);

  @override
  State<Meas> createState() => _MeasState();
}

String capitalize(String value) {
  return value
      .split(' ')
      .map((word) => word[0].toUpperCase() + word.substring(1))
      .join(' ');
}

String formatDate(DateTime timestamp) {
  String formattedDate = DateFormat('dd MMM yyyy').format(timestamp);
  return formattedDate;
}

class _MeasState extends State<Meas> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late Map<String, dynamic> updatedMeasurements;
  late Map<String, dynamic> ogMeasurements;
  Color bg = Colors.white;
  Color text = Colors.black54;

  @override
  void initState() {
    super.initState();
    // remove date from measurements
    updatedMeasurements = Map.from(widget.measurements);
    ogMeasurements = Map.from(widget.measurements);
  }

  void _editMeasurementValue(String key, dynamic value) {
    showDialog(
      context: context,
      builder: (context) {
        dynamic updatedValue = value;
        return Form(
          key: formKey,
          child: AlertDialog(
            title: Text('Edit $key'),
            content: TextFormField(
              autofocus: true,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              initialValue: value.toString(),
              keyboardType: TextInputType.number,
              onChanged: (newValue) {
                updatedValue = double.tryParse(newValue) ?? updatedValue;
              },
              validator: (newValue) {
                if (newValue == null || newValue.isEmpty) {
                  return 'Please enter a value';
                } else if (newValue.contains('.') &&
                    newValue.split('.')[1].length > 2) {
                  return 'Please enter a valid value';
                } else if (double.tryParse(newValue) == null) {
                  return 'Please enter a valid value';
                }
                return null;
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (formKey.currentState != null &&
                      formKey.currentState!.validate()) {
                    setState(() {
                      updatedMeasurements[key] = updatedValue;
                    });
                    Navigator.pop(context);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Rest of the code...

    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    // Map all measurements in containers
    return Scaffold(
      key: _scaffoldKey,
      floatingActionButton: ogMeasurements.toString() !=
              updatedMeasurements.toString()
          ? FloatingActionButton.extended(
              onPressed: () async {
                try {
                  if (!await Method.checkInternetConnection(context)) {
                    return;
                  }
                  setState(() {
                    widget.allmeasurements[widget.index] = updatedMeasurements;
                    ogMeasurements = Map.from(updatedMeasurements);
                  });
                  final userRef = FirebaseDatabase.instance
                      .ref()
                      .child('Coaches')
                      .child(FirebaseAuth.instance.currentUser!.uid)
                      .child('users')
                      .child(widget.uid);
                  await userRef.update({
                    'measurements': widget.allmeasurements,
                  });
                  // twice pop to go back to home page
                  Navigator.pop(_scaffoldKey.currentContext!);
                  Navigator.pop(_scaffoldKey.currentContext!);
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
                  ).show(_scaffoldKey.currentContext!);
                } catch (e) {
                  debugPrint('Error updating user properties: $e');
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
                  ).show(_scaffoldKey.currentContext!);
                }
              },
              label: const Text('Save'),
              icon: const Icon(Icons.save),
            )
          : null,
      appBar: MyAppBar(
        title: formatDate(
          DateTime.fromMillisecondsSinceEpoch(widget.measurements['date']),
        ),
        leftIcon: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: Colors.black26,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.all(width * 0.04),
          child: Column(
            children: updatedMeasurements.entries.map((e) {
              // if date, return nothing
              if (e.key.toLowerCase().contains('date')) {
                return const SizedBox();
              }
              return Container(
                margin: EdgeInsets.only(bottom: height * 0.02),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: widget.card(
                  GestureDetector(
                    onTap: () => !e.key.toLowerCase().contains('date')
                        ? _editMeasurementValue(e.key, e.value)
                        : null,
                    child: Container(
                      padding: EdgeInsets.all(width * 0.04),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              capitalize(e.key),
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines:
                                  2, // Set maxLines to 2 for text wrapping
                            ),
                          ),
                          const SizedBox(
                              width:
                                  10), // Add some spacing between the two Text widgets
                          Text(
                            e.key == 'date'
                                ? formatDate(
                                    DateTime.fromMillisecondsSinceEpoch(
                                        e.value))
                                : updatedMeasurements[e.key].toString(),
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
