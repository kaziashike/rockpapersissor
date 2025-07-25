import 'package:cloud_firestore/cloud_firestore.dart';

enum Move { rock, paper, scissors }

enum GameResult { win, lose, draw }

enum GameStatus { waiting, playing, finished }

enum LobbyStatus { waiting, full, started, finished }

class Player {
  final String id;
  final String name;
  final String? photoUrl;
  final int wins;
  final int losses;
  final int draws;
  final DateTime lastSeen;

  Player({
    required this.id,
    required this.name,
    this.photoUrl,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
    required this.lastSeen,
  });

  factory Player.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Player(
      id: doc.id,
      name: data['name'] ?? 'Anonymous',
      photoUrl: data['photoUrl'],
      wins: data['wins'] ?? 0,
      losses: data['losses'] ?? 0,
      draws: data['draws'] ?? 0,
      lastSeen: (data['lastSeen'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'photoUrl': photoUrl,
      'wins': wins,
      'losses': losses,
      'draws': draws,
      'lastSeen': Timestamp.fromDate(lastSeen),
    };
  }

  Player copyWith({
    String? id,
    String? name,
    String? photoUrl,
    int? wins,
    int? losses,
    int? draws,
    DateTime? lastSeen,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      draws: draws ?? this.draws,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}

class Lobby {
  final String id;
  final String hostId;
  final List<String> playerIds;
  final LobbyStatus status;
  final DateTime createdAt;
  final DateTime? startedAt;
  final String? gameId;
  final bool isPrivate;
  final String? inviteCode;

  Lobby({
    required this.id,
    required this.hostId,
    required this.playerIds,
    required this.status,
    required this.createdAt,
    this.startedAt,
    this.gameId,
    this.isPrivate = false,
    this.inviteCode,
  });

  factory Lobby.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Lobby(
      id: doc.id,
      hostId: data['hostId'] ?? '',
      playerIds: List<String>.from(data['playerIds'] ?? []),
      status: LobbyStatus.values.firstWhere(
        (e) => e.toString() == 'LobbyStatus.${data['status']}',
        orElse: () => LobbyStatus.waiting,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      startedAt: data['startedAt'] != null
          ? (data['startedAt'] as Timestamp).toDate()
          : null,
      gameId: data['gameId'],
      isPrivate: data['isPrivate'] ?? false,
      inviteCode: data['inviteCode'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'hostId': hostId,
      'playerIds': playerIds,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'gameId': gameId,
      'isPrivate': isPrivate,
      'inviteCode': inviteCode,
    };
  }

  bool get isFull => playerIds.length >= 2;
  bool get canJoin => !isFull && status == LobbyStatus.waiting;

  Lobby copyWith({
    String? id,
    String? hostId,
    List<String>? playerIds,
    LobbyStatus? status,
    DateTime? createdAt,
    DateTime? startedAt,
    String? gameId,
    bool? isPrivate,
    String? inviteCode,
  }) {
    return Lobby(
      id: id ?? this.id,
      hostId: hostId ?? this.hostId,
      playerIds: playerIds ?? this.playerIds,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      gameId: gameId ?? this.gameId,
      isPrivate: isPrivate ?? this.isPrivate,
      inviteCode: inviteCode ?? this.inviteCode,
    );
  }
}

class Game {
  final String id;
  final String lobbyId;
  final List<String> playerIds;
  final Map<String, Move?> playerMoves;
  final GameStatus status;
  final GameResult? result;
  final String? winnerId;
  final DateTime createdAt;
  final DateTime? finishedAt;
  final bool isBotGame;

  Game({
    required this.id,
    required this.lobbyId,
    required this.playerIds,
    required this.playerMoves,
    required this.status,
    this.result,
    this.winnerId,
    required this.createdAt,
    this.finishedAt,
    this.isBotGame = false,
  });

  factory Game.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Game(
      id: doc.id,
      lobbyId: data['lobbyId'] ?? '',
      playerIds: List<String>.from(data['playerIds'] ?? []),
      playerMoves: Map<String, Move>.from(
        (data['playerMoves'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(
            key,
            value != null
                ? Move.values.firstWhere(
                    (e) => e.toString() == 'Move.$value',
                    orElse: () => Move.rock,
                  )
                : null,
          ),
        ),
      ),
      status: GameStatus.values.firstWhere(
        (e) => e.toString() == 'GameStatus.${data['status']}',
        orElse: () => GameStatus.waiting,
      ),
      result: data['result'] != null
          ? GameResult.values.firstWhere(
              (e) => e.toString() == 'GameResult.${data['result']}',
              orElse: () => GameResult.draw,
            )
          : null,
      winnerId: data['winnerId'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      finishedAt: data['finishedAt'] != null
          ? (data['finishedAt'] as Timestamp).toDate()
          : null,
      isBotGame: data['isBotGame'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'lobbyId': lobbyId,
      'playerIds': playerIds,
      'playerMoves': playerMoves.map(
        (key, value) => MapEntry(key, value?.toString().split('.').last),
      ),
      'status': status.toString().split('.').last,
      'result': result?.toString().split('.').last,
      'winnerId': winnerId,
      'createdAt': Timestamp.fromDate(createdAt),
      'finishedAt': finishedAt != null ? Timestamp.fromDate(finishedAt!) : null,
      'isBotGame': isBotGame,
    };
  }

  bool get allPlayersMoved =>
      playerIds.every((playerId) => playerMoves[playerId] != null);

  bool get isFinished => status == GameStatus.finished;
}

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
    );
  }

  @override
  String toString() {
    return 'GameState(isLoading: '
        '$isLoading, error: $error, isBotMatch: '
        '$isBotMatch, playerChoice: '
        '$playerChoice, opponentChoice: '
        '$opponentChoice, gameResult: '
        '$gameResult, isWaitingForOpponent: '
        '$isWaitingForOpponent)';
  }
}
