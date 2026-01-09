import 'package:flutter/material.dart';

class OrderListPage extends StatelessWidget {
  final List<dynamic> data;
  const OrderListPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Orders')),
      body: data.isEmpty
          ? Center(child: Text('No orders found.'))
          : ListView.builder(
              itemCount: data.length,
              itemBuilder: (_, i) {
                final order = data[i];
                return Card(
                  margin: EdgeInsets.all(10),
                  child: ListTile(
                    title: Text("Order ID: ${order['id']}"),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Status: ${order['status']}"),
                        Text("Qty: ${order['qty']}"),
                        Text("Price: ₹${order['price']}"),
                        Text("Date: ${order['created_at']}"),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
