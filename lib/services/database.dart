import 'package:cloud_firestore/cloud_firestore.dart';

class Database {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final CollectionReference scores =
      FirebaseFirestore.instance.collection('scores');
  final CollectionReference videos =
      FirebaseFirestore.instance.collection('videos');
  final CollectionReference cheese =
      FirebaseFirestore.instance.collection('cheese');

  Future<QuerySnapshot> getPaginatedDocs(String key, dynamic startAt, int limit,
      {bool descending = false}) async {
    if (descending) {
      QuerySnapshot lowestRank =
          await scores.orderBy(key, descending: true).limit(1).get();
      int rank = lowestRank.docs.first.data()[key];
      int start = rank - (startAt - 1);
      return scores
          .orderBy(key, descending: true)
          .startAt([start])
          .limit(limit)
          .get();
    }
    return scores
        .orderBy(key, descending: false)
        .startAt([startAt])
        .limit(limit)
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
