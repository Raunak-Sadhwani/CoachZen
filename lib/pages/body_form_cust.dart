import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:slimtrap/components/ui/appbar.dart';

class BodyFormCustomer extends StatefulWidget {
  final Map<String, dynamic> userData;
  const BodyFormCustomer({
    Key? key,
    required this.userData,
  }) : super(key: key);

  @override
  State<BodyFormCustomer> createState() => _BodyFormCustomerState();
}

class _BodyFormCustomerState extends State<BodyFormCustomer> {
  // String? _validateField(String? value, String label) {
  //   if (label.toLowerCase().contains('name')) {
  //     if (value!.length < 3 ||
  //         !value.trim().contains(RegExp(r'^((\b[a-zA-Z]{2,40}\b)\s*){2,3}$'))) {
  //       errorMessage.add('Please enter a valid name');
  //       return '';
  //     }
  //   } else if (label.toLowerCase().contains('email')) {
  //     // email field can be empty or should be valid email format
  //     if (value!.isNotEmpty &&
  //         (!RegExp(r'^.+@[a-zA-Z]+\.{1}[a-zA-Z]+(\.{0,1}[a-zA-Z]+)$')
  //             .hasMatch(value))) {
  //       errorMessage.add('Please enter a valid email address');
  //       return '';
  //     }
  //   } else if (label.toLowerCase().contains('phone')) {
  //     // check if phone is valid indian number
  //     if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value!)) {
  //       errorMessage.add('Please enter a valid Indian phone number');
  //       return '';
  //     }
  //   } else if (label.toLowerCase().contains('gender') && value!.isNotEmpty) {
  //     if (value.toLowerCase() != 'm' &&
  //         value.toLowerCase() != 'f' &&
  //         value.toLowerCase() != 'male' &&
  //         value.toLowerCase() != 'female') {
  //       errorMessage.add('Please enter M or F in $label');
  //       return '';
  //     }
  //   } else if (value!.isNotEmpty && label.toLowerCase().contains('city')) {
  //     //  value.trim().length >= 3 &&
  //     //  value.matches('^[a-zA-Z\\s]+$');
  //     if (value.trim().length < 3 ||
  //         !RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
  //       errorMessage.add('Please enter a valid city');
  //       return '';
  //     }
  //   } else if (value.isNotEmpty && label.toLowerCase().contains('age')) {
  //     // if age is valid int and between 18 and 100 then return null
  //     if (int.tryParse(value) == null) {
  //       errorMessage.add('Please enter a valid age');
  //       return '';
  //     } else if (int.parse(value) < 15 || int.parse(value) > 100) {
  //       errorMessage.add('Please enter a valid age');
  //       return '';
  //     }
  //   } else if (value.isNotEmpty && label.toLowerCase().contains('weight')) {
  //     // if weight is valid int and between 18 and 100 then return null
  //     if (double.tryParse(value) == null) {
  //       errorMessage.add('Please enter a valid weight');
  //       return '';
  //     } else if (double.parse(value) < 30 || double.parse(value) > 200) {
  //       errorMessage.add('Please enter a valid weight');
  //       return '';
  //     }
  //   } else if (value.isNotEmpty && label.toLowerCase().contains('height')) {
  //     // if height is valid int and between 18 and 100 then return null
  //     if (int.tryParse(value) == null) {
  //       errorMessage.add('Please enter a valid height');
  //       return '';
  //     } else if (int.parse(value) < 50 || int.parse(value) > 250) {
  //       errorMessage.add('Please enter a valid height');
  //       return '';
  //     }
  //   } else if (label.toLowerCase().contains('medical')) {
  //     // medical history field can be empty
  //     return null;
  //   } else {
  //     if (value.isEmpty) {
  //       errorMessage.add('Please enter a value for $label');
  //       return '';
  //     }
  //   }
  //   return null;
  // }

  DateFormat formatter = DateFormat('dd MMM yyyy');

