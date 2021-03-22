import 'package:flutter/material.dart';
import 'package:frc_leaderboard/services/database.dart';

class LeaderboardPage extends StatefulWidget {
  final Database db;

  LeaderboardPage({Key key, this.db}) : super(key: key);

  @override
  _LeaderboardPageState createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  var _scores = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    widget.db.getScoreDocs().then((querySnapshot) {
      var scores = [];
      for (var doc in querySnapshot.docs) {
        int team = int.parse(doc.id);
        double galactic_search = doc.data()['galactic_search'];
        double auto_nav = doc.data()['auto_nav'];
        double hyperdrive = doc.data()['hyperdrive'];
        double interstellar = doc.data()['interstellar'];
        double powerport = doc.data()['powerport'];

        scores.add({
          'team': team,
          'galactic_search': galactic_search,
          'auto_nav': auto_nav,
          'hyperdrive': hyperdrive,
          'interstellar': interstellar,
          'powerport': powerport
        });
      }
      setState(() {
        _isLoading = false;
        _scores = scores;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Recharge at Home Global Leaderboard"),
      ),
      body: Stack(
        children: [
          showLoading(),
          buildTable(),
        ],
      ),
    );
  }

  Widget showLoading() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }
    return Container(
      height: 0.0,
      width: 0.0,
    );
  }

  List<DataRow> getDataRows() {
    List<DataRow> rows = [];
    for (var score in _scores) {
      rows.add(DataRow(cells: <DataCell>[
        DataCell(Text('?')),
        DataCell(Text(score['team'].toString())),
        DataCell(Text(score['galactic_search'].toString())),
        DataCell(Text(score['auto_nav'].toString())),
        DataCell(Text(score['hyperdrive'].toString())),
        DataCell(Text(score['interstellar'].toString())),
        DataCell(Text(score['powerport'].toString())),
      ]));
    }
    return rows;
  }

  Widget buildTable() {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0),
      child: ListView(
        children: [
          Container(
            alignment: Alignment.center,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(columns: <DataColumn>[
                DataColumn(label: Text('Global Rank')),
                DataColumn(label: Text('Team Number')),
                DataColumn(label: Text('Galactic Search')),
                DataColumn(label: Text('Auto Nav')),
                DataColumn(label: Text('Hyperdrive')),
                DataColumn(label: Text('Interstellar Accuracy')),
                DataColumn(label: Text('Power Port')),
              ], rows: getDataRows()),
            ),
          )
        ],
      ),
    );
  }
}
