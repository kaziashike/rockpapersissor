import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/game_models.dart';
import '../repository/invite_repository.dart';
import 'dart:async';

final inviteRepositoryProvider = Provider<InviteRepository>((ref) {
  return InviteRepository();
});

final inviteProvider = StateNotifierProvider<InviteNotifier, InviteState>((
  ref,
) {
  return InviteNotifier(ref.read(inviteRepositoryProvider));
});

class InviteState {
  final bool isLoading;
  final bool isCreatingLobby;
  final String? error;
  final Lobby? currentLobby;
  final String? inviteLink;

  const InviteState({
    this.isLoading = false,
    this.isCreatingLobby = false,
    this.error,
    this.currentLobby,
    this.inviteLink,
  });

  InviteState copyWith({
    bool? isLoading,
    bool? isCreatingLobby,
    String? error,
    Lobby? currentLobby,
    String? inviteLink,
  }) {
    return InviteState(
      isLoading: isLoading ?? this.isLoading,
      isCreatingLobby: isCreatingLobby ?? this.isCreatingLobby,
      error: error ?? this.error,
      currentLobby: currentLobby ?? this.currentLobby,
      inviteLink: inviteLink ?? this.inviteLink,
    );
  }
}

class InviteNotifier extends StateNotifier<InviteState> {
  final InviteRepository _repository;
  Stream<Lobby?>? _lobbyStream;
  Stream<Lobby?> get lobbyStream => _lobbyStream ?? const Stream.empty();
  StreamSubscription<Lobby?>? _lobbySubscription;

  InviteNotifier(this._repository) : super(const InviteState());

  Future<void> createPrivateLobby() async {
    state = state.copyWith(isCreatingLobby: true, error: null);

    try {
      final lobby = await _repository.createPrivateLobby();
      state = state.copyWith(
        isCreatingLobby: false,
        currentLobby: lobby,
        inviteLink: lobby.inviteCode,
      );
      _listenToLobby(lobby.id);
    } catch (e) {
      state = state.copyWith(
        isCreatingLobby: false,
        error: 'Failed to create private lobby: $e',
      );
    }
  }

  Future<void> joinLobbyWithCode(String inviteCode) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final lobby = await _repository.joinLobbyWithCode(inviteCode);
      state = state.copyWith(isLoading: false, currentLobby: lobby);
      if (lobby != null) {
        _listenToLobby(lobby.id);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to join lobby: $e',
      );
    }
  }

  void _listenToLobby(String lobbyId) {
    _lobbySubscription?.cancel();
    _lobbyStream = _repository.lobbyStream(lobbyId);
    _lobbySubscription = _lobbyStream!.listen((lobby) {
      if (lobby != null) {
        state = state.copyWith(currentLobby: lobby);
      }
    });
  }

  @override
  void dispose() {
    _lobbySubscription?.cancel();
    super.dispose();
  }

  Future<void> shareInviteLink() async {
    if (state.inviteLink != null) {
      try {
        await _repository.shareInviteLink(state.inviteLink!);
      } catch (e) {
        state = state.copyWith(error: 'Failed to share invite link: $e');
      }
    }
  }

  Future<void> shareInviteCode() async {
    if (state.currentLobby?.inviteCode != null) {
      try {
        await _repository.shareInviteCode(state.currentLobby!.inviteCode!);
      } catch (e) {
        state = state.copyWith(error: 'Failed to share invite code: $e');
      }
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void clearLobby() {
    state = state.copyWith(currentLobby: null, inviteLink: null);
  }
}
