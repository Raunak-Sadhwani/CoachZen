import 'package:another_flushbar/flushbar.dart';
import 'package:coach_zen/pages/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
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
  final List<String> users = [
    'Raunak Sadhwani',
    'user2',
    'user3',
  ];
  DateTime selectedDate = DateTime.now();
  List<String> presentStudents = [];
  bool isEdit = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
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
                  suggestionsCallback: (pattern) {
                    return users
                        .where((user) =>
                            user.toLowerCase().contains(pattern.toLowerCase()))
                        .toList();
                  },
                  itemBuilder: (context, suggestion) {
                    return ListTile(
                      title: Text(
                        suggestion,
                        maxLines: 1,
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    );
                  },
                  onSuggestionSelected: (suggestion) {
                    // 2. select the user
                    setState(() {
                      presentStudents.add(suggestion);
                    });
                    debugPrint('presentStudents: $presentStudents');
                  },
                ),
              ),

              // 3. add the user to the list
              // data table of present students
              // columns - name, type, days, action
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
                  rows: List<DataRow>.generate(
                    presentStudents.length,
                    (index) => DataRow(
                      cells: <DataCell>[
                        DataCell(
                          Text((index + 1).toString()),
                        ),
                        DataCell(
                          Text(presentStudents[index]),
                          onLongPress: () {
                            // 4. edit the user
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text(
                                      '${presentStudents[index].split(' ')[0]}\'s Action'),
                                  content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: double.infinity,
                                          child: TextButton(
                                              onPressed: () {
                                                // snack bar
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text('Club Fees'),
                                                    duration:
                                                        Duration(seconds: 2),
                                                  ),
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
                        const DataCell(
                          Text('1000', style: TextStyle(color: Colors.red)),
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
                                            'Are you sure you want to delete ${presentStudents[index]}?'),
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
                                                presentStudents.removeAt(index);
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
                    ),
                  ),
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
