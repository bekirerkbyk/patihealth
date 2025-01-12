import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';

class RegisterScreen extends StatelessWidget {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Hesap Oluştur",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 30),
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: usernameController,
                          decoration: const InputDecoration(
                            labelText: "Kullanıcı Adı",
                            prefixIcon: Icon(Icons.person),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: emailController,
                          decoration: const InputDecoration(
                            labelText: "E-posta",
                            prefixIcon: Icon(Icons.email),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: passwordController,
                          decoration: const InputDecoration(
                            labelText: "Şifre",
                            prefixIcon: Icon(Icons.lock),
                          ),
                          obscureText: true,
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: confirmPasswordController,
                          decoration: const InputDecoration(
                            labelText: "Şifreyi Onayla",
                            prefixIcon: Icon(Icons.lock),
                          ),
                          obscureText: true,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () async {
                            if (passwordController.text ==
                                confirmPasswordController.text) {
                              try {
                                // Kullanıcıyı Firebase'de kaydet
                                UserCredential userCredential =
                                    await FirebaseAuth.instance
                                        .createUserWithEmailAndPassword(
                                  email: emailController.text,
                                  password: passwordController.text,
                                );

                                if (userCredential.user == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          "Kayıt başarısız! Lütfen tekrar deneyin."),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                // Firestore'a kullanıcı bilgisi ekle
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(userCredential.user!.uid)
                                    .set({'username': usernameController.text});

                                // Başarılı kayıt mesajı göster
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Kayıt Başarılı!"),
                                    backgroundColor: Colors.green,
                                  ),
                                );

                                // LoginScreen'e yönlendir
                                Future.delayed(const Duration(seconds: 1), () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const LoginScreen(),
                                    ),
                                  );
                                });
                              } on FirebaseAuthException catch (e) {
                                String errorMessage;
                                if (e.code == 'email-already-in-use') {
                                  errorMessage = "Bu e-posta zaten kullanımda.";
                                } else if (e.code == 'invalid-email') {
                                  errorMessage = "Geçersiz e-posta formatı.";
                                } else {
                                  errorMessage = "Kayıt hatası: ${e.message}";
                                }

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(errorMessage),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        "Beklenmeyen bir hata: ${e.toString()}"),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } else {
                              // Şifreler eşleşmiyorsa hata mesajı göster
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Şifreler eşleşmiyor!"),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF388E3C),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 50, vertical: 15),
                          ),
                          child: const Text(
                            "Kaydol",
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


/*import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';

class RegisterScreen extends StatelessWidget {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Create Account",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 30),
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: usernameController,
                          decoration: const InputDecoration(
                            labelText: "Username",
                            prefixIcon: Icon(Icons.person),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: emailController,
                          decoration: const InputDecoration(
                            labelText: "Email",
                            prefixIcon: Icon(Icons.email),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: passwordController,
                          decoration: const InputDecoration(
                            labelText: "Password",
                            prefixIcon: Icon(Icons.lock),
                          ),
                          obscureText: true,
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: confirmPasswordController,
                          decoration: const InputDecoration(
                            labelText: "Confirm Password",
                            prefixIcon: Icon(Icons.lock),
                          ),
                          obscureText: true,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () async {
                            if (passwordController.text ==
                                confirmPasswordController.text) {
                              try {
                                // Kullanıcıyı Firebase'de kaydet
                                UserCredential userCredential =
                                    await FirebaseAuth.instance
                                        .createUserWithEmailAndPassword(
                                  email: emailController.text,
                                  password: passwordController.text,
                                );

                                // Firestore'a kullanıcı bilgisi ekle
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(userCredential.user?.uid)
                                    .set({'username': usernameController.text});

                                // Başarılı kayıt mesajı göster
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Registration Successful!"),
                                    backgroundColor: Colors.red,
                                  ),
                                );

                                // LoginScreen'e yönlendir
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const LoginScreen()),
                                );
                              } catch (e) {
                                // Hata mesajı göster
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Error: ${e.toString()}"),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } else {
                              // Şifreler eşleşmiyorsa hata mesajı göster
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Passwords do not match!"),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF388E3C),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 50, vertical: 15),
                          ),
                          child: const Text(
                            "Register",
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}*/

