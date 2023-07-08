import 'package:another_flushbar/flushbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../components/ui/appbar.dart';

class CustOrderForm extends StatefulWidget {
  final String name;
  final String uid;
  final List<Map<String, dynamic>> productsHistory;
  final int popIndex;
  final int? index;
  const CustOrderForm({
    Key? key,
    required this.name,
    required this.uid,
    required this.productsHistory,
    required this.popIndex,
    this.index,
  }) : super(key: key);

  @override
  State<CustOrderForm> createState() => _CustOrderFormState();
}

class _CustOrderFormState extends State<CustOrderForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  List<Map<String, dynamic>> tempList = [{}];
  List<TextEditingController> productNameControllers = [];
  List<TextEditingController> productQuantityControllers = [];
  DateTime? selectedDateTime;

  @override
  void initState() {
    super.initState();
    // Initialize the controllers
    if (widget.index == null) {
      for (var _ in tempList) {
        final productNameController = TextEditingController();
        final productQuantityController = TextEditingController();
        productNameControllers.add(productNameController);
        productQuantityControllers.add(productQuantityController);
      }
    } else {
      final products = widget.productsHistory[widget.index!]['products'];
      // debugPrint(widget.productsHistory[widget.index!]['date'].toString());
      selectedDateTime = widget.productsHistory[widget.index!]['date'].toDate();
      tempList.clear();
      for (var i = 0; i < products.length; i++) {
        tempList.add(products);
        final productNameController = TextEditingController(
          text: products.keys.toList()[i],
        );
        final productQuantityController = TextEditingController(
          text: products.values.toList()[i].toString(),
        );
        productNameControllers.add(productNameController);
        productQuantityControllers.add(productQuantityController);
      }
    }
  }

  @override
  void dispose() {
    // Dispose the controllers
    for (int i = 0; i < productNameControllers.length; i++) {
      productNameControllers[i].dispose();
      productQuantityControllers[i].dispose();
    }
    super.dispose();
  }

