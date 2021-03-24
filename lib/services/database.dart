import 'package:cloud_firestore/cloud_firestore.dart';

class Database {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final CollectionReference scores =
      FirebaseFirestore.instance.collection('scores');
  final CollectionReference videos =
      FirebaseFirestore.instance.collection('videos');
  final CollectionReference cheese =
      FirebaseFirestore.instance.collection('cheese');

  Future<QuerySnapshot> getScoreDocs(int startRank, int endRank) async {
    return scores
        .where('rank', isGreaterThanOrEqualTo: startRank)
        .where('rank', isLessThanOrEqualTo: endRank)
        .get();
  }

  Future<QuerySnapshot> getVideoDocs() async {
    return videos.get();
  }

  Future<Map<String, dynamic>> getHighScores() async {
    var scoresDoc = cheese.doc('high_scores');
    var scoresSnapshot = await scoresDoc.get();

    return {
      'galactic_search': scoresSnapshot.data()['galactic_search'],
      'auto_nav': scoresSnapshot.data()['auto_nav'],
      'hyperdrive': scoresSnapshot.data()['hyperdrive'],
      'interstellar': scoresSnapshot.data()['interstellar'],
      'powerport': scoresSnapshot.data()['powerport']
    };
  }
}
