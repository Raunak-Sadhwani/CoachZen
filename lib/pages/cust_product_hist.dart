import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../components/ui/appbar.dart';
import 'cust_order_form.dart';

String formatDate(Timestamp timestamp) {
  DateTime dateTime = timestamp.toDate();
  String formattedDate = DateFormat('dd MMM yyyy').format(dateTime);
  return formattedDate;
}

class ProductsHistory extends StatelessWidget {
  final List<Map<String, dynamic>> products;
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

    return Scaffold(
      backgroundColor: bg,
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
                      productsHistory: products,
                      name: name,
                      popIndex: 2,
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
            child: Column(
              children: products.map((product) {
                return ProductExpansionTile(
                  date: product['date'],
                  products: product['products'],
                  gradientColors: gradientColors,
                  onLongPress: (index) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CustOrderForm(
                          uid: uid,
                          productsHistory: products,
                          name: name,
                          popIndex: 2,
                          index: index,
                        ),
                      ),
                    );
                  },
                  index: products.indexOf(product),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class ProductExpansionTile extends StatefulWidget {
  final Timestamp date;
  final int index;
  final Map<String, dynamic> products;
  final List<Color> gradientColors;
  final void Function(int) onLongPress;

  const ProductExpansionTile({
    required this.date,
    required this.products,
    required this.gradientColors,
    required this.index,
    required this.onLongPress,
    Key? key,
  }) : super(key: key);

  @override
  State<ProductExpansionTile> createState() => _ProductExpansionTileState();
}

class _ProductExpansionTileState extends State<ProductExpansionTile> {
  bool expanded = false;
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    // calculate days from todays date - date

    DateTime now = DateTime.now();
    DateTime date = widget.date.toDate();
    int days = now.difference(date).inDays;
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
              expanded = expanded;
            });
          },
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              RichText(
                  text: TextSpan(
                children: [
                  TextSpan(
                    text: formatDate(widget.date),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: "  ($days days ago)",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 15,
                    ),
                  ),
                ],
              )),
            ],
          ),
          children: [
            Container(
              padding: EdgeInsets.only(
                  left: width * 0.05,
                  right: width * 0.05,
                  bottom: width * 0.03),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.products.entries.map((entry) {
                  return Container(
                    margin: EdgeInsets.only(bottom: height * 0.015),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(
                            color: Colors.black38,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'x${entry.value}',
                          style: const TextStyle(
                            color: Colors.black38,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
