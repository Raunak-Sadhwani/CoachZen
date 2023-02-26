import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
final Function lmao;
  const MyWidget({super.key, required this.lmao});
  @override
  Widget build(BuildContext context) {
    return lmao();
  }
}


class Lol extends StatelessWidget {
  const Lol({super.key});
  @override
  Widget build(BuildContext context) {
    return MyWidget(lmao: () => const Text('lmao'));
  }
}