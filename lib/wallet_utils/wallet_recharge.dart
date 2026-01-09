import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:nainkart_user/provider/wallet_provider.dart';

class WalletRechargePage extends StatefulWidget {
  final String token;
  const WalletRechargePage({
    super.key,
    required this.token,
    required int currentBalance,
  });

  @override
  State<WalletRechargePage> createState() => _WalletRechargePageState();
}

class _WalletRechargePageState extends State<WalletRechargePage> {
  final TextEditingController _amountController = TextEditingController();
  List<dynamic> transactions = [];
  bool _isLoading = true;
  bool _isPaymentLoading = false;
  String? _paymentUrl;
  late InAppWebViewController _webViewController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    try {
      final response = await http.get(
        Uri.parse('https://astroboon.com/api/wallet'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // print(data);
        setState(() {
          transactions = data['data'];
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load transactions');
      }
    } catch (e) {
      print('Error fetching transactions: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _proceedToPay() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isPaymentLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
            'https://astroboon.com/api/pay_now?amt=${_amountController.text}'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          setState(() {
            _paymentUrl = data['redirect'];
          });
        } else {
          throw Exception(
              'Payment failed: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('Payment failed with status ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment error: ${e.toString()}')),
      );
      setState(() {
        _isPaymentLoading = false;
      });
    }
  }

  String? _validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an amount';
    }
    if (int.tryParse(value) == null) {
      return 'Please enter a valid number';
    }
    if (int.parse(value) <= 0) {
      return 'Amount must be greater than 0';
    }
    return null;
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = Provider.of<WalletProvider>(context);
    final currentBalance = walletProvider.walletAmount;

    if (_paymentUrl != null) {
      return WillPopScope(
        onWillPop: () async {
          setState(() {
            _paymentUrl = null;
            _isPaymentLoading = false;
          });
          await walletProvider.fetchWallet(widget.token);
          await _fetchTransactions();
          return false;
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Payment Gateway'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                setState(() {
                  _paymentUrl = null;
                  _isPaymentLoading = false;
                });
                walletProvider.fetchWallet(widget.token);
                _fetchTransactions();
              },
            ),
          ),
          body: InAppWebView(
            initialUrlRequest:
                URLRequest(url: WebUri.uri(Uri.parse(_paymentUrl!))),
            onWebViewCreated: (controller) {
              _webViewController = controller;
            },
            onLoadStop: (controller, url) async {
              final currentUrl = url.toString();
              if (currentUrl.contains('success')) {
                await walletProvider.fetchWallet(widget.token);
                if (mounted) {
                  Navigator.pop(context);
                }
              }

              // 👇 Auto-close WebView if redirected to login page
              if (currentUrl.contains('nainkart.in/login')) {
                setState(() {
                  _paymentUrl = null;
                  _isPaymentLoading = false;
                });
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wallet'),
      ),
      body: Column(
        children: [
          // Current Balance Card
          Card(
            margin: const EdgeInsets.all(16),
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CURRENT BALANCE',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600])),
                      const SizedBox(height: 4),
                      Text(
                        '₹$currentBalance',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.account_balance_wallet,
                        color: Colors.purple),
                  ),
                ],
              ),
            ),
          ),

          // Recharge Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Recharge Wallet',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _amountController,
                        decoration: InputDecoration(
                          labelText: 'Enter Amount',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          prefixIcon: const Icon(Icons.currency_rupee),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                        ),
                        keyboardType: TextInputType.number,
                        validator: _validateAmount,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isPaymentLoading ? null : _proceedToPay,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: _isPaymentLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Text(
                                  'PROCEED TO PAY',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 1),
          const SizedBox(height: 8),

          // Transaction History Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Transaction History',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _fetchTransactions,
                    iconSize: 20),
              ],
            ),
          ),

          // Transaction List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : transactions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long,
                                size: 60, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text('No transactions yet',
                                style: TextStyle(
                                    color: Colors.grey[500], fontSize: 16)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final transaction = transactions[index];
                          final isCredit = transaction['type'] == 'credit';
                          final status = transaction['status'];
                          final isPending = status == 'pending';
                          final isFailed = status == 'failed';

                          // Determine colors and icon based on transaction status
                          Color amountColor =
                              isCredit ? Colors.green : Colors.red;
                          Color statusColor = Colors.green;
                          IconData statusIcon =
                              isCredit ? Icons.call_received : Icons.call_made;

                          if (isPending) {
                            statusColor = Colors.orange;
                          } else if (isFailed) {
                            statusColor = Colors.red;
                            statusIcon = Icons.error_outline;
                            amountColor = Colors.red;
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2)),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isFailed
                                      ? Colors.red.withOpacity(0.1)
                                      : isCredit
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.red.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  statusIcon,
                                  color: isFailed
                                      ? Colors.red
                                      : (isCredit ? Colors.green : Colors.red),
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                transaction['remarks'],
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: isFailed ? Colors.red : null,
                                ),
                              ),
                              subtitle: Text(
                                _formatDate(transaction['created_at']),
                                style: TextStyle(
                                    color: isFailed
                                        ? Colors.red.withOpacity(0.7)
                                        : Colors.grey[500],
                                    fontSize: 12),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${isCredit ? '+' : '-'}₹${transaction['amount']}',
                                    style: TextStyle(
                                        color: amountColor,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      status.toUpperCase(),
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}
