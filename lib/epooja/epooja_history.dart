import 'package:flutter/material.dart';

class EpoojaRequestsPage extends StatelessWidget {
  final List<dynamic> data;
  const EpoojaRequestsPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Epooja Requests')),
      body: data.isEmpty
          ? Center(child: Text('No ePooja requests found.'))
          : ListView.builder(
              itemCount: data.length,
              itemBuilder: (_, i) {
                final req = data[i];
                return Card(
                  margin: EdgeInsets.all(10),
                  child: ListTile(
                    title: Text("Slot: ${req['slot']}"),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Status: ${req['status']}"),
                        Text("Remarks: ${req['remarks']}"),
                        Text("Date: ${req['created_at']}"),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
