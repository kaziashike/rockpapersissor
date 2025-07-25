import 'dart:math';
import '../../../core/models/game_models.dart';

class BotPlayer {
  static final Random _random = Random();

  /// Generates a random move for the bot
  static Move getRandomMove() {
    return Move.values[_random.nextInt(Move.values.length)];
  }

  /// Generates a move with some strategy (slightly more intelligent)
  static Move getStrategicMove() {
    // 30% chance to counter the most common human move (rock)
    if (_random.nextDouble() < 0.3) {
      return Move.paper; // Paper beats rock
    }

    // 20% chance to play rock (most common human choice)
    if (_random.nextDouble() < 0.2) {
      return Move.rock;
    }

    // 50% chance to play randomly
    return getRandomMove();
  }

  /// Generates a move based on previous game history
  static Move getMoveBasedOnHistory(List<Move> playerHistory) {
    if (playerHistory.isEmpty) {
      return getStrategicMove();
    }

    // Analyze player's most common move
    final moveCounts = <Move, int>{};
    for (final move in Move.values) {
      moveCounts[move] = 0;
    }

    for (final move in playerHistory) {
      moveCounts[move] = (moveCounts[move] ?? 0) + 1;
    }

    // Find the most common move
    Move? mostCommonMove;
    int maxCount = 0;

    for (final entry in moveCounts.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        mostCommonMove = entry.key;
      }
    }

    // Counter the most common move
    if (mostCommonMove != null) {
      switch (mostCommonMove) {
        case Move.rock:
          return Move.paper;
        case Move.paper:
          return Move.scissors;
        case Move.scissors:
          return Move.rock;
      }
    }

    return getStrategicMove();
  }

  /// Simulates human-like delay before making a move
  static Future<Move> makeMoveWithDelay({
    List<Move>? playerHistory,
    Duration delay = const Duration(milliseconds: 1500),
  }) async {
    await Future.delayed(delay);

    if (playerHistory != null && playerHistory.isNotEmpty) {
      return getMoveBasedOnHistory(playerHistory);
    }

    return getStrategicMove();
  }

  /// Determines the game result between two moves
  static GameResult determineResult(Move playerMove, Move botMove) {
    if (playerMove == botMove) {
      return GameResult.draw;
    }

    switch (playerMove) {
      case Move.rock:
        return botMove == Move.paper ? GameResult.lose : GameResult.win;
      case Move.paper:
        return botMove == Move.scissors ? GameResult.lose : GameResult.win;
      case Move.scissors:
        return botMove == Move.rock ? GameResult.lose : GameResult.win;
    }
  }

  /// Gets a bot name
  static String getBotName() {
    final botNames = [
      'RPS Master',
      'Rock Star',
      'Paper Cutter',
      'Scissors Pro',
      'Game Bot',
      'AI Player',
      'Smart Bot',
      'RPS Champion',
      'Botzilla',
      'RoboHand',
      'Paper Ninja',
      'Scissorhands',
      'Rocky',
      'Paperino',
      'Scissora',
      'Quickplay Bot',
      'Random Player',
      'Dummy Opponent',
      'AI Challenger',
      'Virtual Player',
    ];
    return botNames[_random.nextInt(botNames.length)];
  }

  /// Gets a bot personality based on name
  static BotPersonality getBotPersonality(String botName) {
    if (botName.contains('Master') ||
        botName.contains('Champion') ||
        botName.contains('Pro')) {
      return BotPersonality.aggressive;
    } else if (botName.contains('Smart') || botName.contains('AI')) {
      return BotPersonality.strategic;
    } else if (botName.contains('Random') || botName.contains('Dummy')) {
      return BotPersonality.random;
    } else {
      return BotPersonality.balanced;
    }
  }

  /// Generates a move based on personality
  static Move getMoveByPersonality(BotPersonality personality,
      {List<Move>? playerHistory}) {
    switch (personality) {
      case BotPersonality.aggressive:
        // Aggressive bots tend to play rock more often
        if (_random.nextDouble() < 0.4) return Move.rock;
        return getStrategicMove();

      case BotPersonality.strategic:
        // Strategic bots analyze player history
        if (playerHistory != null && playerHistory.isNotEmpty) {
          return getMoveBasedOnHistory(playerHistory);
        }
        return getStrategicMove();

      case BotPersonality.random:
        // Random bots play completely randomly
        return getRandomMove();

      case BotPersonality.balanced:
        // Balanced bots use a mix of strategies
        if (_random.nextDouble() < 0.3) {
          return getStrategicMove();
        }
        return getRandomMove();
    }
  }
}

enum BotPersonality {
  aggressive,
  strategic,
  random,
  balanced,
}
