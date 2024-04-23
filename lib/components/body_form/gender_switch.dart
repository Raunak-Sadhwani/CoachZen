import 'package:flutter/material.dart';
import '../ui/card.dart';

class GenderSwitch extends StatefulWidget {
  final Function(bool) onGenderChanged;
  final bool isMale;
  final String title;
  final String firstOpt;
  final String secondOpt;
  const GenderSwitch(
      {Key? key,
      required this.onGenderChanged, 
      required this.isMale,
      this.title = 'Gender',
      this.firstOpt = 'Male',
      this.secondOpt = 'Female'})
      : super(key: key);

  @override
  State<GenderSwitch> createState() => _GenderSwitchState();
}

class _GenderSwitchState extends State<GenderSwitch> {
  @override
  Widget build(BuildContext context) {
    final cardWidth = MediaQuery.of(context).size.width - 20;
    bool isMale = widget.isMale;
    return UICard(
      width: cardWidth,
      children: [
        Column(
          
          children: [
            Text(
              widget.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        widget.onGenderChanged(true);
                      });
                    },
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: isMale ? Colors.blue : Colors.grey[300],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(10),
                          bottomLeft: Radius.circular(10),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          widget.firstOpt,
                          style: TextStyle(
                              color: isMale ? Colors.white : Colors.grey[600],
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        widget.onGenderChanged(false);
                      });
                    },
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: !isMale ? Colors.pink : Colors.grey[300],
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(10),
                          bottomRight: Radius.circular(10),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          widget.secondOpt,
                          style: TextStyle(
                              color: !isMale ? Colors.white : Colors.grey[600],
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
