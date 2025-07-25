// TODO: FirebaseDynamicLinks is deprecated and will be shut down August 25, 2025. See https://firebase.google.com/support/dynamic-links-faq for migration options.
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/game_models.dart';
import '../../../core/utils/game_logic.dart';
import '../../../core/constants.dart';

class InviteRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Create a private lobby with invite code
  Future<Lobby> createPrivateLobby() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final inviteCode = GameLogic.generateInviteCode();

      // Create lobby document in Firestore
      final lobbyRef =
          _firestore.collection(AppConstants.lobbiesCollection).doc();
      final lobby = Lobby(
        id: lobbyRef.id,
        hostId: currentUser.uid,
        playerIds: [currentUser.uid],
        status: LobbyStatus.waiting,
        createdAt: DateTime.now(),
        isPrivate: true,
        inviteCode: inviteCode,
      );

      await lobbyRef.set(lobby.toFirestore());

      return lobby;
    } catch (e) {
      throw Exception('Failed to create private lobby: $e');
    }
  }

  /// Join a lobby using invite code
  Future<Lobby?> joinLobbyWithCode(String inviteCode) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      if (inviteCode.length != 6) {
        throw Exception('Invalid invite code format');
      }

      // Find lobby by invite code
      final querySnapshot = await _firestore
          .collection(AppConstants.lobbiesCollection)
          .where('inviteCode', isEqualTo: inviteCode)
          .where('status',
              isEqualTo: LobbyStatus.waiting.toString().split('.').last)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw 'Lobby not found or already full.';
      }

      final lobbyDoc = querySnapshot.docs.first;
      final lobby = Lobby.fromFirestore(lobbyDoc);

      // Check if lobby is full
      if (lobby.playerIds.length >= 2) {
        throw 'Lobby is full.';
      }

      // Check if user is already in lobby
      if (lobby.playerIds.contains(currentUser.uid)) {
        throw 'You are already in this lobby.';
      }

      // Add user to lobby
      final updatedPlayerIds = [...lobby.playerIds, currentUser.uid];
      final updatedLobby = lobby.copyWith(
        playerIds: updatedPlayerIds,
        status: updatedPlayerIds.length >= 2
            ? LobbyStatus.full
            : LobbyStatus.waiting,
      );

      await lobbyDoc.reference.update(updatedLobby.toFirestore());

      return updatedLobby;
    } catch (e) {
      throw 'Could not join the lobby. Please check the code and try again.';
    }
  }

  /// Create a Firebase Dynamic Link for sharing
  Future<String> createInviteLink(String lobbyId) async {
    try {
      // This method is removed as per the instructions
      throw Exception('This method is removed');
    } catch (e) {
      throw Exception('Invite link feature is not available.');
    }
  }

  /// Share invite link using system share
  Future<void> shareInviteLink(String inviteLink) async {
    try {
      await Share.share(
        'Join my Rock Paper Scissors game! $inviteLink',
        subject: 'Rock Paper Scissors Invite',
      );
    } catch (e) {
      throw Exception('Failed to share invite link: $e');
    }
  }

  /// Share invite code using system share
  Future<void> shareInviteCode(String inviteCode) async {
    try {
      await Share.share(
        'Join my Rock Paper Scissors game! Code: $inviteCode',
        subject: 'Rock Paper Scissors Invite',
      );
    } catch (e) {
      throw Exception('Failed to share invite code: $e');
    }
  }

  /// Handle incoming dynamic links
  Future<void> handleIncomingLinks() async {
    // This method is removed as per the instructions
    throw Exception('This method is removed');
  }

  void _handleDeepLink(Uri link) {
    // This method is removed as per the instructions
    throw Exception('This method is removed');
  }

  /// Generate a QR code for the invite code
  Future<String> generateQRCode(String inviteCode) async {
    try {
      // This would typically use a QR code generation library
      // For now, we'll return a placeholder
      return 'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=$inviteCode';
    } catch (e) {
      throw Exception('Failed to generate QR code: $e');
    }
  }

  /// Listen to lobby updates as a stream
  Stream<Lobby?> lobbyStream(String lobbyId) {
    return _firestore
        .collection(AppConstants.lobbiesCollection)
        .doc(lobbyId)
        .snapshots()
        .map((doc) => doc.exists ? Lobby.fromFirestore(doc) : null);
  }
}
