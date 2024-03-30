import 'dart:async';

import 'package:another_flushbar/flushbar.dart';
import 'package:coach_zen/pages/cust_order_form.dart';
import 'package:coach_zen/pages/home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';
import '../components/ui/appbar.dart';
import 'package:data_table_2/data_table_2.dart';

final DateFormat format = DateFormat('dd MMM yyyy');
final DateTime today = DateTime.now();

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
  Map<String, String> studentsNameUID = {};
  Map<dynamic, dynamic> presentStudentsUID = {};
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
  List sortedPresentStudents = [];
  late String formattedDate;

  void changeSubmitted() {
    setState(() {
      submitted = !submitted;
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
    setupDataListener(selectedDate);
  }

  void setupDataListener(DateTime selectedDate) {
    // Close the previous listener if it exists
    _streamSubscription?.cancel();
    formattedDate = DateFormat('ddMMyy').format(selectedDate);

    mystream = coachDb.child(cid).onValue;
    // Set up the new listener
    _streamSubscription = mystream.listen((event) {
      if (mounted) {
        datas += 1;
        debugPrint('got data - $datas');

        final eventData = event.snapshot.value;
        // Process users data
        final usersData = eventData['users'] ?? {};
        final updatedUsers = usersData.entries.map((entry) {
          final key = entry.key;
          final userData = entry.value;
          studentsNameUID[key] = userData['name'];

          final allDays = ((userData['days'] as Map?)?.entries.where((entry) {
                final dateString = entry.key.toString();
                final dayx = int.parse(dateString.substring(0, 2));
                final month = int.parse(dateString.substring(2, 4));
                final year = int.parse(dateString.substring(4, 6)) + 2000;
                final keyDate = DateTime(year, month, dayx);
                return keyDate.isBefore(selectedDate) ||
                    keyDate.isAtSameMomentAs(selectedDate);
              }).length) ??
              0;
          final totalDays = allDays == 0 ? 0 : allDays - 1;

          // final userPayments = Map.from(userData['payments'] ?? {});
          // get all payments till selected date
          final amountPaidTillNow = ((userData['payments'] as Map?)
                  ?.entries
                  .where((entry) {
                    final dateString = entry.key.toString();
                    final dayx = int.parse(dateString.substring(0, 2));
                    final month = int.parse(dateString.substring(2, 4));
                    final year = int.parse(dateString.substring(4, 6)) + 2000;
                    final keyDate = DateTime(year, month, dayx);
                    return keyDate.isBefore(selectedDate) ||
                        keyDate.isAtSameMomentAs(selectedDate);
                  })
                  .map((entry) => entry.value['totalAmount'] as int)
                  .fold(0, (prev, amount) => prev + amount)) ??
              0;
          debugPrint('Amount Paid: $amountPaidTillNow');

          return {
            'id': key,
            'name': userData['name'],
            'phone': userData['phone'],
            'paid': userData['paid'],
            'productsHistory': List<Map<dynamic, dynamic>>.from(
                userData['productsHistory'] ?? []),
            'days': userData['days'],
            'payments': userData['payments'],
            'totalDays': totalDays,
            'amountPaidTillNow': amountPaidTillNow,
            // Add other user fields as needed
          };
        }).toList();

        // Process attendance data
        final attendanceData = eventData['attendance'] != null
            ? eventData['attendance'][formattedDate]
            : null;
        final presentStudents = attendanceData != null
            ? Map<dynamic, dynamic>.from(attendanceData['students'] ?? {})
            : {};

        // sort the present students

        // Update state
        setState(() {
          sortedPresentStudents = presentStudents.keys.toList();
          users = updatedUsers;
          presentStudentsUID = presentStudents;
          zdays = presentStudents.keys
              .where((student) =>
                  users.firstWhere(
                      (user) => user['id'] == student)['totalDays'] ==
                  0)
              .length;
          clubFees = [];
          revenue = 0;
        });
        sortedPresentStudents.sort((a, b) {
          return presentStudents[a].compareTo(presentStudents[b]);
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
              });
              revenue += clubFeeData['amount'] as int;
            });
          });
        }
      }
    });
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
    final screenWidth = MediaQuery.of(context).size.width;
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
                  // Navigator.pop(context);
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const HomePage()),
                      (Route<dynamic> route) => false);
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
                  lastDate: today,
                ).then((date) {
                  if (date != null) {
                    setState(() {
                      selectedDate = date;
                    });
                    setupDataListener(selectedDate);
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
                      if (presentStudentsUID.keys.contains(selectedUserId)) {
                        return;
                      }
                      // add to firebase
                      try {
                        final DatabaseReference dbRef = coachDb.child(cid);
                        const time = ServerValue.timestamp;
                        Map<String, dynamic> updates = {
                          'attendance/$formattedDate/students/$selectedUserId':
                              time,
                          'users/$selectedUserId/days/$formattedDate': time,
                        };
                        await dbRef.update(updates);
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
                  headingRowHeight: MediaQuery.of(context).size.width * 0.045,
                  dataRowHeight: MediaQuery.of(context).size.width * 0.045,
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
                  rows: List<DataRow>.generate(sortedPresentStudents.length,
                      (index) {
                    // get user
                    final user = users.firstWhere(
                        (user) => user['id'] == sortedPresentStudents[index]);
                    String id = user['id'];
                    String name = user['name'];
                    int amountPaidTillNow = user['amountPaidTillNow'];
                    int day = user['totalDays'];
                    String days = getPlan(day)['day'];
                    int totalBalance = getPlan(day)['balance'];
                    debugPrint('Total Balance: $totalBalance');
                    int realBalance = totalBalance - amountPaidTillNow;
                    String balance = realBalance.toString();
                    String planName = getPlan(day)['plan'];

                    return DataRow(
                      cells: <DataCell>[
                        DataCell(
                          Text((index + 1).toString()),
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
                                                // open a new dialog to enter the cash amount
                                                Navigator.of(context).pop();
                                                showDialog(
                                                  barrierDismissible: true,
                                                  context: context,
                                                  builder: (BuildContext cxt) {
                                                    List<String> plans = [
                                                      '0 day',
                                                      '3 day',
                                                      'Gold UMS',
                                                      'Plat UMS',
                                                      'Other',
                                                    ];
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
                                                    return SingleChildScrollView(
                                                      child: Positioned(
                                                        top: 0,
                                                        child: StatefulBuilder(
                                                            builder: (context,
                                                                setState) {
                                                          return Padding(
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
                                                                        .all(
                                                                        16),
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
                                                                              bottom: 10),
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
                                                                                    if (value == null || value.isEmpty) {
                                                                                      return 'Please enter the amount';
                                                                                    } else if (int.tryParse(value) == null) {
                                                                                      return 'Please enter a valid amount';
                                                                                    } else if (int.tryParse(value)! < -50000) {
                                                                                      return 'Please enter a valid amount';
                                                                                    } else if (int.tryParse(value)! > 50000) {
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
                                                                              if (initalPlan == 'Other')
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
                                                                                        }
                                                                                        return null;
                                                                                      },
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                              if (initalPlan == 'Other')
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
                                                                              if (formKey.currentState!.validate() && !submitted) {
                                                                                changeSubmitted();
                                                                                // save the data
                                                                                // save to firebase
                                                                                // add to firebase
                                                                                try {
                                                                                  if (initalPlan == 'Other') {
                                                                                    initalPlan = customPlan.text.trim();
                                                                                  }
                                                                                  // balance
                                                                                  const time = ServerValue.timestamp;
                                                                                  final int payAmount = int.parse(amount.text.trim());
                                                                                  final DatabaseReference dbRef = coachDb.child(cid);
                                                                                  String newPaymentId = FirebaseDatabase.instance.ref().push().key!;
                                                                                  Map<String, dynamic> updates = {
                                                                                    // Set club fees
                                                                                    'attendance/$formattedDate/fees/$newPaymentId': {
                                                                                      'uid': id,
                                                                                      'program': initalPlan,
                                                                                      'amount': payAmount,
                                                                                      'mode': initalMode,
                                                                                      'balance': realBalance - payAmount,
                                                                                      'time': time,
                                                                                    },
                                                                                    // Set user payments
                                                                                    'users/$id/payments/$formattedDate': {
                                                                                      newPaymentId: {
                                                                                        'date': formattedDate,
                                                                                        'time': time,
                                                                                        'amount': payAmount,
                                                                                        'mode': initalMode,
                                                                                        'program': initalPlan,
                                                                                      },
                                                                                      "totalAmount": ServerValue.increment(payAmount),
                                                                                    },
                                                                                    // Increment user's total paid amount
                                                                                    'users/$id/paid': ServerValue.increment(payAmount),
                                                                                  };
                                                                                  bool wrongPlan = initalPlan.toString().toLowerCase() == '0 day' || initalPlan.toString().toLowerCase() == '3 day';
                                                                                  if (!wrongPlan) {
                                                                                    int days = 30;
                                                                                    if (initalPlan.toLowerCase() == 'gold ums') {
                                                                                      days = 30;
                                                                                    } else if (initalPlan.toLowerCase() == 'plat ums') {
                                                                                      days = 40;
                                                                                    } else {
                                                                                      days = int.parse(customPlanDays.text.trim());
                                                                                    }
                                                                                    String newPlanId = FirebaseDatabase.instance.ref().push().key!;
                                                                                    updates['users/$id/plans/$newPlanId'] = {
                                                                                      'date': formattedDate,
                                                                                      'time': time,
                                                                                      'days': days,
                                                                                      'program': initalPlan,
                                                                                      'paymentId': newPaymentId,
                                                                                      'amount': payAmount,
                                                                                      'balance': (days * shakePrice) - payAmount,
                                                                                    };
                                                                                  }
                                                                                  await dbRef.update(updates);
                                                                                  amount.clear();
                                                                                  customPlan.clear();
                                                                                  customPlanDays.clear();
                                                                                  initalPlan = '0 day';
                                                                                  Navigator.of(scaffoldKey.currentContext!).pop();
                                                                                  changeSubmitted();
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
                                                                                    duration: const Duration(milliseconds: 3000),
                                                                                    leftBarIndicatorColor: Colors.red[300],
                                                                                  ).show(scaffoldKey.currentContext!);
                                                                                  changeSubmitted();
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
                                                          );
                                                        }),
                                                      ),
                                                    );
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
                                              onPressed:
                                                  // snack bar
                                                  () {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text('Retail'),
                                                    duration:
                                                        Duration(seconds: 2),
                                                  ),
                                                );
                                              },
                                              child: const Text(
                                                  'Home Program 🏠',
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
                          Text(planName),
                        ),
                        DataCell(
                          Text(days,
                              style: const TextStyle(letterSpacing: 1.8)),
                        ),
                        DataCell(
                          Text(balance,
                              style: TextStyle(
                                  color: int.tryParse(balance) == 0
                                      ? Colors.black
                                      : Colors.red)),
                        ),
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
                                          'Are you sure you want to delete "${name.split(' ')[0]}" from the attendance list?'),
                                      actions: [
                                        TextButton(
                                          child: const Text('Cancel'),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                        TextButton(
                                          child: const Text('Delete'),
                                          onPressed: () {
                                            // delete from firebase
                                            final DatabaseReference dbRef =
                                                coachDb.child(cid);
                                            Map<String, dynamic> updates = {
                                              'attendance/$formattedDate/students/$id':
                                                  null,
                                              'users/${presentStudentsUID[index]}/days/$formattedDate':
                                                  null,
                                            };
                                            try {
                                              dbRef.update(updates);
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
                                            }
                                            Navigator.of(context).pop();
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

  int shakePrice = 240;
  Map<String, dynamic> getPlan(int days,
      {int? assignedPlanDays, String? planName}) {
    String plan;
    String day;
    int balance = 200;

    if (days == 0 || days == 1) {
      plan = '0 day';
      day = '$days / 1';
    } else if (days >= 2 && days < 5) {
      plan = '3 day'; // Change this value as needed
      day = '${days - 1} / 3';
      for (int i = 1; i < days; i++) {
        balance += shakePrice;
      }
    } else {
      if (assignedPlanDays != null && planName != null) {
        plan = planName;
        day = '${days - 1} / $assignedPlanDays';
      } else {
        plan = 'Paid'; // Change this value as needed
        day = '${days - 4} / ${days - 4}';
      }
      for (int i = 1; i < days; i++) {
        balance += shakePrice;
      }
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
  const DailyDetails({
    super.key,
    required this.selectedDate,
    required this.clubFees,
    required this.studentsNameUID,
    required this.zdays,
    required this.shakes,
    required this.revenue,
    required this.users,
  });

  @override
  State<DailyDetails> createState() => _DailyDetailsState();
}

class _DailyDetailsState extends State<DailyDetails> {
// create date variable and set it to widget.selectedDate
  late DateTime selectedDate;
  bool isEdit = false;
  final String cid = FirebaseAuth.instance.currentUser!.uid;
  List<Map<dynamic, dynamic>> todaysProductsHistory = [];
  final DatabaseReference coachDb =
      FirebaseDatabase.instance.ref().child('Coaches');
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  void initState() {
    super.initState();
    selectedDate = widget.selectedDate;
    // get the products history for the selected date
    for (var user in widget.users) {
      if (user['productsHistory'] != null) {
        List<Map<dynamic, dynamic>> productsHistory =
            List<Map<dynamic, dynamic>>.from(user['productsHistory']);
        for (var product in productsHistory) {
          product['name'] = user['name'];
          // convert ms to datetime
          DateTime productDate =
              DateTime.fromMillisecondsSinceEpoch(product['date']);
          if (format.format(productDate) == format.format(selectedDate)) {
            todaysProductsHistory.add(product);
          }
        }
      }
    }
    debugPrint('Products History: $todaysProductsHistory');
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
            showDatePicker(
              context: context,
              initialDate: widget.selectedDate,
              firstDate: DateTime(2023),
              lastDate: today,
            ).then((date) {
              if (date != null) {
                setState(() {
                  //  update the date
                  selectedDate = date;
                });
              }
            });
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
                      String name =
                          widget.studentsNameUID[widget.clubFees[index]['uid']];
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
                                            // get payment id
                                            try {
                                              final DatabaseReference dbRef =
                                                  coachDb.child(cid);
                                              final String uid =
                                                  widget.clubFees[index]['uid'];
                                              final String paymentId = widget
                                                  .clubFees[index]['paymentId'];
                                              debugPrint('UID: $uid');

                                              // delete from firebase
                                              final Map<String, dynamic>
                                                  updates = {
                                                // delete from club fees
                                                'attendance/${DateFormat('ddMMyy').format(selectedDate)}/fees/$paymentId':
                                                    null,
                                                // delete from user payments
                                                'users/$uid/payments/$paymentId':
                                                    null,
                                                // decrement user's total paid amount
                                                'users/$uid/paid':
                                                    ServerValue.increment(
                                                        -int.parse(amount)),
                                              };
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
                                                    "Please check the data and try again or contact support",
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
