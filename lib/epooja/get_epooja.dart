import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nainkart_user/provider/wallet_provider.dart';
import 'dart:convert';
import 'package:provider/provider.dart';

class EPoojaScreen extends StatefulWidget {
  final String token;
  const EPoojaScreen({Key? key, required this.token}) : super(key: key);

  @override
  _EPoojaScreenState createState() => _EPoojaScreenState();
}

class _EPoojaScreenState extends State<EPoojaScreen> {
  List<dynamic> poojas = [];
  bool isLoading = true;
  String errorMessage = '';
  String? selectedPoojaId;
  String? selectedSlot;
  final String baseUrl = 'https://astroboon.com';
  final String imageBaseUrl = 'https://astroboon.com/storage/';
  final TextEditingController _remarksController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchPoojas();
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> fetchPoojas() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/epooja'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          setState(() {
            poojas = data['data'];
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = data['message'] ?? 'Failed to fetch poojas';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Failed to load poojas: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  Future<void> bookPooja() async {
    if (selectedPoojaId == null ||
        selectedSlot == null ||
        _remarksController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Please select a pooja, time slot, and enter remarks')),
      );
      return;
    }

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final url = Uri.encodeFull(
        '$baseUrl/api/epooja-order/$selectedPoojaId?slot=$selectedSlot&remarks=${_remarksController.text.trim()}',
      );

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Accept': 'application/json',
        },
      );

      Navigator.pop(context); // Dismiss loading dialog

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Response received')),
        );

        // Refresh wallet balance
        await Provider.of<WalletProvider>(context, listen: false)
            .fetchWallet(widget.token);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${response.statusCode}')),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Dismiss loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('E-Pooja Booking'),
        backgroundColor: Colors.purple,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Available Poojas',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...poojas.map((pooja) => _buildPoojaCard(pooja)).toList(),
                      const SizedBox(height: 24),
                      if (selectedPoojaId != null) _buildTimeSlotSelection(),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _remarksController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Enter Remarks',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.note_alt_outlined),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: bookPooja,
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text(
                            'Book Pooja',
                            style: TextStyle(fontSize: 18),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 40, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildPoojaCard(Map<String, dynamic> pooja) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          setState(() {
            selectedPoojaId = pooja['id'].toString();
            selectedSlot = null;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: selectedPoojaId == pooja['id'].toString()
                  ? Colors.purple
                  : Colors.transparent,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (pooja['image'] != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    '$imageBaseUrl${pooja['image']}',
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image, size: 40),
                    ),
                  ),
                )
              else
                Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[200],
                  child: const Icon(Icons.temple_hindu, size: 40),
                ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pooja['name'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      pooja['description'],
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${pooja['price']}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      pooja['is_available'] ? 'Available' : 'Not Available',
                      style: TextStyle(
                        color:
                            pooja['is_available'] ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSlotSelection() {
    final selectedPooja = poojas.firstWhere(
      (pooja) => pooja['id'].toString() == selectedPoojaId,
      orElse: () => {},
    );

    if (selectedPooja.isEmpty || !selectedPooja['is_available']) {
      return Container();
    }

    final slots = List<String>.from(selectedPooja['available_slots'] ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Time Slot',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: slots.map((slot) {
            return ChoiceChip(
              label: Text(slot),
              selected: selectedSlot == slot,
              onSelected: (selected) {
                setState(() {
                  selectedSlot = selected ? slot : null;
                });
              },
              selectedColor: Colors.purple,
              labelStyle: TextStyle(
                color: selectedSlot == slot ? Colors.white : Colors.black,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
