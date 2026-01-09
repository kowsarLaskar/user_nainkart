import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:nainkart_user/products/product_modal.dart';

class ProductService {
  Future<List<Product>> fetchProducts() async {
    final response = await http.get(
      Uri.parse('https://astroboon.com/api/products'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == true) {
        return (data['data'] as List)
            .map((json) => Product.fromJson(json))
            .toList();
      } else {
        throw Exception(data['message']);
      }
    } else {
      throw Exception('Failed to load products');
    }
  }
}
