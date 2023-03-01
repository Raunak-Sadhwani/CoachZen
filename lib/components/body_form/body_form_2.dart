import 'package:flutter/material.dart';
import 'form_fields.dart';

class BodyForm2 extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  const BodyForm2({
    Key? key,
    required this.formKey,
  }) : super(key: key);

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
    );
  }

  static List<Map<String, dynamic>> fields = [
    {
      "label": "Total Body Fat",
      "unit": "g",
      "controller": TextEditingController(),
    },
    {
      "label": "Visceral Fat",
      "unit": "",
      "controller": TextEditingController(),
    },
    {
      "label": "TSF (Trunk Subcutaneous Fat)",
      "unit": "mm",
      "controller": TextEditingController(),
    },
    {
      "label": "RM (Resting Metabolism)",
      "unit": "kcal",
      "controller": TextEditingController(),
    },
    {
      "label": "BMI (Body Mass Index)",
      "unit": "",
      "controller": TextEditingController(),
    },
    {
      "label": "Skeletal Muscle Level",
      "unit": "",
      "controller": TextEditingController(),
    },
  ];

  static List<Map<String, dynamic>> get allFields => BodyForm2.fields;

  String? _validateField(String? value, String label) {
    if (value == null || value.isEmpty) {
      return 'Please enter a value';
    } else if (value.length > 5 || double.tryParse(value) == null) {
      return 'Please enter a valid number';
    }
    return null;
  }
}
