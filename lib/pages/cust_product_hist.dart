// import 'package:cloud_firestore/cloud_firestore.dart';
// ignore_for_file: use_build_context_synchronously

import 'package:another_flushbar/flushbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../components/products.dart';
import '../components/ui/appbar.dart';
import '../components/ui/passwordcheck.dart';
import 'cust_order_form.dart';

String formatDate(DateTime timestamp) {
  String formattedDate = DateFormat('dd MMM yyyy').format(timestamp);
  return formattedDate;
}

final String cid = FirebaseAuth.instance.currentUser!.uid;

class ProductsHistory extends StatelessWidget {
  final Map<dynamic, dynamic> products;
  final String name;
  final String uid;

  const ProductsHistory(
      {Key? key, required this.products, required this.name, required this.uid})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Color> gradientColors = [
      const Color(0xff7248fe).withOpacity(0.8),
      const Color(0xff4390fe).withOpacity(0.8)
    ];
    Color bg = Colors.white;
    double width = MediaQuery.of(context).size.width;
    List<MapEntry<dynamic, dynamic>> sortedEntries = products.entries.toList();

    // Sort the list of entries based on chosenDate
    sortedEntries.sort((a, b) {
      DateTime dateA =
          DateTime.fromMillisecondsSinceEpoch(a.value['chosenDate']);
      DateTime dateB =
          DateTime.fromMillisecondsSinceEpoch(b.value['chosenDate']);
      return dateB.compareTo(dateA); // Sort in descending order (latest first)
    });
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
    bool isSubmited = false;
    return Scaffold(
      backgroundColor: bg,
      key: scaffoldKey,
      appBar: MyAppBar(
        title: 'Order History of $name',
        leftIcon: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: Colors.black26,
          onPressed: () => Navigator.pop(context),
        ),
        rightIcons: [
          IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CustOrderForm(
                      uid: uid,
                      name: name,
                      popIndex: 4,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add, color: Colors.black26)),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.all(width * 0.05),
            child: sortedEntries.isNotEmpty
                ? Column(
                    children: sortedEntries.map((entry) {
                      final isCustom = entry.value['custom'] ?? false;
                      return ProductExpansionTile(
                        uid: uid,
                        index: entry.key,
                        custom: isCustom,
                        products: entry.value['products'],
                        gradientColors: gradientColors,
                        total: entry.value['total'],
                        discount: entry.value['discount'] ?? 0,
                        discountMode: entry.value['discountMode'] ?? '',
                        discountManual: entry.value['discountManual'],
                        shakemateDiscount:
                            entry.value['shakemateDiscount'] ?? 0,
                        initalAutoMode: entry.value['initalAutoMode'],
                        customPrice: entry.value['customPrice'],
                        paid: entry.value['paid'],
                        balance: entry.value['balance'],
                        formattedDate: entry.value['date'],
                        chosenDate: DateTime.fromMillisecondsSinceEpoch(
                            entry.value['chosenDate']),
                        timestamp: DateTime.fromMillisecondsSinceEpoch(
                            entry.value['timestamp']),
                        mode: entry.value['mode'],
                        payments: Map<String, dynamic>.from(
                            entry.value['payments'] ?? {}),
                        updatedTimestamp: entry.value['updated'],
                        onLongPress: (index) async {
                          if (entry.value['balance'] > 0) {
                            bool? selected = await showDialog(
                              context: scaffoldKey.currentContext!,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text('Select an option'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ListTile(
                                        title: const Text('Add Payment'),
                                        onTap: () {
                                          TextEditingController
                                              amountController =
                                              TextEditingController();
                                          final GlobalKey<FormState> formKey =
                                              GlobalKey<FormState>();
                                          String initalMode = 'Cash';
                                          showDialog(
                                              context:
                                                  scaffoldKey.currentContext!,
                                              builder:
                                                  (context) => StatefulBuilder(
                                                          builder: (contextx,
                                                              StateSetter
                                                                  setState) {
                                                        return AlertDialog(
                                                          title: const Text(
                                                              'Add Payment'),
                                                          content: Form(
                                                            key: formKey,
                                                            autovalidateMode:
                                                                AutovalidateMode
                                                                    .onUserInteraction,
                                                            child: Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                TextFormField(
                                                                  decoration:
                                                                      InputDecoration(
                                                                    labelText:
                                                                        'Amount',
                                                                    hintText:
                                                                        "Remaining - ${entry.value['balance']}",
                                                                  ),
                                                                  keyboardType:
                                                                      TextInputType
                                                                          .number,
                                                                  controller:
                                                                      amountController,
                                                                  validator:
                                                                      (value) {
                                                                    if (value ==
                                                                            null ||
                                                                        int.tryParse(value) ==
                                                                            null) {
                                                                      return 'Enter a valid amount';
                                                                    } else if (int.parse(
                                                                            value) <=
                                                                        0) {
                                                                      return 'Amount should be greater than 0';
                                                                    } else if (int.parse(
                                                                            value) >
                                                                        entry.value[
                                                                            'balance']) {
                                                                      return 'Amount should be less than balance';
                                                                    }
                                                                    return null;
                                                                  },
                                                                ),
                                                                SizedBox(
                                                                    height:
                                                                        width *
                                                                            0.02),
                                                                DropdownButtonFormField<
                                                                    String>(
                                                                  decoration:
                                                                      const InputDecoration(
                                                                    contentPadding:
                                                                        EdgeInsets
                                                                            .zero, // Remove any content padding
                                                                    isDense:
                                                                        true,
                                                                    labelText:
                                                                        'Mode',
                                                                  ),
                                                                  value:
                                                                      initalMode,
                                                                  items: [
                                                                    'Cash',
                                                                    'Online',
                                                                    'Cheque',
                                                                  ].map((String
                                                                      value) {
                                                                    return DropdownMenuItem<
                                                                        String>(
                                                                      value:
                                                                          value,
                                                                      child: Text(
                                                                          value),
                                                                    );
                                                                  }).toList(),
                                                                  onChanged:
                                                                      (String?
                                                                          newValue) {
                                                                    setState(
                                                                        () {
                                                                      initalMode =
                                                                          newValue ??
                                                                              '';
                                                                    });
                                                                  },
                                                                ),
                                                                SizedBox(
                                                                    height:
                                                                        width *
                                                                            0.02),
                                                                ElevatedButton(
                                                                  onPressed:
                                                                      () async {
                                                                    if (!formKey
                                                                        .currentState!
                                                                        .validate()) {
                                                                      return;
                                                                    }
                                                                    try {
                                                                      String newKey = FirebaseDatabase
                                                                          .instance
                                                                          .ref()
                                                                          .push()
                                                                          .key!;
                                                                      final int
                                                                          amount =
                                                                          int.parse(
                                                                              amountController.text);
                                                                      Map<String,
                                                                              dynamic>
                                                                          updates =
                                                                          {
                                                                        'balance':
                                                                            ServerValue.increment(-amount),
                                                                        'payments/$newKey':
                                                                            {
                                                                          'amount':
                                                                              amount,
                                                                          'mode':
                                                                              initalMode,
                                                                          'timestamp':
                                                                              ServerValue.timestamp,
                                                                        },
                                                                      };
                                                                      await FirebaseDatabase
                                                                          .instance
                                                                          .ref()
                                                                          .child(
                                                                              'Coaches')
                                                                          .child(
                                                                              cid)
                                                                          .child(
                                                                              'users')
                                                                          .child(
                                                                              uid)
                                                                          .child(
                                                                              'productsHistory')
                                                                          .child(entry
                                                                              .key)
                                                                          .update(
                                                                              updates);
                                                                      Navigator.pop(
                                                                          contextx);
                                                                      Navigator.pop(
                                                                          context);
                                                                      Navigator.pop(
                                                                          context);
                                                                      Navigator.pop(
                                                                          context);
                                                                      Flushbar(
                                                                        margin: const EdgeInsets
                                                                            .all(
                                                                            7),
                                                                        borderRadius:
                                                                            BorderRadius.circular(15),
                                                                        flushbarStyle:
                                                                            FlushbarStyle.FLOATING,
                                                                        flushbarPosition:
                                                                            FlushbarPosition.TOP,
                                                                        message:
                                                                            'Payment added successfully',
                                                                        icon:
                                                                            Icon(
                                                                          Icons
                                                                              .check_circle_outline,
                                                                          size:
                                                                              28.0,
                                                                          color:
                                                                              Colors.green[300],
                                                                        ),
                                                                        duration:
                                                                            const Duration(milliseconds: 2000),
                                                                        leftBarIndicatorColor:
                                                                            Colors.green[300],
                                                                      ).show(
                                                                          context);
                                                                    } catch (e) {
                                                                      Navigator.pop(
                                                                          contextx);
                                                                      Flushbar(
                                                                        margin: const EdgeInsets
                                                                            .all(
                                                                            7),
                                                                        borderRadius:
                                                                            BorderRadius.circular(15),
                                                                        flushbarStyle:
                                                                            FlushbarStyle.FLOATING,
                                                                        flushbarPosition:
                                                                            FlushbarPosition.TOP,
                                                                        message:
                                                                            'Error adding payment',
                                                                        icon:
                                                                            Icon(
                                                                          Icons
                                                                              .error_outline_rounded,
                                                                          size:
                                                                              28.0,
                                                                          color:
                                                                              Colors.red[300],
                                                                        ),
                                                                        duration:
                                                                            const Duration(milliseconds: 3000),
                                                                        leftBarIndicatorColor:
                                                                            Colors.red[300],
                                                                      ).show(
                                                                          context);
                                                                    }
                                                                  },
                                                                  child:
                                                                      const Text(
                                                                          'Add'),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        );
                                                      }));
                                        },
                                      ),
                                      ListTile(
                                        title: const Text('Edit'),
                                        onTap: () {
                                          Navigator.pop(context, true);
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                            if (selected == null || !selected) {
                              return;
                            }
                          }
                          if (!await checkPassword(context, cid)) {
                            return;
                          }
                          if (!isCustom) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CustOrderForm(
                                  uid: uid,
                                  productMap: Map<String, int>.from(
                                      entry.value['products']),
                                  name: name,
                                  popIndex: 4,
                                  index: index,
                                  formattedDate: entry.value['date'],
                                  existingData: {
                                    'total': entry.value['total'],
                                    'discount': entry.value['discount'],
                                    'discountMode': entry.value['discountMode'],
                                    'discountManual':
                                        entry.value['discountManual'],
                                    'shakemateDiscount':
                                        entry.value['shakemateDiscount'],
                                    'initalAutoMode':
                                        entry.value['initalAutoMode'],
                                    'customPrice': entry.value['customPrice'],
                                    'paid': entry.value['paid'],
                                    'balance': entry.value['balance'],
                                    'chosenDate': entry.value['chosenDate'],
                                    'timestamp': entry.value['timestamp'],
                                    'mode': entry.value['mode'],
                                    'payments': Map<String, dynamic>.from(
                                        entry.value['payments'] ?? {}),
                                  },
                                ),
                              ),
                            );
                          } else {
                            if (isSubmited) {
                              return;
                            }
                            isSubmited = true;
                            showDialog(
                              context: scaffoldKey.currentContext!,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text('Delete Order'),
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
                                        try {
                                          final Map<String, dynamic> updates = {
                                            'users/$uid/productsHistory/${entry.key}':
                                                null,
                                            'attendance/${entry.value['date']}/productsHistory/${entry.key}':
                                                null,
                                          };
                                          await FirebaseDatabase.instance
                                              .ref()
                                              .child('Coaches')
                                              .child(cid)
                                              .update(updates);
                                          Navigator.of(
                                                  scaffoldKey.currentContext!)
                                              .pop();
                                          Navigator.of(
                                                  scaffoldKey.currentContext!)
                                              .pop();
                                          Navigator.of(
                                                  scaffoldKey.currentContext!)
                                              .pop();
                                          Flushbar(
                                            margin: const EdgeInsets.all(7),
                                            borderRadius:
                                                BorderRadius.circular(15),
                                            flushbarStyle:
                                                FlushbarStyle.FLOATING,
                                            flushbarPosition:
                                                FlushbarPosition.TOP,
                                            message:
                                                'Product deleted successfully',
                                            icon: Icon(
                                              Icons.check_circle_outline,
                                              size: 28.0,
                                              color: Colors.green[300],
                                            ),
                                            duration: const Duration(
                                                milliseconds: 2000),
                                            leftBarIndicatorColor:
                                                Colors.green[300],
                                          ).show(scaffoldKey.currentContext!);
                                        } catch (e) {
                                          Navigator.of(
                                                  scaffoldKey.currentContext!)
                                              .pop();
                                          Flushbar(
                                            margin: const EdgeInsets.all(7),
                                            borderRadius:
                                                BorderRadius.circular(15),
                                            flushbarStyle:
                                                FlushbarStyle.FLOATING,
                                            flushbarPosition:
                                                FlushbarPosition.TOP,
                                            message: 'Error deleting product',
                                            icon: Icon(
                                              Icons.error_outline_rounded,
                                              size: 28.0,
                                              color: Colors.red[300],
                                            ),
                                            duration: const Duration(
                                                milliseconds: 3000),
                                            leftBarIndicatorColor:
                                                Colors.red[300],
                                          ).show(scaffoldKey.currentContext!);
                                          isSubmited = false;
                                        }
                                      },
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                );
                              },
                            );
                          }
                        },
                      );
                    }).toList(),
                  )
                : SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    width: width,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          color: Colors.black38,
                          size: width * 0.2,
                        ),
                        Text(
                          'No orders found',
                          style: GoogleFonts.poppins(
                            color: Colors.black38,
                            fontSize: width * 0.05,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class ProductExpansionTile extends StatefulWidget {
  final String uid;
  final bool custom;
  final String formattedDate;
  final DateTime chosenDate;
  final DateTime timestamp;
  final int? updatedTimestamp;
  final Map<dynamic, dynamic> products;
  final Map<String, dynamic> payments;
  final int total;
  final String discountMode;
  final int? discountManual;
  final int shakemateDiscount;
  final String? initalAutoMode;
  final int? customPrice;
  final int discount;
  final String index;
  final String mode;
  final int paid;
  final int balance;
  final List<Color> gradientColors;
  final void Function(String) onLongPress;

  const ProductExpansionTile({
    required this.uid,
    required this.custom,
    required this.formattedDate,
    required this.chosenDate,
    required this.timestamp,
    this.updatedTimestamp,
    required this.products,
    required this.payments,
    required this.total,
    required this.discountMode,
    this.discountManual,
    this.shakemateDiscount = 0,
    this.initalAutoMode,
    this.customPrice,
    required this.discount,
    required this.index,
    required this.mode,
    required this.paid,
    required this.balance,
    required this.gradientColors,
    required this.onLongPress,
    Key? key,
  }) : super(key: key);

  @override
  State<ProductExpansionTile> createState() => _ProductExpansionTileState();
}

class _ProductExpansionTileState extends State<ProductExpansionTile> {
  bool expanded = false;
  late String timeAgo;
  String discText = 'Discount';
  int? actShakeMateCost;
  bool isSubmited = false;

  // reusable text widget
  Widget rowText(String text, String text2, double width, double height,
      {bool isIcon = false, void Function()? onPressed}) {
    return Padding(
      padding: EdgeInsets.only(
        left: isIcon ? width * 0.02 : width * 0.05,
        right: width * 0.05,
        top: width * 0.03,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (isIcon)
                IconButton(
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    onPressed: onPressed,
                    icon: Icon(Icons.delete,
                        color: Colors.white, size: width * 0.04)),
              Text(
                text,
                style: GoogleFonts.poppins(
                  color: Colors.black38,
                  fontSize: width * 0.05,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Text(
            text2,
            style: TextStyle(
              color: Colors.black38,
              fontSize: width * 0.05,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    final DateTime date = widget.chosenDate;
    final DateTime now = DateTime.now();
    // get difference in days and time is 00:00:00
    final int days = DateTime(now.year, now.month, now.day)
        .difference(DateTime(date.year, date.month, date.day))
        .inDays;
    if (days == 0) {
      timeAgo = ' (Today)';
    } else if (days == 1) {
      timeAgo = ' (Yesterday)';
    } else {
      timeAgo = ' ($days days ago)';
    }

    if (!widget.custom) {
      if (widget.discountMode == 'DiscountModes.manual') {
        discText += ' (M${widget.discountManual}%)';
        if (widget.shakemateDiscount > 0) {
          final int smprice = allProducts['183K']['price'];
          final int smqty = widget.products['183K'];
          actShakeMateCost =
              (smprice - (widget.shakemateDiscount / smqty)).toInt();
        }
      } else if (widget.discountMode == 'DiscountModes.auto') {
        discText += ' (A${widget.initalAutoMode})';
      } else if (widget.discountMode == 'DiscountModes.custom') {
        double customDiscount = double.parse(
            ((widget.total - widget.customPrice!) * 100 / widget.total)
                .toStringAsFixed(1));

        discText += ' (C$customDiscount%)';
      }
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return GestureDetector(
      onLongPress: () {
        widget.onLongPress(widget.index);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: height * 0.035),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            colors: widget.gradientColors,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: ExpansionTile(
          collapsedBackgroundColor: Colors.transparent,
          backgroundColor: Colors.transparent,
          // chhange arrow color
          collapsedIconColor: Colors.white.withOpacity(0.8),
          iconColor: Colors.white.withOpacity(0.8),
          onExpansionChanged: (expanded) {
            setState(() {
              this.expanded = expanded;
            });
          },
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  RichText(
                      text: TextSpan(
                    children: [
                      TextSpan(
                        text: formatDate(widget.chosenDate),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: timeAgo,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 15,
                        ),
                      ),
                    ],
                  )),
                ],
              ),
              if (expanded)
                Text(
                  DateFormat("hh:mm a").format(widget.chosenDate),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 15,
                  ),
                ),
            ],
          ),
          children: [
            if ((!isSameDay(widget.chosenDate, widget.timestamp)) ||
                widget.updatedTimestamp != null)
              Padding(
                padding: EdgeInsets.all(width * 0.03),
                child: Column(
                  children: [
                    if (!isSameDay(widget.chosenDate, widget.timestamp))
                      Text(
                        'Created at ${DateFormat("dd MMM yyyy - hh:mm a").format(widget.timestamp)}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 15,
                        ),
                      ),
                    if (widget.updatedTimestamp != null)
                      Text(
                        'Updated at ${DateFormat("dd MMM yyyy - hh:mm a").format(DateTime.fromMillisecondsSinceEpoch(widget.updatedTimestamp!))}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 15,
                        ),
                      ),
                  ],
                ),
              ),
            FittedBox(
              child: DataTable(
                horizontalMargin: width * .05,
                columnSpacing: width * .05,
                // only top border
                border: TableBorder(
                  top: BorderSide(
                    color: Colors.white.withOpacity(0.5),
                    width: 1,
                  ),
                  bottom: BorderSide(
                    color: Colors.white.withOpacity(0.5),
                    width: 1,
                  ),
                  verticalInside: BorderSide(
                    color: Colors.white.withOpacity(0.5),
                    width: 1,
                  ),
                ),

                columns: <DataColumn>[
                  DataColumn(
                    label: Container(
                      padding: EdgeInsets.zero,
                      width: widget.custom ? width * .6 : width * .5,
                      child: Text(
                        'Product',
                        style:
                            GoogleFonts.montserrat(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  if (!widget.custom)
                    DataColumn(
                      label: SizedBox(
                        width: width * .1,
                        child: Text(
                          'Qty',
                          style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  DataColumn(
                    label: SizedBox(
                      width: widget.custom ? width * .2 : width * .1,
                      child: Text(
                        'Price',
                        style:
                            GoogleFonts.montserrat(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
                rows: List<DataRow>.generate(widget.products.length, (index) {
                  String key = widget.products.keys.elementAt(index);
                  return DataRow(
                    cells: <DataCell>[
                      DataCell(
                        Text(
                          widget.custom
                              ? key
                              : allProducts[key]['name'].toString(),
                          style: GoogleFonts.montserrat(),
                        ),
                      ),
                      if (!widget.custom)
                        DataCell(
                          Text(
                            widget.products[key].toString(),
                            style: GoogleFonts.montserrat(),
                          ),
                        ),
                      DataCell(
                        Text(
                          '₹${widget.custom ? widget.products[key] : allProducts[key]['price']}',
                          style: GoogleFonts.montserrat(),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: height * 0.02),
              child: Column(
                children: [
                  rowText('Mode:', widget.mode, width, height),
                  rowText('Total:', '₹${widget.total}', width, height),
                  if (!widget.custom)
                    rowText(discText, '- ₹${widget.discount}', width, height),
                  if (actShakeMateCost != null)
                    rowText('ShakeMate(₹$actShakeMateCost) ',
                        '- ₹${widget.shakemateDiscount}', width, height),
                  if (!widget.custom)
                    rowText(
                        'Discounted Total:',
                        '₹${widget.total - (widget.discount + widget.shakemateDiscount)}',
                        width,
                        height),
                  rowText('Paid:', '₹${widget.paid}', width, height),
                  ...widget.payments.entries.map((entry) {
                    return rowText(
                      '${DateFormat('dd/MM/yy').format(DateTime.fromMillisecondsSinceEpoch(entry.value['timestamp']))} (${entry.value['mode']}):',
                      '₹${entry.value['amount']}',
                      width,
                      height,
                      isIcon: true,
                      onPressed: () async {
                        showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text('Delete Payment'),
                                content: const Text(
                                    'Are you sure you want to delete this payment?'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      try {
                                        if (!await checkPassword(
                                            context, cid)) {
                                          return;
                                        }
                                      } catch (e) {
                                        return;
                                      }
                                      if (isSubmited) {
                                        return;
                                      }
                                      isSubmited = true;
                                      try {
                                        Map<String, dynamic> updates = {
                                          'balance': ServerValue.increment(
                                              entry.value['amount']),
                                          'payments/${entry.key}': null,
                                        };

                                        await FirebaseDatabase.instance
                                            .ref()
                                            .child('Coaches')
                                            .child(cid)
                                            .child('users')
                                            .child(widget.uid)
                                            .child('productsHistory')
                                            .child(widget.index)
                                            .update(updates);
                                        Navigator.pop(context);
                                        Navigator.pop(context);
                                        Navigator.pop(context);
                                        Flushbar(
                                          margin: const EdgeInsets.all(7),
                                          borderRadius:
                                              BorderRadius.circular(15),
                                          flushbarStyle: FlushbarStyle.FLOATING,
                                          flushbarPosition:
                                              FlushbarPosition.TOP,
                                          message:
                                              'Payment deleted successfully',
                                          icon: Icon(
                                            Icons.check_circle_outline,
                                            size: 28.0,
                                            color: Colors.green[300],
                                          ),
                                          duration: const Duration(
                                              milliseconds: 2000),
                                          leftBarIndicatorColor:
                                              Colors.green[300],
                                        ).show(context);
                                      } catch (e) {
                                        Navigator.pop(context);
                                        Flushbar(
                                          margin: const EdgeInsets.all(7),
                                          borderRadius:
                                              BorderRadius.circular(15),
                                          flushbarStyle: FlushbarStyle.FLOATING,
                                          flushbarPosition:
                                              FlushbarPosition.TOP,
                                          message: 'Error deleting payment',
                                          icon: Icon(
                                            Icons.error_outline_rounded,
                                            size: 28.0,
                                            color: Colors.red[300],
                                          ),
                                          duration: const Duration(
                                              milliseconds: 3000),
                                          leftBarIndicatorColor:
                                              Colors.red[300],
                                        ).show(context);
                                          isSubmited = false;
                                      }
                                    },
                                    child: const Text('Delete'),
                                  ),
                                ],
                              );
                            });
                      },
                    );
                  }),
                  if (widget.balance > 0)
                    rowText('Balance:', '₹${widget.balance}', width, height),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

bool isSameDay(DateTime date1, DateTime date2) {
  return date1.year == date2.year &&
      date1.month == date2.month &&
      date1.day == date2.day;
}
