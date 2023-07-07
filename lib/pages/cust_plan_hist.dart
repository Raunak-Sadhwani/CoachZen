import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../components/ui/appbar.dart';

class PlanClass {
  final String planName;
  final int planDays;
  final Timestamp planDate;

  PlanClass({
    required this.planName,
    required this.planDays,
    required this.planDate,
  });
  @override
  String toString() {
    return 'Plan Name: $planName, Plan Days: $planDays, Plan Date: $planDate';
  }
}

class CustPlanHist extends StatefulWidget {
  final String name;
  const CustPlanHist({Key? key, required this.name}) : super(key: key);

  @override
  State<CustPlanHist> createState() => _CustPlanHistState();
}

String formatDate(DateTime dateTime) {
  final DateFormat formatter = DateFormat('dd MMM yyyy - hh:mm a');
  final String formatted = formatter.format(dateTime);
  return formatted;
}

class _CustPlanHistState extends State<CustPlanHist> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  List<PlanClass> plans = [];

  @override
  void initState() {
    super.initState();
    // Add some sample data to the plans list
    plans = [];
    debugPrint('Plans: ${plans.toString()}');
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: MyAppBar(
        title: 'Plans of ${widget.name}',
        leftIcon: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: Colors.black26,
          onPressed: () => Navigator.pop(context),
        ),
        rightIcons: [
          IconButton(
            icon: const Icon(Icons.add),
            color: Colors.black26,
            onPressed: () {
              setState(() {
                plans.add(PlanClass(
                  planName: '',
                  planDays: 0,
                  planDate: Timestamp.now(),
                ));
              });
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: plans.length,
        itemBuilder: (context, index) {
          return PlanCard(
            onRemove: (plan) {
              setState(() {
                plans.remove(plan);
              });
            },
          );
        },
      ),
      // floatingActionButton: FloatingActionButton(
      //   child: const Icon(Icons.add),
      //   onPressed: () {
      //     setState(() {
      //       plans.add(PlanClass(
      //         planName: '',
      //         planDays: 0,
      //         planDate: Timestamp.now(),
      //       ));
      //     });
      //   },
      // ),
    );
  }
}

class PlanCard extends StatefulWidget {
  final Function(PlanClass) onRemove;

  const PlanCard({
    Key? key,
    required this.onRemove,
  }) : super(key: key);

  @override
  State<PlanCard> createState() => _PlanCardState();
}
class _PlanCardState extends State<PlanCard> {
  late String planName;
  late int planDays;
  late Timestamp planDate;

  @override
  void initState() {
    super.initState();
    planName = '';
    planDays = 0;
    planDate = Timestamp.now();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return Container(
      margin: EdgeInsets.only(
        right: width * 0.01,
        bottom: height * 0.02,
        top: height * 0.02,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: width * 0.1,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.red, size: 20),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Delete Plan?'),
                      content: const Text(
                          'Are you sure you want to delete this Plan?'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              widget.onRemove(PlanClass(
                                planName: planName,
                                planDays: planDays,
                                planDate: planDate,
                              ));
                            });
                          },
                          child: const Text('Delete'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          Expanded(
            child: Card(
              elevation: 10,
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: width * 0.04, vertical: height * 0.02),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        // Date and time picker code...
                      },
                      child: Container(
                        margin: EdgeInsets.only(bottom: height * 0.02),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Plan Start:',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              formatDate(planDate.toDate()),
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            decoration: const InputDecoration(
                                labelText: 'Plan Name',
                                contentPadding: EdgeInsets.only(left: 10)),
                            validator: (value) {
                              // Validation code...
                            },
                            onChanged: (value) {
                              setState(() {
                                planName = value;
                              });
                            },
                          ),
                        ),
                        SizedBox(
                          width: width * 0.1,
                        ),
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            decoration: const InputDecoration(
                                labelText: 'Days',
                                contentPadding: EdgeInsets.only(left: 10)),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              // Validation code...
                            },
                            onChanged: (value) {
                              setState(() {
                                planDays = int.parse(value);
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
