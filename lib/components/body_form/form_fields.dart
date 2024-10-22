import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../ui/card.dart';

class FormFields extends StatelessWidget {
  final List<Map<String, dynamic>> fields;
  final List<DateTime>? disabledDates;
  
  final Function validator;

  final DateTime? selectedDate;

  const FormFields(
      {Key? key,
      required this.fields,
      required this.validator,
      this.selectedDate,
      this.disabledDates})
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
                    if (field['label']
                        .toString()
                        .toLowerCase()
                        .contains('medical'))
                      MedicalHistory(
                        title: field['label'],
                      )
                    else if (field['label']
                        .toString()
                        .toLowerCase()
                        .contains('date'))
                      TextFormField(
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        readOnly: true,
                        controller: field['controller'],
                        decoration: const InputDecoration(
                          labelText: 'Date',
                        ),
                        onTap: () {
                          showDatePicker(
                            context: context,
                            initialDate: selectedDate!,
                            firstDate: DateTime(DateTime.now().year - 13),
                            lastDate: DateTime.now(),
                            selectableDayPredicate: (DateTime date) {
                              if (disabledDates == null ||
                                  disabledDates!.isEmpty) {
                                return true;
                              } else {
                                return !disabledDates!.contains(date);
                              }
                            },
                          ).then((date) {
                            if (date != null) {
                              field['controller'].text =
                                  DateFormat('dd-MM-yyyy').format(date);
                            }
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a date';
                          }
                          final DateFormat format = DateFormat('dd-MM-yyyy');
                          try {
                            format.parseStrict(value);
                          } catch (e) {
                            return 'Please enter a valid date';
                          }
                          return null;
                        },
                      )
                    else
                      TextFormField(
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        controller: field['controller'],
                        decoration: InputDecoration(
                          counterText: "",
                          labelText: field['label'],
                          prefixText: field['label']
                                  .toString()
                                  .toLowerCase()
                                  .contains('phone')
                              ? "+91  "
                              : null,
                          suffixText: field['unit'],
                        ),
                        maxLength: field['label']
                                .toString()
                                .toLowerCase()
                                .contains('phone')
                            ? 10
                            : null,
                        

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
  static List<TextEditingController> controllers = [TextEditingController()];
  static bool show = false;

  const MedicalHistory({Key? key, required this.title}) : super(key: key);

  @override
  State<MedicalHistory> createState() => _MedicalHistoryState();
}

class _MedicalHistoryState extends State<MedicalHistory> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(widget.title),
            
            Checkbox(
              value: MedicalHistory.show,
              onChanged: (value) {
                setState(() {
                  MedicalHistory.show = value!;
                });
              },
            ),
          ],
        ),
        if (MedicalHistory.show)
          ListView.builder(
            shrinkWrap: true,
            itemCount: MedicalHistory.controllers.length,
            itemBuilder: (BuildContext context, int index) {
              return Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.only(left: 10),
                    ),
                    controller: MedicalHistory.controllers[index],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10, left: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              MedicalHistory.controllers
                                  .add(TextEditingController());
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
                              MedicalHistory.controllers.removeAt(index);
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
