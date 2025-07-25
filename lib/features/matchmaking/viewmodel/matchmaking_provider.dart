import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/game_models.dart';
import '../repository/matchmaking_repository.dart';
import '../../../core/constants.dart';
import '../../bot/logic/bot_player.dart';

final matchmakingRepositoryProvider = Provider<MatchmakingRepository>((ref) {
  return MatchmakingRepository();
});

final matchmakingProvider =
    StateNotifierProvider<MatchmakingNotifier, MatchmakingState>((ref) {
  return MatchmakingNotifier(ref.read(matchmakingRepositoryProvider));
});

class MatchmakingState {
  final bool isLoading;
  final String? error;
  final Lobby? currentLobby;
  final bool isBotMatch;
  final int searchTime;
  final String? botName;

  const MatchmakingState({
    this.isLoading = false,
    this.error,
    this.currentLobby,
    this.isBotMatch = false,
    this.searchTime = 0,
    this.botName,
  });

  MatchmakingState copyWith({
    bool? isLoading,
    String? error,
    Lobby? currentLobby,
    bool? isBotMatch,
    int? searchTime,
    String? botName,
  }) {
    return MatchmakingState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      currentLobby: currentLobby ?? this.currentLobby,
      isBotMatch: isBotMatch ?? this.isBotMatch,
      searchTime: searchTime ?? this.searchTime,
      botName: botName ?? this.botName,
    );
  }
}

class MatchmakingNotifier extends StateNotifier<MatchmakingState> {
  final MatchmakingRepository _repository;

  MatchmakingNotifier(this._repository) : super(const MatchmakingState());

  Future<void> startQuickplay() async {
    print('DEBUG: startQuickplay called');
    // Generate a new random bot name for this session
    final randomBotName = BotPlayer.getBotName();
    state = state.copyWith(
        isLoading: true,
        error: null,
        searchTime: 0,
        botName: randomBotName,
        isBotMatch: false);

    try {
      // Start searching for an opponent
      print('DEBUG: Searching for lobby...');
      final lobby = await _repository.findOrCreateLobby();

      if (lobby != null) {
        print('DEBUG: Found lobby: ${lobby.id}');
        // Found a lobby, join it
        state = state.copyWith(isLoading: false, currentLobby: lobby);

        // Listen for lobby updates
        _listenToLobbyUpdates(lobby.id);
      } else {
        print('DEBUG: No lobby found, starting timeout timer');
        // No lobby found, start timeout timer
        _startTimeoutTimer();
      }
    } catch (e) {
      print('DEBUG: Error in startQuickplay: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to start quickplay: $e',
      );
    }
  }

  Future<void> startMatchmaking() async {
    state = state.copyWith(isLoading: true, error: null, searchTime: 0);

    try {
      // Start searching for an opponent
      final lobby = await _repository.findOrCreateLobby();

      if (lobby != null) {
        // Found a lobby, join it
        state = state.copyWith(isLoading: false, currentLobby: lobby);

        // Listen for lobby updates
        _listenToLobbyUpdates(lobby.id);
      } else {
        // No lobby found, start timeout timer
        _startTimeoutTimer();
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to start matchmaking: $e',
      );
    }
  }

  void _startTimeoutTimer() {
    print('DEBUG: _startTimeoutTimer called');
    int timeElapsed = 0;

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      timeElapsed++;

      print('DEBUG: Time elapsed: $timeElapsed seconds');
      state = state.copyWith(searchTime: timeElapsed);

      // Check if we should match with bot
      if (timeElapsed >= AppConstants.matchmakingTimeoutSeconds) {
        print('DEBUG: Timeout reached, creating bot match');
        // Use the same botName for the session
        state = state.copyWith(
          isLoading: false,
          isBotMatch: true,
          // botName is already set in state from startQuickplay
        );
        return false; // Stop the loop
      }

      // Try to find a lobby again
      try {
        final lobby = await _repository.findOrCreateLobby();
        if (lobby != null) {
          print('DEBUG: Found lobby during timeout: ${lobby.id}');
          state = state.copyWith(isLoading: false, currentLobby: lobby);
          _listenToLobbyUpdates(lobby.id);
          return false; // Stop the loop
        }
      } catch (e) {
        print('DEBUG: Error finding lobby during timeout: $e');
        // Continue searching
      }

      return true; // Continue the loop
    });
  }

  void _listenToLobbyUpdates(String lobbyId) {
    _repository.listenToLobby(lobbyId).listen((lobby) {
      if (lobby != null) {
        state = state.copyWith(currentLobby: lobby);

        // Check if lobby is full and game should start
        if (lobby.isFull && lobby.status == LobbyStatus.started) {
          // Navigate to game screen
          // This will be handled by the UI layer
        }
      }
    });
  }

  Future<void> joinLobbyWithCode(String inviteCode) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final lobby = await _repository.joinLobbyWithCode(inviteCode);
      state = state.copyWith(isLoading: false, currentLobby: lobby);

      if (lobby != null) {
        _listenToLobbyUpdates(lobby.id);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to join lobby: $e',
      );
    }
  }

  Future<void> createPrivateLobby() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final lobby = await _repository.createPrivateLobby();
      state = state.copyWith(isLoading: false, currentLobby: lobby);

      _listenToLobbyUpdates(lobby.id);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create lobby: $e',
      );
    }
  }

  void cancelMatchmaking() {
    if (state.currentLobby != null) {
      _repository.leaveLobby(state.currentLobby!.id);
    }
    state = const MatchmakingState();
  }

  void resetState() {
    state = const MatchmakingState();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}
