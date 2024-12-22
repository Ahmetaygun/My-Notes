import 'package:flutter/material.dart'; import 'package:flutter_screenutil/flutter_screenutil.dart';

class myButton extends StatelessWidget { final String title; final bool isLoading; final VoidCallback onTap; const myButton({super.key, required this.title, this.isLoading=false, required this.onTap

});

@override Widget build(BuildContext context) { return Padding( padding: const EdgeInsets.all(11.0), child: ElevatedButton( style: ButtonStyle( backgroundColor: WidgetStatePropertyAll( Colors.cyan[700] ), minimumSize: const WidgetStatePropertyAll( Size(double.infinity,50) ), shape: WidgetStatePropertyAll( RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)) ) ), onPressed: onTap, child:isLoading? const CircularProgressIndicator():Text(title,style: TextStyle(fontSize: 18.sp, color: Colors.white),) ), ); } }