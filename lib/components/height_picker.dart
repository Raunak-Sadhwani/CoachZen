// height_picker.dart

import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'card.dart';

class HeightPicker extends StatefulWidget {
  // final Function(DragUpdateDetails) setHeight;
  final String value; // current height value
  final double minValue;
  final double step;
  final double maxValue;
  const HeightPicker(
      {Key? key,
      // required this.setHeight,
      required this.value,
      required this.minValue,
      required this.step,
      required this.maxValue})
      : super(key: key);

  @override
  State<HeightPicker> createState() => _HeightPickerState();
}

class _HeightPickerState extends State<HeightPicker> {
  //  double ScreenHeight =  MediaQuery.of(context).size.height;
  // void setHeight(DragUpdateDetails details) {}

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height / 15;
    final cardWidth = MediaQuery.of(context).size.width - 20;
    const Color prime = Color.fromARGB(255, 88, 90, 107);
    String value = widget.value;
    return UICard(
      width: cardWidth,
      children: [
        const Text('Height',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: prime,
            )),
        Text('cm',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.grey[400],
            )),
        const SizedBox(height: 10),
        //  GestureDetector(
        //   onPanUpdate: (details) {
        //     widget.setHeight(details);
        //   },
        Column(
          children: [
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text((int.parse(value) - 2).toString(),
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[200],
                      )),
                  Text((int.parse(value) - 1).toString(),
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[300],
                      )),
                  Text(value,
                      style: const TextStyle(
                        fontSize: 46,
                        fontWeight: FontWeight.w700,
                        color: prime,
                      )),
                  Text((int.parse(value) + 1).toString(),
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[300],
                      )),
                  Text((int.parse(value) + 2).toString(),
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[200],
                      )),
                ]),
            const SizedBox(height: 15),
            ClipRect(
              child: SizedBox(
                width: double.infinity,
                height: height,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 18),
                    Expanded(
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: RulerPainter(widget.minValue, widget.maxValue,
                            widget.step, double.parse(value)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        )
      ],
    );
  }
}

class RulerPainter extends CustomPainter {
  final double minValue;
  final double maxValue;
  final double step;
  final double currentValue;
  final double fadeLength; // length of the fade overlay
  RulerPainter(this.minValue, this.maxValue, this.step, this.currentValue,
      {this.fadeLength = 32});

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;
    final double midWidth = width / 2;
    final double triangleHeight = height * .5;
    final double triangleWidth =
        triangleHeight * 2 / math.sqrt(3); // height * tan(pi/3)
    final Path trianglePath = Path()
      ..moveTo(midWidth - triangleWidth / 2, 0)
      ..lineTo(midWidth + triangleWidth / 2, 0)
      ..lineTo(midWidth, -10)
      ..close();

    final Paint trianglePaint = Paint()..color = Colors.blue[800]!;

    // Draw the modified triangle with margin bottom
    canvas.drawPath(trianglePath, trianglePaint);
    canvas.drawLine(
      Offset(midWidth - width * .15, 0),
      Offset(midWidth + width * .15, 0),
      Paint()
        ..color = Colors.grey.shade300
        ..strokeWidth = .7,
    );

    final double fadeStartPosition = midWidth - fadeLength * 5;
    final double fadeEndPosition = midWidth + fadeLength + 50;
    const double fadeStartAlpha = 0.0;
    const double fadeEndAlpha = 1.0;

    // Draw the lines with fade overlay at both ends
    for (int i = minValue ~/ 1.8; i <= maxValue * 1.2; i += step.toInt()) {
      final double x = midWidth +
          (i - currentValue) * (width / ((maxValue - minValue) / step));
      final double alpha = _getFadeAlpha(
          x, fadeStartPosition, fadeEndPosition, fadeStartAlpha, fadeEndAlpha);
      final bool isLineLong = i % 5 == 0;
      final Paint linePaint = Paint()
        ..color = Colors.grey.shade300
        ..strokeWidth = isLineLong ? 1.4 : 1;

      if (alpha > 0) {
        final double lineHeight = isLineLong ? height * .95 : height * .85;

        linePaint.color = Colors.grey[350]!.withOpacity(alpha);
        // for right side
        canvas.drawLine(
          Offset(x, 0),
          Offset(x, lineHeight),
          linePaint,
        );
      }
    }
  }

  double _getFadeAlpha(double position, double start, double end,
      double startAlpha, double endAlpha) {
    if (position < start) {
      return startAlpha;
    } else if (position > end) {
      return endAlpha;
    } else {
      return startAlpha +
          (endAlpha - startAlpha) * (position - start) / (end - start);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
