import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:notes_app/View/home_page.dart';
import 'package:notes_app/View/Auth/login_page.dart';
 
class SplashServices{
  void isLogin(context){
    FirebaseAuth auth=FirebaseAuth.instance;
    final user=auth.currentUser;
    if(user!=null){
      Timer(const Duration(seconds: 3), ()=>Navigator.pushReplacement(context,MaterialPageRoute(builder:(context) => const HomePage(),)));
    }else{
      Timer(const Duration(seconds: 3), ()=>Navigator.pushReplacement(context,MaterialPageRoute(builder:(context) => const LoginPage(),)));
    }
  }
}