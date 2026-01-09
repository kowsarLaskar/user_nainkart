import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart' as http;
import 'package:nainkart_user/consultation_history.dart';
import 'package:nainkart_user/epooja/epooja_history.dart';
import 'package:nainkart_user/kundli/kundli_history.dart';
import 'package:nainkart_user/login_screen.dart';
import 'package:nainkart_user/orders.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AppDrawer extends StatefulWidget {
  final String token;

  const AppDrawer({Key? key, required this.token}) : super(key: key);

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  Map<String, dynamic>? userData;
  Map<String, dynamic>? userProfile;
  bool isLoading = true;
  bool isProfileLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchUserProfile();
  }

  Future<void> _fetchUserData() async {
    try {
      final response = await http.get(
        Uri.parse('https://astroboon.com/api/user_data'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          userData = data;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Failed to load user data: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching user data: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _fetchUserProfile() async {
    try {
      final response = await http.get(
        Uri.parse('https://astroboon.com/api/user'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          userProfile = data['user'];
          isProfileLoading = false;
        });
      } else {
        setState(() => isProfileLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Failed to load profile: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      setState(() => isProfileLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching profile: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    try {
      final navigatorContext = context;

      // Clear all stored data
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Clear web data
      try {
        await CookieManager.instance().deleteAllCookies();
        await WebStorageManager.instance().deleteAllData();
      } catch (e) {
        debugPrint('Error clearing web data: $e');
      }

      // Ensure we're still mounted before navigation
      if (!navigatorContext.mounted) return;

      // Navigate to login screen
      Navigator.of(navigatorContext).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      debugPrint('Logout error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Profile Header
          Container(
            height: 150,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade800, Colors.purple.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person,
                      size: 40, color: Colors.purple.shade700),
                ),
                if (userProfile != null) ...[
                  SizedBox(height: 8),
                  Text(
                    userProfile!['name'] ?? 'User',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    userProfile!['email'] ?? '',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Drawer Menu
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading:
                      Icon(Icons.account_circle, color: Colors.purple.shade700),
                  title: Text('Profile'),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);
                    _showProfileDialog(context);
                  },
                ),
                Divider(),
                ListTile(
                  leading: Icon(Icons.history, color: Colors.purple.shade700),
                  title: Text('Kundli History'),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            KundliHistoryPage(token: widget.token),
                      ),
                    );
                  },
                ),
                Divider(),
                ListTile(
                  leading: Icon(Icons.history, color: Colors.purple.shade700),
                  title: Text('Consultation History'),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ConsultationHistoryPage(
                          data: userData?['consultation'] ?? [],
                        ),
                      ),
                    );
                  },
                ),
                Divider(),
                ListTile(
                  leading:
                      Icon(Icons.shopping_cart, color: Colors.purple.shade700),
                  title: Text('Orders'),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrderListPage(
                          data: userData?['orders'] ?? [],
                        ),
                      ),
                    );
                  },
                ),
                Divider(),
                ListTile(
                  leading:
                      Icon(Icons.calendar_today, color: Colors.purple.shade700),
                  title: Text('Epooja Requests'),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EpoojaRequestsPage(
                          data: userData?['poojas_request'] ?? [],
                        ),
                      ),
                    );
                  },
                ),
                Divider(),
                ListTile(
                  leading: Icon(Icons.settings, color: Colors.purple.shade700),
                  title: Text('Settings'),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                Divider(),
              ],
            ),
          ),

          // Logout Button at Bottom
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _showLogoutConfirmation(context);
            },
          ),
        ],
      ),
    );
  }

  void _showProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Profile Information'),
        content: isProfileLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildProfileInfoRow(
                        Icons.person, 'Name', userProfile?['name']),
                    _buildProfileInfoRow(
                        Icons.email, 'Email', userProfile?['email']),
                    _buildProfileInfoRow(
                        Icons.phone, 'Mobile', userProfile?['mobile']),
                    _buildProfileInfoRow(Icons.badge, 'Account Type',
                        userProfile?['type']?.toString().toUpperCase()),
                    _buildProfileInfoRow(Icons.calendar_today, 'Member Since',
                        _formatDate(userProfile?['created_at'])),
                  ],
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfoRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.purple),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey)),
              SizedBox(height: 2),
              Text(
                value ?? 'Not available',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Not available';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Logout'),
        content: Text('Are you sure you want to logout from the app?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _logout(context);
              Navigator.pop(context);
            },
            child: Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