  // capitalize first letter of each word
  String capitalize(String value) {
    return value
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  List<Map<String, dynamic>> updateFields = [];
  late Map<String, dynamic> editedData = Map.from(widget.userData);
  late final Map<String, dynamic> originalData = Map.from(widget.userData);
  String tempValue = '';
  String dialogTempValue = '';
  void _editData(String key, dynamic value) {
    setState(() {
      editedData[key] = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: MyAppBar(
          title: widget.userData['name'],
          leftIcon: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            color: Colors.black26,
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Container(
          padding: EdgeInsets.symmetric(
              vertical: height * 0.01, horizontal: width * 0.035),
          child: ListView(
            physics: const BouncingScrollPhysics(),
            children: [
              Container(
                margin: EdgeInsets.symmetric(
                    vertical: height * 0.025, horizontal: width * 0.05),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                          width: width * 0.3,
                          height: width * 0.3,
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.grey[300],
                            child: Icon(
                              Icons.person,
                              size: width * 0.12,
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 2 gradient buttons
                            CustButton(
                              height: height,
                              width: width,
                              onPressed: () {},
                              imgPath: 'lib/assets/focus.png',
                              label: 'Weight',
                              page: Container(),
                            ),
                            CustButton(
                              height: height,
                              width: width,
                              onPressed: () {},
                              imgPath: 'lib/assets/focus.png',
                              label: 'Orders',
                              page: Container(),
                            ),
                          ],
                        )
                      ],
                    ),
                    Row(
                      // crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 2 gradient buttons
                        CustButton(
                          height: height,
                          width: width,
                          onPressed: () {},
                          imgPath: 'lib/assets/focus.png',
                          label: 'Plan',
                          page: Container(),
                        ),
                        CustButton(
                          height: height,
                          width: width,
                          onPressed: () {},
                          imgPath: 'lib/assets/focus.png',
                          label: 'Meds',
                          page: Container(),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              ...editedData.entries.map(
                (entry) {
                  var key = entry.key;
                  var value = entry.value;
                  late dynamic age;
                  if (key == 'dob') {
                    age = value;
                    // calculate age
                    age = DateTime.now().year -
                        DateTime.parse(age.toDate().toString()).year;
                  }

                  return Card(
                    elevation: 10,
                    key: ValueKey(entry.key),
                    margin: const EdgeInsets.all(10),
                    child: ListTile(
                      minVerticalPadding: 15,
                      leading: Icon(
                        _getIcon(entry.key),
                        color: Colors.black,
                        size: 30,
                      ),
                      title: Text(
                        entry.key == 'dob'
                            ? capitalize('dob ($age years)')
                            : capitalize(entry.key),
                        style:
                            const TextStyle(color: Colors.black, fontSize: 18),
                      ),
                      subtitle: Text(
                        entry.value.runtimeType == Timestamp
                            ? formatter.format(entry.value.toDate()).toString()
                            : entry.value.toString(),
                        style:
                            const TextStyle(color: Colors.black, fontSize: 16),
                      ),
                      onTap: () {
                        if (entry.key == 'created') {
                          return;
                        }
                        showDialog(
                          context: context,
                          builder: (context) {
                            String dialogTempValue =
                                entry.value.runtimeType == Timestamp
                                    ? formatter
                                        .format(entry.value.toDate())
                                        .toString()
                                    : entry.value.toString();
                            return StatefulBuilder(
                                builder: (context, StateSetter setState) {
                              return AlertDialog(
                                title: Text(entry.key),
                                content: entry.key.toLowerCase().contains('dob')
                                    ? InkWell(
                                        onTap: () {
                                          showDatePicker(
                                            context: context,
                                            initialDate: entry.value.toDate() ??
                                                DateTime.now(),
                                            firstDate: DateTime(1900),
                                            lastDate: DateTime.now(),
                                          ).then((selectedDate) {
                                            if (selectedDate != null) {
                                              String formattedDate =
                                                  DateFormat('dd MMM yyyy')
                                                      .format(selectedDate);
                                              setState(() {
                                                dialogTempValue = formattedDate;
                                              });
                                            }
                                          });
                                        },
                                        child: InputDecorator(
                                          decoration: const InputDecoration(
                                            border: OutlineInputBorder(),
                                            labelText: 'Select Date',
                                          ),
                                          child: Text(dialogTempValue),
                                        ),
                                      )
                                    : TextFormField(
                                        onChanged: (value) {
                                          setState(() {
                                            dialogTempValue = value;
                                          });
                                        },
                                        initialValue: dialogTempValue,
                                      ),
                                actions: [
                                  TextButton(
                                    child: const Text('Save'),
                                    onPressed: () {
                                      if (entry.key == 'dob') {
                                        // convert to Timestamp
                                        DateTime selectedDateTime =
                                            DateFormat('dd MMM yyyy')
                                                .parse(dialogTempValue);
                                        Timestamp selectedTimestamp =
                                            Timestamp.fromDate(
                                                selectedDateTime);
                                        if (selectedTimestamp !=
                                            originalData[entry.key]) {
                                          _editData(
                                              entry.key, selectedTimestamp);
                                          // if not in updateFields then add
                                          if (!updateFields.any((element) =>
                                              element.containsKey(entry.key))) {
                                            updateFields.add({
                                              entry.key: editedData[entry.key],
                                            });
                                          } else {
                                            updateFields.removeWhere(
                                                (element) => element
                                                    .containsKey(entry.key));
                                          }
                                        } else {
                                          _editData(
                                              entry.key, selectedTimestamp);
                                          updateFields.removeWhere((element) =>
                                              element.containsKey(entry.key));
                                        }
                                      } else {
                                        _editData(entry.key, dialogTempValue);
                                        // if not in updateFields then add
                                        if (!updateFields.any((element) =>
                                            element.containsKey(entry.key))) {
                                          updateFields.add({
                                            entry.key: editedData[entry.key],
                                          });
                                        } else {
                                          updateFields.removeWhere((element) =>
                                              element.containsKey(entry.key));
                                        }
                                      }
                                      debugPrint(updateFields.toString());
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ],
                              );
                            });
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        floatingActionButton: updateFields.isNotEmpty
            ? FloatingActionButton(
                onPressed: () {},
                child: const Icon(Icons.save),
              )
            : null,
      ),
    );
  }

  IconData _getIcon(String key) {
    switch (key) {
      case 'created':
        return Icons.calendar_today;
      case 'gender':
        return Icons.male;
      case 'height':
        return Icons.height;
      case 'image':
        return Icons.photo;
      case 'name':
        return Icons.person;
      case 'phone':
        return Icons.phone;
      case 'plan':
        return Icons.map;
      case 'city':
        return Icons.location_city;
      default:
        if (key.contains('dob')) {
          return Icons.cake;
        }
        return Icons.error;
    }
  }
}

class CustButton extends StatelessWidget {
  final double height;
  final double width;
  final VoidCallback? onPressed;
  final String imgPath;
  final String label;
  final Widget page;

  const CustButton({
    Key? key,
    required this.height,
    required this.width,
    this.onPressed,
    required this.imgPath,
    required this.label,
    required this.page,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        bottom: height * 0.01,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Card(
        elevation: 8.5,
        child: OpenContainerWrapper(
            page: page,
            content: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(imgPath),
                  fit: BoxFit.cover,
                  colorFilter: const ColorFilter.mode(
                    Colors.black38,
                    BlendMode.darken,
                  ),
                  alignment: Alignment.centerRight,
                ),
              ),
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(0, 255, 139, 139),
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: SizedBox(
                  height: height * 0.1,
                  width: width * 0.3,
                  child: Row(
                    children: [
                      Text(label),
                    ],
                  ),
                ),
              ),
            )),
      ),
    );
  }
}
