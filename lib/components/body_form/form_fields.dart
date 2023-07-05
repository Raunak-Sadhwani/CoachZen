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
                    if (!field['label'].toString().contains('Medical'))
                      TextFormField(
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        controller: field['controller'],
                        decoration: InputDecoration(
                          labelText: field['label'],
                          suffixText: field['unit'],
                        ),
                        keyboardType:
                            field['label'].toString().contains('Email')
                                ? TextInputType.emailAddress
                                : field['label'] == 'Name' ||
                                        field['label'] == 'City' ||
                                        field['label']
                                            .toString()
                                            .contains('Medical')
                                    ? TextInputType.text
                                    : TextInputType.number,
                        validator: (value) {
                          return validator(value, field['label']);
                        },
                      )
                    else
                      MedicalHistory(
                        title: field['label'],
                      )
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

class MedicalHistory extends StatefulWidget {
  final String title;

  const MedicalHistory({Key? key, required this.title}) : super(key: key);

  @override
  State<MedicalHistory> createState() => _MedicalHistoryState();
}

class _MedicalHistoryState extends State<MedicalHistory> {
  bool show = false;
  List<TextEditingController> controllers = [TextEditingController()];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(widget.title),
            // checkbox
            Checkbox(
              value: show,
              onChanged: (value) {
                setState(() {
                  show = value!;
                });
              },
            ),
          ],
        ),
        if (show)
          ListView.builder(
            shrinkWrap: true,
            itemCount: controllers.length,
            itemBuilder: (BuildContext context, int index) {
              return Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.only(left: 10),
                    ),
                    controller: controllers[index],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10, left: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              controllers.add(TextEditingController());
                            });
                          },
                          child: const Row(
                            children: [
                              Icon(Icons.add),
                              SizedBox(width: 10),
                              Text('Add More'),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              controllers.removeAt(index);
                            });
                          },
                          child: const Row(
                            children: [
                              Icon(Icons.remove),
                              SizedBox(width: 10),
                              Text('Remove'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }
}
