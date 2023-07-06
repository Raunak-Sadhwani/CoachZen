import 'package:flutter/material.dart';

import '../components/ui/appbar.dart';

class ProductsHistory extends StatelessWidget {
  final List<Map<String, dynamic>> products;
  final String name;
  const ProductsHistory({Key? key, required this.products, required this.name})
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
        title: 'Product History of $name',
        leftIcon: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: Colors.black26,
          onPressed: () => Navigator.pop(context),
        ),
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
  final String date;
  final Map<String, dynamic> products;
  final List<Color> gradientColors;

  const ProductExpansionTile({
    required this.date,
    required this.products,
    required this.gradientColors,
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
    return Container(
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
            Text(
              widget.date,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        children: [
          Container(
            padding: EdgeInsets.only(
                left: width * 0.05, right: width * 0.05, bottom: width * 0.03),
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
    );
  }
}
