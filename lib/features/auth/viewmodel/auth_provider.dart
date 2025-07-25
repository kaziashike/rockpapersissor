import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/game_models.dart';
import '../repository/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.read(authRepositoryProvider).authStateChanges;
});

final currentUserProvider = FutureProvider<User?>((ref) async {
  return ref.read(authRepositoryProvider).getCurrentUser();
});

final userProfileProvider = FutureProvider.family<Player?, String>((
  ref,
  userId,
) async {
  return ref.read(authRepositoryProvider).getUserProfile(userId);
});

class AuthState {
  final bool isLoading;
  final User? user;
  final String? error;
  final bool hasError;

  const AuthState({
    this.isLoading = false,
    this.user,
    this.error,
    this.hasError = false,
  });

  AuthState copyWith({
    bool? isLoading,
    User? user,
    String? error,
    bool? hasError,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error ?? this.error,
      hasError: hasError ?? this.hasError,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthNotifier(this._authRepository) : super(const AuthState()) {
    _authRepository.authStateChanges.listen((user) {
      state = state.copyWith(
        user: user,
        isLoading: false,
        error: null,
        hasError: false,
      );
    });
  }

  Future<void> signInAnonymously() async {
    state = state.copyWith(isLoading: true, error: null, hasError: false);
    try {
      final user = await _authRepository.signInAnonymously();
      state = state.copyWith(
        user: user,
        isLoading: false,
        error: null,
        hasError: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
        hasError: true,
      );
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null, hasError: false);
    try {
      final user = await _authRepository.signInWithGoogle();
      state = state.copyWith(
        user: user,
        isLoading: false,
        error: null,
        hasError: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
        hasError: true,
      );
    }
  }

  Future<void> signOut() async {
    try {
      await _authRepository.signOut();
      state = state.copyWith(
        user: null,
        error: null,
        hasError: false,
      );
    } catch (error) {
      state = state.copyWith(
        error: error.toString(),
        hasError: true,
      );
    }
  }

  Future<void> updateUserProfile(String name) async {
    try {
      await _authRepository.updateUserProfile(name);
    } catch (error) {
      state = state.copyWith(
        error: error.toString(),
        hasError: true,
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null, hasError: false);
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});
