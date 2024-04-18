// ignore_for_file: use_build_context_synchronously

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<bool> checkPassword(context, String cid) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final bool? isPassword = prefs.getBool('isPassword');
  if (isPassword != null && !isPassword) {
    return true;
  }
  TextEditingController password = TextEditingController();
  bool isSubmitted = false;
  bool isCorrect = false;
  // show dialog
  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Enter Password'),
        content: TextField(
          controller: password,
          obscureText: true,
          decoration: const InputDecoration(hintText: 'Password'),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Submit'),
            onPressed: () async {
              if (!isSubmitted && (password.text.length > 6)) {
                isSubmitted = true;
                // check password
                try {
                  final dbRef =
                      FirebaseDatabase.instance.ref().child('Coaches');
                  await dbRef
                      .child(cid)
                      .child('password')
                      .once()
                      .then((DatabaseEvent event) {
                    if (event.snapshot.value.toString() == password.text) {
                      isCorrect = true;
                    }
                  });
                  // ignore: empty_catches
                } catch (e) {}
              }
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
  if (!isCorrect) {
    Flushbar(
      margin: const EdgeInsets.all(7),
      borderRadius: BorderRadius.circular(15),
      flushbarStyle: FlushbarStyle.FLOATING,
      flushbarPosition: FlushbarPosition.BOTTOM,
      message: "Incorrect Password!",
      icon: Icon(
        Icons.error_outline,
        size: 28.0,
        color: Colors.red[300],
      ),
      duration: const Duration(milliseconds: 2000),
      leftBarIndicatorColor: Colors.red[300],
    ).show(context);
  }
  return isCorrect;
}
