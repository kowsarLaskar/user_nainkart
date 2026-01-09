import 'package:flutter/material.dart';

class ConsultationHistoryPage extends StatelessWidget {
  final List<dynamic> data;
  const ConsultationHistoryPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Consultation History')),
      body: data.isEmpty
          ? Center(child: Text('No consultations found.'))
          : ListView.builder(
              itemCount: data.length,
              itemBuilder: (_, i) => ListTile(
                title: Text("Consultation ID: ${data[i]['id']}"),
                subtitle: Text("Created at: ${data[i]['created_at']}"),
              ),
            ),
    );
  }
}
