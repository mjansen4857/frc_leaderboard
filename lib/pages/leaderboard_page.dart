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
  int _sortCol = 0;
  bool _sortAscending = true;
  double _bestGalactic = double.infinity;
  double _bestAuto = double.infinity;
  double _bestHyper = double.infinity;
  double _bestInter = 0;
  double _bestPower = 0;

  @override
  void initState() {
    super.initState();

    widget.db.getScoreDocs().then((querySnapshot) {
      var scores = [];
      for (var doc in querySnapshot.docs) {
        int team = int.parse(doc.id);
        int rank = doc.data()['rank'];
        double galactic_search = doc.data()['galactic_search'];
        if (galactic_search < _bestGalactic && galactic_search != 0)
          _bestGalactic = galactic_search;
        double auto_nav = doc.data()['auto_nav'];
        if (auto_nav < _bestAuto && auto_nav != 0) _bestAuto = auto_nav;
        double hyperdrive = doc.data()['hyperdrive'];
        if (hyperdrive < _bestHyper && hyperdrive != 0) _bestHyper = hyperdrive;
        double interstellar = doc.data()['interstellar'];
        if (interstellar > _bestInter && interstellar != 0)
          _bestInter = interstellar;
        double powerport = doc.data()['powerport'];
        if (powerport > _bestPower && powerport != 0) _bestPower = powerport;

        scores.add({
          'team': team,
          'rank': rank,
          'galactic_search': galactic_search,
          'auto_nav': auto_nav,
          'hyperdrive': hyperdrive,
          'interstellar': interstellar,
          'powerport': powerport
        });
      }
      scores.sort((a, b) => a['rank'].compareTo(b['rank']));
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
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('⭐ = High Score'),
            ],
          ),
        ),
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
        DataCell(Text(score['rank'].toString())),
        DataCell(Text(score['team'].toString())),
        DataCell(Text(score['galactic_search'].toString() +
            (score['galactic_search'] == _bestGalactic ? ' ⭐' : ''))),
        DataCell(Text(score['auto_nav'].toString() +
            (score['auto_nav'] == _bestAuto ? ' ⭐' : ''))),
        DataCell(Text(score['hyperdrive'].toString() +
            (score['hyperdrive'] == _bestHyper ? ' ⭐' : ''))),
        DataCell(Text(score['interstellar'].toString() +
            (score['interstellar'] == _bestInter ? ' ⭐' : ''))),
        DataCell(Text(score['powerport'].toString() +
            (score['powerport'] == _bestPower ? ' ⭐' : ''))),
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
              child: DataTable(
                  sortColumnIndex: _sortCol,
                  sortAscending: _sortAscending,
                  columns: <DataColumn>[
                    DataColumn(
                        label: Text('Global Rank'),
                        onSort: (columnIndex, sortAscending) {
                          setState(() {
                            _sortCol = columnIndex;
                            _sortAscending = sortAscending;

                            sortScores('rank');
                          });
                        }),
                    DataColumn(
                        label: Text('Team Number'),
                        onSort: (columnIndex, sortAscending) {
                          setState(() {
                            _sortCol = columnIndex;
                            _sortAscending = sortAscending;

                            sortScores('team');
                          });
                        }),
                    DataColumn(
                        label: Text('Galactic Search'),
                        onSort: (columnIndex, sortAscending) {
                          setState(() {
                            _sortCol = columnIndex;
                            _sortAscending = sortAscending;

                            sortScores('galactic_search');
                          });
                        }),
                    DataColumn(
                        label: Text('Auto Nav'),
                        onSort: (columnIndex, sortAscending) {
                          setState(() {
                            _sortCol = columnIndex;
                            _sortAscending = sortAscending;

                            sortScores('auto_nav');
                          });
                        }),
                    DataColumn(
                        label: Text('Hyperdrive'),
                        onSort: (columnIndex, sortAscending) {
                          setState(() {
                            _sortCol = columnIndex;
                            _sortAscending = sortAscending;

                            sortScores('hyperdrive');
                          });
                        }),
                    DataColumn(
                        label: Text('Interstellar Accuracy'),
                        onSort: (columnIndex, sortAscending) {
                          setState(() {
                            _sortCol = columnIndex;
                            _sortAscending = sortAscending;

                            sortScores('interstellar', lowerIsBetter: false);
                          });
                        }),
                    DataColumn(
                        label: Text('Power Port'),
                        onSort: (columnIndex, sortAscending) {
                          setState(() {
                            _sortCol = columnIndex;
                            _sortAscending = sortAscending;

                            sortScores('powerport', lowerIsBetter: false);
                          });
                        }),
                  ],
                  rows: getDataRows()),
            ),
          )
        ],
      ),
    );
  }

  int sortScores(String key, {bool lowerIsBetter = true}) {
    _scores.sort((a, b) {
      if (lowerIsBetter) {
        if (a[key] == 0) {
          return 1;
        }
        if (b[key] == 0) {
          return -1;
        }
      }
      return a[key].compareTo(b[key]);
    });

    if (!_sortAscending) {
      _scores = _scores.reversed.toList();
    }
  }
}
