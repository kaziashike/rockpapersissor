import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/game_models.dart';
import '../../../core/constants.dart';
import '../../../core/utils/game_logic.dart';

class MatchmakingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Find an available lobby or create a new one
  Future<Lobby?> findOrCreateLobby() async {
    try {
      print('DEBUG: findOrCreateLobby called');
      final user = _auth.currentUser;
      if (user == null) {
        print('DEBUG: User not authenticated');
        throw 'User not authenticated.';
      }
      print('DEBUG: User authenticated: ${user.uid}');

      // First, try to find an existing lobby that's not full
      final availableLobbyQuery = await _firestore
          .collection(AppConstants.lobbiesCollection)
          .where(
            'status',
            isEqualTo: LobbyStatus.waiting.toString().split('.').last,
          )
          .where('isPrivate', isEqualTo: false)
          .limit(1)
          .get();

      if (availableLobbyQuery.docs.isNotEmpty) {
        // Found an available lobby, join it
        final lobbyDoc = availableLobbyQuery.docs.first;
        final lobby = Lobby.fromFirestore(lobbyDoc);

        if (lobby.canJoin && !lobby.playerIds.contains(user.uid)) {
          await _joinLobby(lobby.id, user.uid);
          return lobby.copyWith(playerIds: [...lobby.playerIds, user.uid]);
        }
      }

      // No available lobby found, create a new one
      return await _createLobby(user.uid);
    } catch (e) {
      print('DEBUG: Error in findOrCreateLobby: $e');
      throw 'Could not find or create a match. Please try again.';
    }
  }

  /// Create a new lobby
  Future<Lobby> _createLobby(String hostId) async {
    try {
      final lobbyData = {
        'hostId': hostId,
        'playerIds': [hostId],
        'status': LobbyStatus.waiting.toString().split('.').last,
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'isPrivate': false,
      };

      final docRef = await _firestore
          .collection(AppConstants.lobbiesCollection)
          .add(lobbyData);

      return Lobby(
        id: docRef.id,
        hostId: hostId,
        playerIds: [hostId],
        status: LobbyStatus.waiting,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      throw 'Could not create lobby: $e';
    }
  }

  /// Join an existing lobby
  Future<void> _joinLobby(String lobbyId, String playerId) async {
    try {
      await _firestore
          .collection(AppConstants.lobbiesCollection)
          .doc(lobbyId)
          .update({
        'playerIds': FieldValue.arrayUnion([playerId]),
      });
    } catch (e) {
      throw 'Failed to join lobby: $e';
    }
  }

  /// Leave a lobby
  Future<void> leaveLobby(String lobbyId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection(AppConstants.lobbiesCollection)
          .doc(lobbyId)
          .update({
        'playerIds': FieldValue.arrayRemove([user.uid]),
      });
    } catch (e) {
      throw 'Failed to leave lobby: $e';
    }
  }

  /// Listen to lobby updates
  Stream<Lobby?> listenToLobby(String lobbyId) {
    return _firestore
        .collection(AppConstants.lobbiesCollection)
        .doc(lobbyId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return Lobby.fromFirestore(doc);
      }
      return null;
    });
  }

  /// Join a lobby using an invite code
  Future<Lobby?> joinLobbyWithCode(String inviteCode) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'User not authenticated.';

      // Find lobby with the given invite code
      final lobbyQuery = await _firestore
          .collection(AppConstants.lobbiesCollection)
          .where('inviteCode', isEqualTo: inviteCode)
          .where(
            'status',
            isEqualTo: LobbyStatus.waiting.toString().split('.').last,
          )
          .limit(1)
          .get();

      if (lobbyQuery.docs.isEmpty) {
        throw 'Invalid invite code or lobby not found.';
      }

      final lobbyDoc = lobbyQuery.docs.first;
      final lobby = Lobby.fromFirestore(lobbyDoc);

      if (!lobby.canJoin) {
        throw 'Lobby is full or no longer accepting players.';
      }

      if (lobby.playerIds.contains(user.uid)) {
        throw 'You are already in this lobby.';
      }

      // Join the lobby
      await _joinLobby(lobby.id, user.uid);

      return lobby.copyWith(playerIds: [...lobby.playerIds, user.uid]);
    } catch (e) {
      throw 'Could not join the lobby. Please check the code and try again.';
    }
  }

  /// Create a private lobby with invite code
  Future<Lobby> createPrivateLobby() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'User not authenticated.';

      final inviteCode = GameLogic.generateInviteCode();

      final lobbyData = {
        'hostId': user.uid,
        'playerIds': [user.uid],
        'status': LobbyStatus.waiting.toString().split('.').last,
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'isPrivate': true,
        'inviteCode': inviteCode,
      };

      final docRef = await _firestore
          .collection(AppConstants.lobbiesCollection)
          .add(lobbyData);

      return Lobby(
        id: docRef.id,
        hostId: user.uid,
        playerIds: [user.uid],
        status: LobbyStatus.waiting,
        createdAt: DateTime.now(),
        isPrivate: true,
        inviteCode: inviteCode,
      );
    } catch (e) {
      throw 'Could not create a private lobby. Please try again.';
    }
  }

  /// Start a game in a lobby
  Future<void> startGame(String lobbyId) async {
    try {
      await _firestore
          .collection(AppConstants.lobbiesCollection)
          .doc(lobbyId)
          .update({
        'status': LobbyStatus.started.toString().split('.').last,
        'startedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw 'Could not start the game.';
    }
  }

  /// Get lobby by ID
  Future<Lobby?> getLobby(String lobbyId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.lobbiesCollection)
          .doc(lobbyId)
          .get();

      if (doc.exists) {
        return Lobby.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw 'Could not load the lobby.';
    }
  }
}
