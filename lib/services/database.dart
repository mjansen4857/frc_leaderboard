import 'package:cloud_firestore/cloud_firestore.dart';

class Database {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final CollectionReference scores =
      FirebaseFirestore.instance.collection('scores');

  Future<QuerySnapshot> getScoreDocs() async {
    return scores.get();
  }
}
