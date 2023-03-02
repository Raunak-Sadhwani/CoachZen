import 'package:flutter/material.dart';
import 'form_fields.dart';
import '../app_colors.dart';

// ignore: must_be_immutable
class BodyForm2 extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  const BodyForm2({
    Key? key,
    required this.formKey,
  }) : super(key: key);

  @override
  State<BodyForm2> createState() => _BodyForm2State();

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
  // create a bool wantKeepAlive with getter and setter

  static bool wantKeepAlive = true;
  static List<Map<String, dynamic>> get allFields => BodyForm2.fields;
}

class _BodyForm2State extends State<BodyForm2>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => BodyForm2.wantKeepAlive;

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
              fields: BodyForm2.fields,
              validator: _validateField,
            ),
          )),
    );
  }

  String? _validateField(String? value, String label) {
    if (value == null || value.isEmpty) {
      return 'Please enter a value';
    } else if (value.length > 5 || double.tryParse(value) == null) {
      return 'Please enter a valid number';
    }
    return null;
  }
}
