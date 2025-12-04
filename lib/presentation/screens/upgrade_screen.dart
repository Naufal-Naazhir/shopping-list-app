import 'package:belanja_praktis/presentation/bloc/payment/payment_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class UpgradeScreen extends StatefulWidget {
  const UpgradeScreen({super.key});

  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen> {
  @override
  void initState() {
    super.initState();
    // Automatically trigger the payment initiation when the screen loads
    context.read<PaymentBloc>().add(
      const InitiatePayment(
        amount: 15000, // Example amount
        productDetails: 'Premium Account Upgrade',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upgrade ke Premium')),
      body: BlocListener<PaymentBloc, PaymentState>(
        listener: (context, state) {
          if (state is PaymentWebViewRequired) {
            // Navigate to the webview when the URL is ready
            context.push(
              '/payment-webview',
              extra: {
                'paymentUrl': state.paymentUrl,
                'merchantOrderId': state.merchantOrderId,
              },
            );
          } else if (state is PaymentSuccess) {
            // Handle successful payment
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                const SnackBar(
                  content: Text(
                    '✅ Pembayaran Berhasil! Akun Anda telah ditingkatkan ke Premium.',
                  ),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 3),
                ),
              );
            // Wait a moment before navigating back
            Future.delayed(const Duration(seconds: 2), () {
              if (context.mounted) {
                context.go('/'); // Go to home instead of pop
              }
            });
          } else if (state is PaymentFailure) {
            // Handle failed payment
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(
                    '❌ Pembayaran Gagal: ${state.message}\n\nSilakan coba lagi.',
                  ),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 4),
                ),
              );
            // Navigate back to allow retry
            Future.delayed(const Duration(seconds: 2), () {
              if (context.mounted) {
                context.pop();
              }
            });
          }
        },
        child: BlocBuilder<PaymentBloc, PaymentState>(
          builder: (context, state) {
            if (state is PaymentFailure) {
              // --- WIDGET UNTUK MENAMPILKAN KEGAGALAN ---
              return Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 60,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Gagal Memulai Pembayaran',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Error: ${state.message}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<PaymentBloc>().add(
                          const InitiatePayment(
                            amount: 15000,
                            productDetails: 'Premium Account Upgrade',
                          ),
                        );
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('Batal'),
                    ),
                  ],
                ),
              );
            }

            // --- WIDGET UNTUK MEMUAT / LOADING ---
            return Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 20),
                      const Text(
                        'Menghubungkan ke gerbang pembayaran...',
                        style: TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
                      Text(
                        'Harga Premium: Rp 1.000',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Dapatkan daftar tak terbatas, item, dan pengalaman bebas iklan',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: () => context.pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                        ),
                        child: const Text('Batal'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
