import 'package:flutter/material.dart';
import 'components/age_weight.dart';
import 'components/height_picker.dart';
import 'components/gender_switch.dart';
import 'dart:math' as math;

class BodyForm extends StatefulWidget {
  // final VoidCallback nextPage;
  final ValueChanged<bool> pageChange;
  final PageController? controller;
  const BodyForm({
    super.key,
    this.controller,
    required this.pageChange,
    //  required this.nextPage
  });

  @override
  State<BodyForm> createState() => _BodyFormState();
}

class _BodyFormState extends State<BodyForm> {
  int age = 25;
  int weight = 60;
  double height = 170;
  bool isMale = true;
  void calc(calc, title) {
    setState(() {
      if (calc == 'add') {
        if (title == 'age') {
          age = age + 1;
        } else {
          weight = weight + 1;
        }
      } else {
        if (title == 'age') {
          age = age - 1;
        } else {
          weight = weight - 1;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // String gender = isMale ? 'Male' : 'Female';
    bool isInteractingWithPicker = false;
    final double width = MediaQuery.of(context).size.width;
    const double minValue = 100; // minimum height value in cms
    const double maxValue = 220; // maximum height value in cms
    const double step = 1; // step value for the height picker
    void setHeight(DragUpdateDetails details) {
      final double delta = -details.delta.dx;
      setState(() {
        height = math.max(
            minValue,
            math.min(maxValue,
                height + delta / (width / ((maxValue - minValue) / step))));
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xfff5f6fd),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.05,
            vertical: MediaQuery.of(context).size.height * 0.03,
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  VCard(
                    value: age.toString(),
                    title: 'Age',
                    fn: (oper) {
                      calc(oper, 'age');
                    },
                  ),
                  VCard(
                    value: weight.toString(),
                    title: 'Weight',
                    fn: (oper) {
                      calc(oper, 'weight');
                    },
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.03),
              GestureDetector(
                // when the user starts touching the height picker or drags it
                // we set the isInteractingWithPicker to true
                onTapDown: (TapDownDetails details) {
                  setState(() {
                    isInteractingWithPicker = true;
                    widget.pageChange(isInteractingWithPicker);
                  });
                },
                onPanDown: (DragDownDetails details) {
                  setState(() {
                    isInteractingWithPicker = true;
                    widget.pageChange(isInteractingWithPicker);
                  });
                },
                onPanUpdate: (details) {
                  isInteractingWithPicker = true;
                  widget.pageChange(isInteractingWithPicker);
                  setHeight(details);
                },
                onPanEnd: (details) {
                  isInteractingWithPicker = false;
                  widget.pageChange(isInteractingWithPicker);
                },
                child: HeightPicker(
                  // setHeight: (DragUpdateDetails details) => setHeight(details),
                  value: height.toStringAsFixed(0),
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
                  setState(() {
                    isMale = value;
                  });
                },
                isMale: isMale,
              ),
              // 3 dots for the page indicator, blue for the current page
              // SizedBox(height: MediaQuery.of(context).size.height * 0.0),
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.center,
              //   children: [
              //     Container(
              //       height: 10,
              //       width: 10,
              //       decoration: const BoxDecoration(
              //         color: Color(0xff3f51b5),
              //         shape: BoxShape.circle,
              //       ),
              //     ),
              //     const SizedBox(width: 10),
              //     Container(
              //       height: 10,
              //       width: 10,
              //       decoration: const BoxDecoration(
              //         color: Color(0xffcfd8dc),
              //         shape: BoxShape.circle,
              //       ),
              //     ),
              //     const SizedBox(width: 10),
              //     Container(
              //       height: 10,
              //       width: 10,
              //       decoration: const BoxDecoration(
              //         color: Color(0xffcfd8dc),
              //         shape: BoxShape.circle,
              //       ),
              //     ),
              //   ],
              // ),
           
            ],
          ),
        ),
      ),
    );
  }
}
