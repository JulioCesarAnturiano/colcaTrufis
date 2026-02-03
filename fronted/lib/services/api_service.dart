import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = 'https://localhost:3000';

  Future<List<dynamic>> fetchTrufis() async {
    final response = await http.get(Uri.parse('$baseUrl/trufis'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load trufis');
    }
  }

  Future<List<dynamic>> fetchRadiotaxis() async {
    final response = await http.get(Uri.parse('$baseUrl/radiotaxis'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load radiotaxis');
    }
  }
}
