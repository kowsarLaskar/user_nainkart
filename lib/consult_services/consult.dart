import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nainkart_user/consult_services/Audio_call.dart';
import 'package:nainkart_user/consult_services/video_call.dart';
import 'dart:convert';
import 'package:nainkart_user/consult_services/webview_chat.dart';
import 'package:nainkart_user/provider/wallet_provider.dart';
import 'package:provider/provider.dart';

class ConsultationPage extends StatefulWidget {
  final int astroUserId;
  final String astologerName;
  final String token;
  final String consultationType;

  const ConsultationPage({
    Key? key,
    required this.astroUserId,
    required this.astologerName,
    required this.token,
    required this.consultationType,
  }) : super(key: key);

  @override
  State<ConsultationPage> createState() => _ConsultationPageState();
}

class _ConsultationPageState extends State<ConsultationPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _birthTimeController = TextEditingController();
  final TextEditingController _placeOfBirthController = TextEditingController();
  final TextEditingController _questionController = TextEditingController();

  int? user_id;
  int? consultationId;
  bool isLoading = false;
  String? errorMessage;

  String? _selectedGender;
  final List<String> _genderOptions = ['Male', 'Female'];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _birthTimeController.text = picked.format(context);
      });
    }
  }

  Future<void> submitConsultation() async {
    debugPrint('\n=== NEW CONSULTATION REQUEST ===');
    debugPrint('Astrologer ID: ${widget.astroUserId}');
    debugPrint('Type: ${widget.consultationType}');

    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    try {
      final formattedTime =
          _birthTimeController.text.replaceAll(' ', '').toUpperCase();

      final url =
          'https://astroboon.com/api/consultant-book/${widget.consultationType}'
          '?astro_user_id=${widget.astroUserId}'
          '&gender=${_genderController.text}'
          '&dob=${_dobController.text}'
          '&name=${_nameController.text}'
          '&birth_time=$formattedTime'
          '&place_of_birth=${_placeOfBirthController.text}'
          '&question=${_questionController.text}';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Accept': 'application/json',
        },
      );

      if (!mounted) return;

      debugPrint('Response: ${response.statusCode}');
      debugPrint('Body: ${response.body}');

      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (jsonResponse['status'] == true) {
          if (jsonResponse.containsKey('data') &&
              jsonResponse['data'] != null) {
            final data = jsonResponse['data'];
            user_id = int.tryParse(data['user_id'].toString());
            consultationId = int.tryParse(data['id'].toString());

            _showMessageCard(
                '✅ Consultation booked successfully!', Colors.green);

            await Provider.of<WalletProvider>(context, listen: false)
                .fetchWallet(widget.token);

            if (!mounted) return;

            if (widget.consultationType == 'chat') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatWebView(
                    userId: user_id!.toString(),
                    consultationId: consultationId!.toString(),
                    astrolgerName: widget.astologerName,
                  ),
                ),
              );
            } else if (widget.consultationType == 'audio') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AudioCall(
                    userId: user_id!,
                    channelId: consultationId!.toString(),
                    astrologerName: widget.astologerName,
                    token: widget.token,
                  ),
                ),
              );
            } else if (widget.consultationType == 'video') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VideoCall(
                    userId: user_id!,
                    channelId: consultationId!.toString(),
                    astrologerName: widget.astologerName,
                    token: widget.token,
                  ),
                ),
              );
            }
          } else {
            // No data, but success = true: show message
            _showMessageCard(
                jsonResponse['message'] ?? 'Something went wrong.', Colors.red);
          }
        } else {
          // status == false
          _showMessageCard(
              jsonResponse['message'] ?? 'Request failed.', Colors.red);
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint('ERROR: $e');
      _showMessageCard('❌ Failed to book: $e', Colors.red);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showMessageCard(String message, Color color) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 100,
        left: 20,
        right: 20,
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              border: Border.all(color: color),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 2), () => overlayEntry.remove());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Consultation Form')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _selectedGender,
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value;
                    _genderController.text = value ?? '';
                  });
                },
                items: _genderOptions.map((gender) {
                  return DropdownMenuItem<String>(
                    value: gender,
                    child: Text(gender),
                  );
                }).toList(),
                decoration: InputDecoration(
                  labelText: 'Gender',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              buildDOBField(context),
              const SizedBox(height: 12),
              buildTextField(_nameController, 'Name', true),
              const SizedBox(height: 12),
              buildTimeField(context),
              const SizedBox(height: 12),
              buildTextField(_placeOfBirthController, 'Place of Birth', true),
              const SizedBox(height: 12),
              buildTextField(_questionController, 'Your Question', true,
                  maxLines: 3),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: isLoading
                    ? null
                    : () async {
                        setState(() => isLoading = true);
                        await submitConsultation();
                        setState(() => isLoading = false);
                      },
                icon: const Icon(Icons.send),
                label: Text(isLoading ? 'Submitting...' : 'Submit'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              if (user_id != null && consultationId != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Text(
                    '✅ Booked Successfully!\nUser ID:  $user_id\nConsultation ID: $consultationId',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTextField(
      TextEditingController controller, String label, bool required,
      {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      validator: required
          ? (value) => (value == null || value.isEmpty) ? 'Required' : null
          : null,
    );
  }

  Widget buildDOBField(BuildContext context) {
    return TextFormField(
      controller: _dobController,
      readOnly: true,
      onTap: () => _selectDate(context),
      decoration: InputDecoration(
        labelText: 'Date of Birth',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: () => _selectDate(context),
        ),
      ),
      validator: (value) =>
          (value == null || value.isEmpty) ? 'Required' : null,
    );
  }

  Widget buildTimeField(BuildContext context) {
    return TextFormField(
      controller: _birthTimeController,
      readOnly: true,
      onTap: () => _selectTime(context),
      decoration: InputDecoration(
        labelText: 'Birth Time (e.g., 10:00 AM)',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        suffixIcon: IconButton(
          icon: const Icon(Icons.access_time),
          onPressed: () => _selectTime(context),
        ),
      ),
      validator: (value) =>
          (value == null || value.isEmpty) ? 'Required' : null,
    );
  }
}
