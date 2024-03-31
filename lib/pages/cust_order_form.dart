// ignore_for_file: use_build_context_synchronously

import 'package:another_flushbar/flushbar.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:coach_zen/pages/daily_attendance.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../components/ui/appbar.dart';

class CustOrderForm extends StatefulWidget {
  final String name;
  final String uid;
  final List<Map<dynamic, dynamic>> productsHistory;
  final int popIndex;
  final int? index;
  final bool? attendance;
  const CustOrderForm({
    Key? key,
    required this.name,
    required this.uid,
    required this.productsHistory,
    required this.popIndex,
    this.index,
    this.attendance,
  }) : super(key: key);

  @override
  State<CustOrderForm> createState() => _CustOrderFormState();
}

class _CustOrderFormState extends State<CustOrderForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Map<dynamic, dynamic>> tempList = [{}];
  List<TextEditingController> productNameControllers = [];
  List<TextEditingController> productQuantityControllers = [];
  DateTime? selectedDateTime;
  static const List<String> allProducts = <String>[
    "F1-Vanilla (₹2276)",
    "F1-Chocolate (₹2276)",
    "F1-Mango (₹2276)",
    "F1-Orange (₹2276)",
    "F1-Strawberry (₹2276)",
    "F1-Kulfi (₹2276)",
    "F1-Banana (₹2276)",
    "F1-Rose (₹2276)",
    "PPP-200 (₹1352)",
    "PPP-400 (₹2594)",
    "ShakeMate (₹681)",
    "Male Factor (₹3559)",
    "Woman's Choice (₹1298)",
    "Brain Health (₹1529)",
    "Immune Health (₹1596)",
    "Afresh-Ginger (₹848)",
    "Afresh-Elaich (₹848)",
    "Afresh-Lemon (₹848)",
    "Afresh-Peach (₹848)",
    "Afresh-Cinnamon (₹848)",
    "Afresh-Kashmiri (₹848)",
    "Afresh-Tulsi (₹848)",
    "H24-Hydrate (₹1709)",
    "H24-Rebuild (₹2731)",
    "Skin Booster (₹4082)",
    "Dino-Choco (₹1164)",
    "Dino-Strawberry (₹1164)",
    "Active Fiber Tablets - (₹1709)",
    "Active Fiber Complex (₹2672)",
    "Aloe Plus (₹1106)",
    "Aloe Concentrate (₹2815)",
    "Probiotic (₹2306)",
    "Triphala (₹1138)",
    "Calcium (₹1256)",
    "Joint Support (₹2563)",
    "Niteworks (₹7442)",
    "Herbalifeline (₹2785)",
    "Beta Heart (₹2342)",
    "Multivitamin (₹2091)",
    "Cell Activator (₹2313)",
    "Cell-U-Loss (₹1780)",
    "Control (₹3584)"
  ];
  int total = 0;
  int given = 0;
  bool isGivenChanged = false;
  @override
  void initState() {
    super.initState();
    if (widget.attendance != null) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
    if (widget.index == null) {
      for (var _ in tempList) {
        final productNameController = TextEditingController();
        final productQuantityController = TextEditingController();
        productNameControllers.add(productNameController);
        productQuantityControllers.add(productQuantityController);
      }
    } else {
      final products = widget.productsHistory[widget.index!]['products'];
      selectedDateTime = DateTime.fromMillisecondsSinceEpoch(
          widget.productsHistory[widget.index!]['date']);
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
      setState(() {
        total = widget.productsHistory[widget.index!]['total'];
        given = widget.productsHistory[widget.index!]['given'];
      });
    }
  }

  @override
  void dispose() {
    // Dispose the controllers
    for (int i = 0; i < productNameControllers.length; i++) {
      productNameControllers[i].dispose();
      productQuantityControllers[i].dispose();
    }
    scrollController.dispose();
    if (widget.attendance != null) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
    super.dispose();
  }

