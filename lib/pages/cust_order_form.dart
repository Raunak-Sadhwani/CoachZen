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
import '../components/products.dart';
import 'cust_order_cust_form.dart';

class CustOrderForm extends StatefulWidget {
  final String name;
  final String uid;
  final Map<String, int>? productMap;
  final int popIndex;
  final String? index;
  final bool? attendance;
  final String? attendanceDate;
  final String? formattedDate;
  final Map<String, dynamic>? existingData;
  const CustOrderForm({
    Key? key,
    required this.name,
    required this.uid,
    this.productMap,
    required this.popIndex,
    this.index,
    this.attendance,
    this.attendanceDate,
    this.formattedDate,
    this.existingData,
  }) : super(key: key);

  @override
  State<CustOrderForm> createState() => _CustOrderFormState();
}

class _CustOrderFormState extends State<CustOrderForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  DateTime selectedDateTime = DateTime.now();
  String productSku = '';
  final productNameController = TextEditingController();
  final productQuantityController = TextEditingController();
  Map<String, int> productMap = {};

  @override
  void initState() {
    super.initState();
    if (widget.attendance != null) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
    if (widget.index != null && widget.productMap != null) {
      productMap = widget.productMap!;
    }
    if (widget.attendanceDate != null) {
      final DateTime newDate = DateTime.parse(widget.attendanceDate!);
      // set current time to the new date
      setState(() {
        selectedDateTime = DateTime(
          newDate.year,
          newDate.month,
          newDate.day,
          DateTime.now().hour,
          DateTime.now().minute,
          DateTime.now().second,
        );
      });
    }
    if (widget.existingData != null && widget.existingData!.isNotEmpty) {
      setState(() {
        selectedDateTime = DateTime.fromMillisecondsSinceEpoch(
            widget.existingData!['chosenDate']);
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

  void addProduct() {
    setState(() {
      autoValidate = true;
    });
    if (_formKey.currentState!.validate()) {
      if (allProducts[productSku]['name'].toLowerCase() ==
          productNameController.text.trim().toLowerCase()) {
        setState(() {
          productMap[productSku] = int.parse(productQuantityController.text);
          isFabEnabled = true;
          autoValidate = false;
          scrollController.animateTo(
            0.0,
            curve: Curves.easeOut,
            duration: const Duration(milliseconds: 300),
          );
        });
      }
      setState(() {
        productSku = '';
      });
      productNameController.clear();
      productQuantityController.clear();
    }
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
        rightIcons: [
          if (widget.index != null)
            IconButton(
              icon: const Icon(Icons.delete_forever_rounded),
              color: Colors.black26,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Delete order?'),
                      content: const Text(
                          'Are you sure you want to delete this order?'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () async {
                            if (isFabEnabled) {
                              return;
                            }
                            if (!await Method.checkInternetConnection(
                                context)) {
                              return setState(() {
                                isFabEnabled = false;
                              });
                            }
                            setState(() {
                              isFabEnabled = true;
                            });
                            try {
                              final Map<String, dynamic> updates = {
                                'users/${widget.uid}/productsHistory/${widget.index}':
                                    null,
                                'attendance/${widget.formattedDate}/productsHistory/${widget.index}':
                                    null,
                              };
                              await FirebaseDatabase.instance
                                  .ref()
                                  .child('Coaches')
                                  .child(FirebaseAuth.instance.currentUser!.uid)
                                  .update(updates);
                              for (int i = 0; i < widget.popIndex; i++) {
                                Navigator.pop(context);
                              }
                              Flushbar(
                                margin: const EdgeInsets.all(7),
                                borderRadius: BorderRadius.circular(15),
                                flushbarStyle: FlushbarStyle.FLOATING,
                                flushbarPosition: FlushbarPosition.BOTTOM,
                                message: 'Order deleted successfully',
                                icon: Icon(
                                  Icons.check_circle_outline_rounded,
                                  size: 28.0,
                                  color: Colors.green[300],
                                ),
                                duration: const Duration(milliseconds: 1500),
                                leftBarIndicatorColor: Colors.green[300],
                              ).show(context);
                            } catch (e) {
                              await Flushbar(
                                margin: const EdgeInsets.all(7),
                                borderRadius: BorderRadius.circular(15),
                                flushbarStyle: FlushbarStyle.FLOATING,
                                flushbarPosition: FlushbarPosition.BOTTOM,
                                message: "Error deleting order",
                                icon: Icon(
                                  Icons.error_outline_rounded,
                                  size: 28.0,
                                  color: Colors.red[300],
                                ),
                                duration: const Duration(milliseconds: 1500),
                                leftBarIndicatorColor: Colors.red[300],
                              ).show(context);
                              setState(() {
                                isFabEnabled = false;
                              });
                            }
                          },
                          child: const Text('Delete'),
                        ),
                      ],
                    );
                  },
                );
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.dashboard_customize_outlined),
              color: Colors.black26,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CustOrderCustForm(
                      name: widget.name,
                      uid: widget.uid,
                      popIndex: widget.popIndex,
                      selectedDateTime: selectedDateTime,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: width * 0.035),
        child: Column(
          children: [
            GestureDetector(
              onTap: () async {
                final selected = await showDatePicker(
                  context: context,
                  initialDate: selectedDateTime,
                  firstDate:
                      selectedDateTime.subtract(const Duration(days: 100)),
                  lastDate: selectedDateTime.millisecondsSinceEpoch >
                          DateTime.now().millisecondsSinceEpoch
                      ? selectedDateTime
                      : DateTime.now(),
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
                margin:
                    EdgeInsets.only(top: height * 0.01, bottom: height * 0.02),
                child: Card(
                  elevation: 10,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
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
                                  onPressed: addProduct,
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
                                        final String prodKey = productMap.keys
                                            .elementAt(index - 1);
                                        final String prodName =
                                            allProducts[prodKey]['name'];
                                        showDialog(
                                          context: context,
                                          builder: (context) {
                                            return AlertDialog(
                                              title:
                                                  const Text('Delete product?'),
                                              content: Text(
                                                  'Are you sure you want to delete $prodName ?'),
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
                                                      productMap
                                                          .remove(prodKey);
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
                                    child: TextField(
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
                                      controller: TextEditingController()
                                        ..text = allProducts[productMap.keys
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
      floatingActionButton: isFabEnabled || widget.index != null
          ? FloatingActionButton(
              onPressed: () async {
                addProduct();

                if (productMap.isNotEmpty) {
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
                  final int tCost = productMap.keys
                      .map((e) => allProducts[e]['price'] * productMap[e])
                      .reduce((a, b) => a + b);
                  final bool isShakeMate = productMap.containsKey('183K');
                  int shakemateDiscount = 0;
                  int discount = 0;
                  String initalAutoMode = '15%';
                  String initalMode = 'Cash';
                  TextEditingController customPriceController =
                      TextEditingController(text: tCost.toString());
                  TextEditingController paidController =
                      TextEditingController(text: tCost.toString());
                  void calcAutoPrice() {
                    final int discountedPrice = productMap.keys
                        .map((e) =>
                            allProducts[e][initalAutoMode] * productMap[e])
                        .reduce((a, b) => a + b);

                    setState(() {
                      discount = tCost - discountedPrice;
                      paidController.text =
                          (tCost - (discount + shakemateDiscount)).toString();
                    });
                  }

                  Map<String, dynamic> data = {};
                  if (widget.existingData != null &&
                      widget.existingData!.isNotEmpty) {
                    data = widget.existingData!;
                    mode = data['discountMode'] == 'DiscountModes.manual'
                        ? DiscountModes.manual
                        : data['discountMode'] == 'DiscountModes.auto'
                            ? DiscountModes.auto
                            : DiscountModes.custom;
                    discount = data['discount'];
                    if (mode == DiscountModes.manual) {
                      discountController.text =
                          data['discountManual'].toString();
                      final shakemateDiscountx = data['shakemateDiscount'];
                      if (productMap.containsKey('183K') &&
                          shakemateDiscountx != null) {
                        final int smprice = shakeMate['price'];
                        final int smqty = productMap['183K']!;
                        final int actShakeMateCost =
                            (smprice - (shakemateDiscountx / smqty)).toInt();
                        shakeMateController.text = actShakeMateCost.toString();
                        shakemateDiscount = data['shakemateDiscount'];
                      }
                    } else if (mode == DiscountModes.auto) {
                      initalAutoMode = data['initalAutoMode'];
                      calcAutoPrice();
                    } else if (mode == DiscountModes.custom) {
                      customPriceController.text =
                          data['customPrice'].toString();
                    }
                    paidController.text = data['paid'].toString();
                    initalMode = data['mode'];
                  }
                  bool handleEdit = false;

                  return showDialog(
                      context: _scaffoldKey.currentContext!,
                      builder: (context) => StatefulBuilder(
                              builder: (contextx, StateSetter setState) {
                            int subTotal =
                                (tCost - (discount + shakemateDiscount));
                            int paid = int.tryParse(paidController.text) ?? 0;
                            int discManual =
                                int.tryParse(discountController.text) ?? 0;
                            int balance = subTotal - paid;
                            int tDiscount = discount + shakemateDiscount;
                            Widget paidWidget() {
                              return Expanded(
                                child: TextFormField(
                                  controller: paidController,
                                  maxLength: tCost.toString().length,
                                  decoration: const InputDecoration(
                                    counterText: '',
                                    labelText: 'Total Paid (₹)',
                                  ),
                                  onChanged: (value) {
                                    if (value.isEmpty ||
                                        int.tryParse(value) == null) {
                                      setState(() {
                                        balance = 0;
                                      });
                                      return;
                                    }
                                    setState(() {
                                      balance = (tCost -
                                              (discount + shakemateDiscount)) -
                                          int.parse(value);
                                    });
                                  },
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    final int tempTotal =
                                        tCost - (discount + shakemateDiscount);

                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a given amount';
                                    } else if (int.tryParse(value) == null) {
                                      return 'Please enter a valid number';
                                    }
                                    // no more than 50% discount
                                    else if (int.parse(value) > tempTotal) {
                                      return 'Please enter a valid number';
                                    } else if (int.parse(value) != 0 &&
                                        int.parse(value) < 100) {
                                      return 'Please enter a valid number';
                                    }
                                    return null;
                                  },
                                ),
                              );
                            }

                            Widget getMode() {
                              return DropdownButtonFormField<String>(
                                decoration: const InputDecoration(
                                  labelText: 'Mode',
                                ),
                                value: initalMode,
                                items: [
                                  'Cash',
                                  'Online',
                                  'Cheque',
                                ].map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    initalMode = newValue ?? '';
                                  });
                                },
                              );
                            }

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
                                                              paidController
                                                                      .text =
                                                                  tCost
                                                                      .toString();
                                                              balance = 0;
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
                                                              paidController
                                                                      .text =
                                                                  tCost
                                                                      .toString();
                                                              balance = 0;
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
                                                  child: Column(
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child:
                                                                TextFormField(
                                                              controller:
                                                                  discountController,
                                                              maxLength: 2,
                                                              onChanged:
                                                                  (value) {
                                                                if (value
                                                                        .isEmpty ||
                                                                    value ==
                                                                        '0' ||
                                                                    int.tryParse(
                                                                            value) ==
                                                                        null) {
                                                                  setState(() {
                                                                    discount =
                                                                        0;
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
                                                                              shakeMateController.text) ??
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
                                                                  paidController
                                                                      .text = (tCost -
                                                                          (discount +
                                                                              shakemateDiscount))
                                                                      .toString();
                                                                  balance = 0;
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
                                                              validator:
                                                                  (value) {
                                                                if (value ==
                                                                    null) {
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
                                                          Expanded(
                                                            child: Row(
                                                              children: [
                                                                SizedBox(
                                                                  width:
                                                                      dialogWidth *
                                                                          .05,
                                                                ),
                                                                if (isShakeMate)
                                                                  Expanded(
                                                                    child:
                                                                        TextFormField(
                                                                      controller:
                                                                          shakeMateController,
                                                                      maxLength:
                                                                          3,
                                                                      onChanged:
                                                                          (value) {
                                                                        if (value.isNotEmpty &&
                                                                            int.tryParse(value) !=
                                                                                null) {
                                                                          setState(
                                                                              () {
                                                                            shakemateDiscount =
                                                                                (shakeMate['price'] - int.parse(value)) * productMap['183K']!;
                                                                            paidController.text =
                                                                                (tCost - (discount + shakemateDiscount)).toString();
                                                                          });
                                                                        } else {
                                                                          setState(
                                                                              () {
                                                                            shakemateDiscount =
                                                                                shakeMate['price'] * productMap['183K']!;
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
                                                                        } else if (int.tryParse(value) ==
                                                                            null) {
                                                                          return 'Please enter a valid number';
                                                                        }
                                                                        // no more than 50% discount
                                                                        else if (shakeMate['50%'] >
                                                                            int.parse(
                                                                                value)) {
                                                                          return 'Please enter a valid number';
                                                                        } else if (int.parse(value) >
                                                                            shakeMate['price']) {
                                                                          return 'Please enter a valid number';
                                                                        }
                                                                        return null;
                                                                      },
                                                                    ),
                                                                  )
                                                                else
                                                                  paidWidget(),
                                                              ],
                                                            ),
                                                          )
                                                        ],
                                                      ),
                                                      if (isShakeMate)
                                                        Row(
                                                          children: [
                                                            paidWidget(),
                                                            SizedBox(
                                                              width:
                                                                  dialogWidth *
                                                                      .05,
                                                            ),
                                                            Expanded(
                                                                child:
                                                                    getMode())
                                                          ],
                                                        )
                                                      else
                                                        getMode()
                                                    ],
                                                  ),
                                                ),
                                              if (mode == DiscountModes.auto)
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal:
                                                          dialogWidth * .05),
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        child:
                                                            DropdownButtonFormField<
                                                                String>(
                                                          decoration:
                                                              const InputDecoration(
                                                            labelText: 'Level',
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
                                                              child:
                                                                  Text(value),
                                                            );
                                                          }).toList(),
                                                          onChanged: (String?
                                                              newValue) {
                                                            setState(() {
                                                              initalAutoMode =
                                                                  newValue!;
                                                            });
                                                            // calculate discount
                                                            calcAutoPrice();
                                                          },
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        width:
                                                            dialogWidth * .05,
                                                      ),
                                                      paidWidget()
                                                    ],
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
                                                              paidController
                                                                  .text = (tCost -
                                                                      discount)
                                                                  .toString();
                                                              balance = int.parse(
                                                                      value) -
                                                                  (tCost -
                                                                      discount);
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
                                                      ),
                                                      SizedBox(
                                                        width:
                                                            dialogWidth * .05,
                                                      ),
                                                      paidWidget()
                                                    ],
                                                  ),
                                                ),
                                              if (mode != DiscountModes.manual)
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal:
                                                          dialogWidth * .05),
                                                  child: getMode(),
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
                                                                      '-₹$tDiscount',
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
                                                            'Total:  ₹$subTotal',
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
                                                                      'Balance: ',
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
                                                                      '₹$balance',
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
                                  child: const Text('Back'),
                                ),
                                TextButton(
                                    onPressed: () async {
                                      if (widget.index != null) {
                                        setState(() {
                                          isFabEnabled = true;
                                        });
                                      }
                                      if (handleEdit ||
                                          !isFabEnabled ||
                                          !formkeydiscount.currentState!
                                              .validate()) {
                                        return;
                                      }
                                      if (!await Method.checkInternetConnection(
                                          context)) {
                                        return setState(() {
                                          isFabEnabled = true;
                                          handleEdit = false;
                                        });
                                      }
                                      setState(() {
                                        isFabEnabled = false;
                                        handleEdit = true;
                                      });
                                      final int timestamp = selectedDateTime
                                          .millisecondsSinceEpoch;
                                      final String formattedDate =
                                          DateFormat('yyyy-MM-dd')
                                              .format(selectedDateTime);
                                      Map<String, dynamic> newOrder = {
                                        'date': formattedDate,
                                        'chosenDate': timestamp,
                                        'products': productMap,
                                        'total': tCost,
                                        'discountMode': mode.toString(),
                                        'discountManual':
                                            mode == DiscountModes.manual
                                                ? discManual
                                                : null,
                                        'initalAutoMode':
                                            mode == DiscountModes.auto
                                                ? initalAutoMode
                                                : null,
                                        'customPrice':
                                            mode == DiscountModes.custom
                                                ? int.parse(
                                                    customPriceController.text)
                                                : null,
                                        'discount': discount,
                                        'shakemateDiscount':
                                            mode == DiscountModes.manual
                                                ? shakemateDiscount
                                                : null,
                                        'paid': paid,
                                        'balance': balance,
                                        'mode': initalMode,
                                      };
                                      try {
                                        final String msg = widget.index != null
                                            ? 'Order updated successfully'
                                            : 'Order added successfully';
                                        String newKey = '';

                                        if (widget.index != null) {
                                          if (data['payments'].isNotEmpty) {
                                            // show dialog
                                            bool? delPayments =
                                                await showDialog(
                                              context: context,
                                              builder: (context) {
                                                return AlertDialog(
                                                    title: const Text(
                                                        'Delete payments?'),
                                                    content: const Text(
                                                        'Updating this order will also delete all extra payments associated with it. Are you sure you want to proceed?'),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () {
                                                          Navigator.pop(
                                                              context, false);
                                                          Navigator.pop(
                                                              context);
                                                        },
                                                        child: const Text('No'),
                                                      ),
                                                      TextButton(
                                                        onPressed: () {
                                                          Navigator.pop(
                                                              context, true);
                                                        },
                                                        child:
                                                            const Text('Yes'),
                                                      ),
                                                    ]);
                                              },
                                            );
                                            if (delPayments == null ||
                                                !delPayments) {
                                              setState(() {
                                                isFabEnabled = true;
                                                handleEdit = false;
                                              });
                                              return Navigator.pop(context);
                                            }
                                          }
                                          newKey = widget.index!;
                                          newOrder['timestamp'] =
                                              data['timestamp'];
                                          newOrder['updated'] =
                                              ServerValue.timestamp;
                                        } else {
                                          newKey = FirebaseDatabase.instance
                                              .ref()
                                              .push()
                                              .key!;
                                          newOrder['timestamp'] =
                                              ServerValue.timestamp;
                                        }

                                        Map<String, dynamic> updates = {
                                          'users/${widget.uid}/productsHistory/$newKey':
                                              newOrder,
                                          'attendance/$formattedDate/productsHistory/$newKey':
                                              widget.uid
                                        };
                                        if (widget.formattedDate != null &&
                                            formattedDate !=
                                                widget.formattedDate) {
                                          updates['attendance/${widget.formattedDate}/productsHistory/${widget.index}'] =
                                              null;
                                        }

                                        await FirebaseDatabase.instance
                                            .ref()
                                            .child('Coaches')
                                            .child(FirebaseAuth
                                                .instance.currentUser!.uid)
                                            .update(updates);

                                        for (int i = 0;
                                            i < widget.popIndex;
                                            i++) {
                                          Navigator.pop(context);
                                        }
                                        Flushbar(
                                          margin: const EdgeInsets.all(7),
                                          borderRadius:
                                              BorderRadius.circular(15),
                                          flushbarStyle: FlushbarStyle.FLOATING,
                                          flushbarPosition:
                                              FlushbarPosition.BOTTOM,
                                          message: msg,
                                          icon: Icon(
                                            Icons.check_circle_outline_rounded,
                                            size: 28.0,
                                            color: Colors.green[300],
                                          ),
                                          duration: const Duration(
                                              milliseconds: 1500),
                                          leftBarIndicatorColor:
                                              Colors.green[300],
                                        ).show(context);
                                      } catch (e) {
                                        await Flushbar(
                                          margin: const EdgeInsets.all(7),
                                          borderRadius:
                                              BorderRadius.circular(15),
                                          flushbarStyle: FlushbarStyle.FLOATING,
                                          flushbarPosition:
                                              FlushbarPosition.BOTTOM,
                                          message: "Error updating user data",
                                          icon: Icon(
                                            Icons.error_outline_rounded,
                                            size: 28.0,
                                            color: Colors.red[300],
                                          ),
                                          duration: const Duration(
                                              milliseconds: 1500),
                                          leftBarIndicatorColor:
                                              Colors.red[300],
                                        ).show(context);
                                        setState(() {
                                          isFabEnabled = true;
                                          handleEdit = false;
                                        });
                                      }
                                    },
                                    child: Text(widget.index != null
                                        ? 'Update'
                                        : 'Done')),
                              ],
                            );
                          }));
                } else {
                  setState(() {
                    isFabEnabled = true;
                  });
                }
              },
              child: widget.index != null
                  ? const Icon(Icons.save_as_rounded)
                  : const Icon(Icons.save_rounded),
            )
          : null,
    );
  }
}
