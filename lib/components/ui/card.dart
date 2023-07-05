import 'package:flutter/material.dart';

class UICard extends StatelessWidget {
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding = const EdgeInsets.all(20);
  final List<Widget> children;

  const UICard(
      {super.key,
      this.width,
      required this.children,
      this.height,
      EdgeInsetsGeometry? padding});
  @override
  Widget build(BuildContext context) {
    return Card(
        elevation: 5,
        // shape: RoundedRectangleBorder(
        //   borderRadius: BorderRadius.circular(10),
        // ),
        child: Container(
            height: height,
            padding: padding,
            width: width,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: children,
            )));
  }
}
