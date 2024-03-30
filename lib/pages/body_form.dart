// ignore_for_file: use_build_context_synchronously

import 'package:another_flushbar/flushbar.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:coach_zen/pages/cust_add_weight.dart';
import 'package:coach_zen/pages/home.dart';
import '../components/body_form/body_form_1.dart';
import '../components/body_form/body_form_2.dart';
import '../components/body_form/body_form_3.dart';
import '../components/body_form/form_fields.dart';
import '../components/ui/appbar.dart';

class FormPage extends StatefulWidget {
  final double? height;
  final String? age;
  final bool? gender;
  final List<Map<dynamic, dynamic>>? measurements;
  final String? name;
  final String? uid;

  const FormPage(
      {Key? key,
      this.height,
      this.age,
      this.gender,
      this.measurements,
      this.uid,
      this.name})
      : super(key: key);

  @override
  State<FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  bool onSubmitted = false;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final GlobalKey<FormState> formKey2 = GlobalKey<FormState>();

  final PageController controller = PageController();
  int currentPage = 0;
  int totalPages = 3;
  bool notChangePage = false;

  bool isUser() {
    return widget.uid != null && widget.uid!.isNotEmpty;
  }

  void handleChangePage(bool newValue) {
    setState(() {
      notChangePage = newValue;
    });
  }

  void wantKeepAlive(bool val) {
    BodyForm2.wantKeepAlive = val;
    BodyForm3.wantKeepAlive = val;
  }

  List<DateTime> disabledDates = [];

  @override
  void initState() {
    super.initState();
    wantKeepAlive(true);
    controller.addListener(() {
      setState(() {
        currentPage = controller.page?.round() ?? 0;
      });
    });
    if (isUser()) {
      setState(() {
        totalPages = 2;
      });
      for (int i = 0; i < widget.measurements!.length; i++) {
        DateTime date = DateTime.fromMillisecondsSinceEpoch(
            widget.measurements![i]['date']);
        // remove time if exists
        date = DateTime(date.year, date.month, date.day);
        disabledDates.add(date);
      }
    }
  }

