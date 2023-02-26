import 'package:flutter/material.dart';
import 'components/card.dart';

class BodyForm2 extends StatefulWidget {
  const BodyForm2({super.key});

  @override
  State<BodyForm2> createState() => _BodyForm2State();
}

class _BodyForm2State extends State<BodyForm2> {
  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
        backgroundColor: const Color(0xfff5f6fd),
        body: SingleChildScrollView(
            child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: width * 0.05,
                  vertical: height * 0.03,
                ),
                child: Column(
                  children: [
                    UICard(width: width, children: const [Text("data")])
                  ],
                ))));
  }
}
