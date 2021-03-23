import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:frc_leaderboard/services/database.dart';
import 'package:url_launcher/url_launcher.dart';

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

    widget.db.getScoreDocs().then((querySnapshot) async {
      var scores = [];
      QuerySnapshot vidSnapshot = await widget.db.getVideoDocs();
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

        var revealVid;
        var galacticVid;
        var autoNavVid;
        var hyperdriveVid;
        var interstellarVid;
        var powerportVid;

        for (var vidDoc in vidSnapshot.docs) {
          if (int.parse(vidDoc.id) == team) {
            revealVid = vidDoc.data()['reveal'];
            galacticVid = vidDoc.data()['galactic_search'];
            autoNavVid = vidDoc.data()['auto_nav'];
            hyperdriveVid = vidDoc.data()['hyperdrive'];
            interstellarVid = vidDoc.data()['interstellar'];
            powerportVid = vidDoc.data()['powerport'];

            break;
          }
        }

        scores.add({
          'team': team,
          'rank': rank,
          'galactic_search': galactic_search,
          'auto_nav': auto_nav,
          'hyperdrive': hyperdrive,
          'interstellar': interstellar,
          'powerport': powerport,
          'reveal_vid': revealVid,
          'galactic_search_vid': galacticVid,
          'auto_nav_vid': autoNavVid,
          'hyperdrive_vid': hyperdriveVid,
          'interstellar_vid': interstellarVid,
          'powerport_vid': powerportVid
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
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Image(
                image: AssetImage('images/logo.png'),
                width: 60,
              ),
            ),
            Text('Infinite Recharge at Home Global Leaderboard'),
          ],
        ),
        backgroundColor: Colors.indigo,
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
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
        ),
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
      var galacticText = Text(score['galactic_search'].toString() +
          (score['galactic_search'] == _bestGalactic ? ' ⭐' : ''));
      var autoNavText = Text(score['auto_nav'].toString() +
          (score['auto_nav'] == _bestAuto ? ' ⭐' : ''));
      var hyperdriveText = Text(score['hyperdrive'].toString() +
          (score['hyperdrive'] == _bestHyper ? ' ⭐' : ''));
      var interstellarText = Text(score['interstellar'].toString() +
          (score['interstellar'] == _bestInter ? ' ⭐' : ''));
      var powerportText = Text(score['powerport'].toString() +
          (score['powerport'] == _bestPower ? ' ⭐' : ''));

      rows.add(DataRow(cells: <DataCell>[
        DataCell(Center(child: Text(score['rank'].toString()))),
        DataCell(score['reveal_vid'] != null
            ? Center(
                child: TextButton(
                  child: Text(score['team'].toString()),
                  onPressed: () async {
                    if (await canLaunch(score['reveal_vid'])) {
                      await launch(score['reveal_vid']);
                    }
                  },
                ),
              )
            : Center(child: Text(score['team'].toString()))),
        DataCell(score['galactic_search_vid'] != null
            ? Center(
                child: TextButton(
                  child: galacticText,
                  onPressed: () async {
                    if (await canLaunch(score['galactic_search_vid'])) {
                      await launch(score['galactic_search_vid']);
                    }
                  },
                ),
              )
            : Center(child: galacticText)),
        DataCell(score['auto_nav_vid'] != null
            ? Center(
                child: TextButton(
                  child: autoNavText,
                  onPressed: () async {
                    if (await canLaunch(score['auto_nav_vid'])) {
                      await launch(score['auto_nav_vid']);
                    }
                  },
                ),
              )
            : Center(child: autoNavText)),
        DataCell(score['hyperdrive_vid'] != null
            ? Center(
                child: TextButton(
                  child: hyperdriveText,
                  onPressed: () async {
                    if (await canLaunch(score['hyperdrive_vid'])) {
                      await launch(score['hyperdrive_vid']);
                    }
                  },
                ),
              )
            : Center(child: hyperdriveText)),
        DataCell(score['interstellar_vid'] != null
            ? Center(
                child: TextButton(
                  child: interstellarText,
                  onPressed: () async {
                    if (await canLaunch(score['interstellar_vid'])) {
                      await launch(score['interstellar_vid']);
                    }
                  },
                ),
              )
            : Center(child: interstellarText)),
        DataCell(score['powerport_vid'] != null
            ? Center(
                child: TextButton(
                  child: powerportText,
                  onPressed: () async {
                    if (await canLaunch(score['powerport_vid'])) {
                      await launch(score['powerport_vid']);
                    }
                  },
                ),
              )
            : Center(child: powerportText)),
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
                        label: Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: Text('Global Rank'),
                        ),
                        onSort: (columnIndex, sortAscending) {
                          setState(() {
                            _sortCol = columnIndex;
                            _sortAscending = sortAscending;

                            sortScores('rank');
                          });
                        }),
                    DataColumn(
                        label: Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: Text('Team Number'),
                        ),
                        onSort: (columnIndex, sortAscending) {
                          setState(() {
                            _sortCol = columnIndex;
                            _sortAscending = sortAscending;

                            sortScores('team');
                          });
                        }),
                    DataColumn(
                        label: Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: Text('Galactic Search'),
                        ),
                        onSort: (columnIndex, sortAscending) {
                          setState(() {
                            _sortCol = columnIndex;
                            _sortAscending = sortAscending;

                            sortScores('galactic_search');
                          });
                        }),
                    DataColumn(
                        label: Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: Text('Auto-Nav'),
                        ),
                        onSort: (columnIndex, sortAscending) {
                          setState(() {
                            _sortCol = columnIndex;
                            _sortAscending = sortAscending;

                            sortScores('auto_nav');
                          });
                        }),
                    DataColumn(
                        label: Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: Text('Hyperdrive'),
                        ),
                        onSort: (columnIndex, sortAscending) {
                          setState(() {
                            _sortCol = columnIndex;
                            _sortAscending = sortAscending;

                            sortScores('hyperdrive');
                          });
                        }),
                    DataColumn(
                        label: Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: Text('Interstellar Accuracy'),
                        ),
                        onSort: (columnIndex, sortAscending) {
                          setState(() {
                            _sortCol = columnIndex;
                            _sortAscending = sortAscending;

                            sortScores('interstellar', lowerIsBetter: false);
                          });
                        }),
                    DataColumn(
                        label: Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: Text('Power Port'),
                        ),
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