// dd MMM yyyy at hh:mm
  String formatDate(DateTime dateTime) {
    final DateFormat formatter = DateFormat('dd MMM yyyy - hh:mm a');
    final String formatted = formatter.format(dateTime);
    return formatted;
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: MyAppBar(
        title: 'Order of ${widget.name}',
        leftIcon: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: Colors.black26,
          onPressed: () => Navigator.pop(context),
        ),
        rightIcons: [
          IconButton(
            icon: const Icon(Icons.add),
            color: Colors.black26,
            onPressed: () {
              setState(() {
                tempList.add({});
                final productNameController = TextEditingController();
                final productQuantityController = TextEditingController();
                productNameControllers.add(productNameController);
                productQuantityControllers.add(productQuantityController);
              });
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: width * 0.035),
          child: Column(
            children: [
              Container(
                margin:
                    EdgeInsets.only(top: height * 0.01, bottom: height * 0.02),
                child: Card(
                  elevation: 10,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: selectedDateTime == null
                        ? Container(
                            padding:
                                EdgeInsets.symmetric(horizontal: width * 0.02),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  children: [
                                    Text(
                                      'Please select',
                                      style: GoogleFonts.poppins(
                                        color: Colors.red,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text('Date and Time',
                                        style: GoogleFonts.poppins(
                                          color: Colors.red,
                                          fontWeight: FontWeight.w500,
                                        )),
                                  ],
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    final selected = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime.now().subtract(
                                          const Duration(days: 13 * 365)),
                                      lastDate: DateTime.now(),
                                    );
                                    if (selected != null) {
                                      final selectedTime = await showTimePicker(
                                        context: context,
                                        initialTime: TimeOfDay.now(),
                                      );
                                      if (selectedTime != null) {
                                        setState(() {
                                          selectedDateTime = DateTime(
                                            selected.year,
                                            selected.month,
                                            selected.day,
                                            selectedTime.hour,
                                            selectedTime.minute,
                                          );
                                        });
                                      }
                                    }
                                  },
                                  child: const Text('Select Date and Time'),
                                ),
                              ],
                            ),
                          )
                        : GestureDetector(
                            onTap: () async {
                              final selected = await showDatePicker(
                                context: context,
                                initialDate: selectedDateTime!,
                                firstDate: DateTime.now()
                                    .subtract(const Duration(days: 13 * 365)),
                                lastDate: DateTime.now(),
                              );
                              if (selected != null) {
                                final selectedTime = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                );
                                if (selectedTime != null) {
                                  setState(() {
                                    selectedDateTime = DateTime(
                                      selected.year,
                                      selected.month,
                                      selected.day,
                                      selectedTime.hour,
                                      selectedTime.minute,
                                    );
                                  });
                                }
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: width * 0.02,
                                  vertical: height * 0.02),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Date and Time:',
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    formatDate(selectedDateTime!),
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: tempList.length,
                  itemBuilder: (context, index) {
                    final productNameController = productNameControllers[index];
                    final productQuantityController =
                        productQuantityControllers[index];

                    return Container(
                      margin: EdgeInsets.only(bottom: height * 0.02),
                      child: Card(
                        elevation: 10,
                        child: Padding(
                          padding:
                              EdgeInsets.symmetric(vertical: height * 0.03),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // x icon
                              Container(
                                padding: EdgeInsets.only(top: height * 0.01),
                                child: IconButton(
                                  icon: const Icon(Icons.close,
                                      color: Colors.red, size: 20),
                                  onPressed: () {
                                    // show dialog
                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: const Text('Delete product?'),
                                          content: const Text(
                                              'Are you sure you want to delete this product?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                setState(() {
                                                  tempList.removeAt(index);
                                                  productNameControllers
                                                      .removeAt(index);
                                                  productQuantityControllers
                                                      .removeAt(index);
                                                });
                                                Navigator.pop(context);
                                              },
                                              child: const Text('Delete'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: productNameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Product Name',
                                    hintText: 'Enter product name',
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a product name';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              SizedBox(width: width * 0.1),
                              Expanded(
                                child: TextFormField(
                                  controller: productQuantityController,
                                  decoration: const InputDecoration(
                                    labelText: 'Quantity',
                                    hintText: 'qty',
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a quantity';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              SizedBox(width: width * 0.05),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: tempList.isNotEmpty
          ? FloatingActionButton(
              onPressed: () async {
                if (_formKey.currentState!.validate() &&
                    selectedDateTime != null) {
                  if (!await Method.checkInternetConnection(context)) {
                    return;
                  }
                  try {
                    Map<String, dynamic> products = {};
                    for (var i = 0; i < tempList.length; i++) {
                      if (int.tryParse(
                              productQuantityControllers[i].text.trim()) !=
                          null) {
                        products[productNameControllers[i].text.trim()] =
                            int.parse(
                                productQuantityControllers[i].text.trim());
                      } else {
                        // quit whole function
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text('Invalid quantity'),
                              content: const Text(
                                  'Please enter a valid quantity for all products'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Ok'),
                                ),
                              ],
                            );
                          },
                        );
                        return;
                      }
                    }
                    setState(() {
                      if (widget.index == null) {
                        widget.productsHistory.add({
                          'date': Timestamp.fromDate(selectedDateTime!),
                          'products': products,
                        });
                      } else {
                        widget.productsHistory[widget.index!] = {
                          'date': Timestamp.fromDate(selectedDateTime!),
                          'products': products,
                        };
                      }
                    });
                    debugPrint(widget.productsHistory.toString());
                    try {
                      await FirebaseFirestore.instance
                          .collection('Users')
                          .doc(widget.uid)
                          .update({
                        'productsHistory': widget.productsHistory,
                      });
                      for (int i = 0; i < widget.popIndex; i++) {
                        Navigator.pop(context);
                      }
                      Flushbar(
                        margin: const EdgeInsets.all(7),
                        borderRadius: BorderRadius.circular(15),
                        flushbarStyle: FlushbarStyle.FLOATING,
                        flushbarPosition: FlushbarPosition.BOTTOM,
                        message: "Order added successfully",
                        icon: Icon(
                          Icons.check_circle_outline_rounded,
                          size: 28.0,
                          color: Colors.green[300],
                        ),
                        duration: const Duration(milliseconds: 1500),
                        leftBarIndicatorColor: Colors.green[300],
                      ).show(context);
                      return;
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
            )
          : null,
    );
  }
}
