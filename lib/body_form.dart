import 'package:flutter/material.dart';
import 'body_form_1.dart';
import 'body_form_2.dart';

class FormPage extends StatefulWidget {
  const FormPage({super.key});

  @override
  State<FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  final PageController _pageController = PageController(initialPage: 0);
  bool notChangePage = false;

  void handleChangePage(bool newValue) {
    setState(() {
      notChangePage = newValue;
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
      body: PageView(
        controller: _pageController,
        physics: notChangePage
            ? const NeverScrollableScrollPhysics()
            : const BouncingScrollPhysics(),
        children: [
          BodyForm(
            pageChange: (bool value) {
              handleChangePage(value);
            },
          ),
          const BodyForm2()
        ],
      ),
    );
  }
}
