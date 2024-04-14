import 'package:another_flushbar/flushbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

import 'package:flutter/material.dart';
import '../components/ui/appbar.dart';

class CustMedHist extends StatefulWidget {
  const CustMedHist({
    Key? key,
    required this.name,
    required this.medicalhistory,
    required this.uid,
    required this.callback,
  }) : super(key: key);

  final String name;
  final List medicalhistory;
  final String uid;
  final VoidCallback callback;

  @override
  State<CustMedHist> createState() => _CustMedHistState();
}

class _CustMedHistState extends State<CustMedHist> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  late List medicalHistoryList = List.from(widget.medicalhistory);
  late List originalList = List.from(widget.medicalhistory);

  void addCard(String newCard) {
    setState(() {
      medicalHistoryList.add(newCard);
    });
  }

  void editCard(int index, String newValue) {
    setState(() {
      medicalHistoryList[index] = newValue;
    });
  }

  void deleteCard(int index) {
    setState(() {
      medicalHistoryList.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Colors.white,
      appBar: MyAppBar(
        title: 'Medical History of ${widget.name}',
        leftIcon: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: Colors.black26,
          onPressed: () => Navigator.pop(context),
        ),
        rightIcons: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            color: Colors.black26,
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AddDialog(
                  onAdd: addCard,
                ),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: medicalHistoryList.length,
        itemBuilder: (context, index) {
          final historyItem = medicalHistoryList[index];

          return Card(
            margin: EdgeInsets.symmetric(
              vertical: height * 0.01,
              horizontal: width * 0.05,
            ),
            child: ListTile(
              title: Text(historyItem),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_rounded),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => EditDialog(
                          initialValue: historyItem,
                          onEdit: (newValue) => editCard(index, newValue),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_rounded),
                    onPressed: () {
                      deleteCard(index);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
      // if Original List is not != Medical History List
      floatingActionButton:
          originalList.toString() != medicalHistoryList.toString()
              ? FloatingActionButton(
                  onPressed: () async {
                    // save to firestore
                    try {
                      if (!await Method.checkInternetConnection(context)) {
                        return;
                      }
                      final userRef = FirebaseDatabase.instance
                          .ref()
                          .child('Coaches')
                          .child(FirebaseAuth.instance.currentUser!.uid)
                          .child('users')
                          .child(widget.uid);
                      await userRef.update({
                        'medicalHistory': medicalHistoryList,
                      });
                      widget.callback();
                      Navigator.pop(scaffoldKey.currentContext!);
                      Navigator.pop(scaffoldKey.currentContext!);
                      return Flushbar(
                        margin: const EdgeInsets.all(7),
                        borderRadius: BorderRadius.circular(15),
                        flushbarStyle: FlushbarStyle.FLOATING,
                        flushbarPosition: FlushbarPosition.BOTTOM,
                        message: "User data updated successfully",
                        icon: Icon(
                          Icons.check_circle_outline_rounded,
                          size: 28.0,
                          color: Colors.green[300],
                        ),
                        duration: const Duration(milliseconds: 1500),
                        leftBarIndicatorColor: Colors.green[300],
                      ).show(scaffoldKey.currentContext!);
                    } catch (error) {
                      debugPrint('Error updating user properties: $error');
                    }
                  },
                  child: const Icon(Icons.save),
                )
              : null,
    );
  }
}

class AddDialog extends StatefulWidget {
  const AddDialog({Key? key, required this.onAdd}) : super(key: key);

  final ValueChanged<String> onAdd;

  @override
  State<AddDialog> createState() => _AddDialogState();
}

class _AddDialogState extends State<AddDialog> {
  late TextEditingController _textEditingController;

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Card'),
      content: TextField(
        controller: _textEditingController,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final newCard = _textEditingController.text;
            widget.onAdd(newCard);
            Navigator.pop(context);
          },
          child: const Text('Add'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }
}

class EditDialog extends StatefulWidget {
  const EditDialog({
    Key? key,
    required this.initialValue,
    required this.onEdit,
  }) : super(key: key);

  final String initialValue;
  final ValueChanged<String> onEdit;

  @override
  State<EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<EditDialog> {
  late TextEditingController _textEditingController;

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController(text: widget.initialValue);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Card'),
      content: TextField(
        controller: _textEditingController,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            widget.onEdit(_textEditingController.text);
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }
}
