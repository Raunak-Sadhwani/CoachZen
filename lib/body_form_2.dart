import 'package:flutter/material.dart';
import 'components/card.dart';
import 'body_form_1.dart';

class BodyForm2 extends StatefulWidget {
  final Function(List<Map<String, dynamic>>) onSubmit;
  const BodyForm2({Key? key, required this.onSubmit}) : super(key: key);

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

  static List<Map<String, dynamic>> get allFields => BodyForm.fields + fields;
}

class _BodyForm2State extends State<BodyForm2> {
  final formKey = GlobalKey<FormState>();

  void submitForm() {
    if (formKey.currentState!.validate()) {
      widget.onSubmit(BodyForm2.allFields);
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xfff5f6fd),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...BodyForm2.fields.map(
                (field) => Container(
                  margin: EdgeInsets.symmetric(
                    vertical: height * 0.01,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: width * 0.05,
                    vertical: height * 0.01,
                  ),
                  child: UICard(
                    width: width,
                    children: [
                      TextFormField(
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        controller: field['controller'],
                        decoration: InputDecoration(
                          labelText: field['label'],
                          suffixText: field['unit'],
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a value';
                          } else if (value.length > 4) {
                            field['controller'].text = value.substring(0, 4);
                            return 'Please enter a valid number';
                          } else if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: height * 0.03),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: submitForm,
        child: const Icon(Icons.check),
      ),
    );
  }
}
