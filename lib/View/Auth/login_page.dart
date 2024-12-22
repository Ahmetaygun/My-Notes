import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:notes_app/View/Auth/forgot_password.dart';
import 'package:notes_app/View/home_page.dart';
import 'package:notes_app/View/Auth/signup_page.dart';
import 'package:notes_app/Widgets/mybutton.dart';
import 'package:notes_app/Widgets/utils.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  bool isLoading = false;
  FirebaseAuth auth = FirebaseAuth.instance;
  GoogleSignIn googleSignIn = GoogleSignIn();

  // E-posta ve şifre ile giriş yapma metodu
  void login() {
    if (formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      auth
          .signInWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          )
          .then((value) {
        setState(() {
          isLoading = false;
        });
        Utils().toastMessage("Başarıyla giriş yapıldı");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }).onError((error, stackTrace) {
        setState(() {
          isLoading = false;
        });
        if (error is FirebaseAuthException) {
          switch (error.code) {
            case 'user-not-found':
              Utils().toastMessage("Bu e-posta ile kayıtlı kullanıcı bulunamadı");
              break;
            case 'wrong-password':
              Utils().toastMessage("Hatalı şifre girdiniz");
              break;
            default:
              Utils().toastMessage("Hata: ${error.message}");
          }
        } else {
          Utils().toastMessage("Hata: ${error.toString()}");
        }
      });
    }
  }

  // Google ile giriş yapma metodu
  Future<void> signInWithGoogle() async {
    try {
      GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return;
      }
      GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await auth.signInWithCredential(credential);
      Utils().toastMessage("Google ile başarıyla giriş yapıldı");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } catch (error) {
      Utils().toastMessage("Google Giriş Hatası: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.cyan,
        title: Text(
          "GİRİŞ",
          style: TextStyle(
            fontSize: 23.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 30.h),
              Center(
                child: Text(
                  "HOŞ GELDİNİZ!",
                  style: TextStyle(
                    fontSize: 23.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.cyan,
                  ),
                ),
              ),
              SizedBox(height: 30.h),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.email, color: Colors.cyan),
                  hintText: "E-posta Girin",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "E-posta adresinizi girin";
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return "Geçerli bir e-posta adresi girin";
                  }
                  return null;
                },
              ),
              SizedBox(height: 8.h),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock, color: Colors.cyan),
                  hintText: "Şifre Girin",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Şifreyi girin";
                  }
                  return null;
                },
              ),
              SizedBox(height: 10.h),
              myButton(
                isLoading: isLoading,
                title: "Giriş Yap",
                onTap: login,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ForgotPassword()),
                    );
                  },
                  child: Text(
                    "Şifremi Unuttum?",
                    style: TextStyle(fontSize: 16.sp, color: Colors.cyan[700]),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Hesabınız yok mu?",
                    style: TextStyle(fontSize: 16.sp),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SignupPage()),
                      );
                    },
                    child: Text(
                      "Kayıt Ol",
                      style: TextStyle(fontSize: 17.sp, color: Colors.cyan[700]),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              InkWell(
                onTap: signInWithGoogle,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/images/google_logo.svg',
                      width: 30.w,
                      height: 30.h,
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      "Google ile Giriş Yap",
                      style: TextStyle(fontSize: 18.sp, color: Colors.black),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
