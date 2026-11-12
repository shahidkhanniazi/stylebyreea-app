import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../theme.dart';

/// In-app browser used for redirect payment gateways and store pages.
class WebViewScreen extends StatefulWidget {
  final String url;
  final String title;
  final bool closeOnOrderReceived;
  const WebViewScreen({super.key, required this.url, required this.title, this.closeOnOrderReceived = false});
  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController ctrl;
  int progress = 0;

  @override
  void initState() {
    super.initState();
    ctrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (p) { if (mounted) setState(() => progress = p); },
        onNavigationRequest: (req) {
          if (widget.closeOnOrderReceived && req.url.contains('order-received')) {
            Navigator.of(context).pop(true);
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(2),
            child: progress < 100 ? LinearProgressIndicator(value: progress / 100, minHeight: 2, color: SBR.gold, backgroundColor: Colors.transparent) : const SizedBox(height: 2),
          ),
        ),
        body: WebViewWidget(controller: ctrl),
      );
}
