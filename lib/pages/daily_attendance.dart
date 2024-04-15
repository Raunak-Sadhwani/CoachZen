import 'dart:async';
import 'dart:convert';

import 'package:another_flushbar/flushbar.dart';
import 'package:coach_zen/pages/body_form_cust.dart';
import 'package:coach_zen/pages/cust_order_form.dart';
import 'package:coach_zen/pages/home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../components/ui/appbar.dart';
import 'package:data_table_2/data_table_2.dart';

final DateFormat format = DateFormat('dd MMM yyyy');
final DateTime today = DateTime.now();
const int shakePrice = 240;

// capitalize first letter of a string
String capitalize(String value) {
  return value
      .split(' ')
      .map((word) => word[0].toUpperCase() + word.substring(1))
      .join(' ');
}

class DailyAttendance extends StatefulWidget {
  const DailyAttendance({super.key});

  @override
  State<DailyAttendance> createState() => _DailyAttendanceState();
}

class _DailyAttendanceState extends State<DailyAttendance> {
  StreamSubscription? _streamSubscription;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  // scaffold key
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final String cid = FirebaseAuth.instance.currentUser!.uid;
  final DatabaseReference coachDb =
      FirebaseDatabase.instance.ref().child('Coaches');
  late Stream mystream;
  List<dynamic> users = [];
  DateTime selectedDate = DateTime.now();
  List<Map<dynamic, dynamic>> clubFees = [];
  List<Map<dynamic, dynamic>> homeProgram = [];
  Map<String, String> studentsNameUID = {};
  Map<dynamic, dynamic> presentStudentsUID = {};
  Map<dynamic, dynamic> reminderList = {};
  bool isEdit = false;
  int zdays = 0;
  int revenue = 0;
  int datas = 0;
  String initalPlan = '0 day';
  TextEditingController amount = TextEditingController();
  TextEditingController customPlan = TextEditingController();
  TextEditingController customPlanDays = TextEditingController();
  String initalMode = 'Cash';
  bool submitted = false;
  Color studentBox = const Color.fromARGB(255, 189, 189, 189);
  List<Map<dynamic, dynamic>> sortedPresentStudents = [];
  late String formattedDate;
  final double screenWidth = (WidgetsBinding
          .instance.platformDispatcher.views.first.physicalSize.width) /
      1.35;

  void changeSubmitted(bool val) {
    setState(() {
      submitted = val;
    });
  }

  @override
  void initState() {
    super.initState();
    // Force landscape orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    initializeData();
  }

  Future<void> initializeData() async {
    // Set up data listener and wait for initial data to be fetched
    await setupDataListener(selectedDate);

    // print('7 initialized');
  }

