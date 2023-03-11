import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:slimtrap/components/ui/appbar.dart';
import '../components/ui/card.dart';

// make proper variables for weight, height, medical history, city, email
String bname = 'Name';
String bphone = 'Phone (+91)';
String bage = 'Age';
String bweight = 'Weight (kg)';
String bheight = 'Height (cm)';
String bmedicalHistory = 'Medical History';
String bcity = 'City';
String bgender = 'Gender';
String bemail = 'Email';
String created = 'Created';

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

  final _controllers = <String, FieldData>{
    bname: FieldData(controller: TextEditingController(), icon: Icons.person),
    bphone: FieldData(controller: TextEditingController(), icon: Icons.phone),
    bage: FieldData(controller: TextEditingController(), icon: Icons.cake),
    bweight:
        FieldData(controller: TextEditingController(), icon: Icons.line_weight),
    bheight: FieldData(controller: TextEditingController(), icon: Icons.height),
    bcity: FieldData(
        controller: TextEditingController(), icon: Icons.location_city),
    bgender: FieldData(controller: TextEditingController(), icon: Icons.wc),
    bemail: FieldData(controller: TextEditingController(), icon: Icons.email),
    bmedicalHistory:
        FieldData(controller: TextEditingController(), icon: Icons.history),
    created: FieldData(
        controller: TextEditingController(), icon: Icons.calendar_today),
  };

  String? _validateField(String? value, String label) {
    if (label.toLowerCase().contains('name')) {
      if (value!.length < 3 ||
          !value.trim().contains(RegExp(r'^((\b[a-zA-Z]{2,40}\b)\s*){2,3}$'))) {
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

  List<String> updateFields = [];

  @override
  void initState() {
    super.initState();

    // previous values of the fields
    Map<String, String> previousValues = {
      bname: widget.name,
      bphone: widget.phone,
      bage: widget.age,
      bweight: widget.weight,
      bheight: widget.height,
      bmedicalHistory: widget.medicalHistory,
      bcity: widget.city,
      bgender: widget.isMale ? 'M' : 'F',
      bemail: widget.email,
      created: widget.timeStamp.substring(0, widget.timeStamp.indexOf('.')),
    };

    _controllers.forEach((key, value) {
      if (key.toLowerCase().contains('created')) {
        value.controller.text = previousValues[key]!;
      } else if (key.toLowerCase().contains('phone')) {
        value.controller.text = previousValues[bphone]!;
        value.controller.text = value.controller.text.substring(3);
      } else if (!key.toLowerCase().contains('medical')) {
        value.controller.text = previousValues[key]!;
      }
      value.controller.addListener(() {
        // check if any field is changed and if yes then add it to updateFields
        if (value.controller.text != previousValues[key]) {
          if (!updateFields.contains(key) &&
              !key.toLowerCase().contains('created')) {
            updateFields.add(key);
          }
        } else {
          // if field is not changed then remove it from updateFields
          if (updateFields.contains(key)) {
            updateFields.remove(key);
          }
        }
        // if updateFields isnot empty then enable the isEditing flag
        setState(() {
          isEditing = updateFields.isNotEmpty;
        });
      });
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

                      Map<String, dynamic> data = {
                        'Name': _controllers[bname]!.controller.text.trim(),
                        'Phone (+91)':
                            int.parse(_controllers[bphone]!.controller.text),
                        'Age': int.parse(_controllers[bage]!.controller.text),
                        'Weight': double.parse(
                            // fixed 2 decimal places
                            _controllers[bweight]!.controller.text.substring(
                                0,
                                _controllers[bweight]!
                                        .controller
                                        .text
                                        .indexOf('.') +
                                    2)),
                        'Height':
                            int.parse(_controllers[bheight]!.controller.text),
                        'City': _controllers[bcity]!.controller.text,
                        'Gender': _controllers[bgender]!
                                    .controller
                                    .text
                                    .toLowerCase() ==
                                'm'
                            ? "Male"
                            : "Female",
                        'Email': _controllers[bemail]!.controller.text,
                      };
                      // update only the fields that are changed
                      List updateValues = [];
                      for (var element in updateFields) {
                        if (element.contains('Weight') ||
                            element.contains('Height')) {
                          element = element.substring(0, element.indexOf(' '));
                        }
                        updateValues.add(data[element]);
                      }
                      for (int i = 0; i < updateFields.length; i++) {
                        debugPrint(
                            '${updateFields[i]} ${updateValues[i]}'.toString());
                      }
                      FirebaseFirestore.instance
                          .collection('body_form')
                          .doc(widget.id)
                          .update({
                        for (int i = 0; i < updateFields.length; i++)
                          updateFields[i]: updateValues[i],
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
                      Text(
                        label[0].toUpperCase() + label.substring(1),
                      ),
                    ],
                  ),
                  if (!label.toLowerCase().contains('created') &&
                      !label.toLowerCase().contains('medical'))
                    SizedBox(
                      width: label.toLowerCase().contains('email') &&
                              controller.text.trim().length > 20
                          ? 200
                          : fieldWidth,
                      child: TextFormField(
                        // initialValue: value,
                        keyboardType: label.toLowerCase().contains('email')
                            ? TextInputType.emailAddress
                            : label.toLowerCase().contains('name') ||
                                    label.toLowerCase().contains('city') ||
                                    label.toLowerCase().contains('gender')
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
        ],
      ),
    );
  }
}

extension BodyFormCustomerExtension on BodyFormCustomer {
  String getValueByKey(String key) {
    return {
          bname: name,
          bphone: phone,
          bage: age,
          bweight: weight,
          bheight: height,
          bmedicalHistory: medicalHistory,
          bcity: city,
          bemail: email,
          created: created,
        }[key] ??
        '';
  }
}
