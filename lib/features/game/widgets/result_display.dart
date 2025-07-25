import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/models/game_models.dart';
import '../../../core/utils/game_logic.dart';
import '../../../theme/app_theme.dart';

class ResultDisplay extends StatelessWidget {
  final GameResult result;
  final Move playerChoice;
  final Move opponentChoice;
  final VoidCallback onPlayAgain;

  const ResultDisplay({
    super.key,
    required this.result,
    required this.playerChoice,
    required this.opponentChoice,
    required this.onPlayAgain,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _getResultColor(result).withAlpha((255 * 0.1).toInt()),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getResultColor(result), width: 2),
      ),
      child: Column(
        children: [
          // Result Emoji and Text
          Text(
            GameLogic.getResultEmoji(result),
            style: const TextStyle(fontSize: 64),
          ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),

          const SizedBox(height: 16),

          Text(
            GameLogic.getResultMessage(result),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _getResultColor(result),
                ),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3),

          const SizedBox(height: 24),

          // Choices Display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildChoiceDisplay('You', playerChoice, true),
              Text(
                'VS',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
              ),
              _buildChoiceDisplay('Opponent', opponentChoice, false),
            ],
          ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.5),

          const SizedBox(height: 32),

          // Play Again Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onPlayAgain,
              icon: const Icon(Icons.refresh),
              label: const Text('Play Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _getResultColor(result),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ).animate().fadeIn(delay: 900.ms).slideY(begin: 0.5),
        ],
      ),
    );
  }

  Widget _buildChoiceDisplay(String label, Move choice, bool isPlayer) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: isPlayer ? Colors.blue[100] : Colors.grey[200],
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isPlayer ? Colors.blue : Colors.grey,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              GameLogic.getMoveEmoji(choice),
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
      ],
    );
  }

  Color _getResultColor(GameResult result) {
    switch (result) {
      case GameResult.win:
        return GameColors.win;
      case GameResult.lose:
        return GameColors.lose;
      case GameResult.draw:
        return GameColors.draw;
    }
  }
}