  Future<void> setupDataListener(DateTime selectedDate) async {
    // Close the previous listener if it exists
    _streamSubscription?.cancel();
    formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
    setState(() {
      sortedPresentStudents = [];
    });

    mystream = coachDb.child(cid).onValue;
    final completer = Completer<void>();
    // final event = await mystream.first;
    // Set up the new listener
    _streamSubscription = mystream.listen((event) {
      try {
        if (mounted) {
          datas += 1;
          debugPrint('got data - $datas');
          final eventData = event.snapshot.value;

// Process attendance data
          final attendanceData = eventData['attendance'] != null
              ? eventData['attendance'][formattedDate]
              : null;
          final presentStudents = attendanceData != null
              ? Map<dynamic, dynamic>.from(attendanceData['students'] ?? {})
              : {};

          List<Map<dynamic, dynamic>> tempSortedPresentStudents = [];

          // if any presentStudents has value['shake'] more than 1, again add to the sortedPresentStudents
          presentStudents.forEach((studentId, studentData) {
            // Check if shakes > 1
            if ((studentData['shakes'] as int) > 1) {
              // Add student twice if shakes > 1
              tempSortedPresentStudents.add({
                'id': studentId,
                'time': studentData['time'],
                'home': true,
              });
              tempSortedPresentStudents.add({
                'id': studentId,
                'time': studentData['time'],
                'second': true,
              });
            } else {
              // Add student once if shakes <= 1
              tempSortedPresentStudents.add({
                'id': studentId,
                'time': studentData['time'],
              });
            }
          });
          final List<Map<dynamic, dynamic>> sortedPresentStudentsx =
              tempSortedPresentStudents;

          // Process users data
          final usersData = eventData['users'] ?? {};
          final updatedUsers = usersData.entries.map((entry) {
            final key = entry.key;
            final userData = entry.value;
            studentsNameUID[key] = userData['name'];
            int totalDays = -1;

            // Iterate through entries in 'days' map
            (userData['days'] as Map?)?.forEach((key, value) {
              // Convert key to date
              final keyDate = DateTime.parse(key);

              // Check if key date is before or at the same moment as selected date
              if (keyDate.isBefore(selectedDate) ||
                  keyDate.isAtSameMomentAs(selectedDate)) {
                totalDays += (value['shakes'] as int);
              }
            });

            // final userPayments = Map.from(userData['payments'] ?? {});
            // get all payments till selected date
            int amountPaidTillNow = 0;
            int day0PaidTillNow = 0;
            int day3PaidTillNow = 0;
            final Map<dynamic, dynamic> payments = userData['payments'] ?? {};
            if (payments.isNotEmpty) {
              payments.forEach((key, value) {
                final paymentDate = DateTime.parse(key);
                if (paymentDate.isBefore(selectedDate) ||
                    paymentDate.isAtSameMomentAs(selectedDate)) {
                  amountPaidTillNow += value['totalAmount'] as int;
                  for (String planKey in value.keys) {
                    if (planKey != 'totalAmount') {
                      final planData = value[planKey];
                      if (planData['program'] == '0 day') {
                        day0PaidTillNow += planData['amount'] as int;
                      } else if (planData['program'] == '3 day') {
                        day3PaidTillNow += planData['amount'] as int;
                      }
                    }
                  }
                }
              });
            }

            String rePlanName = '';
            String planStatus = '';
            String? image = userData['image'];
            final String uid = key;
            String gender = userData['gender'];

            final int userDays = userData['days'].keys.length;

            if (userData['existed'] != null) {
              rePlanName = 'Not Started';
              planStatus = 'No Plans';
            }

            if (userData['plans'] != null) {
              bool existingPlan = false;
              int tempAllPlanDays = 4;
              List sortAllKeys = userData['plans'].keys.toList();
              sortAllKeys.sort((a, b) => a.compareTo(b));
              // final allDaysMap = user['days'];
              // check if today's date comes in between any plan
              for (String key in sortAllKeys) {
                final plan = userData['plans'][key];
                rePlanName = plan['program'];
                // final planDate = DateTime.parse(key);
                final int planDays = plan['days'] as int;
                tempAllPlanDays += planDays;
                // debugPrint('Existing Plan: $existingPlan');
                if (userDays <= tempAllPlanDays) {
                  existingPlan = true;
                  final int daysLeft = tempAllPlanDays - userDays;
                  planStatus =
                      daysLeft > 0 ? '$daysLeft days left' : 'Expires today';
                  if (daysLeft < 7) {
                    reminderList[uid] = {
                      'name': userData['name'],
                      'phone': '+91${userData['phone']}',
                      'planName': rePlanName,
                      'planColor': 'orange',
                      'planStatus': planStatus,
                      'gender': gender,
                      'image': image,
                    };
                  }
                  break;
                }
              }
              if (!existingPlan) {
                planStatus = 'Expired';
                reminderList[uid] = {
                  'name': userData['name'],
                  'phone': '+91${userData['phone']}',
                  'planName': rePlanName,
                  'planColor': 'red',
                  'planStatus': planStatus,
                  'gender': gender,
                  'image': image,
                };
              }
            }

            return {
              'id': key,
              'name': userData['name'],
              'phone': userData['phone'],
              'paid': userData['paid'],
              'productsHistory': List<Map<dynamic, dynamic>>.from(
                  userData['productsHistory'] ?? []),
              'days': userData['days'],
              'payments': userData['payments'],
              'homeProgram': userData['homeProgram'],
              'advancedPayments': userData['advancedPayments'],
              'totalDays': totalDays,
              'amountPaidTillNow': {
                'total': amountPaidTillNow,
                '0 day': day0PaidTillNow,
                '3 day': day3PaidTillNow,
              },
              'plansPaid': userData['plansPaid'],
              'plans': userData['plans'],
              'onHomeProgram': userData['homeProgram'] != null &&
                  userData['homeProgram'][formattedDate] != null,
              'gender': userData['gender'],
              'image': userData['image'],
            };
          }).toList();

          // process home program data
          final homeProgramData = eventData['attendance'] != null
              ? eventData['attendance'][formattedDate]
              : null;

          List<Map<dynamic, dynamic>> homeProgramx = [];
          if (homeProgramData != null &&
              homeProgramData['homeProgram'] != null) {
            homeProgramx = List<Map<dynamic, dynamic>>.from(
                homeProgramData['homeProgram'].values);
          }

          // Update state
          setState(() {
            users = updatedUsers;
            homeProgram = homeProgramx;
            presentStudentsUID = presentStudents;
            sortedPresentStudents = sortedPresentStudentsx;
            zdays = presentStudents.keys
                .where((student) =>
                    users.firstWhere(
                        (user) => user['id'] == student)['totalDays'] ==
                    0)
                .length;
            clubFees = [];
            revenue = 0;
          });

          // sort the present students
          sortedPresentStudents.sort((a, b) {
            final int timeA = a['time'];
            final int timeB = b['time'];
            return timeB.compareTo(timeA);
          });

          // Process club fees data
          final clubFeesData =
              attendanceData != null ? attendanceData['fees'] : null;
          if (clubFeesData != null) {
            final clubFeesDataMap = Map<String, dynamic>.from(clubFeesData);
            clubFeesDataMap.forEach((key, clubFeeData) {
              setState(() {
                clubFees.add({
                  'uid': clubFeeData['uid'],
                  'program': clubFeeData['program'],
                  'mode': clubFeeData['mode'],
                  'amount': clubFeeData['amount'],
                  'balance': clubFeeData['balance'],
                  'paymentId': key,
                  'planId': clubFeeData['planId'],
                  'advancedPayment': clubFeeData['advancedPayment'],
                });
                revenue += clubFeeData['amount'] as int;
              });
            });
          }
          if (!completer.isCompleted) {
            completer
                .complete(); // Resolve the Completer when the first event is received
          }
        }
      } catch (e) {
        Flushbar(
          margin: const EdgeInsets.all(7),
          borderRadius: BorderRadius.circular(15),
          flushbarStyle: FlushbarStyle.FLOATING,
          flushbarPosition: FlushbarPosition.TOP,
          message: "Unable to get data. Please check your internet connection",
          icon: Icon(
            Icons.error_outline_rounded,
            size: 28.0,
            color: Colors.red[300],
          ),
          duration: const Duration(milliseconds: 3000),
          leftBarIndicatorColor: Colors.red[300],
        ).show(scaffoldKey.currentContext!);
      }
    });
    await completer.future;
    debugPrint('Data listener initialized');
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _streamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final ScreenHeight = MediaQuery.of(context).size.height;
    return OrientationBuilder(
      builder: (context, orientation) {
        return Scaffold(
          key: scaffoldKey,
          appBar: MyAppBar(
            leftIcon: Container(
              margin: const EdgeInsets.only(left: 10),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.grey,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  // Navigator.pushAndRemoveUntil(
                  //     context,
                  //     MaterialPageRoute(builder: (context) => const HomePage()),
                  //     (Route<dynamic> route) => false);
                },
              ),
            ),
            ftitle: TextButton(
              child: Text(
                format.format(selectedDate),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              onPressed: () {
                //  open date picker
                showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2023),
                        // one month ahead
                        lastDate: today.add(const Duration(days: 50)))
                    .then((date) async {
                  if (date != null) {
                    setState(() {
                      selectedDate = date;
                    });
                    await setupDataListener(selectedDate);
                    debugPrint('Date changed to $selectedDate');
                  }
                });
              },
            ),
            rightIcons: [
              IconButton(
                icon: const Icon(
                  Icons.file_download_outlined,
                  color: Colors.grey,
                ),
                onPressed: () {
                  //  export to excel
                  Flushbar(
                    margin: const EdgeInsets.all(7),
                    borderRadius: BorderRadius.circular(15),
                    flushbarStyle: FlushbarStyle.FLOATING,
                    flushbarPosition: FlushbarPosition.TOP,
                    message:
                        "${format.format(selectedDate)} data exported to excel",
                    icon: Icon(
                      Icons.check_circle_outline,
                      size: 28.0,
                      color: Colors.green[300],
                    ),
                    duration: const Duration(milliseconds: 2000),
                    leftBarIndicatorColor: Colors.green[300],
                  ).show(context);
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.history_rounded,
                  color: Colors.grey,
                ),
                onPressed: () {
                  //  open history page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DailyDetails(
                        selectedDate: selectedDate,
                        clubFees: clubFees,
                        studentsNameUID: studentsNameUID,
                        zdays: zdays.toString(),
                        shakes: presentStudentsUID.length.toString(),
                        revenue: revenue.toString(),
                        homeProgram: homeProgram,
                        users: users,
                      ),
                    ),
                  );
                },
              ),
              // edit button
              IconButton(
                icon: Icon(
                  isEdit ? Icons.edit_off_rounded : Icons.edit_rounded,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    isEdit = !isEdit;
                  });
                },
              ),
              // add new present student
              IconButton(
                icon: const Icon(
                  Icons.person_add_alt_rounded,
                  color: Colors.grey,
                ),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NewCustWrapper(
                        attendance: true,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // 1. search for the user
              Padding(
                padding: EdgeInsets.only(
                  left: screenWidth * 0.02,
                  right: screenWidth * 0.02,
                  top: screenWidth * 0.01,
                ),
                child: Container(
                  margin: EdgeInsets.only(bottom: screenWidth * 0.02),
                  child: TypeAheadField(
                    direction: AxisDirection.up,
                    textFieldConfiguration: TextFieldConfiguration(
                      autofocus: true,
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          vertical: screenWidth * 0.01,
                          horizontal:
                              screenWidth * 0.02, // Add horizontal padding
                        ),
                        isDense: true,
                        labelText: 'Student Name',
                        // border color grey
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: studentBox,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: studentBox,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: studentBox,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    minCharsForSuggestions: 1,
                    hideOnEmpty: true,
                    // Suggestions callback for TypeAheadField
                    suggestionsCallback: (pattern) {
                      if (users.isNotEmpty) {
                        return users
                            .where((user) =>
                                user['name']
                                    .toString()
                                    .toLowerCase()
                                    .contains(pattern.toLowerCase()) ||
                                user['phone']
                                    .toString()
                                    .toLowerCase()
                                    .contains(pattern.toLowerCase()))
                            .map((user) => {
                                  'id': user['id'],
                                  'name': user['name'],
                                })
                            .toList();
                      } else {
                        return [];
                      }
                    },
                    itemBuilder: (context, suggestion) {
                      return ListTile(
                        title: Text(
                          suggestion['name'],
                          maxLines: 1,
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      );
                    },
                    onSuggestionSelected: (suggestion) async {
                      String selectedUserId = suggestion['id'];

                      // bool doubleShake = false;
                      if (presentStudentsUID.keys.contains(selectedUserId)) {
                        final user = users
                            .firstWhere((user) => user['id'] == selectedUserId);
                        // check if user is in home program today
                        if (user['onHomeProgram'] &&
                            user['days'][formattedDate]['shakes'] == 1) {
                          // confirm if double shake
                          bool? result = await showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Confirmation'),
                                  content: Text(
                                      'Are you sure you want to add "${suggestion['name'].split(' ')[0]}" "again" to the attendance list? It will add second shake to that day.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop(false);
                                      },
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        Navigator.of(context).pop(true);
                                      },
                                      child: const Text('Add'),
                                    ),
                                  ],
                                );
                              });
                          if (result == false) {
                            return;
                          }
                        } else {
                          return;
                        }
                      }
                      if (submitted) {
                        return;
                      }
                      changeSubmitted(true);
                      // add to firebase
                      try {
                        final DatabaseReference dbRef = coachDb.child(cid);
                        const time = ServerValue.timestamp;
                        Map<String, dynamic> updates = {
                          'attendance/$formattedDate/students/$selectedUserId':
                              {
                            'time': time,
                            'shakes': ServerValue.increment(1),
                          },
                          'users/$selectedUserId/days/$formattedDate': {
                            'time': time,
                            'shakes': ServerValue.increment(1),
                          }
                        };
                        await dbRef.update(updates);
                        changeSubmitted(false);
                      } catch (e) {
                        Flushbar(
                          margin: const EdgeInsets.all(7),
                          borderRadius: BorderRadius.circular(15),
                          flushbarStyle: FlushbarStyle.FLOATING,
                          flushbarPosition: FlushbarPosition.TOP,
                          message:
                              "Error adding $suggestion to the attendance list",
                          icon: Icon(
                            Icons.error_outline_rounded,
                            size: 28.0,
                            color: Colors.red[300],
                          ),
                          duration: const Duration(milliseconds: 3000),
                          leftBarIndicatorColor: Colors.red[300],
                        ).show(scaffoldKey.currentContext!);
                        changeSubmitted(false);
                      }
                    },
                  ),
                ),
              ),
              Expanded(
                child: DataTable2(
                  columnSpacing: screenWidth * 0.02,
                  horizontalMargin: screenWidth * 0.02,
                  border: TableBorder.all(
                    color: Colors.black12,
                    width: 1,
                  ),
                  headingTextStyle: GoogleFonts.raleway(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  dataTextStyle: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                  headingRowHeight: screenWidth * 0.045,
                  dataRowHeight: screenWidth * 0.045,
                  headingRowColor: MaterialStateProperty.all(Colors.grey[200]),
                  dividerThickness: 1.5,
                  minWidth: screenWidth * 0.01,
                  columns: <DataColumn2>[
                    const DataColumn2(
                      label: Text('No'),
                      size: ColumnSize.S,
                    ),
                    const DataColumn2(
                      label: Text('Name'),
                      size: ColumnSize.L,
                    ),
                    const DataColumn2(
                      label: Text('Type'),
                      size: ColumnSize.S,
                    ),
                    const DataColumn2(
                      label: Text('Days'),
                      size: ColumnSize.S,
                    ),
                    const DataColumn2(
                      label: Text('Balance'),
                      size: ColumnSize.S,
                    ),
                    if (isEdit)
                      const DataColumn2(
                        label: Text('Delete'),
                        size: ColumnSize.S,
                      ),
                  ],
                  // check why sortedPresentStudents is regenerating
                  rows: List<DataRow>.generate(sortedPresentStudents.length,
                      (index) {
                    debugPrint('Index init: $index');

                    final user = users.firstWhere((user) =>
                        user['id'] == sortedPresentStudents[index]['id']);
                    String id = user['id'];
                    String name = user['name'];
                    int amountPaidTillNow = user['amountPaidTillNow']['total'];
                    int day = user['totalDays'];
                    bool onHomeProgram = user['onHomeProgram'];
                    String sno = (index + 1).toString();
                    // check if 'home' is true
                    bool isHome = sortedPresentStudents[index]['home'] != null;
                    bool isSecond =
                        sortedPresentStudents[index]['second'] != null;
                    if ((isHome || onHomeProgram) && !isSecond) {
                      sno += ' (H)';
                      if (isHome) {
                        day -= 1;
                      }
                    }
                    final gotPlan = getPlan(day);
                    int totalBalance = gotPlan['balance'];
                    int realBalance = totalBalance - amountPaidTillNow;
                    String balance = realBalance.toString();
                    String days = gotPlan['day'];
                    String planName = gotPlan['plan'];
                    Map<String, int> allBalances = {};
                    Map<String, int> actualBalances = {};
                    Map<String, String> prevPlanBalances = {};
                    bool existingPlan = false;
                    String? planDate;
                    int planDays = 0;
                    int tempAllPlanDays = 4;
                    final bool advancedPaymentx =
                        user['advancedPayments'] != null &&
                            user['advancedPayments']['pid'] != null;

                    if (day > 4) {
                      final day0 = user['amountPaidTillNow']['0 day'] ?? 0;
                      final day3 = user['amountPaidTillNow']['3 day'] ?? 0;
                      if (day0 < 200) {
                        int tempBal = 200 - (day0 as int);
                        allBalances['0 day'] = tempBal;
                      }
                      if (day3 < 720) {
                        int tempBal = 720 - (day3 as int);
                        allBalances['3 day'] = tempBal;
                      }
                      final plansPaid = user['plansPaid'];
                      if (plansPaid != null) {
                        final actDay0 = plansPaid['0 day'] ?? 0;
                        final actDay3 = plansPaid['3 day'] ?? 0;
                        if (actDay0 < 200) {
                          int tempBal = 200 - (actDay0 as int);
                          actualBalances['0 day'] = tempBal;
                        }
                        if (actDay3 < 720) {
                          int tempBal = 720 - (actDay3 as int);
                          actualBalances['3 day'] = tempBal;
                        }
                      } else {
                        actualBalances['0 day'] = 200;
                        actualBalances['3 day'] = 720;
                      }

                      if (user['plans'] != null) {
                        List sortAllKeys = user['plans'].keys.toList();
                        sortAllKeys.sort((a, b) => a.compareTo(b));
                        int allPlansCost = 0;
                        // final allDaysMap = user['days'];
                        // check if today's date comes in between any plan
                        for (String key in sortAllKeys) {
                          final plan = user['plans'][key];
                          // final planDate = DateTime.parse(key);
                          planDays = plan['days'] as int;
                          allPlansCost += planDays * shakePrice;
                          tempAllPlanDays += planDays;

                          // debugPrint('Existing Plan: $existingPlan');
                          if (user['totalDays'] <= tempAllPlanDays) {
                            final program = plan['program'];
                            existingPlan = true;
                            planDate = key;
                            int cDay = day - (tempAllPlanDays - planDays);
                            final int planStartDay =
                                (tempAllPlanDays - planDays) + 1;
                            final List userDates = user['days'].keys.toList();
                            userDates.sort((a, b) => a.compareTo(b));

                            if (planDate != userDates[planStartDay]) {
                              final String newDate = userDates[planStartDay];
                              String paymentId = plan['payments'].keys.first;
                              String paymentDate = plan['payments'][paymentId];
                              final Map<String, dynamic> updates = {
                                'users/$id/plans/$planDate': null,
                                'users/$id/plans/$newDate': plan,
                                'users/$id/plansPaid/$program/$planDate': null,
                                'users/$id/plansPaid/$program/$newDate':
                                    user['plansPaid'][program][planDate],
                                'attendance/$paymentDate/fees/$paymentId/planId':
                                    newDate,
                                'users/$id/payments/$paymentDate/$paymentId/planId':
                                    newDate,
                              };
                              coachDb.child(cid).update(updates);
                            }

                            final gotNewPlan = getPlan(cDay,
                                assignedPlanDays: planDays, planName: program);
                            days = gotNewPlan['day'];
                            planName = gotNewPlan['plan'];
                            const int fiveDayCost = 920;
                            realBalance = (allPlansCost + fiveDayCost) -
                                amountPaidTillNow;
                            debugPrint('$amountPaidTillNow sd');
                            balance = realBalance.toString();
                            debugPrint('New Plan: $amountPaidTillNow');
                            break;
                          }
                        }

                        if (plansPaid != null) {
                          final Map<dynamic, dynamic> plans = user['plans'];

                          for (String key in plans.keys) {
                            int bal = plans[key]['balance'] as int;
                            String planName = plans[key]['program'];
                            if (bal != 0) {
                              actualBalances[planName] = bal;
                              prevPlanBalances[planName] = key;
                            }
                            int planPaid = 0;
                            Map<dynamic, dynamic> planPaymentDates =
                                Map.from(plans[key]['payments'] ?? {});
                            // remove any date after today
                            planPaymentDates.removeWhere((key, value) {
                              final planPaymentDate = DateTime.parse(value);
                              return planPaymentDate.isAfter(selectedDate);
                            });
                            if (planPaymentDates.isNotEmpty) {
                              for (String key in planPaymentDates.keys) {
                                final paymentId = key;
                                final datex = planPaymentDates[key];
                                planPaid += user['payments'][datex][paymentId]
                                    ['amount'] as int;
                              }
                            }

                            int planCost =
                                ((user['plans'][key]['days'] as int) *
                                    shakePrice);
                            final int finBal = planCost - planPaid;
                            if (finBal != 0) {
                              allBalances[plans[key]['program']] = finBal;
                            }
                          }
                        }

                        if (!existingPlan) {
                          final int currentDay = day - tempAllPlanDays;
                          if (currentDay == 1 && advancedPaymentx) {
                            // query to firebase to set plan
                            final DatabaseReference dbRef = coachDb.child(cid);
                            final Map<dynamic, dynamic> pid =
                                user['advancedPayments']['pid'];
                            final int pidAmount = pid['amount'] as int;
                            // remove amount from advanced payments
                            pid.remove('amount');
                            final String program = pid['program'];
                            final String paymentId = pid['payments'].keys.first;
                            final String paymentDate =
                                pid['payments'][paymentId];

                            final Map<String, dynamic> updates = {
                              'users/$id/plans/$formattedDate': pid,
                              'users/$id/plansPaid/$program/$formattedDate':
                                  pidAmount,
                              'users/$id/advancedPayments': null,
                              'attendance/$paymentDate/fees/$paymentId/planId':
                                  formattedDate,
                              'users/$id/payments/$paymentDate/$paymentId/planId':
                                  formattedDate,
                            };
                            dbRef.update(updates);
                          }
                          days = '$currentDay / $currentDay';
                          // actualBalances['Paid'] = (currentDay * shakePrice);
                          allBalances['Extra ${currentDay}days'] =
                              currentDay * shakePrice;
                        }
                      } else {
                        final int currentDay = day - tempAllPlanDays;
                        days = '$currentDay / $currentDay';
                        // actualBalances['Paid'] = (currentDay * shakePrice);
                        allBalances['Extra ${currentDay}days'] =
                            currentDay * shakePrice;
                      }
                    }
                    return DataRow(
                      cells: <DataCell>[
                        DataCell(
                          Text(sno),
                        ),
                        DataCell(
                          // get name from users list
                          Text(name),
                          onLongPress: () {
                            // 4. edit the user
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title:
                                      Text('${name.split(' ')[0]}\'s Action'),
                                  content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: double.infinity,
                                          child: TextButton(
                                              onPressed: () {
                                                List<String> plans = [];
                                                List checkWrongValues = [
                                                  '0 day',
                                                  '0 d',
                                                  '0 dy',
                                                  '0 da',
                                                  '0 days',
                                                  '3 day',
                                                  '3 d',
                                                  '3 dy',
                                                  '3 da',
                                                  '3 days',
                                                ];
                                                if (actualBalances.isNotEmpty) {
                                                  bool previousPlanBalance =
                                                      false;
                                                  for (String key
                                                      in actualBalances.keys) {
                                                    if (actualBalances[key]! >
                                                        0) {
                                                      if (!checkWrongValues
                                                          .contains(key)) {
                                                        previousPlanBalance =
                                                            true;
                                                      }
                                                      plans.add(
                                                          "$key (Remaining - ₹${actualBalances[key]})");
                                                    }
                                                  }
                                                  if (!existingPlan &&
                                                      !previousPlanBalance) {
                                                    plans.addAll([
                                                      'Gold UMS',
                                                      'Plat UMS',
                                                      'Other'
                                                    ]);
                                                  }
                                                } else {
                                                  String zeroDay = '0 day';
                                                  String threeDay = '3 day';

                                                  bool zeroDayValid =
                                                      user['plansPaid'] !=
                                                              null &&
                                                          user['plansPaid']
                                                                  ['0 day'] !=
                                                              null;
                                                  bool zeroDayOver =
                                                      zeroDayValid &&
                                                          user['plansPaid']
                                                                  ['0 day'] >=
                                                              200;

                                                  if (!zeroDayOver) {
                                                    zeroDay +=
                                                        ' (Remaining - ₹${zeroDayValid ? 200 - user['plansPaid']['0 day'] : 200})';
                                                    plans.add(zeroDay);
                                                  }

                                                  bool threeDayValid =
                                                      user['plansPaid'] !=
                                                              null &&
                                                          user['plansPaid']
                                                                  ['3 day'] !=
                                                              null;
                                                  bool threeDayOver =
                                                      threeDayValid &&
                                                          user['plansPaid']
                                                                  ['3 day'] >=
                                                              720;
                                                  if (!threeDayOver) {
                                                    threeDay +=
                                                        ' (Remaining - ₹${threeDayValid ? 720 - user['plansPaid']['3 day'] : 720})';
                                                  }

                                                  if (day <= 1) {
                                                    if (zeroDayOver &&
                                                        !threeDayOver) {
                                                      plans.add(threeDay);
                                                    } else if (zeroDayOver &&
                                                        threeDayOver) {
                                                      plans.addAll([
                                                        'Gold UMS',
                                                        'Plat UMS',
                                                        'Other'
                                                      ]);
                                                    }
                                                  } else if (day <= 4) {
                                                    if (!threeDayOver) {
                                                      plans.add(threeDay);
                                                      plans.addAll(['Other']);
                                                    } else {
                                                      plans.addAll([
                                                        'Gold UMS',
                                                        'Plat UMS',
                                                        'Other'
                                                      ]);
                                                    }
                                                  } else {
                                                    if (!threeDayOver) {
                                                      plans.add(threeDay);
                                                    }
                                                    plans.addAll([
                                                      'Gold UMS',
                                                      'Plat UMS',
                                                      'Other'
                                                    ]);
                                                  }
                                                }

                                                setState(() {
                                                  initalPlan = plans[0];
                                                });

                                                // open a new dialog to enter the cash amount
                                                Navigator.of(context).pop();

                                                showDialog(
                                                  barrierDismissible: true,
                                                  context: context,
                                                  builder: (BuildContext cxt) {
                                                    List<
                                                            DropdownMenuItem<
                                                                String>>?
                                                        planItemsx = plans.map(
                                                            (String value) {
                                                      return DropdownMenuItem<
                                                          String>(
                                                        value: value,
                                                        child: Text(value),
                                                      );
                                                    }).toList();
                                                    return StatefulBuilder(
                                                        builder: (context,
                                                            setState) {
                                                      return SingleChildScrollView(
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(16),
                                                          child: Material(
                                                            // color: Colors.green,
                                                            shape: RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            15)),
                                                            child: Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(16),
                                                              child: Column(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                children: [
                                                                  Row(
                                                                    children: [
                                                                      Expanded(
                                                                          child:
                                                                              Container(
                                                                        margin: const EdgeInsets
                                                                            .only(
                                                                            bottom:
                                                                                10),
                                                                        child:
                                                                            const Text(
                                                                          'Club Fees 💵',
                                                                          style: TextStyle(
                                                                              fontSize: 16,
                                                                              fontWeight: FontWeight.w600,
                                                                              color: Colors.greenAccent),
                                                                        ),
                                                                      )),
                                                                    ],
                                                                  ),
                                                                  Form(
                                                                    key:
                                                                        formKey,
                                                                    autovalidateMode:
                                                                        AutovalidateMode
                                                                            .onUserInteraction,
                                                                    child:
                                                                        Column(
                                                                      children: [
                                                                        Row(
                                                                          children: [
                                                                            Expanded(
                                                                              child: TextFormField(
                                                                                keyboardType: TextInputType.number,
                                                                                controller: amount,
                                                                                validator: (value) {
                                                                                  String iniplan = initalPlan;
                                                                                  if (initalPlan.contains(' (')) {
                                                                                    iniplan = initalPlan.split(' (')[0].trim();
                                                                                  }
                                                                                  if (value == null || value.isEmpty) {
                                                                                    return 'Please enter the amount';
                                                                                  } else if (int.tryParse(value) == null) {
                                                                                    return 'Please enter a valid amount';
                                                                                  } else if (actualBalances.isNotEmpty && actualBalances[iniplan] != null) {
                                                                                    if (int.tryParse(value)! < 1) {
                                                                                      return 'Minimum amount is 1';
                                                                                    }

                                                                                    if (actualBalances[iniplan] != null) {
                                                                                      if (int.tryParse(value)! > actualBalances[iniplan]!) {
                                                                                        return 'Amount exceeds the remaining balance';
                                                                                      }
                                                                                    }
                                                                                  } else if (int.tryParse(value)! < 50) {
                                                                                    return 'Minimum amount is 50';
                                                                                  } else if (iniplan == '0 day' && int.tryParse(value)! > 200) {
                                                                                    return 'Maximum amount for 0 day is 200';
                                                                                  } else if (iniplan == '3 day' && int.tryParse(value)! > 720) {
                                                                                    return 'Maximum amount for 3 day is 720';
                                                                                  } else if (iniplan == 'Gold UMS' && int.tryParse(value)! > 7200) {
                                                                                    return 'Please enter a valid amount';
                                                                                  } else if (iniplan == 'Plat UMS' && int.tryParse(value)! > 9600) {
                                                                                    return 'Please enter a valid amount';
                                                                                  } else if (initalPlan == 'Other' && int.tryParse(customPlanDays.text.trim()) != null) {
                                                                                    if (int.tryParse(value)! > int.tryParse(customPlanDays.text.trim())! * shakePrice) {
                                                                                      return 'Plan cost exceeds the entered amount';
                                                                                    }
                                                                                  } else if (int.tryParse(value)! > 30000) {
                                                                                    return 'Please enter a valid amount';
                                                                                  }
                                                                                  return null;
                                                                                },
                                                                                decoration: const InputDecoration(
                                                                                  contentPadding: EdgeInsets.zero, // Remove any content padding
                                                                                  isDense: true,
                                                                                  labelText: 'Amount (₹)',
                                                                                ),
                                                                              ),
                                                                            ),
                                                                            const SizedBox(
                                                                              width: 10,
                                                                            ),
                                                                            // select plan dropdown
                                                                            Expanded(
                                                                              child: DropdownButtonFormField<String>(
                                                                                decoration: const InputDecoration(
                                                                                  contentPadding: EdgeInsets.zero, // Remove any content padding
                                                                                  isDense: true,
                                                                                  labelText: 'Mode',
                                                                                ),
                                                                                value: initalMode,
                                                                                items: [
                                                                                  'Cash',
                                                                                  'Online',
                                                                                  'Cheque',
                                                                                ].map((String value) {
                                                                                  return DropdownMenuItem<String>(
                                                                                    value: value,
                                                                                    child: Text(value),
                                                                                  );
                                                                                }).toList(),
                                                                                onChanged: (String? newValue) {
                                                                                  setState(() {
                                                                                    initalMode = newValue ?? '';
                                                                                  });
                                                                                },
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                        Row(
                                                                          children: [
                                                                            Expanded(
                                                                              flex: 2,
                                                                              child: DropdownButtonFormField<String>(
                                                                                decoration: const InputDecoration(
                                                                                  labelText: 'Program',
                                                                                ),
                                                                                value: initalPlan,
                                                                                items: planItemsx,
                                                                                onChanged: (String? newValue) {
                                                                                  debugPrint('New Value: $newValue');
                                                                                  setState(() {
                                                                                    initalPlan = newValue ?? '';
                                                                                  });
                                                                                },
                                                                              ),
                                                                            ),
                                                                            if (initalPlan ==
                                                                                'Other')
                                                                              Expanded(
                                                                                flex: 2,
                                                                                child: Container(
                                                                                  margin: const EdgeInsets.only(left: 10),
                                                                                  child: TextFormField(
                                                                                    controller: customPlan,
                                                                                    decoration: const InputDecoration(
                                                                                      labelText: 'Custom Plan',
                                                                                    ),
                                                                                    validator: (value) {
                                                                                      if (value == null || value.isEmpty) {
                                                                                        return 'Please enter the plan';
                                                                                      } else if (value.length < 3) {
                                                                                        return 'Please enter a valid plan';
                                                                                      } else if (checkWrongValues.contains(value)) {
                                                                                        return 'Please enter a valid plan';
                                                                                      }
                                                                                      return null;
                                                                                    },
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                            if (initalPlan ==
                                                                                'Other')
                                                                              Expanded(
                                                                                flex: 1,
                                                                                child: Container(
                                                                                  margin: const EdgeInsets.only(left: 10),
                                                                                  child: TextFormField(
                                                                                    controller: customPlanDays,
                                                                                    decoration: const InputDecoration(
                                                                                      labelText: 'Plan Days',
                                                                                    ),
                                                                                    validator: (value) {
                                                                                      if (value == null || value.isEmpty) {
                                                                                        return 'Please enter the plan';
                                                                                      } else if (int.tryParse(value) == null) {
                                                                                        return 'Please enter a valid plan';
                                                                                      } else if (int.tryParse(value)! < 1) {
                                                                                        return 'Please enter a valid plan';
                                                                                      } else if (int.tryParse(value)! > 51) {
                                                                                        return 'Please enter a valid plan';
                                                                                      }
                                                                                      return null;
                                                                                    },
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                          ],
                                                                        ),
                                                                        // 2 buttons
                                                                      ],
                                                                    ),
                                                                  ),
                                                                  Row(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .spaceAround,
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .center,
                                                                    children: [
                                                                      Expanded(
                                                                        child:
                                                                            TextButton(
                                                                          onPressed:
                                                                              () {
                                                                            Navigator.of(context).pop();
                                                                          },
                                                                          child:
                                                                              const Text('Cancel'),
                                                                        ),
                                                                      ),
                                                                      Expanded(
                                                                        child:
                                                                            TextButton(
                                                                          onPressed:
                                                                              () async {
                                                                            if (formKey.currentState!.validate() &&
                                                                                !submitted) {
                                                                              changeSubmitted(true);
                                                                              // save the data
                                                                              // save to firebase
                                                                              // add to firebase
                                                                              try {
                                                                                bool remaining = false;
                                                                                if (initalPlan == 'Other') {
                                                                                  initalPlan = customPlan.text.trim();
                                                                                } else {
                                                                                  // all text before (
                                                                                  if (initalPlan.toLowerCase().contains('remaining')) {
                                                                                    if (prevPlanBalances.isNotEmpty) {
                                                                                      remaining = true;
                                                                                      String firstkey = prevPlanBalances.keys.first;
                                                                                      planDate = prevPlanBalances[firstkey];
                                                                                    }
                                                                                  }
                                                                                  initalPlan = initalPlan.split(' (')[0];
                                                                                }
                                                                                initalPlan = initalPlan.toLowerCase();
                                                                                // balance
                                                                                const time = ServerValue.timestamp;
                                                                                final int payAmount = int.parse(amount.text.trim());
                                                                                final DatabaseReference dbRef = coachDb.child(cid);
                                                                                final String newPaymentId = FirebaseDatabase.instance.ref().push().key!;

                                                                                int days = 30;
                                                                                bool advancedPayment = false;
                                                                                int totalBal = realBalance - payAmount;
                                                                                String iniPlan = initalPlan.toString().toLowerCase();
                                                                                bool wrongPlan = iniPlan == '0 day' || iniPlan == '3 day';
                                                                                if (existingPlan || (!wrongPlan && remaining)) {
                                                                                  if (!wrongPlan && (totalBal < 0) && !remaining) {
                                                                                    bool? result = await showDialog(
                                                                                        context: context,
                                                                                        builder: (BuildContext context) {
                                                                                          return AlertDialog(
                                                                                            title: const Text('Confirmation'),
                                                                                            content: Text('Are you sure you want to add an advanced payment for "${name.split(' ')[0]}"? $initalPlan - ₹$payAmount'),
                                                                                            actions: [
                                                                                              TextButton(
                                                                                                onPressed: () {
                                                                                                  Navigator.of(context).pop(false);
                                                                                                },
                                                                                                child: const Text('Cancel'),
                                                                                              ),
                                                                                              TextButton(
                                                                                                onPressed: () {
                                                                                                  Navigator.of(context).pop(true);
                                                                                                },
                                                                                                child: const Text('Add'),
                                                                                              ),
                                                                                            ],
                                                                                          );
                                                                                        });
                                                                                    if (result != null && result) {
                                                                                      totalBal = realBalance;
                                                                                      if (initalPlan.toLowerCase() == 'gold ums') {
                                                                                        days = 30;
                                                                                      } else if (initalPlan.toLowerCase() == 'plat ums') {
                                                                                        days = 40;
                                                                                      } else {
                                                                                        days = int.parse(customPlanDays.text.trim());
                                                                                      }
                                                                                      advancedPayment = true;
                                                                                      final Map<dynamic, dynamic> userDays = user['days'];
                                                                                      final sortAllKeys = userDays.keys.toList();
                                                                                      sortAllKeys.sort((a, b) => a.compareTo(b));
                                                                                      final int checkDay = tempAllPlanDays + 1;
                                                                                      // check if sortAllKeys has the day
                                                                                      if (sortAllKeys.length > checkDay) {
                                                                                        planDate = sortAllKeys[checkDay];
                                                                                        existingPlan = false;
                                                                                      } else {
                                                                                        planDate = null;
                                                                                      }
                                                                                    } else {
                                                                                      changeSubmitted(false);
                                                                                      throw 'Advanced payment cancelled';
                                                                                    }
                                                                                  }
                                                                                } else if (!wrongPlan) {
                                                                                  // get 5th day of user and set the existing planDate
                                                                                  final Map<dynamic, dynamic> userDays = user['days'];
                                                                                  final sortAllKeys = userDays.keys.toList();
                                                                                  sortAllKeys.sort((a, b) => a.compareTo(b));
                                                                                  if (user['plans'] == null) {
                                                                                    planDate = sortAllKeys[5];
                                                                                  } else {
                                                                                    planDate = sortAllKeys[tempAllPlanDays + 1];
                                                                                  }

                                                                                  if (initalPlan.toLowerCase() == 'gold ums') {
                                                                                    days = 30;
                                                                                  } else if (initalPlan.toLowerCase() == 'plat ums') {
                                                                                    days = 40;
                                                                                  } else {
                                                                                    days = int.parse(customPlanDays.text.trim());
                                                                                  }
                                                                                  // throw '$planDate';
                                                                                  totalBal = (days * shakePrice) - payAmount;
                                                                                  try {
                                                                                    final plansPaid = user['plansPaid'];
                                                                                    if (plansPaid != null) {
                                                                                      final day0 = plansPaid['0 day'] ?? 0;
                                                                                      final day3 = plansPaid['3 day'] ?? 0;
                                                                                      if (day0 < 200) {
                                                                                        int tempBal = 200 - (day0 as int);
                                                                                        totalBal += tempBal;
                                                                                      }
                                                                                      if (day3 < 720) {
                                                                                        int tempBal = 720 - (day3 as int);
                                                                                        totalBal += tempBal;
                                                                                      }
                                                                                    } else {
                                                                                      totalBal += 920;
                                                                                    }
                                                                                  } catch (e) {
                                                                                    debugPrint('Error: $e');
                                                                                  }
                                                                                }
                                                                                Map<String, dynamic> updates = {
                                                                                  // Set club fees
                                                                                  'attendance/$formattedDate/fees/$newPaymentId': {
                                                                                    'uid': id,
                                                                                    'program': initalPlan,
                                                                                    'amount': payAmount,
                                                                                    'mode': initalMode,
                                                                                    'balance': totalBal,
                                                                                    'time': time,
                                                                                    'planId': existingPlan || !wrongPlan ? planDate : null,
                                                                                    'advancedPayment': advancedPayment ? true : null,
                                                                                  },
                                                                                  // Set user payments
                                                                                  'users/$id/payments/$formattedDate/$newPaymentId': {
                                                                                    'date': formattedDate,
                                                                                    'time': time,
                                                                                    'amount': payAmount,
                                                                                    'mode': initalMode,
                                                                                    'balance': totalBal,
                                                                                    'program': initalPlan,
                                                                                    'planId': existingPlan || !wrongPlan ? planDate : null,
                                                                                    'advancedPayment': advancedPayment ? true : null,
                                                                                  },
                                                                                  // test remaining
                                                                                  'users/$id/payments/$formattedDate/totalAmount': ServerValue.increment(payAmount),
                                                                                  'users/$id/paid': ServerValue.increment(payAmount),
                                                                                  // Increment user's total paid amount
                                                                                  'users/$id/plansPaid/$initalPlan': ServerValue.increment(payAmount),
                                                                                };

                                                                                if ((existingPlan && !wrongPlan) || (remaining && !wrongPlan)) {
                                                                                  if (!allBalances.containsKey(initalPlan) && !advancedPayment) {
                                                                                    changeSubmitted(false);
                                                                                    throw 'Plan not found';
                                                                                  }
                                                                                  updates.remove('users/$id/plansPaid/$initalPlan');
                                                                                  if (!advancedPayment) {
                                                                                    updates['users/$id/plans/$planDate/payments/$newPaymentId'] = formattedDate;
                                                                                    updates['users/$id/plans/$planDate/balance'] = ServerValue.increment(-payAmount);
                                                                                    updates['users/$id/plansPaid/$initalPlan/$planDate'] = ServerValue.increment(payAmount);
                                                                                    if (planDate == null) {
                                                                                      changeSubmitted(false);
                                                                                      throw 'Plan Date is null';
                                                                                    }
                                                                                  } else {
                                                                                    updates['users/$id/advancedPayments/pid'] = {
                                                                                      'time': time,
                                                                                      'program': initalPlan,
                                                                                      'payments': {
                                                                                        newPaymentId: formattedDate,
                                                                                      },
                                                                                      'days': days,
                                                                                      'balance': (days * shakePrice) - payAmount,
                                                                                      'amount': payAmount,
                                                                                    };
                                                                                    if (planDate != null) {
                                                                                      changeSubmitted(false);
                                                                                      throw 'Plan Date not null';
                                                                                    }
                                                                                  }
                                                                                  // check if other plan
                                                                                } else if (!wrongPlan) {
                                                                                  updates['users/$id/plans/$planDate'] = {
                                                                                    'time': time,
                                                                                    'program': initalPlan,
                                                                                    'payments': {
                                                                                      newPaymentId: formattedDate,
                                                                                    },
                                                                                    'days': days,
                                                                                    'balance': (days * shakePrice) - payAmount,
                                                                                  };
                                                                                  updates.remove('users/$id/plansPaid/$initalPlan');
                                                                                  updates['users/$id/plansPaid/$initalPlan/$planDate'] = ServerValue.increment(payAmount);
                                                                                  if (planDate == null) {
                                                                                    changeSubmitted(false);
                                                                                    throw 'Plan Date is null';
                                                                                  }
                                                                                }
                                                                                await dbRef.update(updates);
                                                                                amount.clear();
                                                                                customPlan.clear();
                                                                                customPlanDays.clear();
                                                                                initalPlan = '0 day';
                                                                                Navigator.of(scaffoldKey.currentContext!).pop();
                                                                                changeSubmitted(false);
                                                                              } catch (e) {
                                                                                Navigator.of(scaffoldKey.currentContext!).pop();
                                                                                Flushbar(
                                                                                  margin: const EdgeInsets.all(7),
                                                                                  borderRadius: BorderRadius.circular(15),
                                                                                  flushbarStyle: FlushbarStyle.FLOATING,
                                                                                  flushbarPosition: FlushbarPosition.TOP,
                                                                                  message: "$e Please check the data and try again or contact support",
                                                                                  icon: Icon(
                                                                                    Icons.error_outline_rounded,
                                                                                    size: 28.0,
                                                                                    color: Colors.red[300],
                                                                                  ),
                                                                                  duration: const Duration(milliseconds: 5000),
                                                                                  leftBarIndicatorColor: Colors.red[300],
                                                                                ).show(scaffoldKey.currentContext!);
                                                                                changeSubmitted(false);
                                                                              }
                                                                            }
                                                                          },
                                                                          child:
                                                                              const Text('Save'),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    });
                                                  },
                                                );
                                              },
                                              child: const Text('Club Fees 💵',
                                                  style: TextStyle(
                                                      color: Colors.black87))),
                                        ),
                                        SizedBox(
                                          width: double.infinity,
                                          child: TextButton(
                                              onPressed:
                                                  // snack bar
                                                  () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        CustOrderForm(
                                                      uid: id,
                                                      productsHistory: user[
                                                          'productsHistory'],
                                                      name: name,
                                                      popIndex: 2,
                                                      attendance: true,
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: const Text('Retail 🛍️',
                                                  style: TextStyle(
                                                      color: Colors.black87))),
                                        ),
                                        SizedBox(
                                          width: double.infinity,
                                          child: TextButton(
                                              onPressed: () {
                                                // alert dialog
                                                dynamic formkey =
                                                    GlobalKey<FormState>();
                                                TextEditingController
                                                    daysController =
                                                    TextEditingController();
                                                showDialog(
                                                  context: context,
                                                  builder:
                                                      (BuildContext context) {
                                                    return Form(
                                                      key: formkey,
                                                      child: AlertDialog(
                                                        title: const Text(
                                                            'Home Program 🏠'),
                                                        content: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              Expanded(
                                                                child:
                                                                    TextFormField(
                                                                  controller:
                                                                      daysController,
                                                                  decoration:
                                                                      const InputDecoration(
                                                                    labelText:
                                                                        'Days',
                                                                  ),
                                                                  keyboardType:
                                                                      TextInputType
                                                                          .number,
                                                                  validator:
                                                                      (value) {
                                                                    if (value ==
                                                                            null ||
                                                                        value
                                                                            .isEmpty) {
                                                                      return 'Please enter the days';
                                                                    } else if (int.tryParse(
                                                                            value) ==
                                                                        null) {
                                                                      return 'Please enter a valid number';
                                                                    } else if (int.tryParse(
                                                                            value)! <
                                                                        1) {
                                                                      return 'Please enter a valid number';
                                                                    } else if (int.tryParse(
                                                                            value)! >
                                                                        31) {
                                                                      return 'Please enter a valid number';
                                                                    }
                                                                    return null;
                                                                  },
                                                                ),
                                                              ),
                                                            ]),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () {
                                                              Navigator.of(
                                                                      context)
                                                                  .pop();
                                                            },
                                                            child: const Text(
                                                                'Cancel'),
                                                          ),
                                                          TextButton(
                                                            onPressed: () {
                                                              if (formkey
                                                                  .currentState!
                                                                  .validate()) {
                                                                final int
                                                                    tdays =
                                                                    int.tryParse(
                                                                            daysController.text) ??
                                                                        0;

                                                                // confirm
                                                                showDialog(
                                                                    context:
                                                                        context,
                                                                    builder:
                                                                        (BuildContext
                                                                            context) {
                                                                      return AlertDialog(
                                                                        title: const Text(
                                                                            'Confirmation'),
                                                                        content:
                                                                            Text('Are you sure you want to add "$tdays days" to "${name.split(' ')[0]}" ?'),
                                                                        actions: [
                                                                          TextButton(
                                                                            child:
                                                                                const Text('Cancel'),
                                                                            onPressed:
                                                                                () {
                                                                              Navigator.of(context).pop();
                                                                            },
                                                                          ),
                                                                          TextButton(
                                                                            child:
                                                                                const Text('Add'),
                                                                            onPressed:
                                                                                () async {
                                                                              if (submitted) {
                                                                                return;
                                                                              }

                                                                              changeSubmitted(true);

                                                                              try {
                                                                                final DatabaseReference dbRef = coachDb.child(cid);
                                                                                const time = ServerValue.timestamp;
                                                                                Map<String, dynamic> updates = {};
                                                                                bool homeProg = user['homeProgram'] != null;
                                                                                bool error = false;
                                                                                bool overwriteErr = false;
                                                                                String errorDate = '';
                                                                                if (advancedPaymentx && existingPlan) {
                                                                                  // check if existing plan finishes and next day 1 comes
                                                                                  final int curDay = day - (tempAllPlanDays - planDays);
                                                                                  if ((curDay + tdays) > planDays) {
                                                                                    int remainingDays = planDays - curDay;
                                                                                    // query to firebase to set plan
                                                                                    final Map<dynamic, dynamic> pid = user['advancedPayments']['pid'];
                                                                                    final int pidAmount = pid['amount'] as int;
                                                                                    // remove amount from advanced payments
                                                                                    pid.remove('amount');
                                                                                    final String program = pid['program'];
                                                                                    final String paymentId = pid['payments'].keys.first;
                                                                                    final String paymentDate = pid['payments'][paymentId];
                                                                                    final String firstDayDate = DateFormat('yyyy-MM-dd').format(selectedDate.add(Duration(days: remainingDays + 1)));

                                                                                    final Map<String, dynamic> updates = {
                                                                                      'users/$id/plans/$firstDayDate': pid,
                                                                                      'users/$id/plansPaid/$program/$firstDayDate': pidAmount,
                                                                                      'users/$id/advancedPayments': null,
                                                                                      'attendance/$paymentDate/fees/$paymentId/planId': firstDayDate,
                                                                                      'users/$id/payments/$paymentDate/$paymentId/planId': firstDayDate,
                                                                                    };
                                                                                    dbRef.update(updates);
                                                                                  }
                                                                                }

                                                                                for (int i = 1; i <= tdays; i++) {
                                                                                  final String newDate = DateFormat('yyyy-MM-dd').format(selectedDate.add(Duration(days: i)));
                                                                                  // check if already present
                                                                                  if (homeProg && user['homeProgram'][newDate] != null) {
                                                                                    // error
                                                                                    error = true;
                                                                                    errorDate = newDate;
                                                                                    updates.clear();
                                                                                    break;
                                                                                  }
                                                                                  if (user['days'][newDate] != null) {
                                                                                    errorDate = newDate;
                                                                                    errorDate = '${errorDate.substring(8, 10)}/${errorDate.substring(5, 7)}/${errorDate.substring(0, 4)}';
                                                                                    bool? result = await showDialog(
                                                                                      context: context,
                                                                                      builder: (BuildContext context) {
                                                                                        return AlertDialog(
                                                                                          title: const Text('Confirmation'),
                                                                                          content: Text('"${name.split(' ')[0]}" already exists on $errorDate. Do you want to overwrite it? It will add second shake to that day.'),
                                                                                          actions: [
                                                                                            TextButton(
                                                                                              onPressed: () {
                                                                                                Navigator.of(context).pop(false);
                                                                                              },
                                                                                              child: const Text('Cancel'),
                                                                                            ),
                                                                                            TextButton(
                                                                                              onPressed: () {
                                                                                                Navigator.of(context).pop(true);
                                                                                              },
                                                                                              child: const Text('Overwrite'),
                                                                                            ),
                                                                                          ],
                                                                                        );
                                                                                      },
                                                                                    );
                                                                                    if (result == false) {
                                                                                      overwriteErr = true;
                                                                                      updates.clear();
                                                                                      break;
                                                                                    }
                                                                                  }
                                                                                  updates['attendance/$newDate/students/$id'] = {
                                                                                    'time': time,
                                                                                    'shakes': ServerValue.increment(1),
                                                                                  };
                                                                                  updates['users/$id/days/$newDate'] = {
                                                                                    'time': time,
                                                                                    'shakes': ServerValue.increment(1),
                                                                                  };
                                                                                  updates['users/$id/homeProgram/$newDate'] = time;
                                                                                }
                                                                                if (overwriteErr || error) {
                                                                                  Navigator.of(scaffoldKey.currentContext!).pop();
                                                                                  Navigator.of(scaffoldKey.currentContext!).pop();
                                                                                  Navigator.of(scaffoldKey.currentContext!).pop();
                                                                                  if (error) {
                                                                                    errorDate = '${errorDate.substring(8, 10)}/${errorDate.substring(5, 7)}/${errorDate.substring(0, 4)}';
                                                                                    Flushbar(
                                                                                      margin: const EdgeInsets.all(7),
                                                                                      borderRadius: BorderRadius.circular(15),
                                                                                      flushbarStyle: FlushbarStyle.FLOATING,
                                                                                      flushbarPosition: FlushbarPosition.TOP,
                                                                                      message: 'Error: "${name.split(' ')[0]}" already exists on $errorDate. Please add from $errorDate or ensure total days add up to $errorDate.',
                                                                                      icon: Icon(
                                                                                        Icons.error_outline_rounded,
                                                                                        size: 28.0,
                                                                                        color: Colors.red[300],
                                                                                      ),
                                                                                      duration: const Duration(milliseconds: 10000),
                                                                                      leftBarIndicatorColor: Colors.red[300],
                                                                                    ).show(scaffoldKey.currentContext!);
                                                                                  } else {
                                                                                    Flushbar(
                                                                                      margin: const EdgeInsets.all(7),
                                                                                      borderRadius: BorderRadius.circular(15),
                                                                                      flushbarStyle: FlushbarStyle.FLOATING,
                                                                                      flushbarPosition: FlushbarPosition.TOP,
                                                                                      message: 'Home program cancelled',
                                                                                      icon: Icon(
                                                                                        Icons.error_outline_rounded,
                                                                                        size: 28.0,
                                                                                        color: Colors.red[300],
                                                                                      ),
                                                                                      duration: const Duration(milliseconds: 3000),
                                                                                      leftBarIndicatorColor: Colors.red[300],
                                                                                    ).show(scaffoldKey.currentContext!);
                                                                                  }
                                                                                  changeSubmitted(false);
                                                                                  return;
                                                                                }
                                                                                final String newId = FirebaseDatabase.instance.ref().push().key!;
                                                                                updates['attendance/$formattedDate/homeProgram/$newId'] = {
                                                                                  'uid': id,
                                                                                  'days': tdays,
                                                                                  'time': time,
                                                                                  'homeProgramID': newId,
                                                                                };

                                                                                await dbRef.update(updates);
                                                                                Navigator.of(scaffoldKey.currentContext!).pop();
                                                                                Navigator.of(scaffoldKey.currentContext!).pop();
                                                                                Navigator.of(scaffoldKey.currentContext!).pop();
                                                                                await Flushbar(
                                                                                  margin: const EdgeInsets.all(7),
                                                                                  borderRadius: BorderRadius.circular(15),
                                                                                  flushbarStyle: FlushbarStyle.FLOATING,
                                                                                  flushbarPosition: FlushbarPosition.TOP,
                                                                                  message: "${name.split(' ')[0]} added for $tdays days",
                                                                                  icon: Icon(
                                                                                    Icons.check_circle_outline,
                                                                                    size: 28.0,
                                                                                    color: Colors.green[300],
                                                                                  ),
                                                                                  duration: const Duration(milliseconds: 2000),
                                                                                  leftBarIndicatorColor: Colors.green[300],
                                                                                ).show(scaffoldKey.currentContext!);
                                                                                changeSubmitted(false);
                                                                              } catch (e) {
                                                                                Flushbar(
                                                                                  margin: const EdgeInsets.all(7),
                                                                                  borderRadius: BorderRadius.circular(15),
                                                                                  flushbarStyle: FlushbarStyle.FLOATING,
                                                                                  flushbarPosition: FlushbarPosition.TOP,
                                                                                  message: "Error adding ${name.split(' ')[0]} to the home list",
                                                                                  icon: Icon(
                                                                                    Icons.error_outline_rounded,
                                                                                    size: 28.0,
                                                                                    color: Colors.red[300],
                                                                                  ),
                                                                                  duration: const Duration(milliseconds: 3000),
                                                                                  leftBarIndicatorColor: Colors.red[300],
                                                                                ).show(scaffoldKey.currentContext!);
                                                                                changeSubmitted(false);
                                                                              }
                                                                            },
                                                                          ),
                                                                        ],
                                                                      );
                                                                    });
                                                              }
                                                            },
                                                            child: const Text(
                                                                'Save'),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                );
                                              },
                                              child: const Text(
                                                  'Home Program 🏠',
                                                  style: TextStyle(
                                                      color: Colors.black87))),
                                        ),
                                        SizedBox(
                                          width: double.infinity,
                                          child: TextButton(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        BodyFormCustomerWrap(
                                                      uid: id,
                                                      callback: () {},
                                                      attendance: true,
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: const Text(
                                                  'Visit Profile 📝',
                                                  style: TextStyle(
                                                      color: Colors.black87))),
                                        ),
                                      ]),
                                );
                              },
                            );
                          },
                        ),
                        DataCell(
                          Text(capitalize(planName)),
                        ),
                        DataCell(
                          Text(days,
                              style: const TextStyle(letterSpacing: 1.8)),
                        ),
                        DataCell(
                            Text(int.parse(balance) < 0 ? '0' : balance,
                                style: TextStyle(
                                    color: int.tryParse(balance) == 0
                                        ? Colors.black
                                        : Colors.red)),
                            onTap: allBalances.isEmpty
                                ? null
                                : () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title:
                                              const Text('Remaining Balances'),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: allBalances.keys
                                                .map((String key) {
                                              return Text(
                                                  '$key: ₹${allBalances[key]}');
                                            }).toList(),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              child: const Text('Close'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  }),
                        if (isEdit)
                          DataCell(
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                // ask for confirmation
                                String confirmMsg =
                                    'Are you sure you want to delete "${name.split(' ')[0]}" from the attendance list?';
                                if (isHome) {
                                  confirmMsg +=
                                      'It will delete Home program of today, But Remember the issued home program all days are not deleted from given issue date';
                                } else if (isSecond) {
                                  confirmMsg +=
                                      'It will delete the second shake of "${name.split(' ')[0]}" from the attendance list';
                                }
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text('Confirmation'),
                                      content: Text(confirmMsg),
                                      actions: [
                                        TextButton(
                                          child: const Text('Cancel'),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                        TextButton(
                                          child: const Text('Delete'),
                                          onPressed: () async {
                                            if (submitted) {
                                              return;
                                            }
                                            changeSubmitted(true);

                                            // delete from firebase
                                            final DatabaseReference dbRef =
                                                coachDb.child(cid);
                                            Map<String, dynamic> updates = {};
                                            try {
                                              // check if 'home' is true
                                              if (isHome) {
                                                updates = {
                                                  'attendance/$formattedDate/students/$id/shakes':
                                                      ServerValue.increment(-1),
                                                  'users/$id/days/$formattedDate/shakes':
                                                      ServerValue.increment(-1),
                                                  'users/$id/homeProgram/$formattedDate':
                                                      null,
                                                };
                                              } else if (isSecond) {
                                                updates = {
                                                  'attendance/$formattedDate/students/$id/shakes':
                                                      ServerValue.increment(-1),
                                                  'users/$id/days/$formattedDate/shakes':
                                                      ServerValue.increment(-1),
                                                };
                                              } else {
                                                updates = {
                                                  'attendance/$formattedDate/students/$id':
                                                      null,
                                                  'users/$id/days/$formattedDate':
                                                      null,
                                                  'users/$id/homeProgram/$formattedDate':
                                                      null,
                                                };
                                              }

                                              if (existingPlan &&
                                                  user['plans'] != null &&
                                                  user['plans'].keys.length >
                                                      1) {
                                                // get next plan
                                                final List sortedPlanKeys =
                                                    user['plans'].keys.toList();
                                                sortedPlanKeys.sort();
                                                // check if any plan exists after current plan
                                                if (sortedPlanKeys
                                                        .indexOf(planDate) <
                                                    sortedPlanKeys.length - 1) {
                                                  final totalPlansAhead =
                                                      sortedPlanKeys.length -
                                                          sortedPlanKeys
                                                              .indexOf(
                                                                  planDate);

                                                  final List userSortedDays =
                                                      user['days']
                                                          .keys
                                                          .toList();
                                                  userSortedDays.sort();
                                                  // show dialog to not touvh screen
                                                  Navigator.of(scaffoldKey
                                                          .currentContext!)
                                                      .pop();
                                                  showDialog(
                                                      barrierDismissible: false,
                                                      context: context,
                                                      builder: (BuildContext
                                                          context) {
                                                        return const AlertDialog(
                                                            title: Text(
                                                                'Confirmation'),
                                                            content: Text(
                                                                'Dont touch screen'));
                                                      });
                                                  final DateTime originalDate =
                                                      DateTime.parse(
                                                          formattedDate);
                                                  await dbRef.update(updates);

                                                  for (int i = 1;
                                                      i < totalPlansAhead;
                                                      i++) {
                                                    final String nextPlanDate =
                                                        sortedPlanKeys[
                                                            sortedPlanKeys.indexOf(
                                                                    planDate) +
                                                                i];

                                                    final int
                                                        indexOfDateinUser =
                                                        userSortedDays.indexOf(
                                                            nextPlanDate);
                                                    // check if next date is possible
                                                    int next = 0;
                                                    if (indexOfDateinUser <
                                                        userSortedDays.length -
                                                            1) {
                                                      next = 1;
                                                    }
                                                    DateTime newDate = DateTime
                                                        .parse(userSortedDays[
                                                            indexOfDateinUser +
                                                                next]);

                                                    setState(() {
                                                      selectedDate = newDate;
                                                    });
                                                    await setupDataListener(
                                                        selectedDate);
                                                    await Future.delayed(
                                                        const Duration(
                                                            milliseconds:
                                                                1500));
                                                  }
                                                  setState(() {
                                                    selectedDate = originalDate;
                                                  });
                                                  await setupDataListener(
                                                      selectedDate);
                                                  Navigator.of(scaffoldKey
                                                          .currentContext!)
                                                      .pop();
                                                  changeSubmitted(false);
                                                  return Flushbar(
                                                    margin:
                                                        const EdgeInsets.all(7),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            15),
                                                    flushbarStyle:
                                                        FlushbarStyle.FLOATING,
                                                    flushbarPosition:
                                                        FlushbarPosition.TOP,
                                                    message:
                                                        "${name.split(' ')[0]} has been removed from today's list. Please don't remove users from previous plans, it causes errors in the system",
                                                    icon: Icon(
                                                      // alert icon
                                                      Icons
                                                          .error_outline_rounded,
                                                      size: 28.0,
                                                      color: Colors.orange[300],
                                                    ),
                                                    duration: const Duration(
                                                        milliseconds: 10000),
                                                    leftBarIndicatorColor:
                                                        Colors.orange[300],
                                                  ).show(scaffoldKey
                                                      .currentContext!);
                                                }
                                              }

                                              debugPrint('Updates: $updates');
                                              final bool popMsg = isHome;
                                              await dbRef.update(updates);
                                              Navigator.of(scaffoldKey
                                                      .currentContext!)
                                                  .pop();
                                              if (popMsg) {
                                                Flushbar(
                                                  margin:
                                                      const EdgeInsets.all(7),
                                                  borderRadius:
                                                      BorderRadius.circular(15),
                                                  flushbarStyle:
                                                      FlushbarStyle.FLOATING,
                                                  flushbarPosition:
                                                      FlushbarPosition.TOP,
                                                  message:
                                                      "${name.split(' ')[0]} has been removed from today's list. But Remember home program all days are not deleted from given date. You can delete all list by going to the home program section on that day",
                                                  icon: Icon(
                                                    // alert icon
                                                    Icons.error_outline_rounded,
                                                    size: 28.0,
                                                    color: Colors.orange[300],
                                                  ),
                                                  duration: const Duration(
                                                      milliseconds: 15000),
                                                  leftBarIndicatorColor:
                                                      Colors.orange[300],
                                                ).show(scaffoldKey
                                                    .currentContext!);
                                              }
                                              changeSubmitted(false);
                                            } catch (e) {
                                              Flushbar(
                                                margin: const EdgeInsets.all(7),
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                                flushbarStyle:
                                                    FlushbarStyle.FLOATING,
                                                flushbarPosition:
                                                    FlushbarPosition.TOP,
                                                message:
                                                    "Error deleting ${name.split(' ')[0]} from the attendance list",
                                                icon: Icon(
                                                  Icons.error_outline_rounded,
                                                  size: 28.0,
                                                  color: Colors.red[300],
                                                ),
                                                duration: const Duration(
                                                    milliseconds: 3000),
                                                leftBarIndicatorColor:
                                                    Colors.red[300],
                                              ).show(
                                                  scaffoldKey.currentContext!);
                                              changeSubmitted(false);
                                            }
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                      ],
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Map<String, dynamic> getPlan(int days,
      {int? assignedPlanDays, String? planName}) {
    String plan;
    String day;
    int balance = 200;

    if (assignedPlanDays != null && planName != null) {
      plan = planName;
      day = '$days / $assignedPlanDays';
    } else if (days == 0 || days == 1) {
      plan = '0 day';
      day = '$days / 1';
    } else if (days >= 2 && days < 5) {
      plan = '3 day'; // Change this value as needed
      day = '${days - 1} / 3';
    } else {
      plan = 'Paid'; // Change this value as needed
      day = '${days - 4} / ${days - 4}';
    }
    for (int i = 1; i < days; i++) {
      balance += shakePrice;
    }

    return {'plan': plan, 'day': day, 'balance': balance};
  }
}

class DailyDetails extends StatefulWidget {
  final DateTime selectedDate;
  final List<Map<dynamic, dynamic>> clubFees;
  final dynamic studentsNameUID;
  final String zdays;
  final String shakes;
  final String revenue;
  final List<dynamic> users;
  final List<Map<dynamic, dynamic>> homeProgram;
  const DailyDetails({
    super.key,
    required this.selectedDate,
    required this.clubFees,
    required this.studentsNameUID,
    required this.zdays,
    required this.shakes,
    required this.revenue,
    required this.users,
    required this.homeProgram,
  });

  @override
  State<DailyDetails> createState() => _DailyDetailsState();
}

class _DailyDetailsState extends State<DailyDetails> {
// create date variable and set it to widget.selectedDate
  late DateTime selectedDate;
  late String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
  bool isEdit = false;
  bool submitted = false;
  final String cid = FirebaseAuth.instance.currentUser!.uid;
  List<Map<dynamic, dynamic>> todaysProductsHistory = [];
  final DatabaseReference coachDb =
      FirebaseDatabase.instance.ref().child('Coaches');
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  void initState() {
    super.initState();
    selectedDate = widget.selectedDate;
  }

  void changeSubmitted(bool value) {
    setState(() {
      submitted = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: MyAppBar(
        leftIcon: Container(
          margin: const EdgeInsets.only(left: 10),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.grey,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        ftitle: TextButton(
          child: Text(
            "${format.format(widget.selectedDate)} - History",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          onPressed: () {
            //  open date picker
            // showDatePicker(
            //   context: context,
            //   initialDate: widget.selectedDate,
            //   firstDate: DateTime(2023),
            //   lastDate: today,
            // ).then((date) {
            //   if (date != null) {
            //     setState(() {
            //       //  update the date
            //       selectedDate = date;
            //     });
            //   }
            // });
          },
        ),
        rightIcons: [
          // export to excel button
          IconButton(
            icon: const Icon(
              Icons.file_download_outlined,
              color: Colors.grey,
            ),
            onPressed: () {
              //  export to excel
              Flushbar(
                margin: const EdgeInsets.all(7),
                borderRadius: BorderRadius.circular(15),
                flushbarStyle: FlushbarStyle.FLOATING,
                flushbarPosition: FlushbarPosition.TOP,
                message:
                    "${format.format(selectedDate)} data exported to excel",
                icon: Icon(
                  Icons.check_circle_outline,
                  size: 28.0,
                  color: Colors.green[300],
                ),
                duration: const Duration(milliseconds: 2000),
                leftBarIndicatorColor: Colors.green[300],
              ).show(context);
            },
          ),

          // edit button
          IconButton(
            icon: Icon(
              isEdit ? Icons.edit_off_rounded : Icons.edit_rounded,
              color: Colors.grey,
            ),
            onPressed: () {
              setState(() {
                isEdit = !isEdit;
              });
            },
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.035,
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.04,
            vertical: MediaQuery.of(context).size.width * 0.02,
          ),
          // max width: 80% of screen
          width: double.infinity,
          child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: GradientBox(
                        colors: [
                          Colors.blue[400]!,
                          Colors.blue[800]!,
                        ],
                        children: [
                          Text(
                            'Total New 0 Days: ',
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            widget.zdays,
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: GradientBox(
                        colors: [
                          Colors.yellow[800]!,
                          Colors.yellow[400]!,
                        ],
                        children: [
                          Text(
                            'Total Shakes: ',
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            widget.shakes,
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  width: double.infinity,
                  child: GradientBox(
                    colors: [
                      Colors.green[400]!,
                      Colors.green[800]!,
                    ],
                    children: [
                      Text(
                        'Total Revenue: ',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "₹${widget.revenue}",
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.width * 0.04,
                ),
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        height: 1,
                        indent: 10,
                        endIndent: 5,
                        color: Colors.grey[600]!,
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.02,
                    ),
                    Text(
                      "CLUB FEES",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.02,
                    ),
                    Expanded(
                      child: Divider(
                        height: 1,
                        indent: 5,
                        endIndent: 10,
                        color: Colors.grey[600]!,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.width * 0.04,
                ),
                Center(
                  child: DataTable(
                    headingRowColor:
                        MaterialStateProperty.all(Colors.grey[200]),
                    border: TableBorder.all(
                      color: Colors.black12,
                      width: 1,
                    ),
                    horizontalMargin: MediaQuery.of(context).size.width * 0.02,
                    columns: <DataColumn>[
                      const DataColumn(
                        label: Text('Name'),
                      ),
                      const DataColumn(
                        label: Text('Program'),
                      ),
                      const DataColumn(
                        label: Text('Mode'),
                      ),
                      const DataColumn(
                        label: Text('Amount'),
                      ),
                      const DataColumn(
                        label: Text('C. Balance'),
                      ),
                      if (isEdit)
                        const DataColumn2(
                          label: Text('Delete'),
                          size: ColumnSize.S,
                        ),
                    ],
                    rows:
                        List<DataRow>.generate(widget.clubFees.length, (index) {
                      String uid = widget.clubFees[index]['uid'];
                      String name = widget.studentsNameUID[uid];
                      String program = widget.clubFees[index]['program'];
                      String mode = widget.clubFees[index]['mode'];
                      String amount =
                          widget.clubFees[index]['amount'].toString();
                      String balance =
                          widget.clubFees[index]['balance'].toString();
                      return DataRow(cells: <DataCell>[
                        DataCell(Text(name)),
                        DataCell(Text(program)),
                        DataCell(Text(mode)),
                        DataCell(Text(amount)),
                        DataCell(Text(balance,
                            style: TextStyle(
                                color: widget.clubFees[index]['balance'] >= 0
                                    ? Colors.black
                                    : Colors.red))),
                        if (isEdit)
                          DataCell(
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                // ask for confirmation
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text('Confirmation'),
                                      content: Text(
                                          'Are you sure you want to delete "${name.split(' ')[0]}\'s" payment?'),
                                      actions: [
                                        TextButton(
                                          child: const Text('Cancel'),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                        TextButton(
                                          child: const Text('Delete'),
                                          onPressed: () async {
                                            if (submitted) {
                                              return;
                                            }
                                            changeSubmitted(true);
                                            // get payment id
                                            try {
                                              final DatabaseReference dbRef =
                                                  coachDb.child(cid);

                                              final String paymentId = widget
                                                  .clubFees[index]['paymentId'];
                                              final String plan = widget
                                                  .clubFees[index]['program'];
                                              final planId = widget
                                                  .clubFees[index]['planId'];
                                              final advancedPayment =
                                                  widget.clubFees[index]
                                                      ['advancedPayment'];

                                              final user = widget.users
                                                  .firstWhere((element) =>
                                                      element['id'] == uid);

                                              // delete from firebase
                                              Map<String, dynamic> updates = {
                                                // delete from club fees
                                                'attendance/$formattedDate/fees/$paymentId':
                                                    null,
                                                'users/$uid/paid':
                                                    ServerValue.increment(
                                                        -int.parse(amount)),
                                              };

                                              if (user['payments']
                                                          [formattedDate]
                                                      .keys
                                                      .length <=
                                                  2) {
                                                updates['users/$uid/payments/$formattedDate'] =
                                                    null;
                                              } else {
                                                updates['users/$uid/payments/$formattedDate/$paymentId'] =
                                                    null;
                                                updates['users/$uid/payments/$formattedDate/totalAmount'] =
                                                    ServerValue.increment(
                                                        -int.parse(amount));
                                              }
                                              // delete from plans
                                              if ((user['plans'] != null) &&
                                                  planId != null &&
                                                  planId.isNotEmpty) {
                                                // get planId

                                                if (user['plans'].keys.length >
                                                    1) {
                                                  // get next plan
                                                  final List sortedPlanKeys =
                                                      user['plans']
                                                          .keys
                                                          .toList();
                                                  sortedPlanKeys.sort();
                                                  // check if any plan exists after current plan
                                                  if (sortedPlanKeys
                                                          .indexOf(planId) <
                                                      sortedPlanKeys.length -
                                                          1) {
                                                    final String nextPlanId =
                                                        sortedPlanKeys[
                                                            sortedPlanKeys
                                                                    .indexOf(
                                                                        planId) +
                                                                1];
                                                    final String nextPlanName =
                                                        user['plans']
                                                                [nextPlanId]
                                                            ['program'];
                                                    final List
                                                        nextPlanPaymentKeys =
                                                        user['plans']
                                                                    [nextPlanId]
                                                                ['payments']
                                                            .values
                                                            .toList();
                                                    nextPlanPaymentKeys.sort();
                                                    final String
                                                        nextPlanPaymentLastId =
                                                        nextPlanPaymentKeys[
                                                            nextPlanPaymentKeys
                                                                    .length -
                                                                1];
                                                    Navigator.of(scaffoldKey
                                                            .currentContext!)
                                                        .pop();
                                                    changeSubmitted(false);
                                                    return Flushbar(
                                                      margin:
                                                          const EdgeInsets.all(
                                                              7),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              15),
                                                      flushbarStyle:
                                                          FlushbarStyle
                                                              .FLOATING,
                                                      flushbarPosition:
                                                          FlushbarPosition.TOP,
                                                      message:
                                                          'Error: "${name.split(' ')[0]}" has a plan "$nextPlanName" after this plan, which starts on $nextPlanId. Please delete that plan\'s all payments, last payment is on $nextPlanPaymentLastId',
                                                      icon: Icon(
                                                        Icons
                                                            .error_outline_rounded,
                                                        size: 28.0,
                                                        color: Colors.red[300],
                                                      ),
                                                      duration: const Duration(
                                                          milliseconds: 10000),
                                                      leftBarIndicatorColor:
                                                          Colors.red[300],
                                                    ).show(scaffoldKey
                                                        .currentContext!);
                                                  }
                                                }

                                                if (user['plans'][planId]
                                                            ['payments']
                                                        .keys
                                                        .length ==
                                                    1) {
                                                  updates['users/$uid/plans/$planId'] =
                                                      null;
                                                  updates['users/$uid/plansPaid/$plan/$planId'] =
                                                      null;
                                                } else {
                                                  updates['users/$uid/plans/$planId/payments/$paymentId'] =
                                                      null;
                                                  updates['users/$uid/plans/$planId/balance'] =
                                                      ServerValue.increment(
                                                          int.parse(amount));
                                                  updates['users/$uid/plansPaid/$plan/$planId'] =
                                                      ServerValue.increment(
                                                          -int.parse(amount));
                                                }
                                              } else {
                                                if (advancedPayment != null) {
                                                  updates['users/$uid/advancedPayments'] =
                                                      null;
                                                } else {
                                                  updates['users/$uid/plansPaid/$plan'] =
                                                      ServerValue.increment(
                                                          -int.parse(amount));
                                                }
                                              }

                                              await dbRef.update(updates);
                                              Navigator.of(scaffoldKey
                                                      .currentContext!)
                                                  .pop();
                                              Navigator.of(scaffoldKey
                                                      .currentContext!)
                                                  .pop();
                                              Flushbar(
                                                margin: const EdgeInsets.all(7),
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                                flushbarStyle:
                                                    FlushbarStyle.FLOATING,
                                                flushbarPosition:
                                                    FlushbarPosition.TOP,
                                                message:
                                                    "Payment deleted successfully",
                                                icon: Icon(
                                                  Icons.check_circle_outline,
                                                  size: 28.0,
                                                  color: Colors.green[300],
                                                ),
                                                duration: const Duration(
                                                    milliseconds: 2000),
                                                leftBarIndicatorColor:
                                                    Colors.green[300],
                                              ).show(
                                                  scaffoldKey.currentContext!);
                                              changeSubmitted(false);
                                            } catch (e) {
                                              Navigator.of(scaffoldKey
                                                      .currentContext!)
                                                  .pop();
                                              Flushbar(
                                                margin: const EdgeInsets.all(7),
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                                flushbarStyle:
                                                    FlushbarStyle.FLOATING,
                                                flushbarPosition:
                                                    FlushbarPosition.TOP,
                                                message:
                                                    "$e Please check the data and try again or contact support",
                                                icon: Icon(
                                                  Icons.error_outline_rounded,
                                                  size: 28.0,
                                                  color: Colors.red[300],
                                                ),
                                                duration: const Duration(
                                                    milliseconds: 3000),
                                                leftBarIndicatorColor:
                                                    Colors.red[300],
                                              ).show(
                                                  scaffoldKey.currentContext!);
                                              changeSubmitted(false);
                                            }
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                      ]);
                    }),
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.width * 0.04,
                ),
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        height: 1,
                        indent: 10,
                        endIndent: 5,
                        color: Colors.grey[600]!,
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.02,
                    ),
                    Text(
                      "RETAIL",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.02,
                    ),
                    Expanded(
                      child: Divider(
                        height: 1,
                        indent: 5,
                        endIndent: 10,
                        color: Colors.grey[600]!,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.width * 0.04,
                ),
                Center(
                  child: DataTable(
                      headingRowColor:
                          MaterialStateProperty.all(Colors.grey[200]),
                      border: TableBorder.all(
                        color: Colors.black12,
                        width: 1,
                      ),
                      horizontalMargin:
                          MediaQuery.of(context).size.width * 0.02,
                      columns: const <DataColumn>[
                        DataColumn(
                          label: Text('Name'),
                        ),
                        DataColumn(
                          label: Text('Product'),
                        ),
                        DataColumn(
                          label: Text('Mode'),
                        ),
                        DataColumn(
                          label: Text('Amount'),
                        ),
                        DataColumn(label: Text('Balance')),
                      ],
                      rows: List<DataRow>.generate(todaysProductsHistory.length,
                          (index) {
                        String name =
                            todaysProductsHistory[index]['name'].toString();
                        String amount =
                            todaysProductsHistory[index]['given'].toString();
                        String prodName = todaysProductsHistory[index]
                                ['products']
                            .keys
                            .first
                            .toString();
                        prodName =
                            prodName.substring(0, prodName.indexOf('(')).trim();

                        String prodValue = todaysProductsHistory[index]
                                ['products']
                            .values
                            .first
                            .toString();
                        String prod = '$prodName x$prodValue';
                        return DataRow(cells: <DataCell>[
                          DataCell(Text(name)),
                          if (todaysProductsHistory[index]['products'].length <=
                              1)
                            DataCell(Text(prod))
                          else
                            DataCell(
                              IconButton(
                                icon: const Icon(Icons.arrow_drop_down_rounded),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text('$name\'s Retail'),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // for loop in todaysProductsHistory[index]['products']
                                            for (var product
                                                in todaysProductsHistory[index]
                                                        ['products']
                                                    .entries)
                                              Text(
                                                  '${product.key.substring(0, product.key.indexOf('(')).trim()} x${product.value}'),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          const DataCell(Text('Online')),
                          DataCell(Text(amount)),
                          const DataCell(Text('1000',
                              style: TextStyle(color: Colors.red))),
                        ]);
                      })),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.width * 0.04,
                ),
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        height: 1,
                        indent: 10,
                        endIndent: 5,
                        color: Colors.grey[600]!,
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.02,
                    ),
                    Text(
                      "HOME PROGRAM",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.02,
                    ),
                    Expanded(
                      child: Divider(
                        height: 1,
                        indent: 5,
                        endIndent: 10,
                        color: Colors.grey[600]!,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.width * 0.04,
                ),
                Center(
                  child: DataTable(
                    headingRowColor:
                        MaterialStateProperty.all(Colors.grey[200]),
                    border: TableBorder.all(
                      color: Colors.black12,
                      width: 1,
                    ),
                    horizontalMargin: MediaQuery.of(context).size.width * 0.02,
                    columns: <DataColumn>[
                      const DataColumn(
                        label: Text('Name'),
                      ),
                      const DataColumn(
                        label: Text('Days'),
                      ),
                      const DataColumn(
                        label: Text('Until'),
                      ),
                      if (isEdit)
                        const DataColumn2(
                          label: Text('Delete'),
                          size: ColumnSize.S,
                        ),
                    ],
                    rows: List<DataRow>.generate(widget.homeProgram.length,
                        (index) {
                      String name = widget
                          .studentsNameUID[widget.homeProgram[index]['uid']];
                      String days =
                          widget.homeProgram[index]['days'].toString();
                      String until = DateFormat('dd/MM/yy').format(
                          selectedDate.add(Duration(days: int.parse(days))));
                      return DataRow(cells: <DataCell>[
                        DataCell(Text(name)),
                        DataCell(Text(days)),
                        DataCell(Text(until)),
                        if (isEdit)
                          DataCell(
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                // ask for confirmation
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text('Confirmation'),
                                      content: Text(
                                          'Are you sure you want to delete "${name.split(' ')[0]}\'s" home program?'),
                                      actions: [
                                        TextButton(
                                          child: const Text('Cancel'),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                        TextButton(
                                          child: const Text('Delete'),
                                          onPressed: () async {
                                            if (submitted) {
                                              return;
                                            }
                                            changeSubmitted(true);
                                            // get payment id
                                            try {
                                              final DatabaseReference dbRef =
                                                  coachDb.child(cid);
                                              final String uid = widget
                                                  .homeProgram[index]['uid'];
                                              final String homeProgramId =
                                                  widget.homeProgram[index]
                                                      ['homeProgramID'];

                                              // delete from firebase
                                              final Map<String, dynamic>
                                                  updates = {};
                                              final user = widget.users
                                                  .firstWhere((element) =>
                                                      element['id'] == uid);
                                              bool missingDays = false;
                                              int missedDays = 0;

                                              for (int i = 1;
                                                  i <= int.parse(days);
                                                  i++) {
                                                final String newDate =
                                                    DateFormat('yyyy-MM-dd')
                                                        .format(selectedDate
                                                            .add(Duration(
                                                                days: i)));

                                                // check if shakes is 2
                                                if (user['homeProgram'] !=
                                                        null &&
                                                    user['homeProgram']
                                                            [newDate] !=
                                                        null) {
                                                  updates['users/$uid/days/$newDate'] =
                                                      null;
                                                  updates['users/$uid/homeProgram/$newDate'] =
                                                      null;
                                                  updates['attendance/$newDate/students/$uid'] =
                                                      null;
                                                } else {
                                                  missedDays++;
                                                }
                                              }
                                              updates['attendance/$formattedDate/homeProgram/$homeProgramId'] =
                                                  null;

                                              await dbRef.update(updates);
                                              missingDays = missedDays > 0;
                                              String msg =
                                                  "Home Program deleted successfully";
                                              if (missingDays) {
                                                msg +=
                                                    ". But ${missedDays.toString()} days were already deleted from the home program";
                                              }
                                              Navigator.of(scaffoldKey
                                                      .currentContext!)
                                                  .pop();
                                              Navigator.of(scaffoldKey
                                                      .currentContext!)
                                                  .pop();
                                              Flushbar(
                                                margin: const EdgeInsets.all(7),
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                                flushbarStyle:
                                                    FlushbarStyle.FLOATING,
                                                flushbarPosition:
                                                    FlushbarPosition.TOP,
                                                message: msg,
                                                icon: Icon(
                                                  missingDays
                                                      ? Icons
                                                          .error_outline_rounded
                                                      : Icons
                                                          .check_circle_outline,
                                                  size: 28.0,
                                                  color: missingDays
                                                      ? Colors.orange[300]
                                                      : Colors.green[300],
                                                ),
                                                duration: Duration(
                                                    milliseconds: missingDays
                                                        ? 5000
                                                        : 2000),
                                                leftBarIndicatorColor:
                                                    missingDays
                                                        ? Colors.orange[300]
                                                        : Colors.green[300],
                                              ).show(
                                                  scaffoldKey.currentContext!);
                                              changeSubmitted(false);
                                            } catch (e) {
                                              Navigator.of(scaffoldKey
                                                      .currentContext!)
                                                  .pop();
                                              Flushbar(
                                                margin: const EdgeInsets.all(7),
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                                flushbarStyle:
                                                    FlushbarStyle.FLOATING,
                                                flushbarPosition:
                                                    FlushbarPosition.TOP,
                                                message:
                                                    "$e Please check the data and try again or contact support",
                                                icon: Icon(
                                                  Icons.error_outline_rounded,
                                                  size: 28.0,
                                                  color: Colors.red[300],
                                                ),
                                                duration: const Duration(
                                                    milliseconds: 3000),
                                                leftBarIndicatorColor:
                                                    Colors.red[300],
                                              ).show(
                                                  scaffoldKey.currentContext!);
                                              changeSubmitted(false);
                                            }
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                      ]);
                    }),
                  ),
                ),
              ]),
        ),
      ),
    );
  }
}

class GradientBox extends StatelessWidget {
  final List<Widget> children;
  final List<Color> colors;

  const GradientBox({super.key, required this.children, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        // add 3d look
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(2, 2),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(15.0),
      ),
      padding: const EdgeInsets.all(20.0),
      margin: const EdgeInsets.all(10.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}
