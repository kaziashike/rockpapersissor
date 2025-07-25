import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/game_models.dart';
import '../../../core/utils/game_logic.dart';
import '../repository/game_repository.dart';
import '../../bot/logic/bot_player.dart';
import '../../auth/viewmodel/auth_provider.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

final gameRepositoryProvider = Provider<GameRepository>((ref) {
  return GameRepository();
});

final gameProvider = StateNotifierProvider<GameNotifier, GameState>((ref) {
  return GameNotifier(ref.read(gameRepositoryProvider), ref);
});

class GameState {
  final bool isLoading;
  final String? error;
  final Game? currentGame;
  final Lobby? currentLobby;
  final Player? currentPlayer;
  final bool isBotMatch;
  final Move? playerChoice;
  final Move? opponentChoice;
  final GameResult? gameResult;
  final bool isWaitingForOpponent;
  final String? botName;
  final int sessionWins;
  final int sessionLosses;
  final int sessionDraws;

  static const _unset = Object();

  GameState({
    this.isLoading = false,
    this.error,
    this.currentGame,
    this.currentLobby,
    this.currentPlayer,
    this.isBotMatch = false,
    this.playerChoice,
    this.opponentChoice,
    this.gameResult,
    this.isWaitingForOpponent = false,
    this.botName,
    this.sessionWins = 0,
    this.sessionLosses = 0,
    this.sessionDraws = 0,
  });

  GameState copyWith({
    bool? isLoading,
    String? error,
    Game? currentGame,
    Lobby? currentLobby,
    Player? currentPlayer,
    bool? isBotMatch,
    Object? playerChoice = _unset,
    Object? opponentChoice = _unset,
    Object? gameResult = _unset,
    bool? isWaitingForOpponent,
    String? botName,
    int? sessionWins,
    int? sessionLosses,
    int? sessionDraws,
  }) {
    return GameState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      currentGame: currentGame ?? this.currentGame,
      currentLobby: currentLobby ?? this.currentLobby,
      currentPlayer: currentPlayer ?? this.currentPlayer,
      isBotMatch: isBotMatch ?? this.isBotMatch,
      playerChoice: identical(playerChoice, _unset)
          ? this.playerChoice
          : playerChoice as Move?,
      opponentChoice: identical(opponentChoice, _unset)
          ? this.opponentChoice
          : opponentChoice as Move?,
      gameResult: identical(gameResult, _unset)
          ? this.gameResult
          : gameResult as GameResult?,
      isWaitingForOpponent: isWaitingForOpponent ?? this.isWaitingForOpponent,
      botName: botName ?? this.botName,
      sessionWins: sessionWins ?? this.sessionWins,
      sessionLosses: sessionLosses ?? this.sessionLosses,
      sessionDraws: sessionDraws ?? this.sessionDraws,
    );
  }
}

class GameNotifier extends StateNotifier<GameState> {
  final GameRepository _repository;
  final Ref _ref;
  StreamSubscription<Game?>? _gameSubscription;

  GameNotifier(this._repository, this._ref) : super(GameState());

  @override
  void dispose() {
    _gameSubscription?.cancel();
    super.dispose();
  }

