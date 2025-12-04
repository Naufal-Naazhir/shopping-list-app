import 'package:belanja_praktis/presentation/bloc/payment/payment_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final String paymentUrl;
  final String merchantOrderId;

  const PaymentWebViewScreen({
    super.key,
    required this.paymentUrl,
    required this.merchantOrderId,
  });

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            // Check if the user is redirected back from Duitku
            // Duitku typically redirects to finish or return URLs
            if (url.contains('duitku.com') &&
                (url.contains('finish') ||
                    url.contains('return') ||
                    url.contains('cancel'))) {
              // Give it a moment for the payment to be processed
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  context.read<PaymentBloc>().add(
                    CheckPaymentStatus(merchantOrderId: widget.merchantOrderId),
                  );
                }
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            print('WebView error: ${error.description}');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Error loading payment page: ${error.description}',
                ),
                backgroundColor: Colors.red,
              ),
            );
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Payment'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            // When user manually closes the webview
            // Check payment status before closing
            showDialog<void>(
              context: context,
              builder: (BuildContext dialogContext) {
                return AlertDialog(
                  title: const Text('Close Payment?'),
                  content: const Text(
                    'Are you sure you want to close? Payment might still be processing.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Continue Payment'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        context.pop();
                        context.read<PaymentBloc>().add(
                          CheckPaymentStatus(
                            merchantOrderId: widget.merchantOrderId,
                          ),
                        );
                      },
                      child: const Text('Close'),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
