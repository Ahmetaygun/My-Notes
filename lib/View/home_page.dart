import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:notes_app/View/add_note.dart';
import 'package:notes_app/View/Auth/login_page.dart';
import 'package:notes_app/Widgets/utils.dart';

class FirebaseImageHandler {
  final _firebaseAuth = FirebaseAuth.instance;
  final _firebaseStorage = FirebaseStorage.instance;
  final _firestore = FirebaseFirestore.instance;

  Future<void> uploadImage() async {
    try {
      final picker = ImagePicker();
      final pickedImage = await picker.pickImage(source: ImageSource.gallery);

      if (pickedImage == null) return;

      final file = File(pickedImage.path);
      final userId = _firebaseAuth.currentUser?.uid;

      if (userId == null) throw Exception("Kullanıcı kimliği doğrulanmadı");

      final ref = _firebaseStorage
          .ref()
          .child('user_images/$userId/${DateTime.now().toIso8601String()}');
      final uploadTask = await ref.putFile(file);

      final imageUrl = await uploadTask.ref.getDownloadURL();

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('images')
          .add({'url': imageUrl, 'uploadedAt': Timestamp.now()});
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<String>> getImageUrlsStream() {
    final userId = _firebaseAuth.currentUser?.uid;
    if (userId == null) throw Exception("Kullanıcı kimliği doğrulanmadı");

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('images')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc['url'] as String).toList();
    });
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final auth = FirebaseAuth.instance;
  final editController = TextEditingController();
  final FirebaseImageHandler _imageHandler = FirebaseImageHandler();

  Stream<QuerySnapshot> get notesStream => FirebaseFirestore.instance
      .collection('users')
      .doc(auth.currentUser!.uid)
      .collection('notes')
      .snapshots();

  CollectionReference get notesCollection => FirebaseFirestore.instance
      .collection('users')
      .doc(auth.currentUser!.uid)
      .collection('notes');

  void _logout() {
    auth.signOut().then((_) {
      Utils().toastMessage('Çıkış yapıldı');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }).catchError((error) {
      Utils().toastMessage(error.toString());
    });
  }

  void _editNote(BuildContext context, String noteId, String initialText) {
    editController.text = initialText;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[300],
        title: Text(
          "Notu Düzenle",
          style: TextStyle(fontSize: 19.sp, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          maxLines: 2,
          controller: editController,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            hintText: "Notunuzu düzenleyin",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "İptal",
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                color: Colors.cyan[600],
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              notesCollection.doc(noteId).update({'title': editController.text});
              Navigator.pop(context);
            },
            child: Text(
              "Güncelle",
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                color: Colors.cyan[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteNote(String noteId) {
    notesCollection.doc(noteId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.cyan,
        title: Text(
          "Notlarım",
          style: TextStyle(
              fontSize: 23.sp, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, size: 30, color: Colors.red),
            onPressed: _logout,
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            backgroundColor: Colors.cyan[700],
            onPressed: () async {
              try {
                await _imageHandler.uploadImage();
                Utils().toastMessage("Resim başarıyla yüklendi");
              } catch (e) {
                Utils().toastMessage("Resim yüklenemedi: $e");
              }
            },
            child: const Icon(Icons.image),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            backgroundColor: Colors.cyan[700],
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddNote()),
              );
            },
            child: const Icon(Icons.add),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: notesStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return const Center(child: Text("Bir hata oluştu."));
                  }

                  final notes = snapshot.data?.docs ?? [];
                  if (notes.isEmpty) {
                    return const Center(child: Text("Hiç not yok."));
                  }

                  return ListView.builder(
                    itemCount: notes.length,
                    itemBuilder: (context, index) {
                      final note = notes[index];
                      final noteId = note.id;
                      final title = note['title'];

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5.0),
                        child: Card(
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          color: Colors.cyan[100],
                          child: ListTile(
                            title: Text(
                              title,
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            trailing: PopupMenuButton(
                              color: Colors.grey[100],
                              icon: Icon(Icons.more_vert,
                                  color: Colors.cyan[700]),
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  child: ListTile(
                                    leading: Icon(Icons.edit,
                                        color: Colors.cyan[700]),
                                    title: Text(
                                      "Düzenle",
                                      style: TextStyle(fontSize: 16.sp),
                                    ),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _editNote(context, noteId, title);
                                    },
                                  ),
                                ),
                                PopupMenuItem(
                                  child: ListTile(
                                    leading: Icon(Icons.delete,
                                        color: Colors.red),
                                    title: Text(
                                      "Sil",
                                      style: TextStyle(fontSize: 16.sp),
                                    ),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _deleteNote(noteId);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Expanded(
              child: StreamBuilder<List<String>>(
                stream: _imageHandler.getImageUrlsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text("Resimler yüklenemedi"));
                  }

                  final images = snapshot.data ?? [];
                  if (images.isEmpty) {
                    return const Center(child: Text("Hiç resim yok"));
                  }

                  return ListView.builder(
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      final imageUrl = images[index];

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5.0),
                        child: Card(
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Image.network(
                            imageUrl,
                            width: double.infinity, // Resim genişliğini ekler
                            fit: BoxFit.cover, // Resmin kapsayıcıya sığacak şekilde ölçeklenmesini sağlar
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
