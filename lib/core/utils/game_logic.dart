import 'dart:math';
import '../models/game_models.dart';

class GameLogic {
  static final Random _random = Random();

  /// Determines the winner between two moves
  static GameResult determineWinner(Move player1Move, Move player2Move) {
    if (player1Move == player2Move) {
      return GameResult.draw;
    }

    switch (player1Move) {
      case Move.rock:
        return player2Move == Move.paper ? GameResult.lose : GameResult.win;
      case Move.paper:
        return player2Move == Move.scissors ? GameResult.lose : GameResult.win;
      case Move.scissors:
        return player2Move == Move.rock ? GameResult.lose : GameResult.win;
    }
  }

  /// Gets the move that beats the given move
  static Move getWinningMove(Move move) {
    switch (move) {
      case Move.rock:
        return Move.paper;
      case Move.paper:
        return Move.scissors;
      case Move.scissors:
        return Move.rock;
    }
  }

  /// Gets the move that loses to the given move
  static Move getLosingMove(Move move) {
    switch (move) {
      case Move.rock:
        return Move.scissors;
      case Move.paper:
        return Move.rock;
      case Move.scissors:
        return Move.paper;
    }
  }

  /// Checks if a game is ready to determine the result
  static bool isGameReady(Game game) {
    return game.playerIds.every(
      (playerId) => game.playerMoves[playerId] != null,
    );
  }

  /// Determines the game result for a completed game
  static GameResult? getGameResult(Game game, String playerId) {
    if (!isGameReady(game)) return null;

    final playerMove = game.playerMoves[playerId];
    final opponentId = game.playerIds.firstWhere((id) => id != playerId);
    final opponentMove = game.playerMoves[opponentId];

    if (playerMove == null || opponentMove == null) return null;

    return determineWinner(playerMove, opponentMove);
  }

  /// Gets the winner ID for a completed game
  static String? getWinnerId(Game game) {
    if (!isGameReady(game) || game.playerIds.length != 2) return null;

    final player1Id = game.playerIds[0];
    final player2Id = game.playerIds[1];
    final player1Move = game.playerMoves[player1Id];
    final player2Move = game.playerMoves[player2Id];

    if (player1Move == null || player2Move == null) return null;

    final result = determineWinner(player1Move, player2Move);

    switch (result) {
      case GameResult.win:
        return player1Id;
      case GameResult.lose:
        return player2Id;
      case GameResult.draw:
        return null;
    }
  }

  /// Gets the move name as a string
  static String getMoveName(Move move) {
    switch (move) {
      case Move.rock:
        return 'Rock';
      case Move.paper:
        return 'Paper';
      case Move.scissors:
        return 'Scissors';
    }
  }

  /// Gets the move emoji
  static String getMoveEmoji(Move move) {
    switch (move) {
      case Move.rock:
        return '🪨';
      case Move.paper:
        return '📄';
      case Move.scissors:
        return '✂️';
    }
  }

  /// Gets the result emoji
  static String getResultEmoji(GameResult result) {
    switch (result) {
      case GameResult.win:
        return '🎉';
      case GameResult.lose:
        return '😢';
      case GameResult.draw:
        return '🤝';
    }
  }

  /// Gets the result message
  static String getResultMessage(GameResult result) {
    switch (result) {
      case GameResult.win:
        return 'You Win!';
      case GameResult.lose:
        return 'You Lose!';
      case GameResult.draw:
        return 'It\'s a Draw!';
    }
  }

  /// Generates a random invite code
  static String generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    String code;
    do {
      code = String.fromCharCodes(
        Iterable.generate(
          6,
          (_) => chars.codeUnitAt(_random.nextInt(chars.length)),
        ),
      );
    } while (!RegExp(r'^[A-Z0-9]{6}$').hasMatch(code));
    return code;
  }

  /// Gets the move asset path
  static String getMoveAsset(Move move) {
    switch (move) {
      case Move.rock:
        return 'assets/images/rock.png';
      case Move.paper:
        return 'assets/images/paper.png';
      case Move.scissors:
        return 'assets/images/scissors.png';
    }
  }
}
