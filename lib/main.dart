import 'package:flutter/material.dart';
import 'package:frc_leaderboard/pages/leaderboard_page.dart';
import 'package:frc_leaderboard/services/database.dart';

void main() {
  runApp(Leaderboard());
}

class Leaderboard extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IRH Leaderboard',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      home: LeaderboardPage(
        db: Database(),
      ),
    );
  }
}
