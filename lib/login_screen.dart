import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart' as http;
import 'package:nainkart_user/home_page.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late InAppWebViewController _webViewController;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  bool _pageLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _clearPreviousSession();
    });
  }

  Future<void> _clearPreviousSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await CookieManager.instance().deleteAllCookies();
    await WebStorageManager.instance().deleteAllData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            InAppWebView(
              initialUrlRequest: URLRequest(
                url: WebUri('https://astroboon.com/otpless_webview_hook'),
              ),
              onWebViewCreated: (controller) {
                _webViewController = controller;
                controller.addJavaScriptHandler(
                  handlerName: 'otpless',
                  callback: (args) {
                    if (args.isNotEmpty) {
                      final data = args[0];
                      if (data is Map && data['token'] != null) {
                        _handleToken(data['token'].toString());
                      }
                    }
                  },
                );
              },
              onLoadStart: (controller, url) {
                setState(() {
                  _isLoading = true;
                  _pageLoaded = false;
                });
              },
              onLoadStop: (controller, url) {
                setState(() {
                  _pageLoaded = true;
                  _isLoading = false;
                });
              },
              onConsoleMessage: (controller, consoleMessage) {
                debugPrint("WebView Console: ${consoleMessage.message}");

                // Extract token from raw console message
                if (consoleMessage.message.contains('Token:')) {
                  try {
                    final token =
                        consoleMessage.message.split('Token:').last.trim();

                    if (token.isNotEmpty) {
                      _handleToken(token);
                    }
                  } catch (e) {
                    debugPrint("Error extracting token from console: $e");
                  }
                }
              },
              // ignore: deprecated_member_use
              initialOptions: InAppWebViewGroupOptions(
                crossPlatform: InAppWebViewOptions(
                  javaScriptEnabled: true,
                ),
              ),
            ),
            if (_isLoading && !_pageLoaded)
              const Center(child: CircularProgressIndicator()),
            if (_hasError)
              AlertDialog(
                title: const Text('An unexpected error occurred.'),
                content: Text('Try again'),
                actions: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _hasError = false;
                        _isLoading = true;
                        _pageLoaded = false;
                        _webViewController.reload();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleToken(String token) async {
    try {
      debugPrint("Processing token: $token");
      setState(() => _isLoading = true);

      final response = await http.get(
        Uri.parse('https://astroboon.com/api/login?otpless_token=$token'),
      );

      debugPrint("API Response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final authToken = jsonResponse['token'];

        if (authToken != null) {
          print("Auth token received: $authToken");

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', authToken);

          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => HomePage(token: authToken),
              ),
            );
          }
        } else {
          _showError('Auth token missing in response');
        }
      } else {
        _showError('API Error: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    debugPrint("Error: $message");
    if (mounted) {
      setState(() {
        _hasError = true;
        _errorMessage = message;
      });
    }
  }
}