// dd MMM yyyy at hh:mm
  String formatDate(DateTime dateTime) {
    final DateFormat formatter = DateFormat('dd MMM yyyy - hh:mm a');
    final String formatted = formatter.format(dateTime);
    return formatted;
  }

  void addProduct() {
    setState(() {
      // add at 0th index in tempList
      tempList.insert(0, {});
      final productNameController = TextEditingController();
      final productQuantityController = TextEditingController();
      productNameControllers.insert(0, productNameController);
      productQuantityControllers.insert(0, productQuantityController);
      // scroll to bottom
      // scrollController.jumpTo(scrollController.position.maxScrollExtent);
      scrollController.animateTo(
        0.0,
        curve: Curves.easeOut,
        duration: const Duration(milliseconds: 300),
      );
    });
  }

  void calcTotal() {
    int subTotal = 0;
    for (var i = 0; i < productNameControllers.length; i++) {
      try {
        final product = productNameControllers[i].text.trim();
        final quantity = productQuantityControllers[i].text.trim();
        if (product.contains('₹')) {
          final price = int.parse(product.substring(
              product.indexOf('₹') + 1, product.indexOf(')')));
          subTotal += price * int.parse(quantity);
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    setState(() {
      total = subTotal;
      if (!isGivenChanged) {
        given = total;
      }
    });
  }

  final ScrollController scrollController = ScrollController();
  bool isFabEnabled = true;
  bool autoValidate = false;
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      // resizeToAvoidBottomInset: false,
      key: _scaffoldKey,
      appBar: MyAppBar(
        title: 'Order of ${widget.name}',
        leftIcon: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: Colors.black26,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        rightIcons: [
          IconButton(
            icon: const Icon(Icons.add),
            color: Colors.black26,
            onPressed: addProduct,
          ),
        ],
      ),
      body: Form(
        autovalidateMode:
            autoValidate ? AutovalidateMode.always : AutovalidateMode.disabled,
        key: _formKey,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: width * 0.035),
          child: Column(
            children: [
              if (total != 0 && tempList.isNotEmpty)
                Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(
                        top: height * 0.01, bottom: height * 0.02),
                    child: Card(
                        elevation: 5,
                        child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Center(
                              child: Text('Total:  ₹$total',
                                  style: GoogleFonts.workSans(
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: .5,
                                      fontSize: 19.5)),
                            )))),
              if (total != 0 && tempList.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    // open a dialog to change the given amount
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Change Giving At:'),
                          content: TextFormField(
                            initialValue: given.toString(),
                            onChanged: (value) {
                              if (value.isNotEmpty) {
                                setState(() {
                                  given = int.parse(value);
                                  isGivenChanged = true;
                                });
                              }
                            },
                            decoration: const InputDecoration(
                              labelText: 'Given amount',
                            ),
                            keyboardType: TextInputType.number,
                          ),
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
                  },
                  child: Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(
                          top: height * 0.01, bottom: height * 0.02),
                      child: Card(
                          elevation: 5,
                          child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Center(
                                child: Text('Giving At:  ₹$given',
                                    style: GoogleFonts.workSans(
                                        color: (given > total) ||
                                                (given < total / 2)
                                            ? Colors.red
                                            : Colors.black,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: .5,
                                        fontSize: 19.5)),
                              )))),
                )
              else if (tempList.isEmpty)
                Container(
                  margin:
                      EdgeInsets.only(top: height * 0.1, bottom: height * 0.02),
                  child: Center(
                    child: Text(
                        'No products added yet. ${widget.index != null ? '  \n  \nif you want to delete this order, please click on the delete button without adding any products' : ''}',
                        style: GoogleFonts.workSans(
                            fontWeight: FontWeight.w500,
                            letterSpacing: .5,
                            fontSize: 19.5)),
                  ),
                ),
              Flexible(
                child: ListView.builder(
                  controller: scrollController,
                  reverse: true,
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: tempList.length,
                  itemBuilder: (context, index) {
                    final productNameController = productNameControllers[index];
                    final productQuantityController =
                        productQuantityControllers[index];
                    void deleteProduct() {
                      setState(() {
                        tempList.removeAt(index);
                        productNameControllers.removeAt(index);
                        productQuantityControllers.removeAt(index);
                      });
                      calcTotal();
                    }

                    // check if any of the textfields contains '₹'
                    // if yes, then take the number after '₹' and multiply it with the quantity
                    // and add it to total

                    return Column(
                      children: [
                        if (index == tempList.length - 1)
                          Container(
                            margin: EdgeInsets.only(
                                top: height * 0.01, bottom: height * 0.02),
                            child: Card(
                              elevation: 10,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: selectedDateTime == null
                                    ? Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: width * 0.02),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
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
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    )),
                                              ],
                                            ),
                                            ElevatedButton(
                                              onPressed: () async {
                                                final selected =
                                                    await showDatePicker(
                                                  context: context,
                                                  initialDate: DateTime.now(),
                                                  firstDate: DateTime.now()
                                                      .subtract(const Duration(
                                                          days: 13 * 365)),
                                                  lastDate: DateTime.now(),
                                                );
                                                if (selected != null) {
                                                  final selectedTime =
                                                      await showTimePicker(
                                                    context: context,
                                                    initialTime:
                                                        TimeOfDay.now(),
                                                  );
                                                  if (selectedTime != null) {
                                                    setState(() {
                                                      selectedDateTime =
                                                          DateTime(
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
                                              child: const Text(
                                                  'Select Date and Time'),
                                            ),
                                          ],
                                        ),
                                      )
                                    : GestureDetector(
                                        onTap: () async {
                                          final selected = await showDatePicker(
                                            context: context,
                                            initialDate: selectedDateTime!,
                                            firstDate: DateTime.now().subtract(
                                                const Duration(days: 13 * 365)),
                                            lastDate: DateTime.now(),
                                          );
                                          if (selected != null) {
                                            final selectedTime =
                                                await showTimePicker(
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
                                              AutoSizeText(
                                                'Date and Time:',
                                                maxFontSize: 15,
                                                minFontSize: 10,
                                                presetFontSizes: const [
                                                  15,
                                                  12,
                                                  10,
                                                ],
                                                style: GoogleFonts.poppins(),
                                              ),
                                              AutoSizeText(
                                                formatDate(selectedDateTime!),
                                                maxFontSize: 16,
                                                minFontSize: 12,
                                                presetFontSizes: const [
                                                  16,
                                                  14,
                                                  12,
                                                ],
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                          ),

                        Container(
                          margin: EdgeInsets.only(bottom: height * 0.02),
                          child: Card(
                            elevation: 10,
                            child: Padding(
                              padding:
                                  EdgeInsets.symmetric(vertical: height * 0.03),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // x icon
                                  Container(
                                    padding:
                                        EdgeInsets.only(top: height * 0.01),
                                    child: IconButton(
                                      icon: const Icon(Icons.close,
                                          color: Colors.red, size: 20),
                                      onPressed: () {
                                        // show dialog if product is not empty
                                        if (productNameController
                                                .text.isNotEmpty ||
                                            productQuantityController
                                                .text.isNotEmpty) {
                                          showDialog(
                                            context: context,
                                            builder: (context) {
                                              return AlertDialog(
                                                title: const Text(
                                                    'Delete product?'),
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
                                                      deleteProduct();
                                                      Navigator.pop(context);
                                                    },
                                                    child: const Text('Delete'),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        } else {
                                          deleteProduct();
                                        }
                                      },
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: TypeAheadFormField(
                                      minCharsForSuggestions: 1,
                                      hideOnEmpty: true,
                                      animationStart: 0.5,
                                      autoFlipMinHeight: 10,
                                      textFieldConfiguration:
                                          TextFieldConfiguration(
                                              onChanged: (_) {
                                                calcTotal();
                                              },
                                              controller: productNameController,
                                              decoration: const InputDecoration(
                                                  labelText: 'Product Name',
                                                  hintText:
                                                      'Enter product name')),
                                      suggestionsCallback: (pattern) {
                                        return allProducts
                                            .where((element) => element
                                                .toLowerCase()
                                                .contains(
                                                    pattern.toLowerCase()))
                                            // .take(3)
                                            .toList();
                                      },
                                      // only max 5 suggestions
                                      itemBuilder: (context, suggestion) {
                                        return ListTile(
                                          title: Text(
                                            // only show text before '('
                                            suggestion.substring(
                                                0, suggestion.indexOf('(')),
                                            maxLines: 1,
                                            style: GoogleFonts.montserrat(
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        );
                                      },
                                      suggestionsBoxDecoration:
                                          SuggestionsBoxDecoration(
                                        constraints: BoxConstraints(
                                          maxHeight: height * 0.2,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(7.5),
                                      ),
                                      direction: AxisDirection.up,
                                      transitionBuilder: (context,
                                          suggestionsBox, controller) {
                                        return suggestionsBox;
                                      },
                                      onSuggestionSelected: (suggestion) {
                                        productNameController.text = suggestion;
                                      },
                                      validator: (value) {
                                        if (value!.isEmpty) {
                                          return 'Please select a product';
                                        } else if (!value.contains('₹')) {
                                          return 'Please enter a valid product';
                                        }
                                        return null;
                                      },
                                      onSaved: (value) =>
                                          productNameController.text = value!,
                                    ),
                                  ),
                                  SizedBox(width: width * 0.1),
                                  Expanded(
                                    child: TextFormField(
                                      controller: productQuantityController,
                                      onChanged: (_) {
                                        calcTotal();
                                      },
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
                        ),

                        if (index == 0)
                          Container(
                            margin: EdgeInsets.only(bottom: height * 0.02),
                            child: ElevatedButton(
                              onPressed: addProduct,
                              child: const Text('Add new product'),
                            ),
                          ),
                        // an elevated button to add new product
                        // if index is last
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: (tempList.isNotEmpty && isFabEnabled) ||
              widget.index != null
          ? FloatingActionButton(
              onPressed: () async {
                if (!isFabEnabled) {
                  return; // Do nothing if the FAB is already disabled
                }

                setState(() {
                  isFabEnabled = false;
                  autoValidate = true;
                });

                if (_formKey.currentState!.validate() &&
                    selectedDateTime != null) {
                  // debugPrint("products.toString()");
                  // return;
                  if (!await Method.checkInternetConnection(context)) {
                    setState(() {
                      isFabEnabled = true;
                    });
                    return;
                  }
                  // if given is greater than total or given is less than 50% of total

                  try {
                    if (total == 0 && tempList.isNotEmpty) {
                      Flushbar(
                        margin: const EdgeInsets.all(7),
                        borderRadius: BorderRadius.circular(15),
                        flushbarStyle: FlushbarStyle.FLOATING,
                        flushbarPosition: FlushbarPosition.BOTTOM,
                        message: "Please enter valid products",
                        icon: Icon(
                          Icons.error_outline_rounded,
                          size: 28.0,
                          color: Colors.red[300],
                        ),
                        duration: const Duration(milliseconds: 1500),
                        leftBarIndicatorColor: Colors.red[300],
                      ).show(context);
                      setState(() {
                        isFabEnabled = true;
                      });
                      return;
                    }
                    if ((given > total) || (given < total / 2)) {
                      Flushbar(
                        margin: const EdgeInsets.all(7),
                        borderRadius: BorderRadius.circular(15),
                        flushbarStyle: FlushbarStyle.FLOATING,
                        flushbarPosition: FlushbarPosition.BOTTOM,
                        message: "Given amount Invalid",
                        icon: Icon(
                          Icons.error_outline_rounded,
                          size: 28.0,
                          color: Colors.red[300],
                        ),
                        duration: const Duration(milliseconds: 1500),
                        leftBarIndicatorColor: Colors.red[300],
                      ).show(context);
                      setState(() {
                        isFabEnabled = true;
                      });
                      return;
                    }

                    Map<String, dynamic> products = {};
                    for (var i = 0; i < tempList.length; i++) {
                      if (int.tryParse(
                              productQuantityControllers[i].text.trim()) !=
                          null) {
                        products[productNameControllers[i].text.trim()] =
                            int.parse(
                                productQuantityControllers[i].text.trim());
                      } else {
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
                        setState(() {
                          isFabEnabled = true;
                        });
                        return;
                      }
                    }
                    final timestamp = selectedDateTime!.millisecondsSinceEpoch;
                    final newOrder = {
                      'date': timestamp,
                      'products': products,
                      'total': total,
                      'given': given,
                    };
                    String msg = "Order added successfully";
                    List newProductsHistory = [...widget.productsHistory];
                    if (widget.index == null) {
                      newProductsHistory.add(newOrder);
                    } else {
                      if (newOrder[products] == null && tempList.isEmpty) {
                        newProductsHistory.removeAt(widget.index!);
                        msg = "Order deleted successfully";
                      } else {
                        newProductsHistory[widget.index!] = newOrder;
                        msg = "Order updated successfully";
                      }
                    }

                    try {
                      await FirebaseDatabase.instance
                          .ref()
                          .child('Coaches')
                          .child(FirebaseAuth.instance.currentUser!.uid)
                          .child('users')
                          .child(widget.uid)
                          .update({
                        'productsHistory': newProductsHistory,
                      });

                      for (int i = 0; i < widget.popIndex; i++) {
                        Navigator.pop(context);
                      }

                      Flushbar(
                        margin: const EdgeInsets.all(7),
                        borderRadius: BorderRadius.circular(15),
                        flushbarStyle: FlushbarStyle.FLOATING,
                        flushbarPosition: FlushbarPosition.BOTTOM,
                        message: msg,
                        icon: Icon(
                          Icons.check_circle_outline_rounded,
                          size: 28.0,
                          color: Colors.green[300],
                        ),
                        duration: const Duration(milliseconds: 1500),
                        leftBarIndicatorColor: Colors.green[300],
                      ).show(context);
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
                  }

                  setState(() {
                    isFabEnabled = true;
                  });
                } else if (selectedDateTime == null) {
                  Flushbar(
                    margin: const EdgeInsets.all(7),
                    borderRadius: BorderRadius.circular(15),
                    flushbarStyle: FlushbarStyle.FLOATING,
                    flushbarPosition: FlushbarPosition.BOTTOM,
                    message: "Please select a date and time",
                    icon: Icon(
                      Icons.error_outline_rounded,
                      size: 28.0,
                      color: Colors.red[300],
                    ),
                    duration: const Duration(milliseconds: 1500),
                    leftBarIndicatorColor: Colors.red[300],
                  ).show(context);
                  setState(() {
                    isFabEnabled = true;
                  });
                } else {
                  setState(() {
                    isFabEnabled = true;
                  });
                }
              },
              child: widget.index != null && tempList.isEmpty
                  ? const Icon(Icons.delete_rounded)
                  : const Icon(Icons.save_rounded),
            )
          : null,
    );
  }
}
