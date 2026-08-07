import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/presentation/widgets/logout_button.dart';
import '../../../core/network/api_client.dart';

class FarmWebScreen extends StatefulWidget {
  const FarmWebScreen({super.key});

  @override
  State<FarmWebScreen> createState() => _FarmWebScreenState();
}

class _FarmWebScreenState extends State<FarmWebScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.background)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            _controller.runJavaScript("""
              var style = document.createElement('style');
              style.innerHTML = '*::-webkit-scrollbar { display: none !important; width: 0 !important; height: 0 !important; }';
              document.head.appendChild(style);
            """);
          },
        ),
      )
      ..loadRequest(Uri.parse('${ApiClient.baseUrl}/?app=true'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            RichText(
              text: TextSpan(
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                children: const [
                  TextSpan(text: 'ROOT'),
                  TextSpan(
                      text: 'U', style: TextStyle(color: AppColors.secondary)),
                  TextSpan(text: 'S'),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.surface.withValues(alpha: 0.9),
        elevation: 0,
        actions: const [
          LogoutButton(),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF21AC7A)),
            ),
        ],
      ),
    );
  }
}
