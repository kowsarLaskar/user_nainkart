import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nainkart_user/astro_model.dart';

class HomePageApiServices {
  final String baseUrl = 'https://astroboon.com/api';
  final String imageBaseUrl = 'https://astroboon.com/storage/';

  Future<int> fetchWalletBalance(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/user_balance'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['balance'] as int;
    } else {
      throw Exception('Failed to load wallet balance');
    }
  }

  Future<List<Astrologer>> fetchAstrologers(String token) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final response = await http.get(
      Uri.parse('$baseUrl/astrologers?_=$timestamp'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['data'] as List).map((a) => Astrologer.fromMap(a)).toList();
    } else {
      throw Exception('Failed to load astrologers');
    }
  }

  Future<List<dynamic>> fetchSliders(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/sliders'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data'] as List<dynamic>;
    } else {
      throw Exception('Failed to load sliders');
    }
  }
}
