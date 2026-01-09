class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final int stock;
  final String image;
  final bool isActive;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.image,
    required this.isActive,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: double.parse(json['price']),
      stock: json['stock'],
      image: json['image'],
      isActive: json['is_active'] == 1,
    );
  }
}