  Future<void> joinGame(String gameId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final game = await _repository.getGame(gameId);
      if (game != null) {
        state = state.copyWith(
          isLoading: false,
          currentGame: game,
          isWaitingForOpponent: game.status == GameStatus.waiting,
        );

        // Listen to game updates
        _listenToGameUpdates(gameId);
      } else {
        state = state.copyWith(isLoading: false, error: 'Game not found');
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to join game: $e',
      );
    }
  }

  Future<void> joinLobby(String lobbyId) async {
    print('DEBUG: joinLobby called with lobbyId: $lobbyId');
    state = state.copyWith(isLoading: true, error: null);

    // Listen to the lobby document
    final lobbyStream = _repository.listenToLobby(lobbyId);
    StreamSubscription<Lobby?>? lobbySub;
    lobbySub = lobbyStream.listen((lobby) async {
      if (lobby == null) return;
      state = state.copyWith(currentLobby: lobby);
      print(
          'DEBUG: Lobby update: playerIds=${lobby.playerIds}, gameId=${lobby.gameId}');
      // If lobby is full (2 players)
      if (lobby.playerIds.length == 2) {
        // If no gameId, create a new game and update the lobby
        if (lobby.gameId == null) {
          print('DEBUG: Creating new game for lobby');
          final game = await _repository.createGame(lobby.id, lobby.playerIds);
          await _repository.updateLobbyWithGameId(lobby.id, game.id);
        } else {
          // If gameId exists, join the game
          print('DEBUG: Joining game: ${lobby.gameId}');
          lobbySub?.cancel();
          await joinGame(lobby.gameId!);
        }
      } else {
        print('DEBUG: Waiting for another player to join...');
      }
    });
  }

  Future<void> startBotGame(
      {String? botName, bool forceSmartBot = false}) async {
    // If forceSmartBot is true, always use 'Smart Bot' as the bot name
    final name =
        forceSmartBot ? 'Smart Bot' : (botName ?? BotPlayer.getBotName());
    print(
        'DEBUG: startBotGame called with botName: $botName, forceSmartBot: $forceSmartBot');
    state = state.copyWith(
      isLoading: false,
      isBotMatch: true,
      error: null,
      isWaitingForOpponent: false,
      playerChoice: null,
      opponentChoice: null,
      gameResult: null,
      botName: name,
    );
    print('DEBUG: Bot game state set, botName: ${state.botName}');
  }

  Future<void> makeMove(Move move) async {
    if (state.currentGame == null && !state.isBotMatch) return;

    try {
      if (state.isBotMatch) {
        // Handle bot game
        await _handleBotGame(move);
      } else {
        // Handle multiplayer game
        await _repository.makeMove(state.currentGame!.id, move);
        state = state.copyWith(playerChoice: move, isWaitingForOpponent: true);
        // Score will be updated after result is received from Firestore
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to make move: $e');
    }
  }

  Future<void> _handleBotGame(Move move) async {
    // Set player choice
    state = state.copyWith(playerChoice: move);

    // Simulate bot thinking time
    await Future.delayed(const Duration(milliseconds: 1500));

    // Get bot move based on personality
    final botName = state.botName ?? BotPlayer.getBotName();
    final personality = BotPlayer.getBotPersonality(botName);
    final botMove = BotPlayer.getMoveByPersonality(personality);

    state = state.copyWith(opponentChoice: botMove);

    // Calculate result
    final result = _calculateResult(move, botMove);
    state = state.copyWith(gameResult: result);
  }

  GameResult _calculateResult(Move player, Move opponent) {
    if (player == opponent) return GameResult.draw;

    switch (player) {
      case Move.rock:
        return opponent == Move.scissors ? GameResult.win : GameResult.lose;
      case Move.paper:
        return opponent == Move.rock ? GameResult.win : GameResult.lose;
      case Move.scissors:
        return opponent == Move.paper ? GameResult.win : GameResult.lose;
    }
  }

  Future<void> makeChoice(Move move) async {
    await makeMove(move);
  }

  Move getBotMove() {
    return BotPlayer.getStrategicMove();
  }

  void _listenToGameUpdates(String gameId) {
    _gameSubscription?.cancel();
    _gameSubscription = _repository.listenToGame(gameId).listen((game) {
      if (game != null) {
        state = state.copyWith(currentGame: game);

        // Update opponent choice if available
        if (game.playerMoves.length == 2 && state.playerChoice != null) {
          final opponentMove = game.playerMoves.values.firstWhere(
            (move) => move != state.playerChoice,
          );
          if (opponentMove != null) {
            state = state.copyWith(
              opponentChoice: opponentMove,
              isWaitingForOpponent: false,
            );
          }
        }
        // Update session score if result is available
        if (game.status == GameStatus.finished && game.result != null) {
          updateSessionScore(game.result!);
        }
      }
    });
  }

  void _handleGameCompletion(Game game) {
    // Calculate result for current player
    final user = _ref.read(authNotifierProvider).user;
    final currentUserId = user?.uid;
    if (currentUserId == null) {
      state = state.copyWith(error: 'User not authenticated');
      return;
    }
    final result = GameLogic.getGameResult(game, currentUserId);

    if (result != null) {
      state = state.copyWith(gameResult: result);
    }
  }

  Future<void> leaveGame() async {
    if (state.currentGame != null) {
      try {
        await _repository.leaveGame(state.currentGame!.id);
      } catch (e) {
        state = state.copyWith(error: 'Failed to leave game: $e');
      }
    }
    _gameSubscription?.cancel();
    state = GameState();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void resetGame() {
    state = state.copyWith(
      playerChoice: null,
      opponentChoice: null,
      gameResult: null,
      isWaitingForOpponent: false,
    );
  }

  String get _scoreKey {
    if (state.isBotMatch) return 'score_bot';
    if (state.currentLobby != null || state.currentGame != null)
      return 'score_friends';
    return 'score_quickplay';
  }

  Future<void> loadPersistentScore() async {
    final prefs = await SharedPreferences.getInstance();
    final wins = prefs.getInt('${_scoreKey}_wins') ?? 0;
    final losses = prefs.getInt('${_scoreKey}_losses') ?? 0;
    final draws = prefs.getInt('${_scoreKey}_draws') ?? 0;
    state = state.copyWith(
        sessionWins: wins, sessionLosses: losses, sessionDraws: draws);
  }

  Future<void> savePersistentScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('${_scoreKey}_wins', state.sessionWins);
    await prefs.setInt('${_scoreKey}_losses', state.sessionLosses);
    await prefs.setInt('${_scoreKey}_draws', state.sessionDraws);
  }

  void updateSessionScore(GameResult result) {
    if (state.isBotMatch) return; // Do not update score in Practice vs Bot
    switch (result) {
      case GameResult.win:
        state = state.copyWith(sessionWins: state.sessionWins + 1);
        break;
      case GameResult.lose:
        state = state.copyWith(sessionLosses: state.sessionLosses + 1);
        break;
      case GameResult.draw:
        state = state.copyWith(sessionDraws: state.sessionDraws + 1);
        break;
    }
    savePersistentScore();
  }

  Future<void> resetSessionScore() async {
    state = state.copyWith(sessionWins: 0, sessionLosses: 0, sessionDraws: 0);
    await savePersistentScore();
  }
}
