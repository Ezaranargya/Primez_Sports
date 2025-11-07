import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> register(String email, String password,String role) async {
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);

    User? user = userCredential.user;

    await _firestore.collection("users").doc(user!.uid).set({
      "uid": user.uid,
      "email": email,
      "role": role,
      "status": "active",
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  Future<String?> login(String email,String password) async {
    UserCredential userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
    User? user = userCredential.user;
    DocumentSnapshot snapshot = await _firestore.collection("users").doc(user!.uid).get();

    return snapshot["role"];
  }
  Future<void> logout() async{
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;
}