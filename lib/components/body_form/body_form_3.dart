import 'package:flutter/material.dart';
import 'form_fields.dart';

class BodyForm3 extends StatelessWidget {
  final Function(List<Map<String, dynamic>>) onSubmit;

  BodyForm3({Key? key, required this.onSubmit}) : super(key: key);

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  void submitForm() {
    onSubmit(fields);
    if (formKey.currentState!.validate()) {}
  }

  String? _validateField(String? value, String label) {
    if (label == 'Name') {
      // ^((\b[a-zA-Z]{2,40}\b)\s*){2,3}$ regex for name
      if (value!.length < 3 ||
          !value.contains(RegExp(r'^((\b[a-zA-Z]{2,40}\b)\s*){2,3}$'))) {
        return 'Please enter a valid name';
      }
    } else if (label == 'Email (optional)') {
      // email field can be empty or should be valid email format
      if (value!.isNotEmpty &&
          (!RegExp(r'^.+@[a-zA-Z]+\.{1}[a-zA-Z]+(\.{0,1}[a-zA-Z]+)$')
              .hasMatch(value))) {
        return 'Please enter a valid email address';
      }
    } else if ('label' == 'Phone (+91)') {
      // check if phone is valid indian number
      if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value!)) {
        return 'Please enter a valid phone number';
      }
    } else if (label == 'Medical History (optional)') {
      // medical history field can be empty
    } else {
      // other fields should not be empty
      if (value == null || value.isEmpty) {
        return 'Please enter a value';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f6fd),
      body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Form(
            key: formKey,
            child: FormFields(
              fields: fields,
              validator: _validateField,
            ),
          )),
      floatingActionButton: FloatingActionButton(
        onPressed: submitForm,
        child: const Icon(Icons.check),
      ),
    );
  }

  static List<Map<String, dynamic>> fields = [
    {
      "label": "Name",
      "controller": TextEditingController(),
    },
    {
      "label": "Medical History (optional)",
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
      "label": "Email (optional)",
      "controller": TextEditingController(),
    },
  ];

  static List<Map<String, dynamic>> get allFields => BodyForm3.fields;
}
