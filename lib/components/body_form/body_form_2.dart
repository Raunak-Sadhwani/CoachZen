import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'form_fields.dart';
import '../ui/app_colors.dart';

class BodyForm2 extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final VoidCallback? onSubmit;
  final List<DateTime>? disabledDates;
  const BodyForm2({
    Key? key,
    required this.formKey,
    this.onSubmit,
    this.disabledDates,
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
      "unit": "g",
      "controller": TextEditingController(),
    },
    {
      "label": "BMI (Body Mass Index)",
      "unit": "",
      "controller": TextEditingController(),
    },
    {
      "label": "RM (Resting Metabolism)",
      "unit": "kcal",
      "controller": TextEditingController(),
    },
    {
      "label": "Body Age",
      "unit": "yrs",
      "controller": TextEditingController(),
    },
    {
      "label": "TSF (Trunk Subcutaneous Fat)",
      "unit": "mm",
      "controller": TextEditingController(),
    },
    {
      "label": "Skeletal Muscle Level",
      "unit": "",
      "controller": TextEditingController(),
    },
    {
      "label": "date",
      "unit": "",
      "controller": TextEditingController(),
    }
  ];
  // create a bool wantKeepAlive with getter and setter

  static bool wantKeepAlive = true;
  static List<Map<String, dynamic>> get allFields => BodyForm2.fields;
}

class _BodyForm2State extends State<BodyForm2>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => BodyForm2.wantKeepAlive;
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.disabledDates != null && widget.disabledDates!.isNotEmpty) {
      selectedDate =
          DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      while (widget.disabledDates!.contains(selectedDate)) {
        selectedDate =
            DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
        selectedDate = selectedDate.subtract(const Duration(days: 1));
      }
    }
    BodyForm2.fields.last['controller'].text =
        DateFormat('dd-MM-yyyy').format(selectedDate);
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
                selectedDate: selectedDate,
                disabledDates: widget.disabledDates,
                fields: BodyForm2.fields,
                validator: validateField,
              ),
            )),
        floatingActionButton: widget.onSubmit != null
            ? FloatingActionButton(
                onPressed: widget.onSubmit,
                child: const Icon(Icons.check),
              )
            : null);
  }

  String? validateField(String? value, String label) {
    if (value == null || value.isEmpty) {
      return 'Please enter a value';
    }
    double? numericValue = double.tryParse(value);
    if (numericValue == null) {
      return 'Please enter a valid number';
    }
    String lowerCaseLabel = label.toLowerCase();
    if ((lowerCaseLabel.contains('total') &&
            (numericValue > 70 || numericValue < 10)) ||
        (lowerCaseLabel.contains('visceral') && numericValue > 50) ||
        (lowerCaseLabel.contains('bmi') &&
            (numericValue > 50 || numericValue < 10)) ||
        (lowerCaseLabel.contains('resting') &&
            (numericValue > 3000 || numericValue < 500)) ||
        (lowerCaseLabel.contains('age') &&
            (numericValue > 100 || numericValue < 13)) ||
        (lowerCaseLabel.contains('trunk') && numericValue > 70) ||
        (lowerCaseLabel.contains('skeletal') &&
            (numericValue > 60 || numericValue < 10))) {
      return 'Please enter a valid value';
    }
    return null;
  }
}
