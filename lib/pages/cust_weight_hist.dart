import 'package:another_flushbar/flushbar.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:slimtrap/pages/body_form.dart';

import '../components/ui/appbar.dart';
import 'cust_meas.dart';

class WHistory extends StatefulWidget {
  final int idealweight;
  final List<Map<String, dynamic>> measurements;
  final String name;
  final List<Color> colors;
  final String uid;
  final String age;
  final double height;
  final String gender;

  const WHistory(
      {Key? key,
      required this.measurements,
      required this.idealweight,
      required this.name,
      required this.colors,
      required this.uid,
      required this.age,
      required this.height,
      required this.gender})
      : super(key: key);

  @override
  State<WHistory> createState() => _WHistoryState();
}

String formatDate(Timestamp timestamp) {
  DateTime dateTime = timestamp.toDate();
  String formattedDate = DateFormat('dd MMM yyyy').format(dateTime);
  return formattedDate;
}

class _WHistoryState extends State<WHistory> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  // scaffold key
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late List<Map<String, dynamic>> updatedMeasurements;

  @override
  void initState() {
    super.initState();
    updatedMeasurements = List.from(widget.measurements);
  }

  void _editWeight(int index) {
    showDialog(
      context: context,
      builder: (context) {
        dynamic weight = updatedMeasurements[index]['weight'];
        // convert weight to double
        weight = double.parse(weight.toString());
        return Form(
          key: _formKey,
          child: AlertDialog(
            title: const Text('Edit Weight'),
            content: TextFormField(
              autofocus: true,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              initialValue: weight.toString(),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                weight = double.tryParse(value) ?? weight;
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a weight';
                } else if (value.contains('.') &&
                    value.split('.')[1].length > 2) {
                  return 'Please enter a valid weight';
                } else if (double.tryParse(value) == null) {
                  return 'Please enter a valid weight';
                } else if (double.parse(value) <= 20 ||
                    double.parse(value) >= 200) {
                  return 'Please enter a valid weight';
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
                onPressed: () async {
                  try {
                    if (!await Method.checkInternetConnection(context)) {
                      return;
                    }
                    if (_formKey.currentState!.validate()) {
                      setState(() {
                        updatedMeasurements[index]['weight'] = weight;
                      });
                      // save to firestore
                      final userRef = FirebaseFirestore.instance
                          .collection('Users')
                          .doc(widget.uid);
                      await userRef.update({
                        'measurements': updatedMeasurements,
                      });
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
                    }
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
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    Color bg = Colors.white;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: bg,
      appBar: MyAppBar(
        rightIcons: [
          // add weight icon
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FormPageWrapper(
                  uid: widget.uid,
                  age: widget.age,
                  measurements: updatedMeasurements,
                  heightx: widget.height,
                  gender: widget.gender == 'male',
                  popIndex: 3,
                  name: widget.name,
                ),
              ),
            ),
            icon: const Icon(Icons.add_rounded),
            color: Colors.black45,
          ),
        ],
        title: 'Weight History of ${widget.name}',
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
            children: [
              AutoSizeText('Ideal Weight: ${widget.idealweight} kg',
                  style: GoogleFonts.montserrat(
                      color: Colors.grey[600],
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              SizedBox(
                height: height * 0.025,
              ),
              Column(
                children:
                    widget.measurements.reversed.toList().map((measurement) {
                  final int index = widget.measurements.indexOf(measurement);
                  if (measurement['weight'].runtimeType == String) {
                    measurement['weight'] = double.parse(measurement['weight']);
                  }
                  double weightLoss = 0;
                  if (index > 0) {
                    // tryparse to double
                    weightLoss = double.parse((measurement['weight'] -
                            updatedMeasurements[index - 1]['weight'])
                        .toString());
                  }
                  dynamic arrowIcon = false;
                  Color arrowColor = widget.colors[0];

                  if (weightLoss > 0) {
                    arrowIcon = Icons.arrow_upward_outlined;
                    arrowColor = Colors.green;
                  } else if (weightLoss < 0) {
                    arrowIcon = Icons.arrow_downward_outlined;
                    arrowColor = Colors.red;
                  }

                  if (widget.idealweight < measurement['weight'] &&
                      weightLoss < 0) {
                    arrowColor = Colors.green;
                  } else if (widget.idealweight < measurement['weight'] &&
                      weightLoss > 0) {
                    arrowColor = Colors.red;
                  }

                  return Container(
                    margin: EdgeInsets.only(bottom: height * 0.015),
                    color: bg,
                    child: measurement.length > 2
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: OpenContainerWrapper(
                                page: Meas(
                                  measurements: updatedMeasurements[index],
                                  index: index,
                                  allmeasurements: updatedMeasurements,
                                  card: card,
                                  uid: widget.uid,
                                ),
                                content: widMeas(measurement, height, width,
                                    arrowIcon, arrowColor, weightLoss, index)),
                          )
                        : widMeas(measurement, height, width, arrowIcon,
                            arrowColor, weightLoss, index),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget widMeas(
      measurement, height, width, arrowIcon, arrowColor, weightLoss, index) {
    if (index < 0 || index >= updatedMeasurements.length) {
      // Handle the case when the index is out of range.
      // You can return an empty container or handle it differently.
      return Container();
    }
    return card(
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                children: [
                  Text(
                    formatDate(measurement['date'].runtimeType == DateTime
                        ? Timestamp.fromDate(measurement['date'])
                        : measurement['date']),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: height * 0.007),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (arrowIcon != false)
                          Icon(
                            arrowIcon,
                            color: arrowColor,
                            size: 22,
                          )
                        else
                          Container(
                            padding: EdgeInsets.only(right: width * 0.01),
                            child: Text("=",
                                style: TextStyle(
                                    color: arrowColor,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold)),
                          ),
                        const SizedBox(width: 4.0),
                        Text(
                          '${weightLoss.abs().toStringAsFixed(1)} kg',
                          style: const TextStyle(
                              fontSize: 18, color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (measurement.length > 2)
            Container(
              margin: const EdgeInsets.only(right: 10),
              color: Colors.transparent,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: Image.asset(
                  'lib/assets/scan.png',
                  height: 45,
                  width: 45,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          GestureDetector(
            onTap: () => _editWeight(index),
            onLongPress: () {
              // ask if want to delete
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Delete Weight'),
                    content: const Text(
                        'Are you sure you want to delete this weight?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () async {
                          if (!await Method.checkInternetConnection(context)) {
                            return;
                          }
                          try {
                            setState(() {
                              updatedMeasurements.removeAt(index);
                            });
                            // save to firestore
                            final userRef = FirebaseFirestore.instance
                                .collection('Users')
                                .doc(widget.uid);
                            await userRef.update({
                              'measurements': updatedMeasurements,
                            });
                            Navigator.pop(_scaffoldKey.currentContext!);
                            return Flushbar(
                              margin: const EdgeInsets.all(7),
                              borderRadius: BorderRadius.circular(15),
                              flushbarStyle: FlushbarStyle.FLOATING,
                              flushbarPosition: FlushbarPosition.BOTTOM,
                              message: "Weight deleted successfully",
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
                        child: const Text('Delete'),
                      ),
                    ],
                  );
                },
              );
            },
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: updatedMeasurements[index]['weight'].toString(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const TextSpan(
                    text: ' kg',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget card(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 255, 191, 0),
            Color(0xFFFFF176),
          ],
          stops: [0.2, 1.0],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: child,
    );
  }
}
