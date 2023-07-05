import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../components/body_form/body_form_1.dart';
import '../components/body_form/body_form_2.dart';
import '../components/body_form/body_form_3.dart';
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
        dynamic data = [];
        for (var field in allFields) {
          dynamic value = field['controller'].text;
          if (int.tryParse(field['controller'].text) != null) {
            value = int.parse(field['controller'].text);
          } else if (double.tryParse(field['controller'].text) != null) {
            value = double.parse(field['controller'].text);
          } else {
            value = field['controller'].text;
          }
          String label = field['label'];
          if (label.contains(' (optional)') && value.toString().isEmpty) {
            // remove (optional) from label
            label = label.substring(0, label.length - 11);
          }
          data.add({
            label: value,
          });
        }

        try {
          //  convert data to Map<String, dynamic> type
          data = data.reduce((value, element) => value..addAll(element));

          // add timestamp of firestore
          data['timestamp'] = FieldValue.serverTimestamp();

          // Create a Firestore document reference
          final docRef =
              FirebaseFirestore.instance.collection('body_form').doc();

          // Set data to the document
          await docRef.set(
            data,
          );
          // ignore: use_build_context_synchronously
          return ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data stored successfully!'),
            ),
          );
        } catch (e) {
          // SnackBar
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Something went wrong!'),
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