  @override
  void dispose() {
    wantKeepAlive(false);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(
        leftIcon: Container(
          margin: const EdgeInsets.only(left: 10),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            color: Colors.black26,
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        title: 'Check-up ${isUser() ? 'of ${widget.name}' : '(New User)'}',
      ),
      body: Stack(
        children: [
          NotificationListener<OverscrollIndicatorNotification>(
            onNotification: (overscroll) {
              overscroll.disallowIndicator();
              return true;
            },
            child: PageView(
              controller: controller,
              physics: notChangePage
                  ? const NeverScrollableScrollPhysics()
                  : const PageScrollPhysics(),
              children: [
                if (!isUser())
                  BodyForm3(
                    // onSubmit: onSubmit,
                    formKey: formKey,
                  ),
                BodyForm(
                  pageChange: (bool value) {
                    handleChangePage(value);
                  },
                  age: widget.age,
                  heightParam: widget.height,
                  gender: widget.gender,
                ),
                BodyForm2(
                  disabledDates: disabledDates,
                  formKey: formKey2,
                  onSubmit: isUser() ? onSubmitUser : onSubmit,
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                totalPages,
                (index) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: currentPage == index
                        ? Colors.blue
                        : Colors.grey.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  onSubmit() async {
    if (onSubmitted) {
      return;
    }
    setState(() {
      onSubmitted = true;
    });
    if (!await Method.checkInternetConnection(context)) {
      setState(() {
        onSubmitted = false;
      });
      return;
    }
    bool formOneIsValid = formKey.currentState?.validate() ?? false;
    bool formTwoIsValid = formKey2.currentState?.validate() ?? false;

    if (formOneIsValid) {
      try {
        if (!formTwoIsValid) {
          // ScaffoldMessenger.of(context).showSnackBar(
          //   const SnackBar(content: Text('BodyForm2 validation failed!')),
          // );
          setState(() {
            onSubmitted = false;
          });
          return debugPrint('BodyForm2 validation failed');
        }

        List<Map<String, dynamic>> allFields = [
          ...BodyForm.allFields,
          ...BodyForm2.allFields,
          ...BodyForm3.allFields,
        ];
        Map<String, dynamic> data = {};
        List<Map<String, dynamic>> measurements = [];
        List medicalHistory = [];
        for (var field in allFields) {
          if (field['label'] == 'Medical History (optional)') {
            if (MedicalHistory.show) {
              medicalHistory = MedicalHistory.controllers
                  .map((e) => e.text)
                  .toList()
                  .where((element) => element.isNotEmpty)
                  .toList();
              data['medicalHistory'] = medicalHistory;
            }
            continue;
          }
          // I want to make loop go forward if label is 'Medical History (optional)'
          dynamic value = field['controller'].text;
          if (int.tryParse(field['controller'].text) != null) {
            value = int.parse(field['controller'].text);
          } else if (double.tryParse(field['controller'].text) != null) {
            value = double.parse(field['controller'].text);
          } else {
            value = field['controller'].text;
          }
          String label = field['label'];
          if (!BodyForm2.fields.any((element) => element['label'] == label) &&
              label.contains('(')) {
            // split label by '('
            label = label.split('(')[0].trim();
          }
          //  BodyForm2.fields is datatype of List<Map<String, dynamic>>
          // if label contains any of BodyForm2.fields label, add to measurements
          if (value.runtimeType == String) {
            value = value.trim();
          }
          if (BodyForm2.fields.any((element) => element['label'] == label) ||
              label.toLowerCase().contains('weight')) {
            // if measurements doesn't already contain label, add to measurements
            label = label.toLowerCase();
            if (measurements.isNotEmpty) {
              measurements.last[label] = value;
            } else {
              measurements.add({label: value});
            }
            continue;
          } else {
            label = label.toLowerCase();
            data[label] = value;
          }
        }

        try {
          // timestamp from firebase database
          const timestamp = ServerValue.timestamp;
          DateTime date = DateTime.now();
          try {
            final DateFormat format = DateFormat('dd-MM-yyyy');
            date =
                format.parseStrict(BodyForm2.allFields.last['controller'].text);
            measurements.last['date'] = date.millisecondsSinceEpoch;
          } catch (e) {
            setState(() {
              onSubmitted = false;
            });
            Flushbar(
              margin: const EdgeInsets.all(7),
              borderRadius: BorderRadius.circular(15),
              flushbarStyle: FlushbarStyle.FLOATING,
              flushbarPosition: FlushbarPosition.BOTTOM,
              message: "Something went wrong!",
              icon: Icon(
                Icons.error_outline,
                size: 28.0,
                color: Colors.red[300],
              ),
              duration: const Duration(milliseconds: 2000),
              leftBarIndicatorColor: Colors.red[300],
            ).show(context);
            return debugPrint(e.toString());
          }
          User? coach = FirebaseAuth.instance.currentUser;
          String? newUserUid = FirebaseDatabase.instance.ref().push().key;
          if (newUserUid == null) {
            Flushbar(
              margin: const EdgeInsets.all(7),
              borderRadius: BorderRadius.circular(15),
              flushbarStyle: FlushbarStyle.FLOATING,
              flushbarPosition: FlushbarPosition.BOTTOM,
              message: "Something Went Wrong! Try Again",
              icon: Icon(
                Icons.error_outline_rounded,
                size: 28.0,
                color: Colors.red[300],
              ),
              duration: const Duration(milliseconds: 1500),
              leftBarIndicatorColor: Colors.red[300],
            ).show(context);
            setState(() {
              onSubmitted = false;
            });
            return;
          }
          // check if user already exists by phone
          try {
            //  try putting number in phone collection
            // if it fails, then user already exists
            await FirebaseDatabase.instance
                .ref()
                .child('Phones')
                .child(data['phone'].trim())
                .set({
              'cid': coach!.uid,
              'uid': newUserUid,
              'user': true,
              'created': timestamp
            });
          } catch (e) {
            setState(() {
              onSubmitted = false;
            });
            controller.animateToPage(
              0,
              duration: const Duration(milliseconds: 410),
              curve: Curves.easeIn,
            );
            return Flushbar(
              margin: const EdgeInsets.all(7),
              borderRadius: BorderRadius.circular(15),
              flushbarStyle: FlushbarStyle.FLOATING,
              flushbarPosition: FlushbarPosition.BOTTOM,
              message: "User with this phone number already exists!",
              icon: Icon(
                Icons.error_outline,
                size: 28.0,
                color: Colors.red[300],
              ),
              duration: const Duration(milliseconds: 4000),
              leftBarIndicatorColor: Colors.red[300],
            ).show(context);
          }

          data['created'] = timestamp;
          data['measurements'] = measurements;
          data['medicalHistory'] = medicalHistory;
          data['reg'] = 'false';
          data['cid'] = coach.uid;
          // convert age to date of birth
          int age = data['age'];
          DateTime currentDate = DateTime.now();
          DateTime dob = DateTime(
              currentDate.year - age, currentDate.month, currentDate.day);
          data['dob'] = dob.millisecondsSinceEpoch;
          // data['paid'] = 0;
          data['plans'] = [
            {
              'name': 'Zero Day',
              'price': 200,
              'days': 2,
              'started': timestamp,
            }
          ];
          // remove age from data
          data.remove('age');

          // add to firebase database
          await FirebaseDatabase.instance
              .ref()
              .child('Coaches')
              .child(coach.uid)
              .child('users')
              .child(newUserUid)
              .set(data);

          // clear all fields
          for (var field in allFields) {
            if (field['label'] == 'Medical History (optional)') {
              for (var element in MedicalHistory.controllers) {
                element.clear();
              }
              continue;
            }
            String label = field['label'];
            if (!label.toLowerCase().contains('age') &&
                !label.toLowerCase().contains('weight')) {
              field['controller'].clear();
            }
          }
          controller.animateToPage(
            1,
            duration: const Duration(milliseconds: 410),
            curve: Curves.easeIn,
          );
          // if keybord is open, close it
          FocusScope.of(context).unfocus();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
          return Flushbar(
            margin: const EdgeInsets.all(7),
            borderRadius: BorderRadius.circular(15),
            flushbarStyle: FlushbarStyle.FLOATING,
            flushbarPosition: FlushbarPosition.BOTTOM,
            message: "User added successfully!",
            icon: Icon(
              Icons.check_circle_outline,
              size: 28.0,
              color: Colors.green[300],
            ),
            duration: const Duration(milliseconds: 2000),
            leftBarIndicatorColor: Colors.green[300],
          ).show(context);
        } catch (e) {
          // SnackBar
          setState(() {
            onSubmitted = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Something went wrong4!$e'),
            ),
          );
          return debugPrint(e.toString());
        }
      } catch (e) {
        // Error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong 2!'),
          ),
        );
        setState(() {
          onSubmitted = false;
        });
        return debugPrint(e.toString());
      }
    } else {
      controller.animateToPage(
        0,
        duration: const Duration(milliseconds: 410),
        curve: Curves.easeIn,
      );
      setState(() {
        onSubmitted = false;
      });
      return debugPrint('Form1 validation failed');
    }
  }

  onSubmitUser() async {
    if (onSubmitted) {
      return;
    }
    setState(() {
      onSubmitted = true;
    });
    if (!await Method.checkInternetConnection(context)) {
      setState(() {
        onSubmitted = false;
      });
      return;
    }
    bool formOneIsValid = formKey2.currentState?.validate() ?? false;
    if (formOneIsValid) {
      List<Map<String, dynamic>> allFields = [
        // BodyForm.weightController add to allFields
        BodyForm.allFields[1],
        ...BodyForm2.allFields,
      ];
      Map<String, dynamic> data = {};
      for (var field in allFields) {
        dynamic value = field['controller'].text;
        if (int.tryParse(field['controller'].text) != null) {
          value = int.parse(field['controller'].text);
        } else if (double.tryParse(field['controller'].text) != null) {
          value = double.parse(field['controller'].text);
        } else {
          value = field['controller'].text;
        }
        if (field['label'].toLowerCase().contains('weight')) {
          data[field['label'].toLowerCase()] = value;
        } else {
          data[field['label']] = value;
        }
      }
      DateTime date = DateTime.now();
      try {
        final DateFormat format = DateFormat('dd-MM-yyyy');
        date = format.parseStrict(BodyForm2.allFields.last['controller'].text);
        for (int i = 0; i < widget.measurements!.length; i++) {
          if (DateTime.fromMillisecondsSinceEpoch(
                  widget.measurements![i]['date']) ==
              date) {
            setState(() {
              onSubmitted = false;
            });
            return Flushbar(
              margin: const EdgeInsets.all(7),
              borderRadius: BorderRadius.circular(15),
              flushbarStyle: FlushbarStyle.FLOATING,
              flushbarPosition: FlushbarPosition.BOTTOM,
              message: "Weight for this date already exists!",
              icon: Icon(
                Icons.error_outline,
                size: 28.0,
                color: Colors.red[300],
              ),
              duration: const Duration(milliseconds: 2000),
              leftBarIndicatorColor: Colors.red[300],
            ).show(context);
          }
        }
        data['date'] = date.millisecondsSinceEpoch;
      } catch (e) {
        Flushbar(
          margin: const EdgeInsets.all(7),
          borderRadius: BorderRadius.circular(15),
          flushbarStyle: FlushbarStyle.FLOATING,
          flushbarPosition: FlushbarPosition.BOTTOM,
          message: "Something went wrong!",
          icon: Icon(
            Icons.error_outline,
            size: 28.0,
            color: Colors.red[300],
          ),
          duration: const Duration(milliseconds: 2000),
          leftBarIndicatorColor: Colors.red[300],
        ).show(context);
        setState(() {
          onSubmitted = false;
        });
        return debugPrint(e.toString());
      }
      widget.measurements!.add(data);

      final docRef = FirebaseDatabase.instance
          .ref()
          .child('Coaches')
          .child(FirebaseAuth.instance.currentUser!.uid)
          .child('users');
      try {
        await docRef.child(widget.uid!).update({
          'measurements': widget.measurements,
        });
        for (var field in allFields) {
          String label = field['label'];
          if (!label.toLowerCase().contains('age') &&
              !label.toLowerCase().contains('weight')) {
            field['controller'].clear();
          }
        }
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
          (Route<dynamic> route) => false,
        );
        return Flushbar(
          margin: const EdgeInsets.all(7),
          borderRadius: BorderRadius.circular(15),
          flushbarStyle: FlushbarStyle.FLOATING,
          flushbarPosition: FlushbarPosition.BOTTOM,
          message: "${widget.name} check-up added successfully!",
          icon: Icon(
            Icons.check_circle_outline,
            size: 28.0,
            color: Colors.green[300],
          ),
          duration: const Duration(milliseconds: 2000),
          leftBarIndicatorColor: Colors.green[300],
        ).show(context);
      } catch (e) {
        // SnackBar
        Flushbar(
          margin: const EdgeInsets.all(7),
          borderRadius: BorderRadius.circular(15),
          flushbarStyle: FlushbarStyle.FLOATING,
          flushbarPosition: FlushbarPosition.BOTTOM,
          message: "Something went wrong!",
          icon: Icon(
            Icons.error_outline,
            size: 28.0,
            color: Colors.red[300],
          ),
          duration: const Duration(milliseconds: 2000),
          leftBarIndicatorColor: Colors.red[300],
        ).show(context);
        return debugPrint(e.toString());
      }
    } else {
      setState(() {
        onSubmitted = false;
      });
      debugPrint('Form1 validation failed');
    }
  }
}

class FormPageWrapper extends StatelessWidget {
  final double? heightx;
  final String? age;
  final bool? gender;
  final List<Map<dynamic, dynamic>>? measurements;
  final String? name;
  final String? uid;
  final int? popIndex;
  const FormPageWrapper(
      {Key? key,
      this.heightx,
      this.age,
      this.gender,
      this.measurements,
      this.popIndex,
      this.uid,
      this.name})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: MyAppBar(
        // avatar
        leftIcon: Container(
          margin: const EdgeInsets.only(left: 10),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            color: Colors.black26,
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        title: 'Select An Option',
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(width * 0.1),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              HomeButton(
                  height: height,
                  width: width,
                  page: FormPage(
                    age: age,
                    height: heightx,
                    measurements: measurements,
                    uid: uid,
                    name: name,
                    gender: gender,
                  ),
                  colors: const [
                    // pink
                    Color(0xffFF6E6E),
                    Color(0xffFFA6A6),
                  ],
                  label1: 'Full Body',
                  label2: 'Check-up'),
              HomeButton(
                  height: height,
                  width: width,
                  colors: [
                    Colors.blueAccent.shade700,
                    Colors.blue.shade300,
                  ],
                  page: AddWeight(
                    measurements: measurements!,
                    name: name!,
                    popIndex: popIndex!,
                    uid: uid!,
                  ),
                  label1: 'Add ',
                  label2: 'Weight'),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeButton extends StatelessWidget {
  final double height;
  final double width;
  final String label1;
  final String label2;
  final Widget page;
  final List<Color> colors;

  const HomeButton(
      {Key? key,
      required this.height,
      required this.width,
      required this.label1,
      required this.label2,
      required this.page,
      required this.colors})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: height * 0.1),
      height: height * 0.2,
      child: Card(
        elevation: 10,
        child: OpenContainerWrapper(
          page: page,
          content: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label1,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label2,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
