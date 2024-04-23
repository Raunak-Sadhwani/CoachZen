import 'package:another_flushbar/flushbar.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../components/ui/appbar.dart';

class CustOrderCustForm extends StatefulWidget {
  final String name;
  final String uid;
  final int popIndex;
  const CustOrderCustForm(
      {super.key,
      required this.name,
      required this.uid,
      required this.popIndex});
  @override
  State<CustOrderCustForm> createState() => _CustOrderCustFormState();
}

class _CustOrderCustFormState extends State<CustOrderCustForm> {
  final String cid = FirebaseAuth.instance.currentUser!.uid;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ScrollController scrollController = ScrollController();
  Map<String, int> productMap = {};
  bool isFabEnabled = false;
  bool autoValidate = false;
  DateTime selectedDateTime = DateTime.now();
  TextEditingController productNameController = TextEditingController();
  TextEditingController productQuantityController = TextEditingController();

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  void addProduct() {
    setState(() {
      autoValidate = true;
    });
    if (_formKey.currentState!.validate()) {
      setState(() {
        productMap[productNameController.text.trim()] =
            int.parse(productQuantityController.text);
        isFabEnabled = true;
        autoValidate = false;
        scrollController.animateTo(
          0.0,
          curve: Curves.easeOut,
          duration: const Duration(milliseconds: 300),
        );
      });
      productNameController.clear();
      productQuantityController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
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
                        context: _scaffoldKey.currentContext!,
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
                    margin: EdgeInsets.only(
                        top: height * 0.01, bottom: height * 0.02),
                    child: Card(
                      elevation: 10,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: width * 0.02,
                              vertical: height * 0.02),
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
                                DateFormat('dd MMM yyyy - hh:mm a')
                                    .format(selectedDateTime),
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
                                    margin:
                                        EdgeInsets.only(bottom: height * 0.02),
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
                                                child: TextFormField(
                                                  controller:
                                                      productNameController,
                                                  decoration:
                                                      const InputDecoration(
                                                    labelText: 'Name',
                                                    hintText:
                                                        'Enter product name',
                                                  ),
                                                  validator: (value) {
                                                    if (value == null ||
                                                        value.isEmpty) {
                                                      return 'Please enter a name';
                                                    } else if (value.length <
                                                        3) {
                                                      return 'Please enter a valid name';
                                                    }
                                                    return null;
                                                  },
                                                )),
                                            SizedBox(width: width * 0.1),
                                            Expanded(
                                              child: TextFormField(
                                                controller:
                                                    productQuantityController,
                                                decoration:
                                                    const InputDecoration(
                                                  labelText: 'Price (₹)',
                                                  hintText: 'Enter price',
                                                  counterText: '',
                                                ),
                                                keyboardType:
                                                    TextInputType.number,
                                                maxLength: 5,
                                                validator: (value) {
                                                  if (value == null ||
                                                      value.isEmpty) {
                                                    return 'Please enter a price';
                                                  } else if (int.tryParse(
                                                          value) ==
                                                      null) {
                                                    return 'Please enter a valid number';
                                                  } else if (int.parse(value) <=
                                                      0) {
                                                    return 'Please enter a valid number';
                                                  } else if (int.parse(value) >
                                                      20000) {
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
                                    margin:
                                        EdgeInsets.only(bottom: height * 0.02),
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
                                  padding: EdgeInsets.symmetric(
                                      vertical: height * 0.03),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      
                                      Container(
                                        padding:
                                            EdgeInsets.only(top: height * 0.01),
                                        child: IconButton(
                                          icon: const Icon(Icons.close,
                                              color: Colors.red, size: 20),
                                          onPressed: () {
                                            
                                            final String prodName = productMap
                                                .keys
                                                .elementAt(index - 1);
                                            showDialog(
                                              context: context,
                                              builder: (context) {
                                                return AlertDialog(
                                                  title: const Text(
                                                      'Delete product?'),
                                                  content: Text(
                                                      'Are you sure you want to delete $prodName ?'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                      },
                                                      child:
                                                          const Text('Cancel'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () {
                                                        setState(() {
                                                          productMap
                                                              .remove(prodName);
                                                          if (productMap
                                                              .isEmpty) {
                                                            isFabEnabled =
                                                                false;
                                                          }
                                                        });
                                                        Navigator.pop(context);
                                                      },
                                                      child:
                                                          const Text('Delete'),
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
                                            ..text = productMap.keys
                                                .elementAt(index - 1),
                                          readOnly: true,
                                        ),
                                      ),
                                      SizedBox(width: width * 0.1),
                                      Expanded(
                                        child: TextField(
                                          readOnly: true,
                                          decoration: const InputDecoration(
                                            labelText: 'Price (₹)',
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
            )),
        floatingActionButton: isFabEnabled
            ? FloatingActionButton(
                onPressed: () async {
                  addProduct();
                  
                  if (!isFabEnabled) {
                    return;
                  }

                  if (!await Method.checkInternetConnection(context)) {
                    return setState(() {
                      isFabEnabled = true;
                    });
                  }
                  final int tCost = productMap.values
                      .toList()
                      .reduce((value, element) => value + element);
                  TextEditingController paidController =
                      TextEditingController(text: tCost.toString());
                  String initalMode = 'Cash';
                  final GlobalKey<FormState> formkeydiscount =
                      GlobalKey<FormState>();
                  int balance = 0;
                  int paid = tCost;

                  return showDialog(
                      context: _scaffoldKey.currentContext!,
                      builder: (context) => StatefulBuilder(
                              builder: (contextx, StateSetter setState) {
                            final dialogWidth = width * 0.9;
                            void setBalance(val) {
                              int paidx = int.tryParse(val) ?? 0;
                              setState(() {
                                balance = tCost - paidx;
                                paid = paidx;
                              });
                            }

                            return AlertDialog(
                                
                                contentPadding: EdgeInsets.zero,
                                
                                insetPadding: EdgeInsets.zero,
                                actionsPadding: EdgeInsets.symmetric(
                                    vertical: dialogWidth * .02),
                                title: Text(
                                  'Confirmation',
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
                                                        width: dialogWidth * .7,
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
                                                        width: dialogWidth * .2,
                                                        child: Text(
                                                          'Price (₹)',
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
                                                            key,
                                                            style: GoogleFonts
                                                                .montserrat(),
                                                          ),
                                                        ),
                                                        DataCell(
                                                          Text(
                                                            '₹${productMap[key].toString()}',
                                                            style: GoogleFonts
                                                                .montserrat(),
                                                          ),
                                                        ),
                                                      ],
                                                    );
                                                  }),
                                                ),
                                              ),
                                              Padding(
                                                padding: EdgeInsets.symmetric(
                                                    vertical:
                                                        screenHeight * .0075,
                                                    horizontal:
                                                        dialogWidth * .085),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: TextFormField(
                                                        controller:
                                                            paidController,
                                                        maxLength: tCost
                                                            .toString()
                                                            .length,
                                                        decoration:
                                                            const InputDecoration(
                                                          counterText: '',
                                                          labelText:
                                                              'Total Paid (₹)',
                                                        ),
                                                        onChanged: setBalance,
                                                        keyboardType:
                                                            TextInputType
                                                                .number,
                                                        validator: (value) {
                                                          if (value == null ||
                                                              value.isEmpty) {
                                                            return 'Please enter a given amount';
                                                          } else if (int
                                                                  .tryParse(
                                                                      value) ==
                                                              null) {
                                                            return 'Please enter a valid number';
                                                          }
                                                          
                                                          else if (int.parse(
                                                                  value) >
                                                              tCost) {
                                                            return 'Please enter a valid number';
                                                          } else if (int.parse(
                                                                  value) <
                                                              0) {
                                                            return 'Please enter a valid number';
                                                          }
                                                          return null;
                                                        },
                                                      ),
                                                    ),
                                                    SizedBox(
                                                        width:
                                                            dialogWidth * .05),
                                                    Expanded(
                                                        child:
                                                            DropdownButtonFormField<
                                                                String>(
                                                      decoration:
                                                          const InputDecoration(
                                                        labelText: 'Mode',
                                                      ),
                                                      value: initalMode,
                                                      items: [
                                                        'Cash',
                                                        'Online',
                                                        'Cheque',
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
                                                          initalMode =
                                                              newValue ?? '';
                                                        });
                                                      },
                                                    ))
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
                                                    height: height * 0.175,
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
                                                            'Total:  ₹$tCost',
                                                            style: GoogleFonts
                                                                .montserrat(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600),
                                                          ),
                                                          Text(
                                                            'Total Paid:  ₹$paid',
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
                                                                        .black, 
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
                                                                        .red, 
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
                                      ),
                                    )),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Back'),
                                  ),
                                  TextButton(
                                      onPressed: () async {
                                        if (!isFabEnabled ||
                                            !formkeydiscount.currentState!
                                                .validate()) {
                                          return;
                                        }
                                        if (!await Method
                                            .checkInternetConnection(context)) {
                                          return setState(() {
                                            isFabEnabled = true;
                                          });
                                        }
                                        setState(() {
                                          isFabEnabled = false;
                                        });
                                        final int timestamp = selectedDateTime
                                            .millisecondsSinceEpoch;
                                        final String formattedDate =
                                            DateFormat('yyyy-MM-dd')
                                                .format(selectedDateTime);
                                        Map<String, dynamic> newOrder = {
                                          'date': formattedDate,
                                          'chosenDate': timestamp,
                                          'timestamp': ServerValue.timestamp,
                                          'products': productMap,
                                          'total': tCost,
                                          'custom': true,
                                          'paid': paid,
                                          'balance': balance,
                                          'mode': initalMode,
                                        };
                                        try {
                                          const String msg =
                                              'Order added successfully';
                                          String newKey = FirebaseDatabase
                                              .instance
                                              .ref()
                                              .push()
                                              .key!;

                                          Map<String, dynamic> updates = {
                                            'users/${widget.uid}/productsHistory/$newKey':
                                                newOrder,
                                            'attendance/$formattedDate/productsHistory/$newKey':
                                                widget.uid
                                          };
                                          await FirebaseDatabase.instance
                                              .ref()
                                              .child('Coaches')
                                              .child(FirebaseAuth
                                                  .instance.currentUser!.uid)
                                              .update(updates);

                                          for (int i = 0;
                                              i < (widget.popIndex + 1);
                                              i++) {
                                            Navigator.pop(
                                                _scaffoldKey.currentContext!);
                                          }
                                          Flushbar(
                                            margin: const EdgeInsets.all(7),
                                            borderRadius:
                                                BorderRadius.circular(15),
                                            flushbarStyle:
                                                FlushbarStyle.FLOATING,
                                            flushbarPosition:
                                                FlushbarPosition.BOTTOM,
                                            message: msg,
                                            icon: Icon(
                                              Icons
                                                  .check_circle_outline_rounded,
                                              size: 28.0,
                                              color: Colors.green[300],
                                            ),
                                            duration: const Duration(
                                                milliseconds: 1500),
                                            leftBarIndicatorColor:
                                                Colors.green[300],
                                          ).show(_scaffoldKey.currentContext!);
                                        } catch (e) {
                                          await Flushbar(
                                            margin: const EdgeInsets.all(7),
                                            borderRadius:
                                                BorderRadius.circular(15),
                                            flushbarStyle:
                                                FlushbarStyle.FLOATING,
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
                                          ).show(_scaffoldKey.currentContext!);
                                          setState(() {
                                            isFabEnabled = true;
                                          });
                                        }
                                      },
                                      child: const Text('Done')),
                                ]);
                          })

                      
                      
                      
                      
                      
                      
                      
                      
                      
                      
                      
                      
                      
                      
                      
                      
                      
                      
                      
                      
                      );
                },
                child: const Icon(Icons.save),
              )
            : null);
  }
}
