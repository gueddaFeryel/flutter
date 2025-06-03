import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _baseUrl = 'http://10.0.2.2:8089';
  final http.Client _client;

  AuthService({http.Client? client}) : _client = client ?? http.Client();

  Stream<AppUser?> get user {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;

      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (!doc.exists) return null;

        final userData = doc.data()!;
        final medicalStaff = await getMedicalStaffByFirebaseId(user.uid);
        return AppUser.fromFirebase(user, {
          ...userData,
          'id': medicalStaff['id'],
          'role': medicalStaff['role'],
        });
      } catch (e) {
        print('Error fetching user data: $e');
        return null;
      }
    });
  }

  Future<AppUser?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return null;

      final userData = doc.data()!;
      if (userData['isApproved'] == false) {
        throw Exception('Compte non approuvé');
      }

      final medicalStaff = await getMedicalStaffByFirebaseId(user.uid);
      return AppUser.fromFirebase(user, {
        ...userData,
        'id': medicalStaff['id'],
        'role': medicalStaff['role'],
      });
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  Future<AppUser> login(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user!;
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        throw Exception('Données utilisateur non trouvées');
      }

      final userData = doc.data()!;
      if (userData['isApproved'] == false) {
        await _auth.signOut();
        throw Exception('Compte non approuvé par l\'administrateur');
      }

      final medicalStaff = await getMedicalStaffByFirebaseId(user.uid);
      return AppUser.fromFirebase(user, {
        ...userData,
        'id': medicalStaff['id'],
        'role': medicalStaff['role'],
      });
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  Future<AppUser> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user!;
      await _firestore.collection('users').doc(user.uid).set({
        'firebase_uid': user.uid,
        'email': email,
        'prenom': firstName,
        'nom': lastName,
        'role': role,
        'is_admin': false,
        'isApproved': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return AppUser.fromFirebase(user, {
        'prenom': firstName,
        'nom': lastName,
        'role': role,
        'is_admin': false,
        'isApproved': false,
      });
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw Exception('Erreur d\'inscription: $e');
    }
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error during logout: $e');
      throw Exception('Déconnexion échouée: $e');
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<Map<String, dynamic>> getMedicalStaffByFirebaseId(String firebaseId) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/api/medical-staff/by-firebase/$firebaseId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        throw Exception('Personnel médical non trouvé');
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur réseau: $e');
    }
  }

  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Email invalide';
      case 'user-disabled':
        return 'Compte désactivé';
      case 'user-not-found':
        return 'Aucun compte trouvé';
      case 'wrong-password':
        return 'Mot de passe incorrect';
      case 'email-already-in-use':
        return 'Email déjà utilisé';
      case 'operation-not-allowed':
        return 'Opération non autorisée';
      case 'weak-password':
        return 'Mot de passe trop faible';
      default:
        return 'Erreur d\'authentification';
    }
  }
}