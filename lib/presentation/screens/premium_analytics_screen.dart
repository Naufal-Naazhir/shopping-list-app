import 'package:flutter/material.dart';

class PremiumAnalyticsScreen extends StatefulWidget {
  const PremiumAnalyticsScreen({super.key});

  @override
  State<PremiumAnalyticsScreen> createState() => _PremiumAnalyticsScreenState();
}

class _PremiumAnalyticsScreenState extends State<PremiumAnalyticsScreen> {
  bool _isLoading = false;

  Future<void> _activatePremium() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate a network request or purchase process
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fitur Premium berhasil diaktifkan!')),
      );
      // In a real app, you would update user's premium status here
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analisis & Laporan Pantry Premium')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.diamond, size: 80, color: Colors.blueAccent),
              const SizedBox(height: 20),
              const Text(
                'Dapatkan wawasan mendalam tentang kebiasaan belanja dan penggunaan pantry Anda.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 30),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _activatePremium,
                      child: const Text('Aktifkan Fitur Premium'),
                    ),
              const SizedBox(height: 10),
              const Text(
                'Fitur ini akan menyediakan laporan detail tentang pengeluaran, item yang sering dibeli, dan potensi pemborosan.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
