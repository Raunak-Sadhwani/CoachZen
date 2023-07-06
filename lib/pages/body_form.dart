// ignore_for_file: use_build_context_synchronously

import 'package:another_flushbar/flushbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:slimtrap/pages/home.dart';
import '../components/body_form/body_form_1.dart';
import '../components/body_form/body_form_2.dart';
import '../components/body_form/body_form_3.dart';
import '../components/body_form/form_fields.dart';
import '../components/ui/appbar.dart';

class FormPage extends StatefulWidget {
  const FormPage({Key? key}) : super(key: key);

  @override
  State<FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final GlobalKey<FormState> formKey2 = GlobalKey<FormState>();

  final PageController controller = PageController();
  int currentPage = 0;
  int totalPages = 3;
  bool notChangePage = false;

  void handleChangePage(bool newValue) {
    setState(() {
      notChangePage = newValue;
    });
  }

  void wantKeepAlive(bool val) {
    BodyForm2.wantKeepAlive = val;
    BodyForm3.wantKeepAlive = val;
  }

  @override
  void initState() {
    super.initState();
    wantKeepAlive(true);
    controller.addListener(() {
      setState(() {
        currentPage = controller.page?.round() ?? 0;
      });
    });
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
        title: 'Body Form',
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
                BodyForm(
                  pageChange: (bool value) {
                    handleChangePage(value);
                  },
                ),
                BodyForm2(
                  formKey: formKey,
                ),
                BodyForm3(
                  onSubmit: onSubmit,
                  formKey: formKey2,
                )
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
    bool formOneIsValid = formKey.currentState?.validate() ?? false;
    bool formTwoIsValid = formKey2.currentState?.validate() ?? false;

    if (formOneIsValid) {
      try {
        if (!formTwoIsValid) {
          // ScaffoldMessenger.of(context).showSnackBar(
          //   const SnackBar(content: Text('BodyForm2 validation failed!')),
          // );
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
          FieldValue timestamp = FieldValue.serverTimestamp();
          // convert FieldValue timestamp to datetime
          User? coach = FirebaseAuth.instance.currentUser;
          // add timestamp of firestore
          data['created'] = timestamp;
          measurements.last['date'] = DateTime.now();
          data['measurements'] = measurements;
          data['medicalHistory'] = medicalHistory;
          data['reg'] = 'false';
          data['cid'] = coach!.uid;
          // convert age to date of birth
          int age = data['age'];
          DateTime currentDate = DateTime.now();
          DateTime dob = DateTime(
              currentDate.year - age, currentDate.month, currentDate.day);
          data['dob'] = dob;
          // remove age from data
          data.remove('age');
          debugPrint(data.toString());

          // Create a Firestore document reference
          final docRef = FirebaseFirestore.instance.collection('Users');

          // Set data to the document
          await docRef.add(
            data,
          );
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Something went wrong4!'),
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
        return debugPrint(e.toString());
      }
    } else {
      controller.animateToPage(
        1,
        duration: const Duration(milliseconds: 410),
        curve: Curves.easeIn,
      );
      return debugPrint('Form1 validation failed');
    }
  }
}
