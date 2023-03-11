import 'package:flutter/material.dart';
import 'package:slimtrap/components/ui/appbar.dart';
import '../components/ui/card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

extension BodyFormCustomerExtension on BodyFormCustomer {
  String getValueByKey(String key) {
    return {
      'name': name,
      'phone (+91)': phone,
      'age': age,
      'weight (kg)': weight,
      'height (cm)': height,
      'medicalHistory': medicalHistory,
      'city': city,
      'email': email,
    }[key]!;
  }
}

class FieldData {
  final TextEditingController controller;
  final IconData icon;

  FieldData({required this.controller, required this.icon});
}

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
    if (label.toLowerCase().contains('name')) {
      if (value!.length < 3 ||
          !value.contains(RegExp(r'^((\b[a-zA-Z]{2,40}\b)\s*){2,3}$'))) {
        errorMessage.add('Please enter a valid name');
        return '';
      }
    } else if (label.toLowerCase().contains('email')) {
      // email field can be empty or should be valid email format
      if (value!.isNotEmpty &&
          (!RegExp(r'^.+@[a-zA-Z]+\.{1}[a-zA-Z]+(\.{0,1}[a-zA-Z]+)$')
              .hasMatch(value))) {
        errorMessage.add('Please enter a valid email address');
        return '';
      }
    } else if (label.toLowerCase().contains('phone')) {
      // check if phone is valid indian number
      if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value!)) {
        errorMessage.add('Please enter a valid Indian phone number');
        return '';
      }
    } else if (label.toLowerCase().contains('medical')) {
      // medical history field can be empty
    } else if (label == 'Gender') {
      if (value?.toLowerCase() != 'm' && value?.toLowerCase() != 'f') {
        errorMessage.add('Please enter M or F in $label');
        return '';
      }
    } else if (value!.isNotEmpty && label.toLowerCase().contains('age')) {
      // if age is valid int and between 18 and 100 then return null
      if (int.tryParse(value) == null) {
        errorMessage.add('Please enter a valid age');
        return '';
      } else if (int.parse(value) < 15 || int.parse(value) > 100) {
        errorMessage.add('Please enter a valid age');
        return '';
      }
    } else if (value.isNotEmpty && label.toLowerCase().contains('weight')) {
      // if weight is valid int and between 18 and 100 then return null
      if (double.tryParse(value) == null) {
        errorMessage.add('Please enter a valid weight');
        return '';
      } else if (double.parse(value) < 30 || double.parse(value) > 200) {
        errorMessage.add('Please enter a valid weight');
        return '';
      }
    } else if (value.isNotEmpty && label.toLowerCase().contains('height')) {
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
        return 'Please enter a value for $label';
      }
    }
    return null;
  }

  final _controllers = <String, FieldData>{
    'name': FieldData(controller: TextEditingController(), icon: Icons.person),
    'phone (+91)':
        FieldData(controller: TextEditingController(), icon: Icons.phone),
    'age': FieldData(controller: TextEditingController(), icon: Icons.cake),
    'weight (kg)':
        FieldData(controller: TextEditingController(), icon: Icons.line_weight),
    'height (cm)':
        FieldData(controller: TextEditingController(), icon: Icons.height),
    'city': FieldData(
        controller: TextEditingController(), icon: Icons.location_city),
    'email': FieldData(controller: TextEditingController(), icon: Icons.email),
    'Medical History':
        FieldData(controller: TextEditingController(), icon: Icons.history),
    'Created': FieldData(
        controller: TextEditingController(), icon: Icons.calendar_today),
  };

  @override
  void initState() {
    super.initState();
    _controllers.forEach((key, value) {
      if (key.toLowerCase().contains('created')) {
        value.controller.text =
            widget.timeStamp.substring(0, widget.timeStamp.indexOf('.'));
      } else if (key.toLowerCase().contains('phone')) {
        value.controller.text = widget.getValueByKey(key);
        value.controller.text = value.controller.text.substring(3);
      } else if (!key.toLowerCase().contains('medical')) {
        value.controller.text = widget.getValueByKey(key);
      }
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.controller.dispose();
    }
    super.dispose();
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
                for (var controller in _controllers.entries)
                  buildCard(
                    label: controller.key,
                    controller: controller.value.controller,
                    icon: controller.value.icon,
                  ),
              ],
            ),
          ),
        ),
        floatingActionButton: isEditing
            ? FloatingActionButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    try {
                      // update cust in firestore
                      FirebaseFirestore.instance
                          .collection('body_form')
                          .doc(widget.id)
                          .update({
                        'Name': _controllers['name']!.controller.text,
                        'Phone (+91)': int.parse(
                            _controllers['phone (+91)']!.controller.text),
                        'Age': int.parse(_controllers['age']!.controller.text),
                        'Weight': double.parse(
                            _controllers['weight (kg)']!.controller.text),
                        'Height': int.parse(
                            _controllers['height (cm)']!.controller.text),
                        'City': _controllers['city']!.controller.text,
                        'Email': _controllers['email']!.controller.text,
                        'Updated': FieldValue.serverTimestamp(),
                      }).then((value) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Customer updated successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        return Navigator.pop(context);
                      });
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
              )
            : null,
      ),
    );
  }

  Widget buildCard(
      {required String label,
      required IconData icon,
      required TextEditingController controller}) {
    // width according to the value length
    final textPainter = TextPainter(
      text: TextSpan(
        text: controller.text.trim(),
        style: const TextStyle(fontSize: 16),
      ),
      maxLines: 1,
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
                      // capitalize the first letter of the label
                      Text(
                        label[0].toUpperCase() + label.substring(1),
                      ),
                    ],
                  ),
                  if (label != 'Created' && label != 'Medical History')
                    SizedBox(
                      width: (label == 'email' && controller.text.isEmpty)
                          ? 200
                          : fieldWidth,
                      child: TextFormField(
                        // initialValue: value,
                        keyboardType: label.contains('email')
                            ? TextInputType.emailAddress
                            : label.contains('name') ||
                                    label.contains('city') ||
                                    label.contains('gender')
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
                        controller: controller,
                      ),
                    )
                  else
                    Text(controller.text),
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

//  Container(
//                     margin: const EdgeInsets.symmetric(vertical: 5),
//                     child: TextFormField(
//                       controller: fields[i]['controller'],
//                       decoration: InputDecoration(
//                         labelText: fields[i]['label'],
//                         prefixIcon: Icon(fields[i]['icon']),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                         errorStyle: const TextStyle(
//                           color: Colors.red,
//                           fontSize: 15,
//                         ),
//                       ),
//                       validator: (value) =>
//                           _validateField(value, fields[i]['label']),
//                       onSaved: (value) {
//                         fields[i]['value'] = value;
//                       },
//                     ),
//                   ),
