// ignore_for_file: use_build_context_synchronously

import 'package:another_flushbar/flushbar.dart';
import 'package:auto_size_text/auto_size_text.dart';
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
  final screenHeight = WidgetsBinding
      .instance.platformDispatcher.views.first.physicalSize.height;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  DateTime selectedDateTime = DateTime.now();
  String productSku = '';
  final productNameController = TextEditingController();
  final productQuantityController = TextEditingController();
  Map<String, int> productMap = {};

  int total = 0;
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
    } else {
      final products = widget.productsHistory[widget.index!]['products'];
      selectedDateTime = DateTime.fromMillisecondsSinceEpoch(
          widget.productsHistory[widget.index!]['date']);

      setState(() {
        total = widget.productsHistory[widget.index!]['total'];
      });
    }
  }

  @override
  void dispose() {
    // Dispose the controllers

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

  final ScrollController scrollController = ScrollController();
  bool isFabEnabled = false;
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
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: width * 0.035),
        child: Column(
          children: [
            // if (tempList.isEmpty)
            //   Container(
            //     margin:
            //         EdgeInsets.only(top: height * 0.1, bottom: height * 0.02),
            //     child: Center(
            //       child: Text(
            //           'No products added yet. ${widget.index != null ? '  \n  \nif you want to delete this order, please click on the delete button without adding any products' : ''}',
            //           style: GoogleFonts.workSans(
            //               fontWeight: FontWeight.w500,
            //               letterSpacing: .5,
            //               fontSize: 19.5)),
            //     ),
            //   ),
            Container(
              margin:
                  EdgeInsets.only(top: height * 0.01, bottom: height * 0.02),
              child: Card(
                elevation: 10,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GestureDetector(
                    onTap: () async {
                      final selected = await showDatePicker(
                        context: context,
                        initialDate: selectedDateTime,
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
                          horizontal: width * 0.02, vertical: height * 0.02),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AutoSizeText(
                            'Created:',
                            maxFontSize: 15,
                            minFontSize: 10,
                            style: GoogleFonts.poppins(),
                          ),
                          AutoSizeText(
                            formatDate(selectedDateTime),
                            maxFontSize: 15,
                            minFontSize: 10,
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

            Flexible(
              child: ListView.builder(
                controller: scrollController,
                reverse: true,
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: productMap.length + 1,
                itemBuilder: (context, index) {
                  debugPrint('productMap: $productMap');

                  return Column(
                    children: [
                      if (index == 0)
                        Form(
                          autovalidateMode: autoValidate
                              ? AutovalidateMode.always
                              : AutovalidateMode.disabled,
                          key: _formKey,
                          child: Column(
                            children: [
                              Container(
                                margin: EdgeInsets.only(bottom: height * 0.02),
                                child: Card(
                                  elevation: 10,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                        vertical: height * 0.03),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        SizedBox(width: width * 0.05),
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
                                                      // calcTotal();
                                                    },
                                                    controller:
                                                        productNameController,
                                                    decoration:
                                                        const InputDecoration(
                                                            labelText:
                                                                'Product Name',
                                                            hintText:
                                                                'Tap product name')),
                                            suggestionsCallback: (pattern) {
                                              return allProducts.values
                                                  .where((element) =>
                                                      element['name']!
                                                          .toLowerCase()
                                                          .contains(pattern
                                                              .toLowerCase()) ||
                                                      element['sku']!.contains(
                                                          pattern
                                                              .toLowerCase()))
                                                  .toList();
                                            },
                                            // only max 5 suggestions
                                            itemBuilder: (context, suggestion) {
                                              return ListTile(
                                                title: Text(
                                                  suggestion['name']!,
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
                                              productNameController.text =
                                                  suggestion['name'] as String;
                                              setState(() {
                                                productSku =
                                                    suggestion['sku'] as String;
                                              });
                                            },
                                            validator: (value) {
                                              if (value!.isEmpty) {
                                                return 'Please select a product';
                                              } else if (!allProducts.values
                                                  .any((element) =>
                                                      element['name']!
                                                          .toLowerCase() ==
                                                      value
                                                          .trim()
                                                          .toLowerCase())) {
                                                return 'Please select a valid product';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                        SizedBox(width: width * 0.1),
                                        Expanded(
                                          child: TextFormField(
                                            controller:
                                                productQuantityController,
                                            onChanged: (_) {
                                              // calcTotal();
                                            },
                                            decoration: const InputDecoration(
                                              labelText: 'Quantity',
                                              hintText: 'qty',
                                              counterText: '',
                                            ),
                                            keyboardType: TextInputType.number,
                                            maxLength: 2,
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Please enter a quantity';
                                              } else if (int.tryParse(value) ==
                                                  null) {
                                                return 'Please enter a valid number';
                                              } else if (int.parse(value) <=
                                                  0) {
                                                return 'Please enter a valid number';
                                              } else if (int.parse(value) >
                                                  90) {
                                                return 'Please enter a valid number';
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
                              Container(
                                margin: EdgeInsets.only(bottom: height * 0.02),
                                child: ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      autoValidate = true;
                                    });
                                    debugPrint('productSku: $productSku');
                                    if (_formKey.currentState!.validate()) {
                                      if (allProducts[productSku]['name']
                                              .toLowerCase() ==
                                          productNameController.text
                                              .trim()
                                              .toLowerCase()) {
                                        setState(() {
                                          productMap[productSku] = int.parse(
                                              productQuantityController.text);
                                          isFabEnabled = true;
                                          debugPrint('productMap: $productMap');
                                          autoValidate = false;
                                          scrollController.animateTo(
                                            0.0,
                                            curve: Curves.easeOut,
                                            duration: const Duration(
                                                milliseconds: 300),
                                          );
                                        });
                                      }
                                      setState(() {
                                        productSku = '';
                                      });
                                      productNameController.clear();
                                      productQuantityController.clear();
                                    }
                                  },
                                  child: const Text('Add new product'),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
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

                                        showDialog(
                                          context: context,
                                          builder: (context) {
                                            return AlertDialog(
                                              title:
                                                  const Text('Delete product?'),
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
                                                      productMap.remove(
                                                          productMap.keys
                                                              .elementAt(
                                                                  index - 1));
                                                      if (productMap.isEmpty) {
                                                        isFabEnabled = false;
                                                      }
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
                                      decoration: const InputDecoration(
                                        labelText: 'Product Name',
                                        enabledBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Colors.transparent,
                                          ),
                                        ),
                                        focusedBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Colors.transparent,
                                          ),
                                        ),
                                      ),
                                      initialValue: allProducts[productMap.keys
                                          .elementAt(index - 1)]['name'],
                                      readOnly: true,
                                    ),
                                  ),
                                  SizedBox(width: width * 0.1),
                                  Expanded(
                                    child: TextField(
                                      readOnly: true,
                                      decoration: const InputDecoration(
                                        labelText: 'Qty',
                                        enabledBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Colors.transparent,
                                          ),
                                        ),
                                        focusedBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Colors.transparent,
                                          ),
                                        ),
                                      ),
                                      controller: TextEditingController()
                                        ..text = productMap.values
                                            .elementAt(index - 1)
                                            .toString(),
                                    ),
                                  ),
                                  SizedBox(width: width * 0.05),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: (isFabEnabled) || widget.index != null
          ? FloatingActionButton(
              onPressed: () async {
                if (!isFabEnabled) {
                  return; // Do nothing if the FAB is already disabled
                }

                setState(() {
                  isFabEnabled = false;
                });

                if (productMap.isNotEmpty) {
                  // debugPrint("products.toString()");
                  // return;
                  if (!await Method.checkInternetConnection(context)) {
                    setState(() {
                      isFabEnabled = true;
                    });
                    return;
                  }
                  setState(() {
                    isFabEnabled = true;
                  });
                  DiscountModes? mode = DiscountModes.manual;
                  TextEditingController discountController =
                      TextEditingController();
                  final shakeMate = allProducts['183K'];
                  TextEditingController shakeMateController =
                      TextEditingController(
                          text: shakeMate['price'].toString());
                  final GlobalKey<FormState> formkeydiscount =
                      GlobalKey<FormState>();
                  final int tQuantity =
                      productMap.values.reduce((a, b) => a + b);
                  final tCost = productMap.keys
                      .map((e) => allProducts[e]['price'] * productMap[e])
                      .reduce((a, b) => a + b);
                  final bool isShakeMate = productMap.containsKey('183K');
                  int shakemateDiscount = 0;
                  int discount = 0;
                  int total = tCost;
                  String initalAutoMode = '15%';
                  TextEditingController customPriceController =
                      TextEditingController(text: tCost.toString());

                  void calcAutoPrice() {
                    final int discountedPrice = productMap.keys
                        .map((e) =>
                            allProducts[e][initalAutoMode] * productMap[e])
                        .reduce((a, b) => a + b);
                    setState(() {
                      discount = tCost - discountedPrice;
                    });
                  }

                  return showDialog(
                      context: _scaffoldKey.currentContext!,
                      builder: (context) => StatefulBuilder(
                              builder: (contextx, StateSetter setState) {
                            final dialogWidth =
                                MediaQuery.of(contextx).size.width * 0.9;

                            return AlertDialog(
                              // remove all padding
                              contentPadding: EdgeInsets.zero,
                              // dialog width to 95% of screen
                              insetPadding: EdgeInsets.zero,
                              actionsPadding: EdgeInsets.symmetric(
                                  vertical: dialogWidth * .02),
                              title: Text(
                                'Any Discount?',
                                style: GoogleFonts.montserrat(),
                              ),
                              content: Padding(
                                  padding: EdgeInsets.only(
                                    top: screenHeight * 0.01,
                                  ),
                                  child: SizedBox(
                                      height: screenHeight * 0.25,
                                      width: dialogWidth,
                                      child: SingleChildScrollView(
                                        child: Form(
                                          key: formkeydiscount,
                                          autovalidateMode: AutovalidateMode
                                              .onUserInteraction,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              FittedBox(
                                                child: DataTable(
                                                  horizontalMargin:
                                                      dialogWidth * .05,
                                                  columnSpacing:
                                                      dialogWidth * .05,
                                                  border: TableBorder.all(
                                                      color: Colors.black26),
                                                  columns: <DataColumn>[
                                                    DataColumn(
                                                      label: Container(
                                                        padding:
                                                            EdgeInsets.zero,
                                                        width: dialogWidth * .6,
                                                        child: Text(
                                                          'Product',
                                                          style: GoogleFonts
                                                              .montserrat(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600),
                                                        ),
                                                      ),
                                                    ),
                                                    DataColumn(
                                                      label: SizedBox(
                                                        width: dialogWidth * .1,
                                                        child: Text(
                                                          'Qty',
                                                          style: GoogleFonts
                                                              .montserrat(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600),
                                                        ),
                                                      ),
                                                    ),
                                                    DataColumn(
                                                      label: SizedBox(
                                                        width:
                                                            dialogWidth * .15,
                                                        child: Text(
                                                          'Price',
                                                          style: GoogleFonts
                                                              .montserrat(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                  rows: List<DataRow>.generate(
                                                      productMap.length,
                                                      (index) {
                                                    String key = productMap.keys
                                                        .elementAt(index);
                                                    return DataRow(
                                                      cells: <DataCell>[
                                                        DataCell(
                                                          Text(
                                                            allProducts[key]
                                                                    ['name']
                                                                .toString(),
                                                            style: GoogleFonts
                                                                .montserrat(),
                                                          ),
                                                        ),
                                                        DataCell(
                                                          Text(
                                                            productMap[key]
                                                                .toString(),
                                                            style: GoogleFonts
                                                                .montserrat(),
                                                          ),
                                                        ),
                                                        DataCell(
                                                          Text(
                                                            '₹${allProducts[key]['price']}',
                                                            style: GoogleFonts
                                                                .montserrat(),
                                                          ),
                                                        ),
                                                      ],
                                                    );
                                                  }),
                                                ),
                                              ),

                                              // 3 radio in a row
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceEvenly,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  // manual
                                                  Expanded(
                                                    child: Row(
                                                      children: [
                                                        Radio<DiscountModes>(
                                                          value: DiscountModes
                                                              .manual,
                                                          groupValue: mode,
                                                          onChanged: (value) {
                                                            setState(() {
                                                              discountController
                                                                  .clear();
                                                              discount = 0;
                                                              mode = value;
                                                            });
                                                          },
                                                        ),
                                                        Text(
                                                          'Manual',
                                                          style: GoogleFonts
                                                              .montserrat(),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  // auto
                                                  Expanded(
                                                    child: Row(
                                                      children: [
                                                        Radio<DiscountModes>(
                                                          value: DiscountModes
                                                              .auto,
                                                          groupValue: mode,
                                                          onChanged: (value) {
                                                            calcAutoPrice();
                                                            setState(() {
                                                              discountController
                                                                  .clear();
                                                              shakeMateController
                                                                  .text = shakeMate[
                                                                      'price']
                                                                  .toString();
                                                              customPriceController
                                                                      .text =
                                                                  tCost
                                                                      .toString();
                                                              shakemateDiscount =
                                                                  0;
                                                              mode = value;
                                                            });
                                                          },
                                                        ),
                                                        Text(
                                                          'Auto',
                                                          style: GoogleFonts
                                                              .montserrat(),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Row(
                                                      children: [
                                                        Radio<DiscountModes>(
                                                          value: DiscountModes
                                                              .custom,
                                                          groupValue: mode,
                                                          onChanged: (value) {
                                                            setState(() {
                                                              discountController
                                                                  .clear();
                                                              shakeMateController
                                                                  .text = shakeMate[
                                                                      'price']
                                                                  .toString();
                                                              discount = 0;
                                                              shakemateDiscount =
                                                                  0;
                                                              mode = value;
                                                            });
                                                          },
                                                        ),
                                                        Text(
                                                          'Custom',
                                                          style: GoogleFonts
                                                              .montserrat(),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (mode == DiscountModes.manual)
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal:
                                                          dialogWidth * .05),
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        child: TextFormField(
                                                          controller:
                                                              discountController,
                                                          maxLength: 2,
                                                          onChanged: (value) {
                                                            if (value.isEmpty ||
                                                                value == '0' ||
                                                                int.tryParse(
                                                                        value) ==
                                                                    null) {
                                                              setState(() {
                                                                discount = 0;
                                                              });
                                                              return;
                                                            }
                                                            final int disc =
                                                                int.tryParse(
                                                                    value)!;
                                                            int tempTotalCost =
                                                                tCost;

                                                            if (isShakeMate) {
                                                              final int
                                                                  smPrice =
                                                                  int.tryParse(
                                                                          shakeMateController
                                                                              .text) ??
                                                                      0;
                                                              final tShakeMatePrice =
                                                                  smPrice *
                                                                      productMap[
                                                                          '183K']!;
                                                              tempTotalCost -=
                                                                  tShakeMatePrice;
                                                            }
                                                            setState(() {
                                                              discount =
                                                                  tempTotalCost *
                                                                      disc ~/
                                                                      100;
                                                            });
                                                          },
                                                          decoration:
                                                              const InputDecoration(
                                                            counterText: '',
                                                            labelText:
                                                                'Discount %',
                                                          ),
                                                          keyboardType:
                                                              TextInputType
                                                                  .number,
                                                          validator: (value) {
                                                            if (value == null) {
                                                              return 'Please enter a given amount';
                                                            } else if (value
                                                                .isEmpty) {
                                                              return null;
                                                            } else if (int
                                                                    .tryParse(
                                                                        value) ==
                                                                null) {
                                                              return 'Please enter a valid number';
                                                            } else if (int
                                                                    .parse(
                                                                        value) >
                                                                50) {
                                                              return 'Please enter a valid number';
                                                            } else if (int
                                                                    .parse(
                                                                        value) <
                                                                0) {
                                                              return 'Please enter a valid number';
                                                            }
                                                            return null;
                                                          },
                                                        ),
                                                      ),
                                                      if (isShakeMate)
                                                        Expanded(
                                                          child: Row(
                                                            children: [
                                                              SizedBox(
                                                                width:
                                                                    dialogWidth *
                                                                        .05,
                                                              ),
                                                              Expanded(
                                                                child:
                                                                    TextFormField(
                                                                  controller:
                                                                      shakeMateController,
                                                                  maxLength: 3,
                                                                  onChanged:
                                                                      (value) {
                                                                    if (value
                                                                            .isNotEmpty &&
                                                                        int.tryParse(value) !=
                                                                            null) {
                                                                      setState(
                                                                          () {
                                                                        shakemateDiscount =
                                                                            (shakeMate['price'] - int.parse(value)) *
                                                                                productMap['183K']!;
                                                                      });
                                                                    } else {
                                                                      setState(
                                                                          () {
                                                                        shakemateDiscount =
                                                                            shakeMate['price'] *
                                                                                productMap['183K']!;
                                                                      });
                                                                    }
                                                                  },
                                                                  decoration:
                                                                      const InputDecoration(
                                                                    counterText:
                                                                        '',
                                                                    labelText:
                                                                        'ShakeMate Price',
                                                                  ),
                                                                  keyboardType:
                                                                      TextInputType
                                                                          .number,
                                                                  validator:
                                                                      (value) {
                                                                    if (value ==
                                                                            null ||
                                                                        value
                                                                            .isEmpty) {
                                                                      return 'Please enter a given amount';
                                                                    } else if (int.tryParse(
                                                                            value) ==
                                                                        null) {
                                                                      return 'Please enter a valid number';
                                                                    }
                                                                    // no more than 50% discount
                                                                    else if (shakeMate[
                                                                            '50%'] >
                                                                        int.parse(
                                                                            value)) {
                                                                      return 'Please enter a valid number';
                                                                    } else if (int.parse(
                                                                            value) >
                                                                        shakeMate[
                                                                            'price']) {
                                                                      return 'Please enter a valid number';
                                                                    }
                                                                    return null;
                                                                  },
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              if (mode == DiscountModes.auto)
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal:
                                                          dialogWidth * .05),
                                                  child: Expanded(
                                                    child:
                                                        DropdownButtonFormField<
                                                            String>(
                                                      decoration:
                                                          const InputDecoration(
                                                        contentPadding: EdgeInsets
                                                            .zero, // Remove any content padding
                                                        isDense: true,
                                                        labelText: 'Mode',
                                                      ),
                                                      value: initalAutoMode,
                                                      items: [
                                                        '15%',
                                                        '25%',
                                                        '35%',
                                                        '42%',
                                                        '50%'
                                                      ].map((String value) {
                                                        return DropdownMenuItem<
                                                            String>(
                                                          value: value,
                                                          child: Text(value),
                                                        );
                                                      }).toList(),
                                                      onChanged:
                                                          (String? newValue) {
                                                        setState(() {
                                                          initalAutoMode =
                                                              newValue!;
                                                        });
                                                        // calculate discount
                                                        calcAutoPrice();
                                                      },
                                                    ),
                                                  ),
                                                ),
                                              if (mode == DiscountModes.custom)
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal:
                                                          dialogWidth * .05),
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        child: TextFormField(
                                                          controller:
                                                              customPriceController,
                                                          // digits of tcost
                                                          maxLength: tCost
                                                              .toString()
                                                              .length,
                                                          onChanged: (value) {
                                                            int? cusPrice =
                                                                int.tryParse(
                                                                    value);
                                                            if (value.isEmpty ||
                                                                value == '0' ||
                                                                cusPrice ==
                                                                    null) {
                                                              setState(() {
                                                                discount = 0;
                                                              });
                                                              return;
                                                            }
                                                            setState(() {
                                                              discount = tCost -
                                                                  cusPrice;
                                                            });
                                                          },
                                                          decoration:
                                                              const InputDecoration(
                                                            counterText: '',
                                                            labelText:
                                                                'Custom Price',
                                                          ),
                                                          keyboardType:
                                                              TextInputType
                                                                  .number,
                                                          validator: (value) {
                                                            if (value == null) {
                                                              return 'Please enter a given amount';
                                                            } else if (value
                                                                .isEmpty) {
                                                              return null;
                                                            } else if (int
                                                                    .tryParse(
                                                                        value) ==
                                                                null) {
                                                              return 'Please enter a valid number';
                                                            } else if (int
                                                                    .parse(
                                                                        value) >
                                                                tCost) {
                                                              return 'Please enter a valid number';
                                                            } else if (int.parse(
                                                                        value) !=
                                                                    0 &&
                                                                int.parse(
                                                                        value) <
                                                                    (tCost /
                                                                        2)) {
                                                              return 'Please enter a valid number';
                                                            }
                                                            return null;
                                                          },
                                                        ),
                                                      )
                                                    ],
                                                  ),
                                                ),
                                              Padding(
                                                padding: EdgeInsets.all(
                                                    dialogWidth * .05),
                                                child: Card(
                                                  elevation: 8,
                                                  child: Container(
                                                    width: double.infinity,
                                                    height: height * 0.225,
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            horizontal:
                                                                dialogWidth *
                                                                    .05,
                                                            vertical:
                                                                height * 0.02),
                                                    child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            'Total Qty:  $tQuantity',
                                                            style: GoogleFonts
                                                                .montserrat(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600),
                                                          ),
                                                          Text(
                                                            'MRP:  ₹$tCost',
                                                            style: GoogleFonts
                                                                .montserrat(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600),
                                                          ),
                                                          Text.rich(
                                                            TextSpan(
                                                              children: [
                                                                TextSpan(
                                                                  text:
                                                                      'Discount: ',
                                                                  style: GoogleFonts
                                                                      .montserrat(
                                                                    color: Colors
                                                                        .black, // Normal color for the text
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                  ),
                                                                ),
                                                                TextSpan(
                                                                  text:
                                                                      '-₹${discount + shakemateDiscount}',
                                                                  style: GoogleFonts
                                                                      .montserrat(
                                                                    color: Colors
                                                                        .red, // Red color for the discount value
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          Text(
                                                            'Total:  ₹${total - (discount + shakemateDiscount)}',
                                                            style: GoogleFonts
                                                                .montserrat(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600),
                                                          ),
                                                        ]),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ))),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Text('No'),
                                ),
                                TextButton(
                                  onPressed: () {},
                                  child: const Text('Yes'),
                                ),
                              ],
                            );
                          }));

                  // try {
                  //   if (total == 0 && tempList.isNotEmpty) {
                  //     Flushbar(
                  //       margin: const EdgeInsets.all(7),
                  //       borderRadius: BorderRadius.circular(15),
                  //       flushbarStyle: FlushbarStyle.FLOATING,
                  //       flushbarPosition: FlushbarPosition.BOTTOM,
                  //       message: "Please enter valid products",
                  //       icon: Icon(
                  //         Icons.error_outline_rounded,
                  //         size: 28.0,
                  //         color: Colors.red[300],
                  //       ),
                  //       duration: const Duration(milliseconds: 1500),
                  //       leftBarIndicatorColor: Colors.red[300],
                  //     ).show(context);
                  //     setState(() {
                  //       isFabEnabled = true;
                  //     });
                  //     return;
                  //   }
                  //   // if ((given > total) || (given < total / 2)) {
                  //   //   Flushbar(
                  //   //     margin: const EdgeInsets.all(7),
                  //   //     borderRadius: BorderRadius.circular(15),
                  //   //     flushbarStyle: FlushbarStyle.FLOATING,
                  //   //     flushbarPosition: FlushbarPosition.BOTTOM,
                  //   //     message: "Given amount Invalid",
                  //   //     icon: Icon(
                  //   //       Icons.error_outline_rounded,
                  //   //       size: 28.0,
                  //   //       color: Colors.red[300],
                  //   //     ),
                  //   //     duration: const Duration(milliseconds: 1500),
                  //   //     leftBarIndicatorColor: Colors.red[300],
                  //   //   ).show(context);
                  //   //   setState(() {
                  //   //     isFabEnabled = true;
                  //   //   });
                  //   //   return;
                  //   // }

                  //   Map<String, dynamic> products = {};
                  //   for (var i = 0; i < tempList.length; i++) {
                  //     if (int.tryParse(
                  //             productQuantityControllers[i].text.trim()) !=
                  //         null) {
                  //       products[productNameControllers[i].text.trim()] =
                  //           int.parse(
                  //               productQuantityControllers[i].text.trim());
                  //     } else {
                  //       showDialog(
                  //         context: context,
                  //         builder: (context) {
                  //           return AlertDialog(
                  //             title: const Text('Invalid quantity'),
                  //             content: const Text(
                  //                 'Please enter a valid quantity for all products'),
                  //             actions: [
                  //               TextButton(
                  //                 onPressed: () {
                  //                   Navigator.pop(context);
                  //                 },
                  //                 child: const Text('Ok'),
                  //               ),
                  //             ],
                  //           );
                  //         },
                  //       );
                  //       setState(() {
                  //         isFabEnabled = true;
                  //       });
                  //       return;
                  //     }
                  //   }
                  //   final timestamp = selectedDateTime.millisecondsSinceEpoch;
                  //   final newOrder = {
                  //     'date': timestamp,
                  //     'products': products,
                  //     'total': total,
                  //     // 'given': given,
                  //   };
                  //   String msg = "Order added successfully";
                  //   List newProductsHistory = [...widget.productsHistory];
                  //   if (widget.index == null) {
                  //     newProductsHistory.add(newOrder);
                  //   } else {
                  //     if (newOrder[products] == null && tempList.isEmpty) {
                  //       newProductsHistory.removeAt(widget.index!);
                  //       msg = "Order deleted successfully";
                  //     } else {
                  //       newProductsHistory[widget.index!] = newOrder;
                  //       msg = "Order updated successfully";
                  //     }
                  //   }

                  //   try {
                  //     await FirebaseDatabase.instance
                  //         .ref()
                  //         .child('Coaches')
                  //         .child(FirebaseAuth.instance.currentUser!.uid)
                  //         .child('users')
                  //         .child(widget.uid)
                  //         .update({
                  //       'productsHistory': newProductsHistory,
                  //     });

                  //     for (int i = 0; i < widget.popIndex; i++) {
                  //       Navigator.pop(context);
                  //     }

                  //     Flushbar(
                  //       margin: const EdgeInsets.all(7),
                  //       borderRadius: BorderRadius.circular(15),
                  //       flushbarStyle: FlushbarStyle.FLOATING,
                  //       flushbarPosition: FlushbarPosition.BOTTOM,
                  //       message: msg,
                  //       icon: Icon(
                  //         Icons.check_circle_outline_rounded,
                  //         size: 28.0,
                  //         color: Colors.green[300],
                  //       ),
                  //       duration: const Duration(milliseconds: 1500),
                  //       leftBarIndicatorColor: Colors.green[300],
                  //     ).show(context);
                  //   } catch (e) {
                  //     debugPrint(e.toString());
                  //     Flushbar(
                  //       margin: const EdgeInsets.all(7),
                  //       borderRadius: BorderRadius.circular(15),
                  //       flushbarStyle: FlushbarStyle.FLOATING,
                  //       flushbarPosition: FlushbarPosition.BOTTOM,
                  //       message: "Error updating user data",
                  //       icon: Icon(
                  //         Icons.error_outline_rounded,
                  //         size: 28.0,
                  //         color: Colors.red[300],
                  //       ),
                  //       duration: const Duration(milliseconds: 1500),
                  //       leftBarIndicatorColor: Colors.red[300],
                  //     ).show(context);
                  //   }
                  // } catch (e) {
                  //   debugPrint(e.toString());
                  //   Flushbar(
                  //     margin: const EdgeInsets.all(7),
                  //     borderRadius: BorderRadius.circular(15),
                  //     flushbarStyle: FlushbarStyle.FLOATING,
                  //     flushbarPosition: FlushbarPosition.BOTTOM,
                  //     message: "Error updating user data",
                  //     icon: Icon(
                  //       Icons.error_outline_rounded,
                  //       size: 28.0,
                  //       color: Colors.red[300],
                  //     ),
                  //     duration: const Duration(milliseconds: 1500),
                  //     leftBarIndicatorColor: Colors.red[300],
                  //   ).show(context);
                  // }

                  // setState(() {
                  //   isFabEnabled = true;
                  // });
                } else {
                  setState(() {
                    isFabEnabled = true;
                  });
                }
              },
              child: widget.index != null
                  ? const Icon(Icons.delete_rounded)
                  : const Icon(Icons.save_rounded),
            )
          : null,
    );
  }
}

enum DiscountModes { manual, auto, custom }

const Map<String, dynamic> allProducts = {
  '1247': {
    'id': 0,
    'name': 'F1-Vanilla',
    'sku': '1247',
    'price': 2378,
    '15%': 2015,
    '25%': 1857,
    '35%': 1649,
    '42%': 1503,
    '50%': 1337
  },
  '1248': {
    'id': 1,
    'name': 'F1-Chocolate',
    'sku': '1248',
    'price': 2378,
    '15%': 2015,
    '25%': 1857,
    '35%': 1649,
    '42%': 1503,
    '50%': 1337
  },
  '1249': {
    'id': 2,
    'name': 'F1-Mango',
    'sku': '1249',
    'price': 2378,
    '15%': 2015,
    '25%': 1857,
    '35%': 1649,
    '42%': 1503,
    '50%': 1337
  },
  '1269': {
    'id': 3,
    'name': 'F1-Orange',
    'sku': '1269',
    'price': 2378,
    '15%': 2015,
    '25%': 1857,
    '35%': 1649,
    '42%': 1503,
    '50%': 1337
  },
  '1239': {
    'id': 4,
    'name': 'F1-Strawberry',
    'sku': '1239',
    'price': 2378,
    '15%': 2015,
    '25%': 1857,
    '35%': 1649,
    '42%': 1503,
    '50%': 1337
  },
  '4114': {
    'id': 5,
    'name': 'F1-Kulfi',
    'sku': '4114',
    'price': 2378,
    '15%': 2015,
    '25%': 1857,
    '35%': 1649,
    '42%': 1503,
    '50%': 1337
  },
  '082K': {
    'id': 6,
    'name': 'F1-Banana',
    'sku': '082K',
    'price': 2378,
    '15%': 2015,
    '25%': 1857,
    '35%': 1649,
    '42%': 1503,
    '50%': 1337
  },
  '154K': {
    'id': 7,
    'name': 'F1-Rose',
    'sku': '154K',
    'price': 2378,
    '15%': 2015,
    '25%': 1857,
    '35%': 1649,
    '42%': 1503,
    '50%': 1337
  },
  '287K': {
    'id': 8,
    'name': 'F1-Paan',
    'sku': '287K',
    'price': 2378,
    '15%': 2015,
    '25%': 1857,
    '35%': 1649,
    '42%': 1503,
    '50%': 1337
  },
  '1233': {
    'id': 9,
    'name': 'PPP-200',
    'sku': '1233',
    'price': 1413,
    '15%': 1197,
    '25%': 1103,
    '35%': 980,
    '42%': 893,
    '50%': 794
  },
  '1569': {
    'id': 10,
    'name': 'PPP-400',
    'sku': '1569',
    'price': 2711,
    '15%': 2297,
    '25%': 2118,
    '35%': 1880,
    '42%': 1714,
    '50%': 1525
  },
  '183K': {
    'id': 11,
    'name': 'ShakeMate',
    'sku': '183K',
    'price': 712,
    '15%': 603,
    '25%': 624,
    '35%': 589,
    '42%': 564,
    '50%': 536
  },
  '175K': {
    'id': 12,
    'name': 'Male Factor',
    'sku': '175K',
    'price': 3720,
    '15%': 3152,
    '25%': 2906,
    '35%': 2580,
    '42%': 2352,
    '50%': 2092
  },
  '127K': {
    'id': 13,
    'name': "Woman's Choice",
    'sku': '127K',
    'price': 1357,
    '15%': 1150,
    '25%': 1060,
    '35%': 941,
    '42%': 858,
    '50%': 763
  },
  '109K': {
    'id': 14,
    'name': 'Brain Health',
    'sku': '109K',
    'price': 1597,
    '15%': 1353,
    '25%': 1247,
    '35%': 1108,
    '42%': 1010,
    '50%': 898
  },
  '115K': {
    'id': 15,
    'name': 'Immune Health',
    'sku': '115K',
    'price': 1668,
    '15%': 1413,
    '25%': 1302,
    '35%': 1156,
    '42%': 1054,
    '50%': 938
  },
  '1291': {
    'id': 16,
    'name': 'Afresh-Ginger',
    'sku': '1291',
    'price': 885,
    '15%': 750,
    '25%': 691,
    '35%': 614,
    '42%': 559,
    '50%': 497
  },
  '1294': {
    'id': 17,
    'name': 'Afresh-Elaichi',
    'sku': '1294',
    'price': 885,
    '15%': 750,
    '25%': 691,
    '35%': 614,
    '42%': 559,
    '50%': 497
  },
  '1295': {
    'id': 18,
    'name': 'Afresh-Lemon',
    'sku': '1295',
    'price': 885,
    '15%': 750,
    '25%': 691,
    '35%': 614,
    '42%': 559,
    '50%': 497
  },
  '1296': {
    'id': 19,
    'name': 'Afresh-Peach',
    'sku': '1296',
    'price': 885,
    '15%': 750,
    '25%': 691,
    '35%': 614,
    '42%': 559,
    '50%': 497
  },
  '1238': {
    'id': 20,
    'name': 'Afresh-Cinnamon',
    'sku': '1238',
    'price': 885,
    '15%': 750,
    '25%': 691,
    '35%': 614,
    '42%': 559,
    '50%': 497
  },
  '230K': {
    'id': 21,
    'name': 'Afresh-Kashmiri-Kahwa',
    'sku': '230K',
    'price': 885,
    '15%': 750,
    '25%': 691,
    '35%': 614,
    '42%': 559,
    '50%': 497
  },
  '080K': {
    'id': 22,
    'name': 'Afresh-Tulsi',
    'sku': '080K',
    'price': 885,
    '15%': 750,
    '25%': 704,
    '35%': 632,
    '42%': 582,
    '50%': 524
  },
  '1458': {
    'id': 23,
    'name': 'H24-Hydrate',
    'sku': '1458',
    'price': 1786,
    '15%': 1513,
    '25%': 1461,
    '35%': 1331,
    '42%': 1240,
    '50%': 1136
  },
  '031K': {
    'id': 24,
    'name': 'H24-Rebuild',
    'sku': '031K',
    'price': 2854,
    '15%': 2418,
    '25%': 2270,
    '35%': 2037,
    '42%': 1874,
    '50%': 1687
  },
  '046K': {
    'id': 25,
    'name': 'Skin Booster',
    'sku': '046K',
    'price': 4266,
    '15%': 3615,
    '25%': 3478,
    '35%': 3163,
    '42%': 2943,
    '50%': 2691
  },
  '1279': {
    'id': 26,
    'name': 'Dino-Choco',
    'sku': '1279',
    'price': 1216,
    '15%': 1030,
    '25%': 949,
    '35%': 843,
    '42%': 768,
    '50%': 683
  },
  '1236': {
    'id': 27,
    'name': 'Dino-Strawberry',
    'sku': '1236',
    'price': 1216,
    '15%': 1030,
    '25%': 949,
    '35%': 843,
    '42%': 768,
    '50%': 683
  },
  '1278': {
    'id': 28,
    'name': 'Active Fiber Tablets',
    'sku': '1278',
    'price': 1786,
    '15%': 1513,
    '25%': 1395,
    '35%': 1239,
    '42%': 1129,
    '50%': 1004
  },
  '2865': {
    'id': 29,
    'name': 'Active Fiber Complex',
    'sku': '2865',
    'price': 2792,
    '15%': 2366,
    '25%': 2181,
    '35%': 1937,
    '42%': 1765,
    '50%': 1570
  },
  '1293': {
    'id': 30,
    'name': 'Aloe Plus',
    'sku': '1293',
    'price': 1156,
    '15%': 979,
    '25%': 902,
    '35%': 801,
    '42%': 730,
    '50%': 650
  },
  '0006': {
    'id': 31,
    'name': 'Aloe Concentrate',
    'sku': '0006',
    'price': 2941,
    '15%': 2492,
    '25%': 2297,
    '35%': 2040,
    '42%': 1860,
    '50%': 1654
  },
  '025K': {
    'id': 32,
    'name': 'Probiotic',
    'sku': '025K',
    'price': 2410,
    '15%': 2042,
    '25%': 1882,
    '35%': 1672,
    '42%': 1524,
    '50%': 1355
  },
  '186K': {
    'id': 33,
    'name': 'Triphala',
    'sku': '186K',
    'price': 1189,
    '15%': 1007,
    '25%': 928,
    '35%': 824,
    '42%': 751,
    '50%': 668
  },
  '0020': {
    'id': 34,
    'name': 'Calcium',
    'sku': '0020',
    'price': 1313,
    '15%': 1112,
    '25%': 1025,
    '35%': 910,
    '42%': 830,
    '50%': 738
  },
  '0555': {
    'id': 35,
    'name': 'Joint Support',
    'sku': '0555',
    'price': 2679,
    '15%': 2270,
    '25%': 2092,
    '35%': 1858,
    '42%': 1694,
    '50%': 1506
  },
  '2637': {
    'id': 36,
    'name': 'Niteworks',
    'sku': '2637',
    'price': 7777,
    '15%': 6590,
    '25%': 6075,
    '35%': 5394,
    '42%': 4918,
    '50%': 4374
  },
  '0065': {
    'id': 37,
    'name': 'Herbalifeline',
    'sku': '0065',
    'price': 2910,
    '15%': 2466,
    '25%': 2273,
    '35%': 2019,
    '42%': 1840,
    '50%': 1637
  },
  '051K': {
    'id': 38,
    'name': 'Beta Heart',
    'sku': '051K',
    'price': 2447,
    '15%': 2073,
    '25%': 1995,
    '35%': 1814,
    '42%': 1688,
    '50%': 1543
  },
  '1232': {
    'id': 39,
    'name': 'Multivitamin',
    'sku': '1232',
    'price': 2186,
    '15%': 1852,
    '25%': 1707,
    '35%': 1516,
    '42%': 1382,
    '50%': 1229
  },
  '3123': {
    'id': 40,
    'name': 'Cell Activator',
    'sku': '3123',
    'price': 2417,
    '15%': 2048,
    '25%': 1888,
    '35%': 1677,
    '42%': 1529,
    '50%': 1359
  },
  '0111': {
    'id': 41,
    'name': 'Cell U Loss',
    'sku': '0111',
    'price': 1860,
    '15%': 1576,
    '25%': 1453,
    '35%': 1290,
    '42%': 1176,
    '50%': 1046
  },
  '0077': {
    'id': 42,
    'name': 'Herbal Control',
    'sku': '0077',
    'price': 3746,
    '15%': 3174,
    '25%': 2926,
    '35%': 2598,
    '42%': 2369,
    '50%': 2106
  },
  '0064': {
    'id': 43,
    'name': 'Ocular Defense',
    'sku': '0064',
    'price': 2103,
    '15%': 1782,
    '25%': 1643,
    '35%': 1458,
    '42%': 1330,
    '50%': 1182
  }
};
