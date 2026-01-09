import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:nainkart_user/products/product_modal.dart';
import 'package:nainkart_user/provider/wallet_provider.dart';
import 'package:provider/provider.dart'; // Ensure this is your actual path

class AddToProductPage extends StatefulWidget {
  final Product product;
  final String token;

  const AddToProductPage({Key? key, required this.product, required this.token})
      : super(key: key);

  @override
  _AddToProductPageState createState() => _AddToProductPageState();
}

class _AddToProductPageState extends State<AddToProductPage> {
  final _formKey = GlobalKey<FormState>();

  final quantityController = TextEditingController(text: '1');
  final fullNameController = TextEditingController();
  final phoneNumberController = TextEditingController();
  final addressLine1Controller = TextEditingController();
  final addressLine2Controller = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final postalCodeController = TextEditingController();
  final countryController = TextEditingController();
  final deliveryInstructionsController = TextEditingController();

  bool isLoading = false;

  Future<void> placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final baseUrl = 'https://astroboon.com/api/shop/${widget.product.id}';
    final params = {
      'quantity': quantityController.text,
      'full_name': fullNameController.text,
      'phone_number': phoneNumberController.text,
      'address_line_1': addressLine1Controller.text,
      'address_line_2': addressLine2Controller.text,
      'city': cityController.text,
      'state': stateController.text,
      'postal_code': postalCodeController.text,
      'country': countryController.text,
      'delivery_instructions': deliveryInstructionsController.text,
    };

    final uri = Uri.parse(baseUrl).replace(queryParameters: params);

    try {
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Accept': 'application/json',
        },
      );

      final data = json.decode(response.body);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? 'Order placed')),
      );

      // ✅ Fetch wallet balance after successful order
      await Provider.of<WalletProvider>(context, listen: false)
          .fetchWallet(widget.token);

      Navigator.pop(context); // Optionally return to the previous screen
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType? keyboardType, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        keyboardType: keyboardType,
        validator: validator ??
            (value) => (value == null || value.isEmpty) ? 'Required' : null,
      ),
    );
  }

  @override
  void dispose() {
    quantityController.dispose();
    fullNameController.dispose();
    phoneNumberController.dispose();
    addressLine1Controller.dispose();
    addressLine2Controller.dispose();
    cityController.dispose();
    stateController.dispose();
    postalCodeController.dispose();
    countryController.dispose();
    deliveryInstructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Your Order')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                widget.product.name,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Price: ₹${widget.product.price.toStringAsFixed(2)}'),
              const SizedBox(height: 16),
              _buildTextField(
                'Quantity',
                quantityController,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  final qty = int.tryParse(value);
                  if (qty == null || qty < 1)
                    return 'Quantity must be at least 1';
                  return null;
                },
              ),
              _buildTextField('Full Name', fullNameController),
              _buildTextField(
                'Phone Number',
                phoneNumberController,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (value.length != 10)
                    return 'Phone number must be 10 digits';
                  return null;
                },
              ),
              _buildTextField('Address Line 1', addressLine1Controller),
              _buildTextField('Address Line 2', addressLine2Controller),
              _buildTextField('City', cityController),
              _buildTextField('State', stateController),
              _buildTextField('Postal Code', postalCodeController,
                  keyboardType: TextInputType.number),
              _buildTextField('Country', countryController),
              _buildTextField(
                  'Delivery Instructions', deliveryInstructionsController),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isLoading ? null : placeOrder,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.purple,
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Place Order',
                        style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
