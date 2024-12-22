import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:notes_app/Widgets/mybutton.dart';
import 'package:notes_app/Widgets/utils.dart';

class AddNote extends StatefulWidget {
  const AddNote({super.key});

  @override
  State<AddNote> createState() => _AddNoteState();
}

class _AddNoteState extends State<AddNote> {
  bool isLoading = false;
  final TextEditingController addC = TextEditingController();

  // Firestore Koleksiyonu Referansı
  late final CollectionReference addNote;

  @override
  void initState() {
    super.initState();

    // Kullanıcının oturum açıp açmadığını kontrol et
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      addNote = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notes');
    } else {
      Utils().toastMessage("Kullanıcı doğrulanmadı!");
      Navigator.pushNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    addC.dispose(); // Controller'ı serbest bırak
    super.dispose();
  }

  void addNoteToFirestore() async {
    // Kullanıcı not eklemek isterken loading durumu
    setState(() {
      isLoading = true;
    });

    if (addC.text.isEmpty) {
      setState(() {
        isLoading = false;
      });
      Utils().toastMessage("Not içeriği boş olamaz!");
      return;
    }

    try {
      await addNote.add({
        "title": addC.text,
        "created_at": FieldValue.serverTimestamp(),
      });
      Utils().toastMessage("Not başarıyla eklendi!");
      Navigator.pop(context);
    } catch (error) {
      Utils().toastMessage("Hata: ${error.toString()}");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.cyan,
        title: Text(
          "NOT EKLE",
          style: TextStyle(fontSize: 23.sp, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: addC,
                maxLines: 5,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: "Notunuzu girin",
                  focusColor: Colors.cyan,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                ),
              ),
              SizedBox(height: 20.h),
              myButton(
                isLoading: isLoading,
                title: "EKLE",
                onTap: addNoteToFirestore,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
