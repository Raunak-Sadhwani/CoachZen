import 'dart:convert';

import 'package:flutter/material.dart';
import 'body_form_1.dart';
import 'body_form_2.dart';

class FormPage extends StatefulWidget {
  const FormPage({Key? key}) : super(key: key);

  @override
  State<FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  final controller = PageController();
  int currentPage = 0;
  int totalPages = 2;
  bool notChangePage = false;

  void handleChangePage(bool newValue) {
    setState(() {
      notChangePage = newValue;
    });
  }

  void onSubmit(List<Map<String, dynamic>> fields) {
    dynamic data = [];
    for (var field in fields) {
      dynamic value = field['controller'].text;
      if (int.tryParse(field['controller'].text) != null) {
        value = int.parse(field['controller'].text);
      } else if (double.tryParse(field['controller'].text) != null) {
        value = double.parse(field['controller'].text);
      } else {
        value = field['controller'].text;
      }
      String label = field['label'];
      // json
      data.add({
        label: value,
      });
    }
    data = jsonEncode(data);
    print(data);
  }

  @override
  void initState() {
    super.initState();
    controller.addListener(() {
      setState(() {
        currentPage = controller.page?.round() ?? 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          color: Colors.black26,
          onPressed: () {},
        ),
        title: const Text(
          'Body Form',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          NotificationListener<OverscrollIndicatorNotification>(
            onNotification: (overscroll) {
              overscroll.disallowIndicator();
              return true;
            },
            child: PageView(
              controller: controller,
              physics: notChangePage
                  ? const NeverScrollableScrollPhysics()
                  : const PageScrollPhysics(),
              children: [
                BodyForm(
                  pageChange: (bool value) {
                    handleChangePage(value);
                  },
                ),
                BodyForm2(onSubmit: onSubmit)
              ],
            ),
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                totalPages,
                (index) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: currentPage == index
                        ? Colors.blue
                        : Colors.grey.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     if (currentPage == 0) {
      //       controller.animateToPage(
      //         1,
      //         duration: const Duration(milliseconds: 300),
      //         curve: Curves.easeInOut,
      //       );
      //     } else {
      //       controller.animateToPage(
      //         0,
      //         duration: const Duration(milliseconds: 300),
      //         curve: Curves.easeInOut,
      //       );
      //     }
      //   },
      //   child: const Icon(Icons.arrow_forward),
      // ),
    );
  }
}
