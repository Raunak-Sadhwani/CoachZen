// import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../components/ui/appbar.dart';

int dayx = 0;

class CustPlanHist extends StatelessWidget {
  final String name;
  final Map<dynamic, dynamic> plans;
  final Map<dynamic, dynamic> days;
  final Map<dynamic, dynamic> homeProgram;
  const CustPlanHist(
      {Key? key,
      required this.name,
      required this.plans,
      required this.days,
      required this.homeProgram})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    debugPrint('days: $days');
    double joinedFontSize = width * 0.035;
    // check if any dates are in 1970
    // if so remove them
    if (days.containsKey('1970-01-01')) {
      dayx = 1;
      days.removeWhere((key, value) => key == '1970-01-01');
      plans.removeWhere((key, value) => key == '1970-01-01');
      days.removeWhere((key, value) => key == '1970-01-02');
      days.removeWhere((key, value) => key == '1970-01-03');
      days.removeWhere((key, value) => key == '1970-01-04');
      days.removeWhere((key, value) => key == '1970-01-05');
      plans.removeWhere((key, value) => key == '1970-01-05');
    }

    List absentDates = [];

    // check if any payment date is not in days
    plans.forEach((key, value) {
      if (!days.containsKey(key)) {
        absentDates.add(key);
      }
    });

