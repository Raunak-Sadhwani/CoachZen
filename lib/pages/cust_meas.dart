import 'package:flutter/material.dart';

import '../components/ui/appbar.dart';

class Meas extends StatelessWidget {
  final Map<String, dynamic> measurements;
  final Widget Function(Widget child) card;

  const Meas({
    Key? key,
    required this.measurements,
    required this.card,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // List<Color> gradientColors = AppUi.gradientColors;
    String capitalize(String value) {
      return value
          .split(' ')
          .map((word) => word[0].toUpperCase() + word.substring(1))
          .join(' ');
    }

    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    Color bg = Colors.white;
    Color text = Colors.black54;

    // check if year is present in string, if yes, remove it
    String date = measurements['date'];
    if (date.contains(RegExp(r'[0-9]{4}'))) {
      date = date.substring(0, date.length - 5);
    }
    return Scaffold(
      backgroundColor: bg,
      appBar: MyAppBar(
        title: date,
        leftIcon: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: Colors.black26,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.all(width * 0.04),
          child: Column(
            // map all measurements in containers
            children: measurements.entries.map((e) {
              return Container(
                margin: EdgeInsets.only(bottom: height * 0.02),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: card(
                  Container(
                    padding: EdgeInsets.all(width * 0.04),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            capitalize(e.key),
                            style: TextStyle(
                              color: text,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),

                            maxLines: 2, // Set maxLines to 2 for text wrapping
                          ),
                        ),
                        const SizedBox(
                            width:
                                10), // Add some spacing between the two Text widgets
                        Text(
                          e.value.toString(),
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
