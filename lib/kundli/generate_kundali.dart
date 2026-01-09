import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';

import 'package:nainkart_user/kundli/kundli_history.dart';
import 'package:nainkart_user/provider/wallet_provider.dart';
import 'package:provider/provider.dart';

class GenerateKundli extends StatefulWidget {
  final String token;
  const GenerateKundli({Key? key, required this.token}) : super(key: key);

  @override
  _GenerateKundliState createState() => _GenerateKundliState();
}

class _GenerateKundliState extends State<GenerateKundli> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _tobController = TextEditingController();
  final _latController = TextEditingController();
  final _lonController = TextEditingController();
  final _tzController = TextEditingController(text: '5.5');
  final _pobController = TextEditingController();

  String _lang = 'hi';
  String _style = 'north';
  bool _isLoading = false;
  bool _success = false;
  String? _errorMessage;
  String _kundliPrice = '0'; // Initialize with default value

  final List<Map<String, String>> _languageOptions = [
    {'code': 'hi', 'name': 'हिंदी (Hindi)'},
    {'code': 'en', 'name': 'English'},
    {'code': 'bn', 'name': 'বাংলা (Bengali)'},
    {'code': 'mr', 'name': 'मराठी (Marathi)'},
    {'code': 'kn', 'name': 'ಕನ್ನಡ (Kannada)'},
    {'code': 'ta', 'name': 'தமிழ் (Tamil)'},
    {'code': 'as', 'name': 'অসমীয়া (Assamese)'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchKundliPrice();
  }

  Future<void> _fetchKundliPrice() async {
    try {
      final response = await http.get(
        Uri.parse('https://astroboon.com/api/settings'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Accept': 'application/json',
        },
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['status'] == true) {
        final settings = data['data'] as List;
        final kundliPriceSetting = settings.firstWhere(
          (setting) => setting['key'] == 'kundli_price',
          orElse: () => {'value': '0'},
        );
        setState(() {
          _kundliPrice = kundliPriceSetting['value'] ?? '0';
        });
      }
    } catch (e) {
      print('Error fetching kundli price: $e');
      // Use default value if fetch fails
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      _tobController.text = picked.format(context);
    }
  }

  Future<void> _showPaymentDialog() async {
    if (!_formKey.currentState!.validate()) return;

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Generate Kundli'),
          content: Text(
              'Unlock your destiny--pay ₹$_kundliPrice to generate your kundli.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Pay & Generate'),
              onPressed: () {
                Navigator.of(context).pop();
                _generateKundli();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _generateKundli() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _success = false;
    });

    try {
      final response = await http.get(
        Uri.parse(
            'https://astroboon.com/api/generate_kundli?name=${_nameController.text}'
            '&dob=${_dobController.text}'
            '&tob=${_tobController.text}'
            '&lat=${_latController.text}'
            '&lon=${_lonController.text}'
            '&tz=${_tzController.text}'
            '&lang=$_lang'
            '&style=$_style'
            '&pob=${_pobController.text}'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Accept': 'application/json',
        },
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['status'] == true) {
        setState(() => _success = true);
        await Provider.of<WalletProvider>(context, listen: false)
            .fetchWallet(widget.token);
      } else {
        setState(() =>
            _errorMessage = data['message'] ?? 'Failed to generate Kundli');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _tobController.dispose();
    _latController.dispose();
    _lonController.dispose();
    _tzController.dispose();
    _pobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Kundli',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.purple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _success
          ? _buildSuccessContent(context)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField(_nameController, 'Name', Icons.person),
                    const SizedBox(height: 16),
                    _buildDatePickerField(context, _dobController,
                        'Date of Birth', Icons.calendar_today),
                    const SizedBox(height: 16),
                    _buildTimePickerField(context, _tobController,
                        'Time of Birth', Icons.access_time),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                            child: _buildTextField(
                                _latController, 'Latitude', Icons.location_on)),
                        const SizedBox(width: 16),
                        Expanded(
                            child: _buildTextField(_lonController, 'Longitude',
                                Icons.location_on)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                        _tzController, 'Timezone', Icons.time_to_leave),
                    const SizedBox(height: 16),
                    _buildLanguageDropdown(),
                    const SizedBox(height: 16),
                    _buildChartStyleDropdown(),
                    const SizedBox(height: 16),
                    _buildTextField(
                        _pobController, 'Place of Birth', Icons.place),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _showPaymentDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: const Text('Generate Kundli',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                            ),
                    ),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(_errorMessage!,
                            style: const TextStyle(color: Colors.red)),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSuccessContent(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline,
                size: 100, color: Colors.green),
            const SizedBox(height: 20),
            const Text(
              'Your Kundli has been generated successfully!',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text(
              'You can find it in the Kundli History.',
              style: TextStyle(fontSize: 16, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          KundliHistoryPage(token: widget.token)),
                );
              },
              icon: const Icon(Icons.arrow_forward,
                  size: 24, color: Colors.white),
              label: const Text('Go to Kundli History',
                  style: TextStyle(fontSize: 16, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon, color: Colors.purple),
      ),
      validator: (value) =>
          value == null || value.isEmpty ? 'Please enter $label' : null,
    );
  }

  Widget _buildDatePickerField(BuildContext context,
      TextEditingController controller, String label, IconData icon) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon, color: Colors.purple),
        suffixIcon: IconButton(
          icon: const Icon(Icons.date_range, color: Colors.purple),
          onPressed: () => _selectDate(context),
        ),
      ),
      validator: (value) =>
          value == null || value.isEmpty ? 'Please select $label' : null,
    );
  }

  Widget _buildTimePickerField(BuildContext context,
      TextEditingController controller, String label, IconData icon) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon, color: Colors.purple),
        suffixIcon: IconButton(
          icon: const Icon(Icons.schedule, color: Colors.purple),
          onPressed: () => _selectTime(context),
        ),
      ),
      validator: (value) =>
          value == null || value.isEmpty ? 'Please select $label' : null,
    );
  }

  Widget _buildLanguageDropdown() {
    return DropdownButtonFormField<String>(
      value: _lang,
      decoration: const InputDecoration(
        labelText: 'Language',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.language, color: Colors.purple),
      ),
      items: _languageOptions.map((lang) {
        return DropdownMenuItem<String>(
          value: lang['code'],
          child: Text(lang['name']!),
        );
      }).toList(),
      onChanged: (value) => setState(() => _lang = value!),
    );
  }

  Widget _buildChartStyleDropdown() {
    return DropdownButtonFormField<String>(
      value: _style,
      decoration: const InputDecoration(
        labelText: 'Chart Style',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.pie_chart, color: Colors.purple),
      ),
      items: const [
        DropdownMenuItem(value: 'north', child: Text('North Indian')),
        DropdownMenuItem(value: 'south', child: Text('South Indian')),
      ],
      onChanged: (value) => setState(() => _style = value!),
    );
  }
}
