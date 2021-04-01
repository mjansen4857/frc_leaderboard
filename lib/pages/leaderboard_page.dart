import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:frc_leaderboard/services/database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

enum RankMode { best3, overall }
enum ScoreMode { rawScore, computedScore, rank }

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
  int _startRow = 1;
  int _rowsPerPage = 50;
  String _currentSortKey = 'rank';
  QuerySnapshot _vidSnapshot;
  bool _paginated = true;
  String _searchKey;
  RankMode _rankMode = RankMode.best3;
  ScoreMode _scoreMode = ScoreMode.rawScore;
  SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((val) {
      _prefs = val;
      String savedRankMode = _prefs.getString('rankMode');
      widget.db.getVideoDocs().then((vidSnap) {
        _vidSnapshot = vidSnap;
        widget.db.getHighScores().then((highScores) {
          _bestGalactic = highScores['galactic_search'];
          _bestAuto = highScores['auto_nav'];
          _bestHyper = highScores['hyperdrive'];
          _bestInter = highScores['interstellar'];
          _bestPower = highScores['powerport'];

          _startRow = 1;
          _paginated = true;
          if (savedRankMode == 'RankMode.best3' || savedRankMode == null) {
            _rankMode = RankMode.best3;
            _currentSortKey = 'rank';
          } else {
            _rankMode = RankMode.overall;
            _currentSortKey = 'rank_5';
          }
          getPaginatedTableData();
        });
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
            Text('IRH Leaderboard'),
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
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              child: Text(''),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                image: DecorationImage(
                  image: AssetImage('images/ir_logo2.png'),
                  fit: BoxFit.fitHeight,
                ),
              ),
            ),
            ListTile(
              title: Text('Rank Mode'),
            ),
            RadioListTile(
                title: Text('Best 3 Scores'),
                activeColor: Colors.indigoAccent,
                value: RankMode.best3,
                groupValue: _rankMode,
                onChanged: (RankMode mode) {
                  setState(() {
                    _rankMode = mode;
                    _prefs.setString('rankMode', mode.toString());
                    if (_currentSortKey == 'rank_5') {
                      _isLoading = true;
                      _currentSortKey = 'rank';
                      _scores = [];
                      getPaginatedTableData(descending: !_sortAscending);
                    }
                  });
                }),
            RadioListTile(
                title: Text('Overall Performance'),
                activeColor: Colors.indigoAccent,
                value: RankMode.overall,
                groupValue: _rankMode,
                onChanged: (RankMode mode) {
                  setState(() {
                    _rankMode = mode;
                    _prefs.setString('rankMode', mode.toString());
                    if (_currentSortKey == 'rank') {
                      _isLoading = true;
                      _currentSortKey = 'rank_5';
                      _scores = [];
                      getPaginatedTableData(descending: !_sortAscending);
                    }
                  });
                }),
            Divider(),
            ListTile(
              title: Text('Score Display Mode'),
            ),
            RadioListTile(
                title: Text('Raw Score'),
                activeColor: Colors.indigoAccent,
                value: ScoreMode.rawScore,
                groupValue: _scoreMode,
                onChanged: (ScoreMode mode) {
                  setState(() {
                    _scoreMode = mode;
                  });
                }),
            RadioListTile(
                title: Text('Computed Score'),
                activeColor: Colors.indigoAccent,
                value: ScoreMode.computedScore,
                groupValue: _scoreMode,
                onChanged: (ScoreMode mode) {
                  setState(() {
                    _scoreMode = mode;
                  });
                }),
            RadioListTile(
                title: Text('Challenge Rank'),
                activeColor: Colors.indigoAccent,
                value: ScoreMode.rank,
                groupValue: _scoreMode,
                onChanged: (ScoreMode mode) {
                  setState(() {
                    _scoreMode = mode;
                  });
                }),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8.0, 12, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              buildTeamSearch(),
              Visibility(
                child: buildPageButtons(),
                visible: _paginated,
              ),
              SizedBox(
                width: 205,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String getRankKey() {
    if (_rankMode == RankMode.best3) {
      return 'rank';
    } else {
      return 'rank_5';
    }
  }

  String getChangeKey() {
    if (_rankMode == RankMode.best3) {
      return 'change';
    } else {
      return 'change_5';
    }
  }

  void getSearchTableData(String searchKey, {bool descending = false}) {
    if (int.tryParse(searchKey) != null) {
      widget.db.getSingleTeamDoc(searchKey).then((doc) {
        var scores = [];

        if (doc.exists) {
          int team = int.parse(doc.id);
          int rank = doc.data()['rank'];
          double galactic_search = doc.data()['galactic_search'];
          double auto_nav = doc.data()['auto_nav'];
          double hyperdrive = doc.data()['hyperdrive'];
          double interstellar = doc.data()['interstellar'];
          double powerport = doc.data()['powerport'];
          int change = doc.data()['change'];

          var revealVid;
          var galacticVid;
          var autoNavVid;
          var hyperdriveVid;
          var interstellarVid;
          var powerportVid;

          for (var vidDoc in _vidSnapshot.docs) {
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
            'rank_5': doc.data()['rank_5'],
            'change': change,
            'change_5': doc.data()['change_5'],
            'galactic_search': galactic_search,
            'computed_galactic': doc.data()['computed_galactic'],
            'galactic_rank': doc.data()['galactic_rank'],
            'auto_nav': auto_nav,
            'computed_auto': doc.data()['computed_auto'],
            'auto_rank': doc.data()['auto_rank'],
            'hyperdrive': hyperdrive,
            'computed_hyperdrive': doc.data()['computed_hyperdrive'],
            'hyper_rank': doc.data()['hyper_rank'],
            'interstellar': interstellar,
            'computed_interstellar': doc.data()['computed_interstellar'],
            'inter_rank': doc.data()['inter_rank'],
            'powerport': powerport,
            'computed_powerport': doc.data()['computed_powerport'],
            'power_rank': doc.data()['power_rank'],
            'reveal_vid': revealVid,
            'galactic_search_vid': galacticVid,
            'auto_nav_vid': autoNavVid,
            'hyperdrive_vid': hyperdriveVid,
            'interstellar_vid': interstellarVid,
            'powerport_vid': powerportVid
          });
        }

        setState(() {
          _isLoading = false;
          _scores = scores;
          _paginated = false;
        });
      });
    } else {
      widget.db
          .getGroupDocs(searchKey, _currentSortKey, descending: descending)
          .then((querySnapshot) {
        var scores = [];

        for (var doc in querySnapshot.docs) {
          int team = int.parse(doc.id);
          int rank = doc.data()['rank'];
          double galactic_search = doc.data()['galactic_search'];
          double auto_nav = doc.data()['auto_nav'];
          double hyperdrive = doc.data()['hyperdrive'];
          double interstellar = doc.data()['interstellar'];
          double powerport = doc.data()['powerport'];
          int change = doc.data()['change'];

          var revealVid;
          var galacticVid;
          var autoNavVid;
          var hyperdriveVid;
          var interstellarVid;
          var powerportVid;

          for (var vidDoc in _vidSnapshot.docs) {
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
            'rank_5': doc.data()['rank_5'],
            'change': change,
            'change_5': doc.data()['change_5'],
            'galactic_search': galactic_search,
            'computed_galactic': doc.data()['computed_galactic'],
            'galactic_rank': doc.data()['galactic_rank'],
            'auto_nav': auto_nav,
            'computed_auto': doc.data()['computed_auto'],
            'auto_rank': doc.data()['auto_rank'],
            'hyperdrive': hyperdrive,
            'computed_hyperdrive': doc.data()['computed_hyperdrive'],
            'hyper_rank': doc.data()['hyper_rank'],
            'interstellar': interstellar,
            'computed_interstellar': doc.data()['computed_interstellar'],
            'inter_rank': doc.data()['inter_rank'],
            'powerport': powerport,
            'computed_powerport': doc.data()['computed_powerport'],
            'power_rank': doc.data()['power_rank'],
            'reveal_vid': revealVid,
            'galactic_search_vid': galacticVid,
            'auto_nav_vid': autoNavVid,
            'hyperdrive_vid': hyperdriveVid,
            'interstellar_vid': interstellarVid,
            'powerport_vid': powerportVid
          });
        }

        setState(() {
          _isLoading = false;
          _scores = scores;
          _paginated = false;
        });
      });
    }
  }

  void getPaginatedTableData({bool descending = false}) {
    widget.db
        .getPaginatedDocs(_currentSortKey, _startRow, _rowsPerPage,
            descending: descending)
        .then((querySnapshot) async {
      var scores = [];

      for (var doc in querySnapshot.docs) {
        int team = int.parse(doc.id);
        int rank = doc.data()['rank'];
        double galactic_search = doc.data()['galactic_search'];
        double auto_nav = doc.data()['auto_nav'];
        double hyperdrive = doc.data()['hyperdrive'];
        double interstellar = doc.data()['interstellar'];
        double powerport = doc.data()['powerport'];
        int change = doc.data()['change'];

        var revealVid;
        var galacticVid;
        var autoNavVid;
        var hyperdriveVid;
        var interstellarVid;
        var powerportVid;

        for (var vidDoc in _vidSnapshot.docs) {
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
          'rank_5': doc.data()['rank_5'],
          'change': change,
          'change_5': doc.data()['change_5'],
          'galactic_search': galactic_search,
          'computed_galactic': doc.data()['computed_galactic'],
          'galactic_rank': doc.data()['galactic_rank'],
          'auto_nav': auto_nav,
          'computed_auto': doc.data()['computed_auto'],
          'auto_rank': doc.data()['auto_rank'],
          'hyperdrive': hyperdrive,
          'computed_hyperdrive': doc.data()['computed_hyperdrive'],
          'hyper_rank': doc.data()['hyper_rank'],
          'interstellar': interstellar,
          'computed_interstellar': doc.data()['computed_interstellar'],
          'inter_rank': doc.data()['inter_rank'],
          'powerport': powerport,
          'computed_powerport': doc.data()['computed_powerport'],
          'power_rank': doc.data()['power_rank'],
          'reveal_vid': revealVid,
          'galactic_search_vid': galacticVid,
          'auto_nav_vid': autoNavVid,
          'hyperdrive_vid': hyperdriveVid,
          'interstellar_vid': interstellarVid,
          'powerport_vid': powerportVid
        });
      }

      setState(() {
        _isLoading = false;
        _scores = scores;
        _paginated = true;
      });
    });
  }

  Widget buildTeamSearch() {
    return Row(
      children: [
        (_searchKey == null)
            ? IconButton(
                icon: Icon(Icons.search),
                onPressed: null,
              )
            : IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _scores = [];
                    _sortCol = 0;
                    _sortAscending = true;
                    _searchKey = null;
                    _currentSortKey = getRankKey();
                    _isLoading = true;
                    getPaginatedTableData();
                  });
                },
              ),
        Padding(
          padding: const EdgeInsets.only(left: 10.0),
          child: SizedBox(
            width: 145,
            height: 40,
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Team # or Group Code',
                labelStyle: TextStyle(fontSize: 12),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              onSubmitted: (String search) {
                setState(() {
                  _scores = [];
                  _sortCol = 0;
                  _sortAscending = true;
                  _isLoading = true;
                  _searchKey = search;
                  getSearchTableData(_searchKey);
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget buildPageButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
            icon: Icon(Icons.chevron_left_rounded),
            onPressed: _startRow == 1
                ? null
                : () {
                    setState(() {
                      _isLoading = true;
                      _startRow -= 50;
                      _scores = [];
                      getPaginatedTableData(descending: !_sortAscending);
                    });
                  }),
        Text(_startRow.toString() +
            ' - ' +
            (_startRow + _rowsPerPage - 1).toString()),
        IconButton(
            icon: Icon(Icons.chevron_right_rounded),
            onPressed: _scores.length < 49 // ?
                ? null
                : () {
                    setState(() {
                      _isLoading = true;
                      _startRow += 50;
                      _scores = [];
                      getPaginatedTableData(descending: !_sortAscending);
                    });
                  }),
      ],
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

  Widget getScoreLabel(double score, bool isBest, bool hasLink) {
    if (isBest) {
      return RichText(
        text: TextSpan(
          style: TextStyle(color: (hasLink) ? Colors.blue : Colors.white),
          children: [
            WidgetSpan(
              child: Icon(
                Icons.star,
                color: Colors.yellow,
                size: 16,
              ),
            ),
            TextSpan(
              text: score.toString(),
            ),
          ],
        ),
      );
    }
    return Text(score.toString());
  }

  Widget getRankWidget(int rank, int change) {
    if (change != 0) {
      Icon changeIcon = (change > 0)
          ? Icon(
              Icons.keyboard_arrow_up,
              color: Colors.green,
              size: 16,
            )
          : Icon(
              Icons.keyboard_arrow_down,
              color: Colors.red,
              size: 16,
            );

      return Padding(
        padding: const EdgeInsets.only(left: 48.0),
        child: RichText(
          textAlign: TextAlign.start,
          text: TextSpan(
            style: TextStyle(color: Colors.white),
            children: [
              TextSpan(
                text: rank.toString() + '  ',
              ),
              WidgetSpan(
                child: changeIcon,
              ),
              TextSpan(
                  text: change.abs().toString(),
                  style: TextStyle(
                      color: change > 0 ? Colors.green : Colors.red,
                      fontSize: 12)),
            ],
          ),
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(left: 48.0),
        child: Text(
          rank.toString(),
          textAlign: TextAlign.start,
        ),
      );
    }
  }

  double getGalacticValue(var score) {
    if (_scoreMode == ScoreMode.rank) {
      return score['galactic_rank'];
    } else if (_scoreMode == ScoreMode.computedScore) {
      return score['computed_galactic'];
    } else {
      return score['galactic_search'];
    }
  }

  double getAutoValue(var score) {
    if (_scoreMode == ScoreMode.rank) {
      return score['auto_rank'];
    } else if (_scoreMode == ScoreMode.computedScore) {
      return score['computed_auto'];
    } else {
      return score['auto_nav'];
    }
  }

  double getHyperdriveValue(var score) {
    if (_scoreMode == ScoreMode.rank) {
      return score['hyper_rank'];
    } else if (_scoreMode == ScoreMode.computedScore) {
      return score['computed_hyperdrive'];
    } else {
      return score['hyperdrive'];
    }
  }

  double getInterstellarValue(var score) {
    if (_scoreMode == ScoreMode.rank) {
      return score['inter_rank'];
    } else if (_scoreMode == ScoreMode.computedScore) {
      return score['computed_interstellar'];
    } else {
      return score['interstellar'];
    }
  }

  double getPowerportValue(var score) {
    if (_scoreMode == ScoreMode.rank) {
      return score['power_rank'];
    } else if (_scoreMode == ScoreMode.computedScore) {
      return score['computed_powerport'];
    } else {
      return score['powerport'];
    }
  }

  List<DataRow> getDataRows() {
    List<DataRow> rows = [];
    for (var score in _scores) {
      var galacticText = getScoreLabel(
          getGalacticValue(score),
          score['galactic_search'] == _bestGalactic,
          score['galactic_search_vid'] != null);
      var autoNavText = getScoreLabel(getAutoValue(score),
          score['auto_nav'] == _bestAuto, score['auto_nav_vid'] != null);
      var hyperdriveText = getScoreLabel(getHyperdriveValue(score),
          score['hyperdrive'] == _bestHyper, score['hyperdrive_vid'] != null);
      var interstellarText = getScoreLabel(
          getInterstellarValue(score),
          score['interstellar'] == _bestInter,
          score['interstellar_vid'] != null);
      var powerportText = getScoreLabel(getPowerportValue(score),
          score['powerport'] == _bestPower, score['powerport_vid'] != null);

      rows.add(DataRow(cells: <DataCell>[
        DataCell(getRankWidget(score[getRankKey()], score[getChangeKey()])),
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
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        RichText(
                          text: TextSpan(
                            style: TextStyle(color: Colors.white),
                            children: [
                              WidgetSpan(
                                  child: Icon(
                                Icons.keyboard_arrow_up,
                                color: Colors.green,
                                size: 16,
                              )),
                              TextSpan(text: '/'),
                              WidgetSpan(
                                  child: Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.red,
                                size: 16,
                              )),
                              TextSpan(text: ' = Daily Change'),
                              TextSpan(text: '      '),
                              WidgetSpan(
                                  child: Icon(
                                Icons.star,
                                color: Colors.yellow,
                                size: 16,
                              )),
                              TextSpan(text: ' = High Score'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  DataTable(
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
                                if (_searchKey == null) {
                                  _scores = [];
                                  _isLoading = true;
                                  _startRow = 1;
                                  _currentSortKey = getRankKey();

                                  getPaginatedTableData(
                                      descending: !_sortAscending);
                                } else {
                                  sortScores(getRankKey());
                                }
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
                                if (_searchKey == null) {
                                  _scores = [];
                                  _isLoading = true;
                                  _startRow = 1;
                                  _currentSortKey = 'team_rank';

                                  getPaginatedTableData(
                                      descending: !_sortAscending);
                                } else {
                                  sortScores('team');
                                }
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
                                if (_searchKey == null) {
                                  _scores = [];
                                  _isLoading = true;
                                  _startRow = 1;
                                  _currentSortKey = 'galactic_rank';

                                  getPaginatedTableData(
                                      descending: !_sortAscending);
                                } else {
                                  sortScores('galactic_search');
                                }
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
                                if (_searchKey == null) {
                                  _scores = [];
                                  _isLoading = true;
                                  _startRow = 1;
                                  _currentSortKey = 'auto_rank';

                                  getPaginatedTableData(
                                      descending: !_sortAscending);
                                } else {
                                  sortScores('auto_nav');
                                }
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
                                if (_searchKey == null) {
                                  _scores = [];
                                  _isLoading = true;
                                  _startRow = 1;
                                  _currentSortKey = 'hyper_rank';

                                  getPaginatedTableData(
                                      descending: !_sortAscending);
                                } else {
                                  sortScores('hyperdrive');
                                }
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
                                if (_searchKey == null) {
                                  _scores = [];
                                  _isLoading = true;
                                  _startRow = 1;
                                  _currentSortKey = 'inter_rank';

                                  getPaginatedTableData(
                                      descending: !_sortAscending);
                                } else {
                                  sortScores('interstellar',
                                      lowerIsBetter: false);
                                }
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
                                if (_searchKey == null) {
                                  _scores = [];
                                  _isLoading = true;
                                  _startRow = 1;
                                  _currentSortKey = 'power_rank';

                                  getPaginatedTableData(
                                      descending: !_sortAscending);
                                } else {
                                  sortScores('powerport', lowerIsBetter: false);
                                }
                              });
                            }),
                      ],
                      rows: getDataRows()),
                ],
              ),
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

    if ((!_sortAscending && lowerIsBetter) ||
        (_sortAscending && !lowerIsBetter)) {
      _scores = _scores.reversed.toList();
    }
  }
}
