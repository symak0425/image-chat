import 'dart:io';
import 'dart:convert';
import 'package:hackaton/main.dart';
import 'package:http/http.dart' as http;

class ASRservice {
  final String asrRoot = "https://uwebasr.zcu.cz/api/v2/lindat/";

  Future<List<dynamic>> recognize(String filePath, String model,
      {bool wordsOnly = false}) async {
    try {
      final fileBytes = File(filePath).readAsBytesSync();
      final response = await http.post(
        Uri.parse('$asrRoot$model?format=json'),
        body: fileBytes,
      );

      logger.v(response.statusCode);
      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);
        if (wordsOnly) {
          return List<String>.from(decodedData.map((item) => item['word']));
        } else {
          return decodedData;
        }
      } else {
        throw Exception('Failed to recognize audio: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error during recognition: $e');
    }
  }
}
