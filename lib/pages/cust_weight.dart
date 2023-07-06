import 'package:flutter/material.dart';

import '../components/ui/appbar.dart';
import 'cust_meas.dart';

class WHistory extends StatelessWidget {
  final int idealweight;
  final List<Map<String, dynamic>> measurements;
  final String name;
  final List<Color> colors;

  const WHistory(
      {Key? key,
      required this.measurements,
      required this.idealweight,
      required this.name,
      required this.colors})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    debugPrint('measurements: $measurements');
    // List<Color> gradientColors = AppUi.gradientColors;
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    Color bg = Colors.white;
    return Scaffold(
      backgroundColor: bg,
      appBar: MyAppBar(
        title: 'Weight History of $name',
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
            children: measurements.reversed.toList().map((measurement) {
              final int index = measurements.indexOf(measurement);
              double weightLoss = 0;
              if (index > 0) {
                weightLoss =
                    measurement['weight'] - measurements[index - 1]['weight'];
              }
              dynamic arrowIcon = false;
              Color arrowColor = colors[0];

              if (weightLoss > 0) {
                arrowIcon = Icons.arrow_upward_outlined;
                arrowColor = Colors.green;
              } else if (weightLoss < 0) {
                arrowIcon = Icons.arrow_downward_outlined;
                arrowColor = Colors.red;
              }
              // if ideal weight is lesser than current weight change arrow color to red
              if (idealweight < measurement['weight'] && weightLoss < 0) {
                arrowColor = Colors.green;
              } else if (idealweight < measurement['weight'] &&
                  weightLoss > 0) {
                arrowColor = Colors.red;
              }
              return Container(
                margin: EdgeInsets.only(bottom: height * 0.015),
                color: bg,
                child: measurement.length > 2
                    ? OpenContainerWrapper(
                        page: Meas(
                          measurements: measurements[index],
                          card: card,
                        ),
                        content: widMeas(measurement, height, width, arrowIcon,
                            arrowColor, weightLoss))
                    : widMeas(measurement, height, width, arrowIcon, arrowColor,
                        weightLoss),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget widMeas(
      measurement, height, width, arrowIcon, arrowColor, weightLoss) {
    return card(
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                children: [
                  Text(
                    measurement['date'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: height * 0.007),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (arrowIcon != false)
                          Icon(
                            arrowIcon,
                            color: arrowColor,
                            size: 22,
                          )
                        else
                          Container(
                            padding: EdgeInsets.only(right: width * 0.01),
                            child: Text("=",
                                style: TextStyle(
                                    color: arrowColor,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold)),
                          ),
                        const SizedBox(
                            width:
                                4.0), // Add some space between the icon and text
                        Text(
                          '${weightLoss.abs().toStringAsFixed(1)} kg',
                          style: const TextStyle(
                              fontSize: 18, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          // if index has items other than weight and date
          if (measurement.length > 2)
            Container(
              margin: const EdgeInsets.only(right: 10),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                color: Color.fromARGB(255, 98, 0, 255),
                size: 20,
              ),
            ),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: measurement['weight'].toString(),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const TextSpan(
                  text: ' kg',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget card(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          // orange gradient
          colors: [
            Color.fromARGB(255, 255, 153, 0),
            Color.fromARGB(255, 255, 102, 0),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: child,
    );
  }
}
