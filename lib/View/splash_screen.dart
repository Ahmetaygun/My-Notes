import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:notes_app/View/splash_services.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
  
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    SplashServices splashscreen=SplashServices();
    splashscreen.isLogin(context);
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text("NOTLARIM",style: TextStyle(fontSize: 25.sp,fontWeight: FontWeight.bold,color: Colors.cyan[800]),)),
    );
  }
}