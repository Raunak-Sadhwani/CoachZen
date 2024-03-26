import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import '../ui/app_colors.dart';
import 'age_weight.dart';
import 'height_picker.dart';
import 'gender_switch.dart';
import 'dart:math' as math;

class BodyForm extends StatefulWidget {
  // final VoidCallback detailsSubmitted;
  final ValueChanged<bool> pageChange;
  final PageController? controller;
  final String? age;
  final double? heightParam;
  final bool? gender;
  // final Function(List<Map<String, dynamic>>) onSubmit;
  const BodyForm({
    Key? key,
    this.controller,
    required this.pageChange,
    this.age,
    this.heightParam,
    this.gender,
    // required this.onSubmit,
    // required this.detailsSubmitted,
  }) : super(key: key);

  @override
  State<BodyForm> createState() => _BodyFormState();

  // List<Map<String, dynamic>> get fields => sendDetails();
  static TextEditingController ageController =
      TextEditingController(text: '25');
  static TextEditingController weightController =
      TextEditingController(text: '60.0');
  // void init

  static double height = 170;
  static bool isMale = true;

  static List<Map<String, dynamic>> get allFields => [
        {
          'label': 'Age',
          'controller': ageController,
        },
        {
          'label': 'Weight',
          'controller': weightController,
        },
        {
          'label': 'Height',
          'controller':
              TextEditingController(text: BodyForm.height.toStringAsFixed(0)),
        },
        {
          'label': 'Gender',
          'controller': TextEditingController(text: isMale ? 'male' : 'female'),
        },
      ];
}

class _BodyFormState extends State<BodyForm> {
  @override
  void initState() {
    super.initState();
    if (widget.heightParam != null) {
      BodyForm.height = widget.heightParam!;
    }
    if (widget.age != null) {
      BodyForm.ageController.text = widget.age!;
    }
    if (widget.gender != null) {
      BodyForm.isMale = widget.gender!;
    }
  }

  @override
  void dispose() {
    // BodyForm.ageController.text = '25';
    // BodyForm.height = 170;
    // BodyForm.isMale = true;
    super.dispose();
  }

  final double minValue = 100; // minimum height value in cms
  final double maxValue = 220; // maximum height value in cms
  final double step = 1; // step value for the height picker
  TextEditingController ageController = BodyForm.ageController;
  TextEditingController weightController = BodyForm.weightController;
  bool isInteractingWithPicker = false;

  // make sendDetails() a getter

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double height = MediaQuery.of(context).size.height;
    void calc(calc, title) {
      setState(() {
        if (title == 'age') {
          if (widget.age == null) {
            if (calc == 'add') {
              ageController.text =
                  (int.parse(ageController.text) + 1).toString();
            } else {
              ageController.text =
                  (int.parse(ageController.text) - 1).toString();
            }
          } else {
            Flushbar(
              margin: const EdgeInsets.all(7),
              borderRadius: BorderRadius.circular(15),
              flushbarStyle: FlushbarStyle.FLOATING,
              flushbarPosition: FlushbarPosition.BOTTOM,
              message:
                  "Age is already set, change it from the user's profile page",
              icon: Icon(
                Icons.error_outline_rounded,
                size: 28.0,
                color: Colors.red[300],
              ),
              duration: const Duration(milliseconds: 3000),
              leftBarIndicatorColor: Colors.red[300],
            ).show(context);
          }
        } else {
          if (calc == 'add') {
            weightController.text = int.tryParse(weightController.text) != null
                ? (int.parse(weightController.text) + 1).toString()
                : (double.parse(weightController.text) + 1).toStringAsFixed(1);
          } else {
            weightController.text = int.tryParse(weightController.text) != null
                ? (int.parse(weightController.text) - 1).toString()
                : (double.parse(weightController.text) - 1).toStringAsFixed(1);
          }
        }
      });
    }

    void setHeight(DragUpdateDetails details) {
      if (widget.heightParam == null) {
        final double delta = -details.delta.dx;
        setState(() {
          BodyForm.height = math.max(
              minValue,
              math.min(
                  maxValue,
                  BodyForm.height +
                      delta / (width / ((maxValue - minValue) / step))));
        });
      } else {
        Flushbar(
          margin: const EdgeInsets.all(7),
          borderRadius: BorderRadius.circular(15),
          flushbarStyle: FlushbarStyle.FLOATING,
          flushbarPosition: FlushbarPosition.BOTTOM,
          message:
              "Height is already set, change it from the user's profile page",
          icon: Icon(
            Icons.error_outline_rounded,
            size: 28.0,
            color: Colors.red[300],
          ),
          duration: const Duration(milliseconds: 3000),
          leftBarIndicatorColor: Colors.red[300],
        ).show(context);
      }
      // BodyForm.height = height;
    }

    void tappedOutside() {
      FocusScope.of(context).unfocus();

      setState(() {
        if (widget.heightParam == null) {
          isInteractingWithPicker = true;
        }
        if (weightController.text.endsWith(".") ||
            weightController.text.startsWith(".")) {
          weightController.text = weightController.text
              .substring(0, weightController.text.length - 1);
        }

        if (double.tryParse(weightController.text) == null ||
            double.tryParse(weightController.text)! < 15.0) {
          weightController.text = '60.0';
        }

        if (int.tryParse(ageController.text) == null ||
            int.tryParse(ageController.text)! < 15) {
          ageController.text = '25';
        }
        if (widget.heightParam == null) {
          widget.pageChange(isInteractingWithPicker);
        }
      });
    }

