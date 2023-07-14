import 'package:flutter/material.dart';
import 'form_fields.dart';
import '../ui/app_colors.dart';

class BodyForm3 extends StatefulWidget {
  // final VoidCallback onSubmit;
  final GlobalKey<FormState> formKey;
  const BodyForm3({Key? key, required this.formKey}) : super(key: key);

  @override
  State<BodyForm3> createState() => _BodyForm3State();

  static List<Map<String, dynamic>> fields = [
    {
      "label": "Name",
      "controller": TextEditingController(),
    },
    {
      "label": "Phone (+91)",
      "controller": TextEditingController(),
    },
    {
      "label": "City",
      "controller": TextEditingController(),
    },
    {
      "label": "Medical History (optional)",
      // "controller": TextEditingController(),
    },
    {
      "label": "Email (optional)",
      "controller": TextEditingController(),
    },
  ];
  static bool wantKeepAlive = true;

  static List<Map<String, dynamic>> get allFields => BodyForm3.fields;
}

class _BodyForm3State extends State<BodyForm3>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => BodyForm3.wantKeepAlive;

  String? _validateField(String? value, String label) {
    if (label == 'Name') {
      if (value!.length < 3 ||
          !value.contains(RegExp(r'^((\b[a-zA-Z]{2,40}\b)\s*){2,3}$'))) {
        return 'Please enter a valid name';
      }
    } else if (label.contains('Email')) {
      // email field can be empty or should be valid email format
      if (value!.isNotEmpty &&
          (!RegExp(r'^.+@[a-zA-Z]+\.{1}[a-zA-Z]+(\.{0,1}[a-zA-Z]+)$')
              .hasMatch(value))) {
        return 'Please enter a valid email address';
      }
    } else if (label.contains('Phone')) {
      // check if phone is valid indian number
      if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value!)) {
        return 'Please enter a valid Indian phone number';
      }
    } else if (label == 'City') {
      // containy only alphabets and spaces
      if (value!.length < 3 || !value.contains(RegExp(r'^[a-zA-Z\s]+$'))) {
        return 'Invalid city name';
      }
      return null;
    }
    // else if (label == 'Medical History (optional)') {
    //   // medical history field can be empty
    // }
    else {
      // other fields should not be empty
      if (value == null || value.isEmpty) {
        return 'Please enter a value';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Form(
            key: widget.formKey,
            child: FormFields(
              fields: BodyForm3.fields,
              validator: _validateField,
            ),
          )),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: widget.onSubmit,
      //   child: const Icon(Icons.check),
      // ),
    );
  }
}
