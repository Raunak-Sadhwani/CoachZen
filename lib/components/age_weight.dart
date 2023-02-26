import 'package:flutter/material.dart';
import 'card.dart';

class VCard extends StatefulWidget {
  final String value;
  final String title;
  final Function fn;

  const VCard({
    Key? key,
    required this.title,
    required this.fn,
    required this.value,
  }) : super(key: key);

  @override
  State<VCard> createState() => _VCardState();
}

class _VCardState extends State<VCard> {
  final Color prime = const Color.fromARGB(255, 88, 90, 107);

  @override
  Widget build(BuildContext context) {
    final cardHeight = MediaQuery.of(context).size.width / 2 - 40;
    return UICard(
      width: cardHeight,
      children: [
        Text(widget.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: prime,
            )),
        const SizedBox(height: 10),
        Text(widget.value,
            style: TextStyle(
              fontSize: 46,
              fontWeight: FontWeight.w700,
              color: prime,
            )),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            sum(Icons.remove, 'sub'),
            sum(Icons.add, 'add'),
          ],
        )
      ],
    );
  }

  Widget sum(IconData icon, String calc) {
    return GestureDetector(
      onTap: () {
        widget.fn(calc);
      },
      child: Container(
        height: 35,
        width: 35,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.grey[200]!,
            width: 2,
          ),
        ),
        child: Center(
          child: Icon(
            icon,
            size: 30,
            color: Colors.blue[800]!,
          ),
        ),
      ),
    );
  }
}
