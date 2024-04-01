// import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../components/ui/appbar.dart';

class CustPlanHist extends StatelessWidget {
  final String name;
  final List<Map<String, dynamic>> plans;
  const CustPlanHist({Key? key, required this.name, required this.plans})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
        appBar: MyAppBar(
          title: 'Payments of $name',
          leftIcon: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            color: Colors.black26,
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Container(
          margin: EdgeInsets.all(width * 0.02),
          width: width,
          child: ListView.builder(
            itemCount: plans.length,
            itemBuilder: (context, index) {
              return paymentCard(
                name: plans[index]['name'],
                plan: plans[index]['plan'],
                date: plans[index]['date'],
                amount: plans[index]['amount'],
                width: width,
                height: height,
              );
            },
          ),
        ));
  }
}

// create a payment history card
Widget paymentCard(
    {required String name,
    required String plan,
    required DateTime date,
    required int amount,
    required double width,
    required double height}) {
  return Column(
    children: [
      Container(
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
              formatDate(date),
              style: GoogleFonts.poppins(
                fontSize: 16,
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
      ),
      Card(
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
              "Program: $name",
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Mode: $plan",
                  style: GoogleFonts.raleway(
                    color: Colors.white70,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  // in am/pm format
                  "Time: ${DateFormat.jm().format(date)}",
                  style: GoogleFonts.raleway(
                    color: Colors.white70,
                    fontSize: 15,
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
                  'C. Balance: \u20B9 $amount',
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
      ),
    ],
  );
}

String formatDate(DateTime dateTime) {
  final DateFormat formatter = DateFormat('dd MMM yyyy');
  final String formatted = formatter.format(dateTime);
  return formatted;
}
