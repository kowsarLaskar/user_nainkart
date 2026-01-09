import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart'; // For date formatting

class KundliHistoryPage extends StatefulWidget {
  final String token;

  const KundliHistoryPage({Key? key, required this.token}) : super(key: key);

  @override
  _KundliHistoryPageState createState() => _KundliHistoryPageState();
}

class _KundliHistoryPageState extends State<KundliHistoryPage> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _history = [];

  @override
  void initState() {
    super.initState();
    fetchKundliHistory();
  }

  Future<void> fetchKundliHistory() async {
    try {
      final response = await http.get(
        Uri.parse('https://astroboon.com/api/kundli_history'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Accept': 'application/json',
        },
      );

      final jsonData = json.decode(response.body);
      // print("Raw JSON Data: $jsonData");

      if (response.statusCode == 200 && jsonData['status'] == true) {
        setState(() {
          _history = jsonData['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = jsonData['message'] ?? 'Something went wrong';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open link")),
      );
    }
  }

  String formatDate(String? dateStr) {
    if (dateStr == null) return "Unknown";
    try {
      final dateTime = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy • hh:mm a').format(dateTime);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Kundli History', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.purple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child:
                      Text(_error!, style: const TextStyle(color: Colors.red)))
              : _history.isEmpty
                  ? const Center(
                      child: Text(
                        'Your kundli will arrive soon.',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _history.length,
                      padding: const EdgeInsets.all(16),
                      itemBuilder: (context, index) {
                        final item = _history[index];
                        final name = item['name'] ?? 'Kundli Document';
                        final createdAt = formatDate(item['created_at']);
                        final url = item['download_link'] ?? '';

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 5,
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.person,
                                        color: Colors.purple),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (url.isNotEmpty)
                                      IconButton(
                                        icon: const Icon(Icons.open_in_new,
                                            color: Colors.purple),
                                        onPressed: () => _openLink(url),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time_rounded,
                                        size: 18, color: Colors.grey),
                                    const SizedBox(width: 6),
                                    Text(
                                      createdAt,
                                      style: const TextStyle(
                                          fontSize: 14, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
