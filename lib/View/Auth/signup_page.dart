import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final emailC = TextEditingController();
  final passC = TextEditingController();
  final nameC = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool _obscurePassword = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  void signUp() async {
    if (formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      try {
        // Kullanıcıyı Firebase Authentication'da oluştur
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: emailC.text.trim(),
          password: passC.text.trim(),
        );

        // Firestore'da kullanıcı verilerini sakla
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'name': nameC.text.trim(),
          'email': emailC.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });

        setState(() {
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Kayıt başarıyla tamamlandı!")),
        );

        // Kullanıcı giriş sayfasına yönlendir
        Navigator.pop(context);
      } on FirebaseAuthException catch (e) {
        setState(() {
          isLoading = false;
        });

        String errorMessage = "Kayıt olurken bir hata oluştu.";
        if (e.code == 'weak-password') {
          errorMessage = "Şifre çok zayıf.";
        } else if (e.code == 'email-already-in-use') {
          errorMessage = "Bu email zaten kullanımda.";
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      } catch (e) {
        setState(() {
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata: ${e.toString()}")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kayıt Ol"),
        centerTitle: true,
        backgroundColor: Colors.cyan,
      ),
      body: Form(
        key: formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              TextFormField(
                controller: nameC,
                decoration: const InputDecoration(
                  labelText: "İsim",
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "İsim girin.";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: emailC,
                decoration: const InputDecoration(
                  labelText: "Email",
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Email girin.";
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return "Geçerli bir email girin.";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: passC,
                decoration: InputDecoration(
                  labelText: "Şifre",
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscurePassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Şifre girin.";
                  }
                  if (value.length < 6) {
                    return "Şifre en az 6 karakter olmalı.";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: signUp,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text("Kayıt Ol"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan, 
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
