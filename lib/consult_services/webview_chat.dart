import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class ChatWebView extends StatefulWidget {
  final String userId;
  final String consultationId;
  final String astrolgerName;

  const ChatWebView({
    Key? key,
    required this.userId,
    required this.consultationId,
    required this.astrolgerName,
  }) : super(key: key);

  @override
  State<ChatWebView> createState() => _ChatWebViewState();
}

class _ChatWebViewState extends State<ChatWebView> {
  bool _isLoading = true;
  late final String url;

  @override
  void initState() {
    super.initState();
    url =
        "https://astroboon.com/chatapiendpoint?user_id=${widget.userId}&id=${widget.consultationId}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${widget.astrolgerName}")),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(url)),
            initialOptions: InAppWebViewGroupOptions(
              crossPlatform: InAppWebViewOptions(
                javaScriptEnabled: true,
                mediaPlaybackRequiresUserGesture: false,
              ),
              android: AndroidInAppWebViewOptions(
                useHybridComposition: true,
              ),
            ),
            onLoadStart: (controller, _) {
              setState(() => _isLoading = true);
            },
            onLoadStop: (controller, _) {
              setState(() => _isLoading = false);
            },
            onLoadError: (controller, url, code, message) {
              setState(() => _isLoading = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Failed to load page: $message")),
              );
            },
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
