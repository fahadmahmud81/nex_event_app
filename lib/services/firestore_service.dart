import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Add user data with the user's UID as the document ID
  Future<bool> addUser(Map<String, dynamic> userData, String userId) async {
    try {
      await _db.collection('users').doc(userId).set(userData);
      return true; // Successfully added user data
    } catch (e) {
      print('Error adding user: $e');
      return false;
    }
  }
}
