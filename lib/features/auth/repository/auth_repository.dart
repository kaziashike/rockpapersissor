import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/game_models.dart';
import '../../../core/constants.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<User?> getCurrentUser() async {
    return _auth.currentUser;
  }

  Future<User> signInAnonymously() async {
    try {
      final userCredential = await _auth.signInAnonymously();
      final user = userCredential.user;

      if (user != null) {
        // Create user profile in Firestore
        await _createUserProfile(user);
        return user;
      } else {
        throw 'Failed to sign in anonymously.';
      }
    } catch (e) {
      throw 'Sign in failed. Please try again.';
    }
  }

  Future<User> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn();
      // Optionally sign out first to ensure a fresh sign-in
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw 'Google sign-in was cancelled.';
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user != null) {
        await _createUserProfile(user);
        return user;
      } else {
        throw 'Failed to sign in with Google.';
      }
    } catch (e) {
      throw 'Google sign in failed. Please try again.';
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw 'Sign out failed. Please try again.';
    }
  }

  Future<void> updateUserProfile(String name) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(name);
        await _updateUserProfileInFirestore(user.uid, name);
      }
    } catch (e) {
      throw 'Profile update failed. Please try again.';
    }
  }

  Future<void> _createUserProfile(User user) async {
    try {
      final player = Player(
        id: user.uid,
        name: user.displayName ?? 'Anonymous Player',
        photoUrl: user.photoURL,
        lastSeen: DateTime.now(),
      );

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .set(player.toFirestore());
    } catch (e) {
      throw 'Failed to create user profile.';
    }
  }

  Future<void> _updateUserProfileInFirestore(String userId, String name) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
        'name': name,
        'lastSeen': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw 'Failed to update user profile.';
    }
  }

  Future<Player?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      if (doc.exists) {
        return Player.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw 'Failed to get user profile.';
    }
  }
}
