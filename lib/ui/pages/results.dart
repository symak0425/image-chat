import 'package:flutter/material.dart';
import 'package:hackaton/ui/components/top-bar.dart';

class ResultsPage extends StatefulWidget {
  final String imagePath;
  final String ip;
  final String resultText;

  const ResultsPage(
      {super.key,
      required this.imagePath,
      required this.ip,
      required this.resultText});

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(50),
        child: TopBar(),
      ),
      body: Center(
        // text with style
        child: Text(
          widget.ip,
          style: const TextStyle(color: Colors.green, fontSize: 50),
        ),
      ),
    );
  }
}
