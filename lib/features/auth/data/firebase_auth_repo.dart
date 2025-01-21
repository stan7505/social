import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:social/features/auth/domain/auth_repo.dart';
import 'package:social/features/auth/domain/entities/app_user.dart';

class FirebaseAuthRepo implements AuthRepo {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<AppUser?> getCurrentUser() async {
    final User? user = _firebaseAuth.currentUser;

    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      return AppUser(uid: user.uid, email: user.email!, name: userDoc['name']);
    } else {
      return null;
    }
  }

  String getUid() {
    final User? user = _firebaseAuth.currentUser;
    return user!.uid;
  }

  @override
  Future<void> logOut() async {
    await _firebaseAuth.signOut();
  }

  @override
  Future<AppUser> loginwithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();
      AppUser user = AppUser(
          uid: userCredential.user!.uid,
          email: userCredential.user!.email!,
          name: userDoc['name']);
      return user;
    } catch (e) {
      throw Exception('Login failed $e');
    }
  }

  @override
  Future<AppUser> registerwithEmailAndPassword(String name, String email, String password) async {
    try {
      UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);
      AppUser user = AppUser(
          uid: userCredential.user!.uid,
          email: userCredential.user!.email!,
          name: name);
      await _firestore.collection('users').doc(user.uid).set(user.toJson());
      return user;
    } catch (e) {
      throw Exception('Registration failed $e');
    }
  }
}
