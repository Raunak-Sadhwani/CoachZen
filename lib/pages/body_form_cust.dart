import 'package:flutter/material.dart';
import 'package:slimtrap/components/ui/appbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../components/ui/card.dart';

class BodyFormCustomer extends StatefulWidget {
  final String id,
      name,
      phone,
      age,
      weight,
      height,
      medicalHistory,
      city,
      email,
      timeStamp;
  final bool isMale;
  const BodyFormCustomer({
    Key? key,
    required this.id,
    required this.name,
    required this.phone,
    required this.age,
    required this.weight,
    required this.height,
    required this.medicalHistory,
    required this.email,
    required this.isMale,
    required this.timeStamp,
    required this.city,
  }) : super(key: key);

  @override
  State<BodyFormCustomer> createState() => _BodyFormCustomerState();
}

class _BodyFormCustomerState extends State<BodyFormCustomer> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  bool isEditing = false;
  List errorMessage = [];

  String? _validateField(String? value, String label) {
    if (label == 'Name') {
      if (value!.length < 3 ||
          !value.contains(RegExp(r'^((\b[a-zA-Z]{2,40}\b)\s*){2,3}$'))) {
        errorMessage.add('Please enter a valid name');
        return '';
      }
    } else if (label.contains('Email')) {
      // email field can be empty or should be valid email format
      if (value!.isNotEmpty &&
          (!RegExp(r'^.+@[a-zA-Z]+\.{1}[a-zA-Z]+(\.{0,1}[a-zA-Z]+)$')
              .hasMatch(value))) {
        errorMessage.add('Please enter a valid email address');
        return '';
      }
    } else if (label.contains('Phone')) {
      // check if phone is valid indian number
      if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value!)) {
        errorMessage.add('Please enter a valid Indian phone number');
        return '';
      }
    } else if (label == 'Medical History (optional)') {
      // medical history field can be empty
    } else if (label == 'Gender') {
      if (value?.toLowerCase() != 'm' && value?.toLowerCase() != 'f') {
        errorMessage.add('Please enter M or F in $label');
        return '';
      }
    } else if (value!.isNotEmpty && label == 'Age') {
      // if age is valid int and between 18 and 100 then return null
      if (int.tryParse(value) == null) {
        errorMessage.add('Please enter a valid age');
        return '';
      } else if (int.parse(value) < 15 || int.parse(value) > 100) {
        errorMessage.add('Please enter a valid age');
        return '';
      }
    } else if (value.isNotEmpty && label == 'Weight (kg)') {
      // if weight is valid int and between 18 and 100 then return null
      if (double.tryParse(value) == null) {
        errorMessage.add('Please enter a valid weight');
        return '';
      } else if (double.parse(value) < 30 || double.parse(value) > 200) {
        errorMessage.add('Please enter a valid weight');
        return '';
      }
    } else if (value.isNotEmpty && label == 'Height (cm)') {
      // if height is valid int and between 18 and 100 then return null
      if (int.tryParse(value) == null) {
        errorMessage.add('Please enter a valid height');
        return '';
      } else if (int.parse(value) < 50 || int.parse(value) > 250) {
        errorMessage.add('Please enter a valid height');
        return '';
      }
    } else {
      if (value.isEmpty) {
        errorMessage.add('Please enter a value for $label');
        return '';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: MyAppBar(
          title: widget.name,
          leftIcon: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            color: Colors.black26,
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Container(
          margin: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
          child: Form(
            key: formKey,
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                buildCard('Name', widget.name, Icons.person),
                buildCard(
                    'Phone (+91)', widget.phone.substring(3), Icons.phone),
                buildCard('Age', widget.age, Icons.cake),
                buildCard('Weight (kg)', widget.weight, Icons.line_weight),
                buildCard('Height (cm)', widget.height, Icons.height),
                buildCard('Email', widget.email, Icons.email),
                buildCard('Gender', widget.isMale ? 'M' : 'F', Icons.wc),
                buildCard('Medical History', widget.medicalHistory,
                    Icons.medical_services),
                buildCard(
                    'Created',
                    widget.timeStamp
                        .substring(0, widget.timeStamp.indexOf('.')),
                    Icons.timer),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              try {
                // print all the values in the form
                formKey.currentState!.save();
                print('Name: ${widget.name}');
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error updating customer $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              // if susuccessful show successful message
            } else {
              // break line for each error message if there are multiple
              String error = '';
              for (int i = 0; i < errorMessage.length; i++) {
                error += errorMessage[i];
                if (i != errorMessage.length - 1) {
                  error += '\n';
                }
              }

              // show error message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(error),
                  backgroundColor: Colors.red,
                ),
              );
              errorMessage = [];
            }
          },
          child: const Icon(Icons.save),
        ),
      ),
    );
  }

  Widget buildCard(String label, String value, IconData icon) {
    final textPainter = TextPainter(
      text: TextSpan(text: value, style: const TextStyle(fontSize: 16)),
      textDirection: TextDirection.ltr,
    )..layout();

    final fieldWidth = textPainter.size.width + 5;

    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      child: Column(
        children: [
          UICard(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(icon),
                      const SizedBox(width: 10),
                      Text(label),
                    ],
                  ),
                  if (label != 'Created' && label != 'Medical History')
                    SizedBox(
                      width:
                          label == 'Email' && value.isEmpty ? 200 : fieldWidth,
                      child: TextFormField(
                        initialValue: value,
                        keyboardType: label.toString().contains('Email')
                            ? TextInputType.emailAddress
                            : label == 'Name' ||
                                    label == 'City' ||
                                    label == 'Gender'
                                ? TextInputType.text
                                : TextInputType.number,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(0),
                          errorStyle: TextStyle(
                              height: 0,
                              fontSize: 0,
                              color: Colors.transparent),
                          focusedErrorBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                        ),
                        onChanged: (newValue) {
                          setState(() {
                            isEditing = true;
                          });
                        },
                        validator: (value) => _validateField(value, label),
                      ),
                    )
                  else
                    Text(value),
                ],
              )
            ],
          ),
          // error should be shown here
          // Text()
        ],
      ),
    );
  }
}
