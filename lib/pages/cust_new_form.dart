import 'package:another_flushbar/flushbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:slimtrap/components/body_form/gender_switch.dart';

import '../components/ui/appbar.dart';

class CustNewForm extends StatefulWidget {
  const CustNewForm({Key? key}) : super(key: key);

  @override
  State<CustNewForm> createState() => _CustNewFormState();
}

class _CustNewFormState extends State<CustNewForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _dateController = TextEditingController(
    text: DateFormat('dd-MM-yyyy - hh:mm a').format(DateTime.now()),
  );
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  bool autoValidate = false;
  bool isMale = true;

  @override
  void dispose() {
    _dateController.dispose();
    _nameController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      key: scaffoldKey,
      appBar: MyAppBar(
        title: 'New Customer',
        leftIcon: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: Colors.black26,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: width * 0.06, vertical: height * 0.02),
          child: Form(
            autovalidateMode: autoValidate
                ? AutovalidateMode.always
                : AutovalidateMode.disabled,
            key: _formKey,
            child: Column(
              children: [
                CustomTextFormField(
                  labelText: 'Creation Date',
                  readOnly: true,
                  controller: _dateController,
                  onTap: () {
                    showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(DateTime.now().year - 13),
                      lastDate: DateTime.now(),
                    ).then((date) {
                      if (date != null) {
                        // show time picker
                        showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        ).then((time) {
                          if (time != null) {
                            setState(() {
                              _dateController.text =
                                  DateFormat('dd-MM-yyyy - hh:mm a').format(
                                DateTime(
                                  date.year,
                                  date.month,
                                  date.day,
                                  time.hour,
                                  time.minute,
                                ),
                              );
                            });
                          }
                        });
                      }
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a date';
                    }
                    final DateFormat format =
                        DateFormat('dd-MM-yyyy - hh:mm a');
                    try {
                      format.parseStrict(value);
                    } catch (e) {
                      return 'Please enter a valid date';
                    }
                    return null;
                  },
                ),
                CustomTextFormField(
                  controller: _nameController,
                  labelText: 'Name',
                  keyboardType: TextInputType.name,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter name';
                    } else if (value.length < 3 ||
                        !value.contains(
                            RegExp(r'^((\b[a-zA-Z]{2,40}\b)\s*){2,3}$'))) {
                      return 'Please enter a valid name';
                    }
                    return null;
                  },
                ),
                CustomTextFormField(
                  labelText: 'Age',
                  controller: _ageController,
                  suffixText: 'years',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter age';
                    }
                    final ageValue = int.tryParse(value);
                    if (ageValue == null || ageValue < 13 || ageValue > 100) {
                      return 'Please enter a valid age between 13 and 100';
                    }
                    return null;
                  },
                ),
                CustomTextFormField(
                  controller: _weightController,
                  labelText: 'Weight',
                  suffixText: 'kg',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter weight';
                    }
                    final weightValue = double.tryParse(value);
                    if (weightValue == null ||
                        weightValue < 30 ||
                        weightValue > 200) {
                      return 'Please enter a valid weight between 30 and 200';
                    }
                    return null;
                  },
                ),
                CustomTextFormField(
                  controller: _heightController,
                  labelText: 'Height',
                  suffixText: 'cm',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter height';
                    }
                    final weightValue = int.tryParse(value);
                    if (weightValue == null ||
                        weightValue < 30 ||
                        weightValue > 200) {
                      return 'Please enter a valid weight between 30 and 200';
                    }
                    return null;
                  },
                ),
                CustomTextFormField(
                  controller: _phoneController,
                  labelText: 'Phone Number',
                  prefixText: '+91',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter phone number';
                    } else if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value)) {
                      return 'Please enter a valid Indian phone number';
                    }
                    return null;
                  },
                ),
                CustomTextFormField(
                  controller: _cityController,
                  labelText: 'City',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter city';
                    } else if (!value.contains(RegExp(r'^[a-zA-Z ]+$'))) {
                      return 'Please enter a valid city name';
                    }
                    return null;
                  },
                ),
                CustomTextFormField(
                  controller: _emailController,
                  labelText: 'Email',
                  suffixText: 'Optional',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value != null &&
                        value.isNotEmpty &&
                        !RegExp(r'^.+@[a-zA-Z]+\.{1}[a-zA-Z]+(\.{0,1}[a-zA-Z]+)$')
                            .hasMatch(value)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                GenderSwitch(
                    onGenderChanged: (gender) {
                      setState(() {
                        isMale = gender;
                      });
                    },
                    isMale: isMale),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          setState(() {
            autoValidate = true;
          });
          if (_formKey.currentState!.validate()) {
            // get all the values
            try {
              final DateFormat format = DateFormat('dd-MM-yyyy - hh:mm a');
              DateTime created = format.parse(_dateController.text);
              String cid = FirebaseAuth.instance.currentUser!.uid;
              int age = int.parse(_ageController.text);
              DateTime currentDate = DateTime.now();
              DateTime dob = DateTime(
                  currentDate.year - age, currentDate.month, currentDate.day);
              List<Map<String, dynamic>> measurements = [
                {
                  'date': created,
                  'weight': double.parse(_weightController.text),
                }
              ];
              Map<String, dynamic> data = {
                'name': _nameController.text.trim(),
                'dob': dob,
                'gender': isMale ? 'male' : 'female',
                'height': int.parse(_heightController.text),
                'measurements': measurements,
                'phone': _phoneController.text.trim(),
                'city': _cityController.text.trim(),
                'email': _emailController.text.trim(),
                'created': created,
                'cid': cid,
              };
              QuerySnapshot userSnapshot = await FirebaseFirestore.instance
                  .collection('Users')
                  .where('phone', isEqualTo: data['phone'])
                  .get();

              QuerySnapshot coachSnapshot = await FirebaseFirestore.instance
                  .collection('Coaches')
                  .where('phone', isEqualTo: data['phone'])
                  .get();
              if (userSnapshot.docs.isNotEmpty ||
                  coachSnapshot.docs.isNotEmpty) {
                return Flushbar(
                  margin: const EdgeInsets.all(7),
                  borderRadius: BorderRadius.circular(15),
                  flushbarStyle: FlushbarStyle.FLOATING,
                  flushbarPosition: FlushbarPosition.BOTTOM,
                  message: "User with this phone number already exists!",
                  icon: Icon(
                    Icons.error_outline,
                    size: 28.0,
                    color: Colors.red[300],
                  ),
                  duration: const Duration(milliseconds: 4000),
                  leftBarIndicatorColor: Colors.red[300],
                ).show(scaffoldKey.currentContext!);
              }
              await FirebaseFirestore.instance.collection('Users').add(data);
              //  dispose all the controllers
              _dateController.clear();
              _nameController.clear();
              _weightController.clear();
              _heightController.clear();
              _phoneController.clear();
              _cityController.clear();
              _emailController.clear();
              _ageController.clear();
              _dateController.clear();

              Navigator.pop(scaffoldKey.currentContext!);
              Flushbar(
                margin: const EdgeInsets.all(7),
                borderRadius: BorderRadius.circular(15),
                flushbarStyle: FlushbarStyle.FLOATING,
                flushbarPosition: FlushbarPosition.BOTTOM,
                message: "User added successfully",
                icon: Icon(
                  Icons.check_circle_outline_rounded,
                  size: 28.0,
                  color: Colors.green[300],
                ),
                duration: const Duration(milliseconds: 1500),
                leftBarIndicatorColor: Colors.green[300],
              ).show(scaffoldKey.currentContext!);
            } catch (e) {
              debugPrint(e.toString());
              Flushbar(
                margin: const EdgeInsets.all(7),
                borderRadius: BorderRadius.circular(15),
                flushbarStyle: FlushbarStyle.FLOATING,
                flushbarPosition: FlushbarPosition.BOTTOM,
                message: "Error updating user data",
                icon: Icon(
                  Icons.error_outline_rounded,
                  size: 28.0,
                  color: Colors.red[300],
                ),
                duration: const Duration(milliseconds: 1500),
                leftBarIndicatorColor: Colors.red[300],
              ).show(context);
              return;
            }
          }
        },
        child: const Icon(Icons.save),
      ),
    );
  }
}

class CustomTextFormField extends StatelessWidget {
  final String labelText;
  final String? suffixText;
  final String? prefixText;
  final bool readOnly;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final VoidCallback? onTap;
  final String? Function(String?)? validator;

  const CustomTextFormField({
    Key? key,
    required this.labelText,
    this.suffixText,
    this.prefixText,
    this.readOnly = false,
    this.controller,
    this.keyboardType,
    this.validator,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return Container(
      margin: EdgeInsets.only(bottom: height * 0.02),
      child: Card(
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Container(
          padding: EdgeInsets.symmetric(
              vertical: height * 0.04, horizontal: width * 0.07),
          child: TextFormField(
            readOnly: readOnly,
            controller: controller,
            keyboardType: keyboardType,
            onTap: onTap,
            // change font family
            style: GoogleFonts.raleway(
              fontSize: height * 0.02,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              labelText: labelText,
              suffixText: suffixText,
              prefixText: prefixText,
              contentPadding: EdgeInsets.symmetric(
                horizontal: height * 0.007,
                vertical: height * 0.01,
              ),
              // full round border
            ),
            validator: validator,
          ),
        ),
      ),
    );
  }
}
