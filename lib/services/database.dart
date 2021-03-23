import 'package:cloud_firestore/cloud_firestore.dart';

class Database {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final CollectionReference scores =
      FirebaseFirestore.instance.collection('scores');
  final CollectionReference videos =
      FirebaseFirestore.instance.collection('videos');

  Future<QuerySnapshot> getScoreDocs() async {
    return scores.get();
  }

  Future<QuerySnapshot> getVideoDocs() async {
    return videos.get();
  }
}