    // String previousValue = '';
    return GestureDetector(
      onTap: () {
        tappedOutside();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: width * 0.05,
              vertical: height * 0.03,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: VCard(
                        value: ageController.text,
                        readonly: widget.age != null,
                        title: 'Age',
                        fn: (oper) {
                          if (widget.age == null &&
                              widget.heightParam == null) {
                            if ((oper == 'add' || oper == 'sub') &&
                                !(int.parse(ageController.text) > 100 ||
                                    int.parse(ageController.text) < 1)) {
                              calc(oper, 'age');
                            } else {
                              setState(() {
                                if (int.parse(ageController.text) > 100 ||
                                    int.parse(ageController.text) < 1) {
                                  ageController.text = ageController.text
                                      .substring(
                                          0, ageController.text.length - 1);
                                } else {
                                  ageController.text = oper;
                                }
                                ageController.selection =
                                    TextSelection.fromPosition(TextPosition(
                                        offset: ageController.text.length));
                              });
                            }
                          } else {
                            Flushbar(
                              margin: const EdgeInsets.all(7),
                              borderRadius: BorderRadius.circular(15),
                              flushbarStyle: FlushbarStyle.FLOATING,
                              flushbarPosition: FlushbarPosition.BOTTOM,
                              message:
                                  "Age is already set, change it from the user's profile page",
                              icon: Icon(
                                Icons.error_outline_rounded,
                                size: 28.0,
                                color: Colors.red[300],
                              ),
                              duration: const Duration(milliseconds: 3000),
                              leftBarIndicatorColor: Colors.red[300],
                            ).show(context);
                          }
                        },
                        controller: ageController,
                      ),
                    ),
                    SizedBox(width: width * 0.04),
                    Expanded(
                      child: VCard(
                        value: weightController.text.trim(),
                        title: 'Weight',
                        fn: (oper) {
                          String weightText = weightController.text.trim();
                          {
                            if ((oper == 'add' || oper == 'sub') &&
                                !(double.parse(weightText) < 31 ||
                                    double.parse(weightText) > 300)) {
                              calc(oper, 'weight');
                            } else {
                              setState(() {
                                // proper regex for weight
                                try {
                                  if (!RegExp(r'^\d{0,3}(\.\d{0,1})?$')
                                          .hasMatch(weightText) ||
                                      weightText.contains(' ')) {
                                    weightController.text =
                                        weightController.text.substring(0,
                                            weightController.text.length - 1);
                                  } else {
                                    if ((weightText.isEmpty ||
                                            double.tryParse(weightText) !=
                                                null) &&
                                        (oper != 'add' && oper != 'sub')) {
                                      weightController.text = oper;
                                    }
                                  }
                                  weightController.selection =
                                      TextSelection.fromPosition(TextPosition(
                                          offset:
                                              weightController.text.length));
                                } catch (e) {
                                  weightController.text = '31';
                                }
                              });
                            }
                          }
                        },
                        controller: weightController,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                GestureDetector(
                  onTap: () {
                    if (widget.heightParam != null) {
                      Flushbar(
                        margin: const EdgeInsets.all(7),
                        borderRadius: BorderRadius.circular(15),
                        flushbarStyle: FlushbarStyle.FLOATING,
                        flushbarPosition: FlushbarPosition.BOTTOM,
                        message:
                            "Height is already set, change it from the user's profile page",
                        icon: Icon(
                          Icons.error_outline_rounded,
                          size: 28.0,
                          color: Colors.red[300],
                        ),
                        duration: const Duration(milliseconds: 3000),
                        leftBarIndicatorColor: Colors.red[300],
                      ).show(context);
                    }
                  },
                  // when the user starts touching the height picker or drags it
                  // we set the isInteractingWithPicker to true
                  onTapDown: (TapDownDetails details) {
                    tappedOutside();
                  },
                  onPanDown: (DragDownDetails details) {
                    if (widget.heightParam == null) {
                      setState(() {
                        isInteractingWithPicker = true;
                        widget.pageChange(isInteractingWithPicker);
                      });
                    }
                  },
                  onPanUpdate: (details) {
                    if (widget.heightParam == null) {
                      isInteractingWithPicker = true;
                      widget.pageChange(isInteractingWithPicker);
                      setHeight(details);
                    }
                  },
                  onPanEnd: (details) {
                    if (widget.heightParam == null) {
                      isInteractingWithPicker = false;
                      widget.pageChange(isInteractingWithPicker);
                    }
                  },
                  child: HeightPicker(
                    // setHeight: (DragUpdateDetails details) => setHeight(details),
                    value: BodyForm.height.toStringAsFixed(0),
                    minValue: minValue,
                    step: step,
                    maxValue: maxValue,
                  ),
                  // when the user stops touching the height picker or drags it
                  // we set the isInteractingWithPicker to false
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                GenderSwitch(
                  onGenderChanged: (bool value) {
                    if (widget.gender == null) {
                      setState(() {
                        BodyForm.isMale = value;
                      });
                    } else {
                      Flushbar(
                        margin: const EdgeInsets.all(7),
                        borderRadius: BorderRadius.circular(15),
                        flushbarStyle: FlushbarStyle.FLOATING,
                        flushbarPosition: FlushbarPosition.BOTTOM,
                        message:
                            "Gender is already set, change it from the user's profile page",
                        icon: Icon(
                          Icons.error_outline_rounded,
                          size: 28.0,
                          color: Colors.red[300],
                        ),
                        duration: const Duration(milliseconds: 3000),
                        leftBarIndicatorColor: Colors.red[300],
                      ).show(context);
                    }
                  },
                  isMale: BodyForm.isMale,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
