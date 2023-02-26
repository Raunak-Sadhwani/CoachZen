import 'package:flutter/material.dart';

class UICard extends StatelessWidget {
  final double width;
  final List<Widget> children;
  const UICard({super.key, required this.width, required this.children});
  @override
  Widget build(BuildContext context) {
    return Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Container(
            padding: const EdgeInsets.all(20),
            width: width,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: children,
            )));
  }
}
