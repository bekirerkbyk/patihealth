import 'package:flutter/material.dart';
import 'login_screen.dart';

class HomeScreen extends StatelessWidget {
  final String username;

  const HomeScreen({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4CAF50),
      body: Center(
        // Center widget ile ekranı ortalıyoruz
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Minimum boyutta tutuyoruz
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo
              Image.asset(
                'assets/loading_dog.gif',
                height: 120,
                fit: BoxFit.cover,
              ),
              const Text(
                'Merhaba! Hoş Geldiniz',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),

              // Alt metin
              const Text(
                'Otur ve bekle - Biz dışarı çıkıp oynayacağız',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 40),

              // Başla Butonu
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber, // Buton rengi
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                  );
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'HAYDİ BAŞLAYALIM',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                    SizedBox(width: 10),
                    Icon(Icons.arrow_forward, color: Colors.white),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              TextButton(
                onPressed: () {},
                child: const Text(
                  'Zaten bir hesabınız var mı? Giriş Yap',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
