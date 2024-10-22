import 'package:another_flushbar/flushbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../components/ui/appbar.dart';

class AddWeight extends StatefulWidget {
  final String name;
  final String uid;
  final List<Map<dynamic, dynamic>> measurements;
  final int popIndex;
  const AddWeight(
      {super.key,
      required this.name,
      required this.uid,
      required this.popIndex,
      required this.measurements});

  @override
  State<AddWeight> createState() => _AddWeightState();
}

class _AddWeightState extends State<AddWeight> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  
  double weight = 60.0;


  final TextEditingController _dateController = TextEditingController();

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      if (!await Method.checkInternetConnection(context)) {
        return;
      }
      
      DateTime date = DateTime.now();
      try {
        final DateFormat format = DateFormat('dd-MM-yyyy');
        date = format.parseStrict(_dateController.text);
        
        for (int i = 0; i < widget.measurements.length; i++) {
          if (DateTime.fromMillisecondsSinceEpoch(
                  widget.measurements[i]['date']) ==
              date) {
            return Flushbar(
              margin: const EdgeInsets.all(7),
              borderRadius: BorderRadius.circular(15),
              flushbarStyle: FlushbarStyle.FLOATING,
              flushbarPosition: FlushbarPosition.BOTTOM,
              message: "Weight for this date already exists!",
              icon: Icon(
                Icons.error_outline,
                size: 28.0,
                color: Colors.red[300],
              ),
              duration: const Duration(milliseconds: 2000),
              leftBarIndicatorColor: Colors.red[300],
            ).show(scaffoldKey.currentContext!);
          }
        }
      } catch (e) {
        return Flushbar(
          margin: const EdgeInsets.all(7),
          borderRadius: BorderRadius.circular(15),
          flushbarStyle: FlushbarStyle.FLOATING,
          flushbarPosition: FlushbarPosition.BOTTOM,
          message: "Something went wrong!",
          icon: Icon(
            Icons.error_outline,
            size: 28.0,
            color: Colors.red[300],
          ),
          duration: const Duration(milliseconds: 2000),
          leftBarIndicatorColor: Colors.red[300],
        ).show(scaffoldKey.currentContext!);
      }
      Map<dynamic, dynamic> data = {
        'weight': weight,
        'date': date.millisecondsSinceEpoch,
      };
      widget.measurements.add(data);

      final docRef = FirebaseDatabase.instance
          .ref()
          .child('Coaches')
          .child(FirebaseAuth.instance.currentUser!.uid)
          .child('users');
      try {
        await docRef.child(widget.uid).update({
          'measurements': widget.measurements,
        });
        for (int i = 0; i < widget.popIndex; i++) {
          Navigator.pop(scaffoldKey.currentContext!);
        }

        return Flushbar(
          margin: const EdgeInsets.all(7),
          borderRadius: BorderRadius.circular(15),
          flushbarStyle: FlushbarStyle.FLOATING,
          flushbarPosition: FlushbarPosition.BOTTOM,
          message: "${widget.name} weight added successfully!",
          icon: Icon(
            Icons.check_circle_outline,
            size: 28.0,
            color: Colors.green[300],
          ),
          duration: const Duration(milliseconds: 2000),
          leftBarIndicatorColor: Colors.green[300],
        ).show(scaffoldKey.currentContext!);
      } catch (e) {
        
        Flushbar(
          margin: const EdgeInsets.all(7),
          borderRadius: BorderRadius.circular(15),
          flushbarStyle: FlushbarStyle.FLOATING,
          flushbarPosition: FlushbarPosition.BOTTOM,
          message: "Something went wrong!",
          icon: Icon(
            Icons.error_outline,
            size: 28.0,
            color: Colors.red[300],
          ),
          duration: const Duration(milliseconds: 2000),
          leftBarIndicatorColor: Colors.red[300],
        ).show(scaffoldKey.currentContext!);
        return debugPrint(e.toString());
      }
    }
  }

  List<DateTime> disabledDates = [];
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    
    for (int i = 0; i < widget.measurements.length; i++) {
      DateTime date =
          DateTime.fromMillisecondsSinceEpoch(widget.measurements[i]['date']);
      
      date = DateTime(date.year, date.month, date.day);
      disabledDates.add(date);
    }
    selectedDate =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    while (disabledDates.contains(selectedDate)) {
      selectedDate =
          DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      selectedDate = selectedDate.subtract(const Duration(days: 1));
    }
    _dateController.text = DateFormat('dd-MM-yyyy').format(selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: MyAppBar(
        title: 'Adding Weight of ${widget.name}',
        leftIcon: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: Colors.black26,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                readOnly: true,
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: 'Date',
                ),
                onTap: () {
                  showDatePicker(
                    context: context,
                    
                    initialDate: selectedDate,
                    firstDate: DateTime(DateTime.now().year - 13),
                    lastDate: DateTime.now(),
                    
                    
                    
                    selectableDayPredicate: (DateTime date) {
                      if (disabledDates.isEmpty) {
                        return true;
                      } else {
                        return !disabledDates.contains(date);
                      }
                    },
                  ).then((date) {
                    if (date != null) {
                      setState(() {
                        _dateController.text =
                            DateFormat('dd-MM-yyyy').format(date);
                      });
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
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Weight',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter weight';
                  }
                  final weightValue = double.tryParse(value);
                  if (weightValue == null ||
                      weightValue < 35 ||
                      weightValue > 150) {
                    return 'Please enter a valid weight between 30 and 200';
                  }
                  return null;
                },
                onSaved: (value) {
                  weight = double.parse(value!);
                },
              ),
              const SizedBox(height: 16.0),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _submitForm,
        child: const Icon(Icons.check),
      ),
    );
  }
}
