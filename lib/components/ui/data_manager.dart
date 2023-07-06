import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DataManager {
  static Stream<QuerySnapshot<Map<String, dynamic>>> getLatestUserDataStream() {
    return FirebaseFirestore.instance
        .collection("Users")
        .where('cid', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .snapshots();
  }
}
