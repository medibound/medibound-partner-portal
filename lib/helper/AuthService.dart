import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;

  Future<User?> loginUser(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return result.user;
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  Future<User?> createUser(
    String email,
    String password,
    String firstName,
    String lastName,
    String middleName,
    String gender,
    DateTime birthdate,
    Uint8List imageData,
  ) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      await uploadImageToFirebase(imageData, "profile", result.user!.uid);
      return result.user;
    } catch (e) {
      print('Registration error: $e');
      return null;
    }
  }

  Future<void> uploadImageToFirebase(
      Uint8List imageData, String name, String userId) async {
    if (imageData != Uint8List(0)) {
      final storageRef =
          storage.ref().child('profile_pictures/$userId/$name.jpg');
      try {
        // Upload the image to Firebase Storage
        await storageRef.putData(imageData);
        // Fetch the updated profile data
        // Image upload successful, you can proceed with other actions
      } catch (e) {
        // Handle the error
        print('Error uploading image: $e');
      }
    }
  }

  
}
