import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:frc_leaderboard/services/database.dart';
import 'package:url_launcher/url_launcher.dart';

enum RankMode { best3, overall }
enum ScoreMode { rawScore, computedScore, rank }

class LeaderboardPage extends StatefulWidget {
  final Database db;
  final FirebaseAnalytics analytics;

  LeaderboardPage({Key key, this.db, this.analytics}) : super(key: key);

  @override
  _LeaderboardPageState createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  var _scores = [];
  var _fixedScores = [];
  bool _isLoading = true;
  int _sortCol = 0;
  bool _sortAscending = true;
  double _bestGalactic = double.infinity;
  double _bestAuto = double.infinity;
  double _bestHyper = double.infinity;
  double _bestInter = 0;
  double _bestPower = 0;
  int _startRow = 1;
  int _rowsPerPage = 25;
  String _currentSortKey = 'rank';
  QuerySnapshot _vidSnapshot;
  bool _paginated = true;
  String _searchKey;
  RankMode _rankMode = RankMode.best3;
  ScoreMode _scoreMode = ScoreMode.rawScore;

  @override
  void initState() {
    super.initState();
    widget.analytics.logAppOpen();
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
        _currentSortKey = 'rank';
        getPaginatedTableData();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
          bottom: TabBar(
            tabs: [
              Tab(
                text: 'Game Manual Scoring',
              ),
              Tab(
                text: 'Reduced Bounding Scoring',
              ),
            ],
          ),
        ),
        body: Stack(
          children: [
            showLoading(),
            TabBarView(
              children: [buildTable(false), buildTable(true)],
            ),
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
                    widget.analytics.logSelectContent(
                        contentType: 'Rank Mode', itemId: 'Best 3');
                    setState(() {
                      _rankMode = mode;
                      if (_currentSortKey == 'rank_5') {
                        _isLoading = true;
                        _currentSortKey = 'rank';
                        _scores = [];
                        _fixedScores = [];
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
                    widget.analytics.logSelectContent(
                        contentType: 'Rank Mode', itemId: 'Overall');
                    setState(() {
                      _rankMode = mode;
                      if (_currentSortKey == 'rank') {
                        _isLoading = true;
                        _currentSortKey = 'rank_5';
                        _scores = [];
                        _fixedScores = [];
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
                    widget.analytics.logSelectContent(
                        contentType: 'Score Mode', itemId: 'Raw Score');
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
                    widget.analytics.logSelectContent(
                        contentType: 'Score Mode', itemId: 'Computed Score');
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
                    widget.analytics.logSelectContent(
                        contentType: 'Score Mode', itemId: 'Rank');
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
      ),
    );
  }

  String getRankKey(bool fixed) {
    if (_rankMode == RankMode.best3) {
      return fixed ? 'rank_fixed' : 'rank';
    } else {
      return fixed ? 'rank_5_fixed' : 'rank_5';
    }
  }

  String getChangeKey() {
    if (_rankMode == RankMode.best3) {
      return 'change';
    } else {
      return 'change_5';
    }
  }

  Map<String, dynamic> getScoresFromDoc(DocumentSnapshot doc) {
    int team = int.parse(doc.id);

    var revealVid;
    var galacticVid;
    var autoNavVid;
    var hyperdriveVid;
    var interstellarVid;
    var powerportVid;

    for (var vidDoc in _vidSnapshot.docs) {
      if (int.parse(vidDoc.id) == team) {
        var vidData = vidDoc.data();
        revealVid = vidData['reveal'];
        galacticVid = vidData['galactic_search'];
        autoNavVid = vidData['auto_nav'];
        hyperdriveVid = vidData['hyperdrive'];
        interstellarVid = vidData['interstellar'];
        powerportVid = vidData['powerport'];

        break;
      }
    }

    var docData = doc.data();

    return {
      'team': team,
      'rank': docData['rank'],
      'rank_fixed': docData['rank_fixed'],
      'rank_5': docData['rank_5'],
      'rank_5_fixed': docData['rank_5_fixed'],
      'change': docData['change'],
      'change_5': docData['change_5'],
      'galactic_search': docData['galactic_search'],
      'computed_galactic': docData['computed_galactic'],
      'computed_galactic_fixed': docData['computed_galactic_fixed'],
      'galactic_rank': docData['galactic_rank'],
      'auto_nav': docData['auto_nav'],
      'computed_auto': docData['computed_auto'],
      'computed_auto_fixed': docData['computed_auto_fixed'],
      'auto_rank': docData['auto_rank'],
      'hyperdrive': docData['hyperdrive'],
      'computed_hyperdrive': docData['computed_hyperdrive'],
      'computed_hyperdrive_fixed': docData['computed_hyperdrive_fixed'],
      'hyper_rank': docData['hyper_rank'],
      'interstellar': docData['interstellar'],
      'computed_interstellar': docData['computed_interstellar'],
      'computed_interstellar_fixed': docData['computed_interstellar_fixed'],
      'inter_rank': docData['inter_rank'],
      'powerport': docData['powerport'],
      'computed_powerport': docData['computed_powerport'],
      'computed_powerport_fixed': docData['computed_powerport_fixed'],
      'power_rank': docData['power_rank'],
      'reveal_vid': revealVid,
      'galactic_search_vid': galacticVid,
      'auto_nav_vid': autoNavVid,
      'hyperdrive_vid': hyperdriveVid,
      'interstellar_vid': interstellarVid,
      'powerport_vid': powerportVid
    };
  }

  void getSearchTableData(String searchKey, {bool descending = false}) {
    if (int.tryParse(searchKey) != null) {
      widget.db.getSingleTeamDoc(searchKey).then((doc) {
        var scores = [];

        if (doc.exists) {
          scores.add(getScoresFromDoc(doc));
        }

        setState(() {
          _isLoading = false;
          _scores = scores;
          _fixedScores = scores;
          _paginated = false;
        });
      });
    } else {
      widget.db
          .getGroupDocs(searchKey, _currentSortKey, descending: descending)
          .then((querySnapshot) {
        var scores = [];

        for (var doc in querySnapshot.docs) {
          scores.add(getScoresFromDoc(doc));
        }

        var fixedScores = [];

        if (_currentSortKey == 'rank' || _currentSortKey == 'rank_5') {
          widget.db
              .getGroupDocs(searchKey, _currentSortKey + '_fixed',
                  descending: descending)
              .then((fixedQuerySnap) {
            for (var doc in fixedQuerySnap.docs) {
              fixedScores.add(getScoresFromDoc(doc));
            }
            setState(() {
              _isLoading = false;
              _scores = scores;
              _fixedScores = fixedScores;
              _paginated = false;
            });
          });
        } else {
          fixedScores = scores;
          setState(() {
            _isLoading = false;
            _scores = scores;
            _fixedScores = fixedScores;
            _paginated = false;
          });
        }
      });
    }
  }

  void getPaginatedTableData({bool descending = false}) {
    // if(sortKey == 'rank' && fixed) sortKey = 'rank_fixed';
    // if(sortKey == 'rank_5' && fixed) sortKey = 'rank_5_fixed';
    widget.db
        .getPaginatedDocs(_currentSortKey, _startRow, _rowsPerPage,
            descending: descending)
        .then((querySnapshot) async {
      var scores = [];

      for (var doc in querySnapshot.docs) {
        scores.add(getScoresFromDoc(doc));
      }

      var fixedScores = [];

      if (_currentSortKey == 'rank' || _currentSortKey == 'rank_5') {
        widget.db
            .getPaginatedDocs(
                _currentSortKey + '_fixed', _startRow, _rowsPerPage,
                descending: descending)
            .then((fixedQuerySnap) async {
          for (var doc in fixedQuerySnap.docs) {
            fixedScores.add(getScoresFromDoc(doc));
          }
          setState(() {
            _isLoading = false;
            _scores = scores;
            _fixedScores = fixedScores;
            _paginated = true;
          });
        });
      } else {
        fixedScores = scores;
        setState(() {
          _isLoading = false;
          _scores = scores;
          _fixedScores = fixedScores;
          _paginated = true;
        });
      }
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
                    _fixedScores = [];
                    _sortCol = 0;
                    _sortAscending = true;
                    _searchKey = null;
                    _currentSortKey = getRankKey(false);
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
                widget.analytics.logSearch(searchTerm: search);
                setState(() {
                  _scores = [];
                  _fixedScores = [];
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
                      widget.analytics.logEvent(name: 'previous_page');
                      _isLoading = true;
                      _startRow -= _rowsPerPage;
                      _scores = [];
                      _fixedScores = [];
                      getPaginatedTableData(descending: !_sortAscending);
                    });
                  }),
        Text(_startRow.toString() +
            ' - ' +
            (_startRow + _rowsPerPage - 1).toString()),
        IconButton(
            icon: Icon(Icons.chevron_right_rounded),
            onPressed: _scores.length < _rowsPerPage // ?
                ? null
                : () {
                    setState(() {
                      widget.analytics.logEvent(name: 'next_page');
                      _isLoading = true;
                      _startRow += _rowsPerPage;
                      _scores = [];
                      _fixedScores = [];
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

  double getGalacticValue(var score, bool fixed) {
    if (_scoreMode == ScoreMode.rank) {
      return score['galactic_rank'];
    } else if (_scoreMode == ScoreMode.computedScore) {
      return fixed
          ? score['computed_galactic_fixed']
          : score['computed_galactic'];
    } else {
      return score['galactic_search'];
    }
  }

  double getAutoValue(var score, bool fixed) {
    if (_scoreMode == ScoreMode.rank) {
      return score['auto_rank'];
    } else if (_scoreMode == ScoreMode.computedScore) {
      return fixed ? score['computed_auto_fixed'] : score['computed_auto'];
    } else {
      return score['auto_nav'];
    }
  }

  double getHyperdriveValue(var score, bool fixed) {
    if (_scoreMode == ScoreMode.rank) {
      return score['hyper_rank'];
    } else if (_scoreMode == ScoreMode.computedScore) {
      return fixed
          ? score['computed_hyperdrive_fixed']
          : score['computed_hyperdrive'];
    } else {
      return score['hyperdrive'];
    }
  }

  double getInterstellarValue(var score, bool fixed) {
    if (_scoreMode == ScoreMode.rank) {
      return score['inter_rank'];
    } else if (_scoreMode == ScoreMode.computedScore) {
      return fixed
          ? score['computed_interstellar_fixed']
          : score['computed_interstellar'];
    } else {
      return score['interstellar'];
    }
  }

  double getPowerportValue(var score, bool fixed) {
    if (_scoreMode == ScoreMode.rank) {
      return score['power_rank'];
    } else if (_scoreMode == ScoreMode.computedScore) {
      return fixed
          ? score['computed_powerport_fixed']
          : score['computed_powerport'];
    } else {
      return score['powerport'];
    }
  }

  List<DataRow> getDataRows(bool fixed) {
    List<DataRow> rows = [];
    var scores = fixed ? _fixedScores : _scores;
    for (var score in scores) {
      var galacticText = getScoreLabel(
          getGalacticValue(score, fixed),
          score['galactic_search'] == _bestGalactic,
          score['galactic_search_vid'] != null);
      var autoNavText = getScoreLabel(getAutoValue(score, fixed),
          score['auto_nav'] == _bestAuto, score['auto_nav_vid'] != null);
      var hyperdriveText = getScoreLabel(getHyperdriveValue(score, fixed),
          score['hyperdrive'] == _bestHyper, score['hyperdrive_vid'] != null);
      var interstellarText = getScoreLabel(
          getInterstellarValue(score, fixed),
          score['interstellar'] == _bestInter,
          score['interstellar_vid'] != null);
      var powerportText = getScoreLabel(getPowerportValue(score, fixed),
          score['powerport'] == _bestPower, score['powerport_vid'] != null);

      var change = score[getRankKey(false)] - score[getRankKey(fixed)];

      rows.add(DataRow(cells: <DataCell>[
        DataCell(getRankWidget(score[getRankKey(fixed)], change)),
        DataCell(score['reveal_vid'] != null
            ? Center(
                child: TextButton(
                  child: Text(score['team'].toString()),
                  onPressed: () async {
                    if (await canLaunch(score['reveal_vid'])) {
                      widget.analytics.logEvent(
                          name: 'launch_link',
                          parameters: {
                            'team': score['team'],
                            'link_type': 'reveal'
                          });
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
                    widget.analytics.logEvent(name: 'launch_link', parameters: {
                      'team': score['team'],
                      'link_type': 'galactic'
                    });
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
                    widget.analytics.logEvent(name: 'launch_link', parameters: {
                      'team': score['team'],
                      'link_type': 'auto-nav'
                    });
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
                    widget.analytics.logEvent(name: 'launch_link', parameters: {
                      'team': score['team'],
                      'link_type': 'hyperdrive'
                    });
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
                    widget.analytics.logEvent(name: 'launch_link', parameters: {
                      'team': score['team'],
                      'link_type': 'interstellar'
                    });
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
                    widget.analytics.logEvent(name: 'launch_link', parameters: {
                      'team': score['team'],
                      'link_type': 'powerport'
                    });
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

  Widget buildTable(bool fixed) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: ListView(
        children: [
          Container(
            alignment: Alignment.center,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                children: [
                  // Padding(
                  //   padding: const EdgeInsets.only(bottom: 8.0),
                  //   child: Row(
                  //     children: [
                  //       RichText(
                  //         text: TextSpan(
                  //           style: TextStyle(color: Colors.white),
                  //           children: [
                  //             WidgetSpan(
                  //                 child: Icon(
                  //               Icons.keyboard_arrow_up,
                  //               color: Colors.green,
                  //               size: 16,
                  //             )),
                  //             TextSpan(text: '/'),
                  //             WidgetSpan(
                  //                 child: Icon(
                  //               Icons.keyboard_arrow_down,
                  //               color: Colors.red,
                  //               size: 16,
                  //             )),
                  //             TextSpan(text: ' = Daily Change'),
                  //             TextSpan(text: '      '),
                  //             WidgetSpan(
                  //                 child: Icon(
                  //               Icons.star,
                  //               color: Colors.yellow,
                  //               size: 16,
                  //             )),
                  //             TextSpan(text: ' = High Score'),
                  //           ],
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),
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
                              widget.analytics.logEvent(
                                  name: 'sort_col',
                                  parameters: {'col': 'rank'});
                              setState(() {
                                _sortCol = columnIndex;
                                _sortAscending = sortAscending;
                                if (_searchKey == null) {
                                  _scores = [];
                                  _fixedScores = [];
                                  _isLoading = true;
                                  _startRow = 1;
                                  _currentSortKey = getRankKey(fixed);

                                  getPaginatedTableData(
                                      descending: !_sortAscending);
                                } else {
                                  sortScores(getRankKey(fixed));
                                }
                              });
                            }),
                        DataColumn(
                            label: Padding(
                              padding: const EdgeInsets.only(left: 16.0),
                              child: Text('Team Number'),
                            ),
                            onSort: (columnIndex, sortAscending) {
                              widget.analytics.logEvent(
                                  name: 'sort_col',
                                  parameters: {'col': 'team'});
                              setState(() {
                                _sortCol = columnIndex;
                                _sortAscending = sortAscending;
                                if (_searchKey == null) {
                                  _scores = [];
                                  _fixedScores = [];
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
                              widget.analytics.logEvent(
                                  name: 'sort_col',
                                  parameters: {'col': 'galactic'});
                              setState(() {
                                _sortCol = columnIndex;
                                _sortAscending = sortAscending;
                                if (_searchKey == null) {
                                  _scores = [];
                                  _fixedScores = [];
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
                              widget.analytics.logEvent(
                                  name: 'sort_col',
                                  parameters: {'col': 'auto-nav'});
                              setState(() {
                                _sortCol = columnIndex;
                                _sortAscending = sortAscending;
                                if (_searchKey == null) {
                                  _scores = [];
                                  _fixedScores = [];
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
                              widget.analytics.logEvent(
                                  name: 'sort_col',
                                  parameters: {'col': 'hyperdrive'});
                              setState(() {
                                _sortCol = columnIndex;
                                _sortAscending = sortAscending;
                                if (_searchKey == null) {
                                  _scores = [];
                                  _fixedScores = [];
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
                              widget.analytics.logEvent(
                                  name: 'sort_col',
                                  parameters: {'col': 'interstellar'});
                              setState(() {
                                _sortCol = columnIndex;
                                _sortAscending = sortAscending;
                                if (_searchKey == null) {
                                  _scores = [];
                                  _fixedScores = [];
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
                              widget.analytics.logEvent(
                                  name: 'sort_col',
                                  parameters: {'col': 'powerport'});
                              setState(() {
                                _sortCol = columnIndex;
                                _sortAscending = sortAscending;
                                if (_searchKey == null) {
                                  _scores = [];
                                  _fixedScores = [];
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
                      rows: getDataRows(fixed)),
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

    _fixedScores.sort((a, b) {
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
      _fixedScores = _fixedScores.reversed.toList();
    }
  }
}
