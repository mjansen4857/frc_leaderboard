import 'package:flutter/material.dart';

class LeaderboardPage extends StatefulWidget {
  LeaderboardPage({Key key}) : super(key: key);

  @override
  _LeaderboardPageState createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Recharge at Home Global Leaderboard"),
      ),
      body: Stack(
        children: [
          buildTable(),
        ],
      ),
    );
  }

  Widget buildTable() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
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
              ], rows: <DataRow>[
                DataRow(
                  cells: <DataCell>[
                    DataCell(Text('1')),
                    DataCell(Text('3015')),
                    DataCell(Text('8.7')),
                    DataCell(Text('24.6')),
                    DataCell(Text('31.5')),
                    DataCell(Text('45')),
                    DataCell(Text('75')),
                  ],
                ),
                DataRow(
                  cells: <DataCell>[
                    DataCell(Text('2')),
                    DataCell(Text('254')),
                    DataCell(Text('21.8')),
                    DataCell(Text('63.7')),
                    DataCell(Text('52.9')),
                    DataCell(Text('22')),
                    DataCell(Text('31')),
                  ],
                ),
                DataRow(
                  cells: <DataCell>[
                    DataCell(Text('3')),
                    DataCell(Text('148')),
                    DataCell(Text('30.1')),
                    DataCell(Text('72.7')),
                    DataCell(Text('48.4')),
                    DataCell(Text('27')),
                    DataCell(Text('33')),
                  ],
                ),
                DataRow(
                  cells: <DataCell>[
                    DataCell(Text('3')),
                    DataCell(Text('148')),
                    DataCell(Text('30.1')),
                    DataCell(Text('72.7')),
                    DataCell(Text('48.4')),
                    DataCell(Text('27')),
                    DataCell(Text('33')),
                  ],
                ),
                DataRow(
                  cells: <DataCell>[
                    DataCell(Text('3')),
                    DataCell(Text('148')),
                    DataCell(Text('30.1')),
                    DataCell(Text('72.7')),
                    DataCell(Text('48.4')),
                    DataCell(Text('27')),
                    DataCell(Text('33')),
                  ],
                ),
                DataRow(
                  cells: <DataCell>[
                    DataCell(Text('3')),
                    DataCell(Text('148')),
                    DataCell(Text('30.1')),
                    DataCell(Text('72.7')),
                    DataCell(Text('48.4')),
                    DataCell(Text('27')),
                    DataCell(Text('33')),
                  ],
                ),
              ]),
            ),
          )
        ],
      ),
    );
  }
}
