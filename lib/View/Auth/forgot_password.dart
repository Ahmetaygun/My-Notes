import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:notes_app/Widgets/mybutton.dart';
import 'package:notes_app/Widgets/utils.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final emailC = TextEditingController();
  bool isLoading = false;
  final auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.cyan,
        title: Text(
          "ŞİFREMİ UNUTTUM",
          style: TextStyle(fontSize: 23.sp, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: TextField(
              controller: emailC,
              decoration: InputDecoration(
                hintText: "E-posta adresini girin",
                prefixIcon: const Icon(Icons.email, color: Colors.cyan),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: myButton(
              isLoading: isLoading,
              title: "Şifreyi Gönder", 
              onTap: () {
                setState(() {
                  isLoading = true;
                });
                auth.sendPasswordResetEmail(email: emailC.text).then((value) {
                  setState(() {
                    isLoading = false;
                  });
                  Utils().toastMessage("Şifreniz gönderildi, lütfen e-posta adresinizi kontrol edin.");
                }).onError((error, stackTrace) {
                  setState(() {
                    isLoading = false;
                  });
                  Utils().toastMessage(error.toString());
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
