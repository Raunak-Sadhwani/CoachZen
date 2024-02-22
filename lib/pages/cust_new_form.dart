import 'package:another_flushbar/flushbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:coach_zen/components/body_form/gender_switch.dart';
import 'package:firebase_database/firebase_database.dart';

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
  final ScrollController _scrollController = ScrollController();
  bool autoValidate = false;
  bool isMale = true;
  bool isFabEnabled = true;

  @override
  void initState() {
    super.initState();
    // snackbar if firebase is connected
    FirebaseDatabase.instance
        .ref()
        .child('.info/connected')
        .onValue
        .listen((event) {
      if (event.snapshot.value == true) {
        Flushbar(
          margin: const EdgeInsets.all(7),
          borderRadius: BorderRadius.circular(15),
          flushbarStyle: FlushbarStyle.FLOATING,
          flushbarPosition: FlushbarPosition.BOTTOM,
          message: "Firebase connected",
          icon: Icon(
            Icons.check_circle_outline_rounded,
            size: 28.0,
            color: Colors.green[300],
          ),
          duration: const Duration(milliseconds: 1500),
          leftBarIndicatorColor: Colors.green[300],
        ).show(context);
      }
    });
  }

  @override
  void dispose() {
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
        controller: _scrollController,
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
                  maxLength: 3,
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
                  maxLength: 3,
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
                  // max cahracters 3
                  maxLength: 3,
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
                  maxLength: 10,
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
      floatingActionButton: IgnorePointer(
        ignoring: !isFabEnabled,
        child: FloatingActionButton(
          onPressed: () async {
            if (!isFabEnabled) {
              return; // Ignore button press if it's already disabled
            }

            setState(() {
              autoValidate = true;
              isFabEnabled = false; // Disable the button on press
            });

            if (_formKey.currentState!.validate()) {
              // get all the values
              try {
                final DateFormat format = DateFormat('dd-MM-yyyy - hh:mm a');
                DateTime created = format.parse(_dateController.text);
                int realtime = created.millisecondsSinceEpoch;
                String cid = FirebaseAuth.instance.currentUser!.uid;
                int age = int.parse(_ageController.text);
                DateTime currentDate = DateTime.now();
                DateTime dob = DateTime(
                    currentDate.year - age, currentDate.month, currentDate.day);
                int dobTime = dob.millisecondsSinceEpoch;
                List<Map<String, dynamic>> measurements = [
                  {
                    'date': realtime,
                    'weight': double.parse(_weightController.text),
                  }
                ];
                Map<String, dynamic> data = {
                  'name': _nameController.text.trim(),
                  'dob': dobTime,
                  'gender': isMale ? 'male' : 'female',
                  'height': int.parse(_heightController.text),
                  'measurements': measurements,
                  'phone': _phoneController.text.trim(),
                  'city': _cityController.text.trim(),
                  'email': _emailController.text.trim(),
                  'created': realtime,
                  'cid': cid,
                };

                // check if user already exists by phone
                final userSnapshot = await FirebaseDatabase.instance
                    .ref()
                    .child('Users')
                    .orderByChild('phone')
                    .equalTo(_phoneController.text.trim())
                    .once();

                final coachSnapshot = await FirebaseDatabase.instance
                    .ref()
                    .child('Coaches')
                    .orderByChild('phone')
                    .equalTo(_phoneController.text.trim())
                    .once();

                if (userSnapshot.snapshot.value != null ||
                    coachSnapshot.snapshot.value != null) {
                  setState(() {
                    isFabEnabled = true;
                  });
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

                try {
                  await FirebaseDatabase.instance
                      .ref()
                      .child('Users')
                      .push()
                      .set(data);
                } catch (e) {
                  Flushbar(
                    margin: const EdgeInsets.all(7),
                    borderRadius: BorderRadius.circular(15),
                    flushbarStyle: FlushbarStyle.FLOATING,
                    flushbarPosition: FlushbarPosition.BOTTOM,
                    message: "Something Went Wrong!$e",
                    icon: Icon(
                      Icons.error_outline,
                      size: 28.0,
                      color: Colors.red[300],
                    ),
                    duration: const Duration(milliseconds: 4000),
                    leftBarIndicatorColor: Colors.red[300],
                  ).show(scaffoldKey.currentContext!);
                  setState(() {
                    isFabEnabled = true;
                  });
                }

                _dateController.clear();
                _nameController.clear();
                _weightController.clear();
                _heightController.clear();
                _phoneController.clear();
                _cityController.clear();
                _emailController.clear();
                _ageController.clear();

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
                ).show(scaffoldKey.currentContext!);
                setState(() {
                  isFabEnabled = true;
                });
                return;
              }
            } else {
              // Enable the button if form validation failed
              setState(() {
                isFabEnabled = true;
              });
              final ScrollPosition position = _scrollController.position;
              final double firstErrorFieldOffset = _formKey.currentContext!
                  .findRenderObject()!
                  .getTransformTo(null)
                  .getTranslation()
                  .y;
              final double scrollOffset =
                  position.pixels + firstErrorFieldOffset;
              _scrollController.animateTo(
                scrollOffset,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          },
          child: const Icon(Icons.save),
        ),
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
  final int? maxLength;

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
    this.maxLength,
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
            maxLength: maxLength,
            onTap: onTap,
            // change font family
            style: GoogleFonts.raleway(
              fontSize: height * 0.02,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              counterText: '',
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
