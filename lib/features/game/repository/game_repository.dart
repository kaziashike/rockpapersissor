import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/game_models.dart';
import '../../../core/constants.dart';
import '../../../core/utils/game_logic.dart';

class GameRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get a game by ID
  Future<Game?> getGame(String gameId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.gamesCollection)
          .doc(gameId)
          .get()
          .timeout(const Duration(seconds: 5));

      if (doc.exists) {
        return Game.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw 'Could not get game. Please try again.';
    }
  }

  /// Listen to game updates
  Stream<Game?> listenToGame(String gameId) {
    return _firestore
        .collection(AppConstants.gamesCollection)
        .doc(gameId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return Game.fromFirestore(doc);
      }
      return null;
    });
  }

  /// Make a move in a game
  Future<void> makeMove(String gameId, Move move) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore
          .collection(AppConstants.gamesCollection)
          .doc(gameId)
          .update({
        'playerMoves.${user.uid}': move.toString().split('.').last
      }).timeout(const Duration(seconds: 5));

      // Check if all players have moved
      final game = await getGame(gameId).timeout(const Duration(seconds: 5));
      if (game != null && game.allPlayersMoved) {
        await _finishGame(game);
      }
    } catch (e) {
      throw 'Could not make your move. Please try again.';
    }
  }

  /// Finish a game and determine the winner
  Future<void> _finishGame(Game game) async {
    try {
      final winnerId = GameLogic.getWinnerId(game);

      await _firestore
          .collection(AppConstants.gamesCollection)
          .doc(game.id)
          .update({
        'status': GameStatus.finished.toString().split('.').last,
        'finishedAt': Timestamp.fromDate(DateTime.now()),
        if (winnerId != null) 'winnerId': winnerId,
      }).timeout(const Duration(seconds: 5));

      // Update player stats
      await _updatePlayerStats(game, winnerId);
    } catch (e) {
      throw 'Could not finish the game. Please try again.';
    }
  }

  /// Update player statistics
  Future<void> _updatePlayerStats(Game game, String? winnerId) async {
    try {
      for (final playerId in game.playerIds) {
        final result = GameLogic.getGameResult(game, playerId);
        if (result != null) {
          final statField = _getStatField(result);
          await _firestore
              .collection(AppConstants.usersCollection)
              .doc(playerId)
              .update({statField: FieldValue.increment(1)}).timeout(
                  const Duration(seconds: 5));
        }
      }
    } catch (e) {
      throw 'Could not update player stats.';
    }
  }

  String _getStatField(GameResult result) {
    switch (result) {
      case GameResult.win:
        return 'wins';
      case GameResult.lose:
        return 'losses';
      case GameResult.draw:
        return 'draws';
    }
  }

  /// Create a new game
  Future<Game> createGame(
    String lobbyId,
    List<String> playerIds, {
    bool isBotGame = false,
  }) async {
    try {
      final gameData = {
        'lobbyId': lobbyId,
        'playerIds': playerIds,
        'playerMoves': Map<String, String>.fromIterables(
          playerIds,
          List.filled(playerIds.length, ''),
        ),
        'status': GameStatus.waiting.toString().split('.').last,
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'isBotGame': isBotGame,
      };

      final docRef = await _firestore
          .collection(AppConstants.gamesCollection)
          .add(gameData)
          .timeout(const Duration(seconds: 5));

      return Game(
        id: docRef.id,
        lobbyId: lobbyId,
        playerIds: playerIds,
        playerMoves: Map.fromIterables(
          playerIds,
          List.filled(playerIds.length, null),
        ),
        status: GameStatus.waiting,
        createdAt: DateTime.now(),
        isBotGame: isBotGame,
      );
    } catch (e) {
      throw 'Could not create a new game. Please try again.';
    }
  }

  /// Leave a game
  Future<void> leaveGame(String gameId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection(AppConstants.gamesCollection)
          .doc(gameId)
          .update({
        'playerIds': FieldValue.arrayRemove([user.uid]),
        'playerMoves.$user.uid': FieldValue.delete(),
      }).timeout(const Duration(seconds: 5));
    } catch (e) {
      throw 'Could not leave the game.';
    }
  }

  /// Get game history for a player
  Future<List<Game>> getGameHistory(String playerId) async {
    try {
      final query = await _firestore
          .collection(AppConstants.gamesCollection)
          .where('playerIds', arrayContains: playerId)
          .where(
            'status',
            isEqualTo: GameStatus.finished.toString().split('.').last,
          )
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      return query.docs.map((doc) => Game.fromFirestore(doc)).toList();
    } catch (e) {
      throw 'Could not load your game history.';
    }
  }

  /// Listen to lobby updates
  Stream<Lobby?> listenToLobby(String lobbyId) {
    return _firestore
        .collection(AppConstants.lobbiesCollection)
        .doc(lobbyId)
        .snapshots()
        .map((doc) => doc.exists ? Lobby.fromFirestore(doc) : null);
  }

  /// Update lobby with gameId
  Future<void> updateLobbyWithGameId(String lobbyId, String gameId) async {
    await _firestore
        .collection(AppConstants.lobbiesCollection)
        .doc(lobbyId)
        .update({
      'gameId': gameId,
      'status': LobbyStatus.started.toString().split('.').last
    });
  }
}
