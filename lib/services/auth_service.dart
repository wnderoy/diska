import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

/// Wraps Firebase Auth + local session state.
/// Provides reactive auth state via a ValueNotifier so widgets can listen.
class AuthService {
  AuthService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static final ValueNotifier<User?> authState = ValueNotifier(null);
  static UserModel? _profileCache;

  static Future<void> init() async {
    // Listen to Firebase auth state changes
    _auth.authStateChanges().listen((user) {
      authState.value = user;
      if (user == null) _profileCache = null;
    });
    // Populate initial state
    authState.value = _auth.currentUser;
  }

  static bool get isLoggedIn => _auth.currentUser != null;
  static String? get userId => _auth.currentUser?.uid;
  static String? get userEmail => _auth.currentUser?.email;

  // ---------------------------------------------------------------------------
  // Auth actions
  // ---------------------------------------------------------------------------
  static Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      authState.value = cred.user;
      return cred;
    } on FirebaseAuthException catch (e) {
      throw Exception(_friendlyAuthError(e));
    }
  }

  static Future<UserCredential?> signUpWithEmail(String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      authState.value = cred.user;

      // Create user document in Firestore on first sign-up
      if (cred.user != null) {
        await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
          'user_id': cred.user!.uid,
          'username': email.split('@').first,
          'bio': '',
          'profile_image_url': '',
          'is_artist': false,
          'is_verified': false,
          'top_genres': [],
          'top_artists': [],
          'following_count': 0,
          'followers_count': 0,
          'displayed_patch_ids': [],
          'saved_shows': [],
        });
      }

      return cred;
    } on FirebaseAuthException catch (e) {
      throw Exception(_friendlyAuthError(e));
    }
  }

  static Future<void> signOut() async {
    await _auth.signOut();
    authState.value = null;
    _profileCache = null;
  }

  // ---------------------------------------------------------------------------
  // Profile updates
  // ---------------------------------------------------------------------------
  static Future<void> updateProfile({
    String? username,
    String? bio,
    List<String>? topGenres,
    List<String>? topArtists,
  }) async {
    final uid = userId;
    if (uid == null) return;
    final data = <String, dynamic>{};
    if (username != null) data['username'] = username;
    if (bio != null) data['bio'] = bio;
    if (topGenres != null) data['top_genres'] = topGenres;
    if (topArtists != null) data['top_artists'] = topArtists;
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update(data);
      _profileCache = null; // invalidate cache
    } on FirebaseException catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // Firestore user profile
  // ---------------------------------------------------------------------------
  static Future<UserModel?> fetchProfile() async {
    final uid = userId;
    if (uid == null) return null;
    if (_profileCache != null) return _profileCache;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      _profileCache = UserModel.fromJson({...doc.data() as Map<String, dynamic>, 'user_id': doc.id});
      return _profileCache;
    } on FirebaseException catch (_) {
      return null;
    }
  }

  static void invalidateProfileCache() => _profileCache = null;

  // ---------------------------------------------------------------------------
  // Saved shows array (read from Firestore user doc)
  // ---------------------------------------------------------------------------
  static Future<List<String>> getSavedShowIds() async {
    final uid = userId;
    if (uid == null) return [];
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!doc.exists) return [];
      final data = doc.data()!;
      return (data['saved_shows'] as List<dynamic>?)?.cast<String>() ?? [];
    } on FirebaseException catch (_) {
      return [];
    }
  }

  static Future<void> toggleSavedShow(String showId) async {
    final uid = userId;
    if (uid == null) return;
    final docRef = FirebaseFirestore.instance.collection('users').doc(uid);

    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final doc = await tx.get(docRef);
        if (!doc.exists) return;
        final data = doc.data() as Map<String, dynamic>;
        final saved = List<String>.from(data['saved_shows'] as List? ?? []);
        if (saved.contains(showId)) {
          saved.remove(showId);
        } else {
          saved.add(showId);
        }
        tx.update(docRef, {'saved_shows': saved});
      });
      invalidateProfileCache();
    } on FirebaseException catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // Error message helper
  // ---------------------------------------------------------------------------
  static String _friendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'invalid-credential':
        return 'No account found with that email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with that email.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
