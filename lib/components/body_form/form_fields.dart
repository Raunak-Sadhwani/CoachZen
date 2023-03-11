import 'package:flutter/material.dart';
import '../ui/card.dart';

class FormFields extends StatelessWidget {
  final List<Map<String, dynamic>> fields;
  // validator
  final Function validator;

  const FormFields({Key? key, required this.fields, required this.validator})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...fields.map(
          (field) => Container(
            margin: EdgeInsets.symmetric(
              vertical: height * 0.02,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: width * 0.05,
              vertical: height * 0.01,
            ),
            child: Column(
              children: [
                UICard(
                  width: width,
                  children: [
                    TextFormField(
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      controller: field['controller'],
                      decoration: InputDecoration(
                        labelText: field['label'],
                        suffixText: field['unit'],
                      ),
                      keyboardType: field['label'].toString().contains('Email')
                          ? TextInputType.emailAddress
                          : field['label'] == 'Name' ||
                                  field['label'] == 'City' ||
                                  field['label'].toString().contains('Medical')
                              ? TextInputType.text
                              : TextInputType.number,
                      validator: (value) {
                        return validator(value, field['label']);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: height * 0.03),
      ],
    );
  }
}
