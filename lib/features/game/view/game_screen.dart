import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodel/game_provider.dart';
import '../../../core/models/game_models.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

class GameScreen extends ConsumerStatefulWidget {
  final String? gameId;
  final String? lobbyId;
  final bool isBotMatch;

  const GameScreen({
    super.key,
    this.gameId,
    this.lobbyId,
    this.isBotMatch = false,
  });

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with TickerProviderStateMixin {
  late AnimationController _playerHandController;
  late AnimationController _opponentHandController;
  late AnimationController _resultController;
  late Animation<double> _playerHandScale;
  late Animation<double> _opponentHandScale;
  late Animation<double> _resultScale;

  Move? _lastPlayerChoice;
  Move? _lastOpponentChoice;
  GameResult? _lastGameResult;

  int _countdown = 0;
  Timer? _countdownTimer;

  late final AudioPlayer _audioPlayer;
  int _lastWins = 0, _lastLosses = 0, _lastDraws = 0;
  double _scoreScale = 1.0;

  @override
  void initState() {
    super.initState();
    print('DEBUG: GameScreen initState called');
    print('DEBUG: gameId: ${widget.gameId}');
    print('DEBUG: lobbyId: ${widget.lobbyId}');
    print('DEBUG: isBotMatch: ${widget.isBotMatch}');

    _playerHandController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _opponentHandController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _resultController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _playerHandScale = CurvedAnimation(
        parent: _playerHandController, curve: Curves.elasticOut);
    _opponentHandScale = CurvedAnimation(
        parent: _opponentHandController, curve: Curves.elasticOut);
    _resultScale =
        CurvedAnimation(parent: _resultController, curve: Curves.easeOutBack);

    _audioPlayer = AudioPlayer();

    if (widget.gameId != null) {
      print('DEBUG: Starting multiplayer game with gameId');
      Future.microtask(() {
        ref.read(gameProvider.notifier).joinGame(widget.gameId!);
      });
    } else if (widget.lobbyId != null) {
      print('DEBUG: Starting multiplayer game with lobbyId');
      Future.microtask(() {
        ref.read(gameProvider.notifier).joinLobby(widget.lobbyId!);
      });
    } else if (widget.isBotMatch) {
      print('DEBUG: Starting bot game');
      Future.microtask(() {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        final botName = args?['botName'] as String?;
        // If Practice vs Bot, forceSmartBot should be true
        final forceSmartBot = (botName == null || botName == 'Smart Bot');
        ref
            .read(gameProvider.notifier)
            .startBotGame(botName: botName, forceSmartBot: forceSmartBot);
      });
    }

    Future.microtask(() {
      ref.read(gameProvider.notifier).loadPersistentScore();
    });
  }

  void _startCountdownAndReset() {
    setState(() => _countdown = 3);
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
        _handlePlayAgain();
        setState(() => _countdown = 0);
      }
    });
  }

  void _playSound(String asset) async {
    await _audioPlayer.stop();
    await _audioPlayer.play(AssetSource(asset));
  }

  void _animateScore(int wins, int losses, int draws) {
    if (wins != _lastWins || losses != _lastLosses || draws != _lastDraws) {
      setState(() => _scoreScale = 1.3);
      Future.delayed(const Duration(milliseconds: 200), () {
        setState(() => _scoreScale = 1.0);
      });
      _lastWins = wins;
      _lastLosses = losses;
      _lastDraws = draws;
    }
  }

  @override
  void dispose() {
    _playerHandController.dispose();
    _opponentHandController.dispose();
    _resultController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _handleChoiceSelected(Move move) {
    ref.read(gameProvider.notifier).makeChoice(move);
  }

  void _handlePlayAgain() {
    if (widget.isBotMatch) {
      ref
          .read(gameProvider.notifier)
          .startBotGame(botName: 'Smart Bot', forceSmartBot: true);
    } else if (widget.lobbyId != null) {
      ref.read(gameProvider.notifier).resetGame();
    } else if (widget.gameId != null) {
      ref.read(gameProvider.notifier).resetGame();
    }
    _playerHandController.reset();
    _opponentHandController.reset();
    _resultController.reset();
    setState(() {
      _lastPlayerChoice = null;
      _lastOpponentChoice = null;
      _lastGameResult = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final playerChoice = gameState.playerChoice;
    final opponentChoice = gameState.opponentChoice;
    final gameResult = gameState.gameResult;
    final isWaiting = gameState.isWaitingForOpponent;
    final botName = gameState.botName;
    final isMultiplayer = widget.lobbyId != null || widget.gameId != null;

    // Animate score on change
    _animateScore(
        gameState.sessionWins, gameState.sessionLosses, gameState.sessionDraws);

    Widget _scoreBox(String label, int value, Color color) {
      return Column(
        children: [
          Text('$value',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      );
    }

    // Show session score for Quickplay and Play with Friends
    Widget _buildSessionScore() {
      if (!isMultiplayer) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
        child: Transform.scale(
          scale: _scoreScale,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _scoreBox('Wins', gameState.sessionWins, Colors.green),
              const SizedBox(width: 16),
              _scoreBox('Losses', gameState.sessionLosses, Colors.red),
              const SizedBox(width: 16),
              _scoreBox('Draws', gameState.sessionDraws, Colors.orange),
            ],
          ),
        ),
      );
    }

    // Animate hands when choices change
    if (playerChoice != null && playerChoice != _lastPlayerChoice) {
      _playerHandController.forward(from: 0);
      _lastPlayerChoice = playerChoice;
    }
    if (opponentChoice != null && opponentChoice != _lastOpponentChoice) {
      _opponentHandController.forward(from: 0);
      _lastOpponentChoice = opponentChoice;
    }
    if (gameResult != null && gameResult != _lastGameResult) {
      _resultController.forward(from: 0);
      _lastGameResult = gameResult;
    }
    if (playerChoice == null && _lastPlayerChoice != null) {
      _lastPlayerChoice = null;
    }
    if (opponentChoice == null && _lastOpponentChoice != null) {
      _lastOpponentChoice = null;
    }
    if (gameResult == null && _lastGameResult != null) {
      _lastGameResult = null;
    }

    Widget _buildHand(Move? move, {bool isOpponent = false}) {
      if (move == null) {
        return Image.asset('assets/images/question.png', width: 80, height: 80);
      }
      String asset;
      switch (move) {
        case Move.rock:
          asset = isOpponent
              ? 'assets/images/hand_rock.png'
              : 'assets/images/rock.png';
          break;
        case Move.paper:
          asset = isOpponent
              ? 'assets/images/hand_paper.png'
              : 'assets/images/paper.png';
          break;
        case Move.scissors:
          asset = isOpponent
              ? 'assets/images/hand_scissors.png'
              : 'assets/images/scissors.png';
          break;
      }
      final scale = isOpponent ? _opponentHandScale : _playerHandScale;
      return ScaleTransition(
        scale: scale,
        child: Image.asset(asset, width: 80, height: 80),
      );
    }

    Widget _buildResult() {
      if (gameResult == null) return const SizedBox.shrink();
      String text;
      Color color;
      String soundAsset = '';
      switch (gameResult) {
        case GameResult.win:
          text = 'You Win!';
          color = Colors.green;
          soundAsset = 'assets/sounds/win.mp3';
          break;
        case GameResult.lose:
          text = 'You Lose!';
          color = Colors.red;
          soundAsset = 'assets/sounds/lose.mp3';
          break;
        case GameResult.draw:
          text = 'Draw!';
          color = Colors.orange;
          soundAsset = 'assets/sounds/draw.mp3';
          break;
      }
      // Play sound on result
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (soundAsset.isNotEmpty) _playSound(soundAsset);
      });
      // Start countdown for multiplayer modes only
      if (_countdown == 0 && isMultiplayer) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _playSound('assets/sounds/button_click.mp3');
          _startCountdownAndReset();
        });
      }
      return ScaleTransition(
        scale: _resultScale,
        child: Column(
          children: [
            Text(text,
                style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: color,
                    shadows: [Shadow(color: Colors.black26, blurRadius: 8)])),
            const SizedBox(height: 8),
            if (!isMultiplayer)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  textStyle: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                onPressed: _handlePlayAgain,
                child: const Text('Play Again'),
              ),
            if (isMultiplayer && _countdown > 0)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text('Next round in $_countdown...',
                    style: const TextStyle(fontSize: 18)),
              ),
          ],
        ),
      );
    }

    Widget _buildChoiceButton(Move move, String label, String asset) {
      final isEnabled = !isWaiting && playerChoice == null;
      return _AnimatedChoiceButton(
        enabled: isEnabled,
        onTap: isEnabled ? () => _handleChoiceSelected(move) : null,
        asset: asset,
        label: label,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Game'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/home',
              (route) => false,
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'New Game',
            onPressed: () async {
              await ref.read(gameProvider.notifier).resetSessionScore();
              setState(() {
                _lastWins = 0;
                _lastLosses = 0;
                _lastDraws = 0;
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSessionScore(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _PlayerCard(
                        title: 'You',
                        child: _buildHand(playerChoice),
                      ),
                      _PlayerCard(
                        title: botName != null && gameState.isBotMatch
                            ? botName
                            : 'Opponent',
                        child: _buildHand(opponentChoice, isOpponent: true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildResult(),
                  const SizedBox(height: 32),
                  if (playerChoice == null && !isWaiting)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildChoiceButton(
                            Move.rock, 'Rock', 'assets/images/rock.png'),
                        _buildChoiceButton(
                            Move.paper, 'Paper', 'assets/images/paper.png'),
                        _buildChoiceButton(Move.scissors, 'Scissors',
                            'assets/images/scissors.png'),
                      ],
                    ),
                ],
              ),
            ),
            if (gameState.isLoading)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            if (gameState.error != null)
              Positioned(
                top: 100,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          gameState.error!,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          ref.read(gameProvider.notifier).clearError();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            if (isWaiting)
              Positioned(
                top: 100,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Waiting for opponent...',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _PlayerCard({required this.title, required this.child});
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white.withOpacity(0.1),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 120,
        height: 160,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _AnimatedChoiceButton extends StatefulWidget {
  final bool enabled;
  final VoidCallback? onTap;
  final String asset;
  final String label;
  const _AnimatedChoiceButton(
      {required this.enabled,
      required this.onTap,
      required this.asset,
      required this.label});
  @override
  State<_AnimatedChoiceButton> createState() => _AnimatedChoiceButtonState();
}

class _AnimatedChoiceButtonState extends State<_AnimatedChoiceButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 120),
        lowerBound: 0.9,
        upperBound: 1.0);
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.value = 1.0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap() {
    if (widget.enabled) {
      _controller.reverse().then((_) {
        _controller.forward();
        widget.onTap?.call();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: Column(
        children: [
          ScaleTransition(
            scale: _scale,
            child: Container(
              decoration: BoxDecoration(
                color: widget.enabled ? Colors.white : Colors.white24,
                shape: BoxShape.circle,
                boxShadow: widget.enabled
                    ? [
                        BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 4))
                      ]
                    : [],
              ),
              padding: const EdgeInsets.all(8),
              child: Image.asset(widget.asset, width: 64, height: 64),
            ),
          ),
          const SizedBox(height: 4),
          Text(widget.label,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
