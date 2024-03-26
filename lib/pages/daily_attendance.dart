import 'package:another_flushbar/flushbar.dart';
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
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  // scaffold key
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  final String cid = FirebaseAuth.instance.currentUser!.uid;
  final DatabaseReference coachDb =
      FirebaseDatabase.instance.ref().child('Coaches');
  List<dynamic> users = [];
  DateTime selectedDate = DateTime.now();
  List<Map<dynamic, dynamic>> clubFees = [];
  List<String> presentStudentsUID = [];
  bool isEdit = false;
  String initalPlan = '0 day';
  TextEditingController amount = TextEditingController();
  TextEditingController customPlan = TextEditingController();
  String initalMode = 'Cash';

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    getUsers();
    coachDb
        .child(cid)
        .child('attendance')
        .child(DateFormat('ddMMyy').format(selectedDate))
        .onValue
        .listen((event) {
      debugPrint('Data: ${event.snapshot.value}');
      if (mounted) {
        setState(() {
          presentStudentsUID.clear();
          Object? data = event.snapshot.value;
          if (data != null) {
            Map<dynamic, dynamic> attendanceData =
                Map<dynamic, dynamic>.from(data as Map<dynamic, dynamic>);
            List<dynamic> students = attendanceData['students'];
            presentStudentsUID = List<String>.from(students);
          }
        });
      }
    });
  }

  void getUsers() async {
    final DatabaseReference dbRef = coachDb.child(cid).child('users');
    dbRef.once().then((DatabaseEvent event) {
      Object? usersData = event.snapshot.value;
      if (usersData != null) {
        // users.add({
        //     'id': key,
        //     'name': userData['name'],
        //     'phone': userData['phone'],
        //     // Add other user fields as needed
        //   });
        // Cast usersData to Map<String, dynamic> and then iterate through it
        Map<dynamic, dynamic> usersDataMap =
            Map<dynamic, dynamic>.from(usersData as Map<dynamic, dynamic>);
        usersDataMap.forEach((key, userData) {
          // userIdToNameMap[key] = userData['name'];
          users.add({
            'id': key,
            'name': userData['name'],
            'phone': userData['phone'],
            'balance': userData['balance'],
            // Add other user fields as needed
          });
        });
      }
      // Now you have a list of user objects in the users list
      // Do whatever you want with the users list here
    });
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
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
                  Navigator.pop(context);
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
                      //  update the date
                      selectedDate = date;
                    });
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
                  Navigator.pop(context);
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
                padding: EdgeInsets.all(screenWidth * 0.04),
                child: TypeAheadField(
                  direction: AxisDirection.up,
                  textFieldConfiguration: TextFieldConfiguration(
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Student Name',
                      border: OutlineInputBorder(
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
                    if (!presentStudentsUID.contains(selectedUserId)) {
                      setState(() {
                        presentStudentsUID.add(selectedUserId);
                      });
                    } else {
                      return;
                    }
                    // add to firebase
                    try {
                      final DatabaseReference dbRef = coachDb
                          .child(cid)
                          .child('attendance')
                          .child(DateFormat('ddMMyy').format(selectedDate))
                          .child('students');
                      dbRef.set(presentStudentsUID);
                    } catch (e) {
                      setState(() {
                        presentStudentsUID.remove(suggestion);
                      });
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
                      ).show(context);
                    }
                  },
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
                  rows: List<DataRow>.generate(presentStudentsUID.length,
                      (index) {
                    // get user
                    final user = users.firstWhere(
                        (user) => user['id'] == presentStudentsUID[index]);
                    String id = user['id'];
                    String name = user['name'];
                    String balance = user['balance'].toString();
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
                                                    return SingleChildScrollView(
                                                      child: Positioned(
                                                        top: 0,
                                                        child: StatefulBuilder(
                                                            builder: (context,
                                                                setState) {
                                                          {
                                                            return Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(16),
                                                              child: Material(
                                                                // color: Colors.green,
                                                                shape: RoundedRectangleBorder(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
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
                                                                              child: Container(
                                                                            margin:
                                                                                const EdgeInsets.only(bottom: 10),
                                                                            child:
                                                                                const Text(
                                                                              'Club Fees 💵',
                                                                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.greenAccent),
                                                                            ),
                                                                          )),
                                                                        ],
                                                                      ),
                                                                      Form(
                                                                        key:
                                                                            formKey,
                                                                        autovalidateMode:
                                                                            AutovalidateMode.onUserInteraction,
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
                                                                                      } else if (int.tryParse(value)! < 0) {
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
                                                                                  child: DropdownButtonFormField<String>(
                                                                                    decoration: const InputDecoration(
                                                                                      labelText: 'Program',
                                                                                    ),
                                                                                    value: initalPlan,
                                                                                    items: [
                                                                                      '0 day',
                                                                                      '3 day',
                                                                                      'Gold UMS',
                                                                                      'Plat UMS',
                                                                                      'Other', // Add 'Other' option
                                                                                    ].map((String value) {
                                                                                      return DropdownMenuItem<String>(
                                                                                        value: value,
                                                                                        child: Text(value),
                                                                                      );
                                                                                    }).toList(),
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
                                                                              ],
                                                                            ),
                                                                            // 2 buttons
                                                                          ],
                                                                        ),
                                                                      ),
                                                                      Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.spaceAround,
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.center,
                                                                        children: [
                                                                          Expanded(
                                                                            child:
                                                                                TextButton(
                                                                              onPressed: () {
                                                                                Navigator.of(context).pop();
                                                                              },
                                                                              child: const Text('Cancel'),
                                                                            ),
                                                                          ),
                                                                          Expanded(
                                                                            child:
                                                                                TextButton(
                                                                              onPressed: () async {
                                                                                if (formKey.currentState!.validate()) {
                                                                                  // save the data
                                                                                  // save to firebase
                                                                                  // add to firebase
                                                                                  try {
                                                                                    if (initalPlan == 'Other') {
                                                                                      initalPlan = customPlan.text.trim();
                                                                                    }
                                                                                    // balance
                                                                                    int newBalance = int.parse(balance) - int.parse(amount.text.trim());
                                                                                    final DatabaseReference dbRef = coachDb.child(cid);
                                                                                    await dbRef.child('attendance').child(DateFormat('ddMMyy').format(selectedDate)).child('fees').push().set({
                                                                                      'uid': id,
                                                                                      'program': initalPlan,
                                                                                      'amount': int.parse(amount.text.trim()),
                                                                                      'mode': initalMode,
                                                                                      'balance': newBalance,
                                                                                    });
                                                                                    // set user balance
                                                                                    await dbRef.child('users').child(id).update({
                                                                                      'balance': newBalance,
                                                                                    });
                                                                                    getUsers();
                                                                                    Navigator.of(scaffoldKey.currentContext!).pop();
                                                                                  } catch (e) {
                                                                                    Flushbar(
                                                                                      margin: const EdgeInsets.all(7),
                                                                                      borderRadius: BorderRadius.circular(15),
                                                                                      flushbarStyle: FlushbarStyle.FLOATING,
                                                                                      flushbarPosition: FlushbarPosition.TOP,
                                                                                      message: "Please check the data and try again or contact support",
                                                                                      icon: Icon(
                                                                                        Icons.error_outline_rounded,
                                                                                        size: 28.0,
                                                                                        color: Colors.red[300],
                                                                                      ),
                                                                                      duration: const Duration(milliseconds: 3000),
                                                                                      leftBarIndicatorColor: Colors.red[300],
                                                                                    ).show(scaffoldKey.currentContext!);
                                                                                  }
                                                                                }
                                                                              },
                                                                              child: const Text('Save'),
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                            );
                                                          }
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
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text('Retail'),
                                                    duration:
                                                        Duration(seconds: 2),
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
                        const DataCell(
                          Text('UMS'),
                        ),
                        const DataCell(
                          Text('25/30', style: TextStyle(letterSpacing: 1.8)),
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
                                setState(() {
                                  // ask for confirmation
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text('Confirmation'),
                                        content: Text(
                                            'Are you sure you want to delete ${presentStudentsUID[index]}?'),
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
                                              setState(() {
                                                presentStudentsUID
                                                    .removeAt(index);
                                              });
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                });
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
}

class DailyDetails extends StatefulWidget {
  final DateTime selectedDate;
  const DailyDetails({
    super.key,
    required this.selectedDate,
  });

  @override
  State<DailyDetails> createState() => _DailyDetailsState();
}

class _DailyDetailsState extends State<DailyDetails> {
// create date variable and set it to widget.selectedDate
  late DateTime selectedDate;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.selectedDate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                            '4',
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
                            '24',
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
                        '₹ 10000',
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
                    columns: const <DataColumn>[
                      DataColumn(
                        label: Text('Name'),
                      ),
                      DataColumn(
                        label: Text('Program'),
                      ),
                      DataColumn(
                        label: Text('Mode'),
                      ),
                      DataColumn(
                        label: Text('Amount'),
                      ),
                      DataColumn(
                        label: Text('C. Balance'),
                      ),
                    ],
                    rows: const <DataRow>[
                      DataRow(cells: <DataCell>[
                        DataCell(Text('Raunak Sadhwani')),
                        DataCell(Text('UMS')),
                        DataCell(Text('Cash')),
                        DataCell(Text('1000')),
                        DataCell(
                            Text('6000', style: TextStyle(color: Colors.red))),
                      ]),
                      DataRow(cells: <DataCell>[
                        DataCell(Text('Raunak Sadhwani')),
                        DataCell(Text('UMS')),
                        DataCell(Text('Online')),
                        DataCell(Text('3000')),
                        DataCell(
                            Text('3000', style: TextStyle(color: Colors.red))),
                      ]),
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
                    horizontalMargin: MediaQuery.of(context).size.width * 0.02,
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
                    rows: <DataRow>[
                      DataRow(cells: <DataCell>[
                        const DataCell(Text('Raunak Sadhwani')),
                        DataCell(
                          IconButton(
                            icon: const Icon(Icons.arrow_drop_down_rounded),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return const AlertDialog(
                                    title: Text('Raunak Sadhwani\'s Retail'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('1 Multivitamin'),
                                        Text('1 F2 Kulfi'),
                                        Text('1 F3 Kulfi'),
                                        Text('1 F4 Kulfi'),
                                        Text('1 F5 Kulfi'),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        const DataCell(Text('Cash')),
                        const DataCell(Text('10000')),
                        const DataCell(
                            Text('0', style: TextStyle(color: Colors.red))),
                      ]),
                      const DataRow(cells: <DataCell>[
                        DataCell(Text('Raunak Sadhwani')),
                        DataCell(Text('1 F1 Kulfi')),
                        DataCell(Text('Online')),
                        DataCell(Text('1500')),
                        DataCell(
                            Text('1000', style: TextStyle(color: Colors.red))),
                      ]),
                    ],
                  ),
                ),
              ]),
        ),
      ),
    );
  }

  void showCustomDialog(BuildContext context, String message) {}
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
