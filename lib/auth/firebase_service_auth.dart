import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Хэрэглэгч бүртгэх функц
  Future<User?> signUpWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = credential.user;
      if (user != null) {
        // Firestore-д хэрэглэгчийн мэдээллийг хадгалах
        await _createUserRecord(user.uid, email);
      }
      return user;
    } catch (e) {
      print("Бүртгэл үүсгэх үед алдаа гарлаа: $e");
      rethrow; // Алдааг UI хэсэгт харуулах
    }
  }

  // Хэрэглэгч нэвтрэх функц
  Future<User?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return credential.user;
    } catch (e) {
      print("Нэвтрэх үед алдаа гарлаа: $e");
      rethrow; // Алдааг UI хэсэгт харуулах
    }
  }

  // Firestore-д хэрэглэгчийн мэдээллийг хадгалах функц
  Future<void> _createUserRecord(
    String userId,
    String email,
  ) async {
    try {
      await FirebaseFirestore.instance.collection('student').doc(userId).set({
        'email': email,
        'createdAt': DateTime.now(), // Бүртгэл үүссэн огноо
      });
    } catch (e) {
      print("Хэрэглэгчийн мэдээллийг хадгалах үед алдаа гарлаа: $e");
      rethrow;
    }
  }
}
