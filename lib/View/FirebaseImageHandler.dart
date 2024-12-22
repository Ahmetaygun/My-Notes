import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseImageHandler {
  final ImagePicker _picker = ImagePicker();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Görüntü seçme
  Future<XFile?> selectImage() async {
    try {
      return await _picker.pickImage(source: ImageSource.gallery);
    } catch (e) {
      debugPrint('Görsel seçerken hata: $e');
      return null;
    }
  }

  // Firebase Storage’a yükleme
  Future<String?> uploadImage(XFile imageFile) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference storageRef =
          FirebaseStorage.instance.ref().child('images/$fileName');
      // Dosyayı yükleme işlemi
      await storageRef.putFile(File(imageFile.path));
      // Yükleme sonrası URL al
      return await storageRef.getDownloadURL();
    } catch (e) {
      debugPrint('Görsel yüklerken hata: $e');
      return null;
    }
  }

  // Firestore’a URL kaydetme
  Future<void> saveImageUrl(String imageUrl) async {
    try {
      await _firestore.collection('images').add({
        'url': imageUrl,
        'uploadedAt': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('Firestore’a kaydederken hata: $e');
    }
  }

  // URL’leri okuma (Stream kullanarak gerçek zamanlı güncellemeler için)
  Stream<List<String>> getImageUrls() {
    return _firestore
        .collection('images')
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => doc['url'] as String).toList());
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Görüntü İşlemleri',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseImageHandler handler = FirebaseImageHandler();
  List<String> imageUrls = [];
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _fetchImageUrls();
  }

  // Firebase’den görüntü URL'lerini al
  Future<void> _fetchImageUrls() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('images').get();
      setState(() {
        imageUrls = snapshot.docs.map((doc) => doc['url'] as String).toList();
      });
    } catch (e) {
      debugPrint('Firestore’dan veriler alınırken hata oluştu: $e');
    }
  }

  // Görsel yükleme işlemi
  void uploadImage(BuildContext context) async {
    // 1. Kullanıcının oturum açıp açmadığını kontrol et
    User? user = _auth.currentUser;
    if (user == null) {
      // Oturum açılmamışsa mesaj göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Görsel yüklemek için giriş yapın.')),
      );
      return;
    }

    XFile? selectedImage = await handler.selectImage();
    if (selectedImage != null) {
      String? imageUrl = await handler.uploadImage(selectedImage);
      if (imageUrl != null) {
        // Yükleme başarılıysa URL kaydetme
        await handler.saveImageUrl(imageUrl);

        // Listeyi güncelle
        setState(() {
          imageUrls.add(imageUrl);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Görsel yüklendi!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Görsel yüklenemedi.')),
        );
      }
    } else {
      // Görsel seçilmediğinde bildirim göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Görsel seçilmedi.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Firebase Görüntü İşlemleri')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () => uploadImage(context),
            child: Text('Görsel Seç ve Yükle'),
          ),
          Expanded(
            child: imageUrls.isEmpty
                ? Center(child: CircularProgressIndicator())
                : GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.0,
                      crossAxisSpacing: 10.0,
                      mainAxisSpacing: 10.0,
                    ),
                    itemCount: imageUrls.length,
                    itemBuilder: (context, index) {
                      final imageUrl = imageUrls[index];

                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        elevation: 4,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Firebase başlatma
  runApp(MyApp());
}
