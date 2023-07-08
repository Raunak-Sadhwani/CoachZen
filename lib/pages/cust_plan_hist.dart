import 'package:another_flushbar/flushbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../components/ui/appbar.dart';

class CustPlanHist extends StatefulWidget {
  final String name;
  final String uid;
  final List<Map<String, dynamic>> plans;
  const CustPlanHist(
      {Key? key, required this.name, required this.uid, required this.plans})
      : super(key: key);

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
  List<TextEditingController> planNameControllers = [];
  List<TextEditingController> planDaysControllers = [];
  List<Map<String, dynamic>> newPlans = [];
  bool isPlanModified = false;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.plans.length; i++) {
      newPlans.add(Map<String, dynamic>.from(widget.plans[i]));
      var old = {'old': true};
      newPlans[i].addAll(old);
      planNameControllers.add(TextEditingController(text: newPlans[i]['name']));
      planDaysControllers
          .add(TextEditingController(text: newPlans[i]['days'].toString()));
    }
    debugPrint('newPlans: ${newPlans.toString()}');
    debugPrint('plans: ${widget.plans.toString()}');
  }

  @override
  void dispose() {
    for (int i = 0; i < planNameControllers.length; i++) {
      planNameControllers[i].dispose();
      planDaysControllers[i].dispose();
    }
    newPlans.clear();
    super.dispose();
  }

  void isPlanModifiedFunc() {
    if (newPlans.length != widget.plans.length) {
      setState(() {
        isPlanModified = true;
      });
      return;
    }

    for (int i = 0; i < newPlans.length; i++) {
      if (newPlans[i]['name'] != planNameControllers[i].text ||
          newPlans[i]['days'].toString() != planDaysControllers[i].text ||
          newPlans[i]['started'].toDate() !=
              widget.plans[i]['started'].toDate()) {
        setState(() {
          isPlanModified = true;
        });
        return;
      }
    }

    setState(() {
      isPlanModified = false;
    });
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
                newPlans.add(
                  {
                    'name': '',
                    'days': 0,
                    'started': Timestamp.now(),
                  },
                );
                planNameControllers.add(TextEditingController());
                planDaysControllers.add(TextEditingController());
              });
              isPlanModifiedFunc();
            },
          ),
        ],
      ),
      body: Form(
        autovalidateMode: AutovalidateMode.onUserInteraction,
        key: _formKey,
        child: ListView.builder(
          itemCount: newPlans.length,
          itemBuilder: (context, index) {
            final planNameController = planNameControllers[index];
            final planDaysController = planDaysControllers[index];
            final plan = newPlans[index];
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
                      icon:
                          const Icon(Icons.close, color: Colors.red, size: 20),
                      onPressed: () {
                        setState(() {
                          // ask dialog
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text('Delete Plan'),
                                content: const Text(
                                    'Are you sure you want to delete this plan?'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: const Text('No'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        newPlans.removeAt(index);
                                        planNameControllers[index].dispose();
                                        planDaysControllers[index].dispose();
                                        planNameControllers.removeAt(index);
                                        planDaysControllers.removeAt(index);
                                      });
                                      Navigator.pop(context);

                                      isPlanModifiedFunc();
                                    },
                                    child: const Text('Yes'),
                                  ),
                                ],
                              );
                            },
                          );
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: Card(
                      elevation: 10,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: width * 0.04,
                          vertical: height * 0.02,
                        ),
                        child: Column(
                          children: [
                            if (plan['old'] != null && plan['old'] == true)
                              Container(
                                margin: EdgeInsets.only(bottom: height * 0.02),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Current Day:',
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                      ),
                                    ),
                                    Text(
                                      // today - started + 1
                                      '${(DateTime.now().difference(plan['started'].toDate()).inDays + 1) > plan['days'] ? 'Expired' : (DateTime.now().difference(plan['started'].toDate()).inDays + 1)}',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: (DateTime.now()
                                                        .difference(
                                                            plan['started']
                                                                .toDate())
                                                        .inDays +
                                                    1) >
                                                plan['days']
                                            ? Colors.red
                                            : Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            GestureDetector(
                              onTap: () async {
                                final selected = await showDatePicker(
                                  context: context,
                                  initialDate: plan['started'].toDate(),
                                  firstDate: DateTime.now()
                                      .subtract(const Duration(days: 13 * 365)),
                                  lastDate: DateTime.now(),
                                );
                                if (selected != null) {
                                  final selectedTime = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.now(),
                                  );
                                  if (selectedTime != null) {
                                    setState(() {
                                      DateTime selectedDateTime = DateTime(
                                        selected.year,
                                        selected.month,
                                        selected.day,
                                        selectedTime.hour,
                                        selectedTime.minute,
                                      );
                                      plan['started'] =
                                          Timestamp.fromDate(selectedDateTime);
                                    });
                                    isPlanModifiedFunc();
                                  }
                                }
                              },
                              child: Container(
                                margin: EdgeInsets.only(bottom: height * 0.02),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Plan Start:',
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                      ),
                                    ),
                                    Text(
                                      formatDate(
                                        plan['started'].toDate(),
                                      ),
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (plan['old'] != null && plan['old'] == true)
                              Container(
                                margin: EdgeInsets.only(bottom: height * 0.02),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Plan End:',
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                      ),
                                    ),
                                    Text(
                                      formatDate(
                                        plan['started'].toDate().add(
                                              Duration(
                                                days: plan['days'],
                                              ),
                                            ),
                                      ),
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: TextFormField(
                                    controller: planNameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Plan Name',
                                      contentPadding: EdgeInsets.only(left: 10),
                                    ),
                                    onChanged: (value) {
                                      isPlanModifiedFunc();
                                    },
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter a plan name';
                                      } else if (value.length < 3) {
                                        return 'Plan name must be atleast 3 characters long';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                SizedBox(
                                  width: width * 0.1,
                                ),
                                Expanded(
                                  flex: 1,
                                  child: TextFormField(
                                    controller: planDaysController,
                                    decoration: const InputDecoration(
                                      labelText: 'Days',
                                      contentPadding: EdgeInsets.only(left: 10),
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Empty';
                                      } else if (int.parse(value) < 1) {
                                        return '> 1';
                                      } else {
                                        return null;
                                      }
                                    },
                                    onChanged: (value) {
                                      isPlanModifiedFunc();
                                      debugPrint(
                                          'newPlans: ${newPlans.toString()}');
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
          },
        ),
      ),
      floatingActionButton: newPlans.isNotEmpty && isPlanModified
          ? FloatingActionButton(
              child: const Icon(Icons.save),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  if (!await Method.checkInternetConnection(context)) {
                    return;
                  }
                  try {
                    // remove 'old' key if exists
                    for (int i = 0; i < newPlans.length; i++) {
                      if (newPlans[i]['old'] != null) {
                        newPlans[i].remove('old');
                      }
                      newPlans[i]['name'] = planNameControllers[i].text;
                      newPlans[i]['days'] =
                          int.parse(planDaysControllers[i].text);
                    }
                    await FirebaseFirestore.instance
                        .collection('Users')
                        .doc(widget.uid)
                        .update({
                      'plans': newPlans,
                    });
                    Navigator.pop(context);
                    Flushbar(
                      margin: const EdgeInsets.all(7),
                      borderRadius: BorderRadius.circular(15),
                      flushbarStyle: FlushbarStyle.FLOATING,
                      flushbarPosition: FlushbarPosition.BOTTOM,
                      message: "Plan updated successfully",
                      icon: Icon(
                        Icons.check_circle_outline_rounded,
                        size: 28.0,
                        color: Colors.green[300],
                      ),
                      duration: const Duration(milliseconds: 1500),
                      leftBarIndicatorColor: Colors.green[300],
                    ).show(context);
                  } catch (e) {
                    debugPrint(e.toString());
                    Flushbar(
                      margin: const EdgeInsets.all(7),
                      borderRadius: BorderRadius.circular(15),
                      flushbarStyle: FlushbarStyle.FLOATING,
                      flushbarPosition: FlushbarPosition.BOTTOM,
                      message: "Error updating user data",
                      icon: Icon(
                        Icons.error_outline_rounded,
                        size: 28.0,
                        color: Colors.red[300],
                      ),
                      duration: const Duration(milliseconds: 1500),
                      leftBarIndicatorColor: Colors.red[300],
                    ).show(context);
                  }
                }
              },
            )
          : null,
    );
  }
}