    List sortedKeys = days.keys.toList()..sort((a, b) => b.compareTo(a));
    return Scaffold(
        appBar: MyAppBar(
          title: 'Plans of $name',
          leftIcon: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            color: Colors.black26,
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Container(
          margin: EdgeInsets.all(width * 0.02),
          width: width,
          child: sortedKeys.isNotEmpty
              ? ListView.builder(
                  itemCount: sortedKeys.length,
                  itemBuilder: (context, index) {
                    String key = sortedKeys[index];

                    String actualDay =
                        "Day ${(sortedKeys.length - index - 1) + dayx},";
                    // dynamic values = days.values.elementAt(index);
                    DateTime joinedTime = DateTime.fromMillisecondsSinceEpoch(
                        days[key]['time'] ?? 0);
                    String joined =
                        "$actualDay Joined on: ${DateFormat.jm().format(joinedTime)}";

                    if (homeProgram.containsKey(key)) {
                      joined = "$actualDay Took in Home";
                    }

                    bool showPayment = false;
                    String? absentDate;
                    final DateTime currentDate = DateTime.parse(key);
                    final DateTime nextDate = DateTime.parse(
                        sortedKeys.length - index - 1 >= 0
                            ? sortedKeys[sortedKeys.length - index - 1]
                            : key);

                    for (int i = 0; i < absentDates.length; i++) {
                      if (index == 0) {
                        if (DateTime.parse(absentDates[i])
                            .isAfter(currentDate)) {
                          showPayment = true;
                          absentDate = absentDates[i];
                        }
                      }
                      if (DateTime.parse(absentDates[i])
                              .isBefore(currentDate) &&
                          DateTime.parse(absentDates[i]).isAfter(nextDate)) {
                        showPayment = true;
                        absentDate = absentDates[i];
                        break;
                      }
                      if (index == (sortedKeys.length - 1)) {
                        if (DateTime.parse(absentDates[i])
                            .isBefore(currentDate)) {
                          showPayment = true;
                          absentDate = absentDates[i];
                        }
                      }
                    }
                    Map<dynamic, dynamic> plan = {};
                    String? secondKey;
                    dynamic secondPlan;
                    DateTime? secondDate;
                    if (showPayment || plans.containsKey(key)) {
                      if (showPayment && absentDate != null) {
                        if (!plans.containsKey(key)) {
                          key = absentDate;
                        } else {
                          secondKey = key;
                          key = absentDate;
                          if (plans[secondKey].containsKey('totalAmount')) {
                            plans[secondKey].remove('totalAmount');
                          }
                          secondPlan =
                              plans[secondKey][plans[secondKey].keys.first];
                          secondDate = DateTime.parse(
                              secondPlan['date'] ?? '1999-12-31');
                        }
                      }
                      // remove the key from the map
                      if (plans[key].containsKey('totalAmount')) {
                        plans[key].remove('totalAmount');
                      }

                      // set first key as plan
                      plan = plans[key][plans[key].keys.first];

                      DateTime date =
                          DateTime.parse(plan['date'] ?? '1999-12-31');

                      return Column(
                        children: [
                          if (showPayment && absentDate != null)
                            Column(
                              children: [
                                dateDivider(
                                  width: width,
                                  height: height,
                                  date: currentDate,
                                ),
                                textWidget(
                                  joined,
                                  joinedFontSize,
                                ),
                                if (secondKey != null &&
                                    secondPlan != null &&
                                    secondDate != null)
                                  paymentCard(
                                    plan: secondPlan['program'] ?? '',
                                    advancedPayment:
                                        secondPlan['advancedPayment'] ?? false,
                                    mode: secondPlan['mode'] ?? '',
                                    date: secondDate,
                                    amount: secondPlan['amount'] ?? 0,
                                    time: secondPlan['time'] ?? 0,
                                    balance: secondPlan['balance'] ?? 0,
                                    width: width,
                                    height: height,
                                  ),
                              ],
                            ),
                          dateDivider(
                            width: width,
                            height: height,
                            date: date,
                          ),
                          textWidget(
                            showPayment ? 'Absent' : joined,
                            joinedFontSize,
                          ),
                          paymentCard(
                            plan: plan['program'] ?? '',
                            advancedPayment: plan['advancedPayment'] ?? false,
                            mode: plan['mode'] ?? '',
                            date: date,
                            amount: plan['amount'] ?? 0,
                            time: plan['time'] ?? 0,
                            balance: plan['balance'] ?? 0,
                            width: width,
                            height: height,
                          ),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        dateDivider(
                          width: width,
                          height: height,
                          date: DateTime.parse(key),
                        ),
                        textWidget(
                          joined,
                          joinedFontSize,
                        ),
                      ],
                    );
                  },
                )
              : textWidget('User yet to start....', width * 0.05),
        ));
  }
}

Widget textWidget(String text, double fontSize) {
  return Center(
    child: Text(
      text,
      style: GoogleFonts.montserrat(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: Colors.black54),
    ),
  );
}

Widget dateDivider({
  required double width,
  required double height,
  required DateTime date,
}) {
  return Container(
    margin: EdgeInsets.symmetric(vertical: height * 0.02),
    child: Row(
      children: [
        const Expanded(
          child: Divider(
            height: 1,
            indent: 10,
            endIndent: 5,
            color: Color.fromARGB(255, 191, 191, 191),
          ),
        ),
        SizedBox(
          width: width * 0.02,
        ),
        Text(
          DateFormat('dd MMM yyyy').format(date),
          style: GoogleFonts.poppins(
            fontSize: width * 0.05,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(
          width: width * 0.02,
        ),
        const Expanded(
          child: Divider(
            height: 1,
            indent: 5,
            endIndent: 10,
            color: Color.fromARGB(255, 191, 191, 191),
          ),
        ),
      ],
    ),
  );
}

// create a payment history card
Widget paymentCard(
    {required String plan,
    required String mode,
    required DateTime date,
    required int time,
    required int amount,
    required int balance,
    required double width,
    required double height,
    required bool advancedPayment}) {
  DateTime timex = DateTime.fromMillisecondsSinceEpoch(time);
  String dateText =
      "Entered: ${DateFormat('dd/MM/yyyy hh mm a').format(timex)}";
  // check if timex is same as date
  if (timex.day == date.day &&
      timex.month == date.month &&
      timex.year == date.year) {
    dateText = "Time: ${DateFormat.jm().format(timex)}";
  }
  return Card(
    elevation: 5,
    margin: EdgeInsets.all(width * 0.04),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15.0),
    ),
    child: Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.0),
          gradient: const LinearGradient(
            colors: [
              Colors.green,
              Colors.blue,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
            vertical: height * 0.03, horizontal: width * 0.06),
        title: Text(
          "Program: $plan",
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white70,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (advancedPayment)
              Text(
                "Advanced Payment",
                style: GoogleFonts.raleway(
                  color: Colors.white70,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            Text(
              "Mode: $mode",
              style: GoogleFonts.raleway(
                color: Colors.white70,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              // in am/pm format from ms
              dateText,
              style: GoogleFonts.montserrat(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'Paid: \u20B9 $amount',
              style: GoogleFonts.montserrat(
                color: Colors.white70,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'C. Balance: \u20B9 $balance',
              style: GoogleFonts.montserrat(
                color: Colors.white70,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}


// String formatDate(DateTime dateTime) {
//   final DateFormat formatter = DateFormat('dd MMM yyyy');
//   final String formatted = formatter.format(dateTime);
//   return formatted;
// }
