import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/models/game_models.dart';
import '../../../core/utils/game_logic.dart';
import '../../../theme/app_theme.dart';

class ChoiceButton extends StatelessWidget {
  final Move move;
  final VoidCallback onPressed;

  const ChoiceButton({super.key, required this.move, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: _getMoveColor(move),
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((255 * 0.2).toInt()),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Image.asset(
            GameLogic.getMoveAsset(move),
            width: 40,
            height: 40,
          ),
        ),
      ).animate().scale(duration: 200.ms, curve: Curves.easeInOut).then().scale(
            duration: 200.ms,
            curve: Curves.easeInOut,
            begin: const Offset(0.95, 0.95),
            end: const Offset(1.0, 1.0),
          ),
    );
  }

  Color _getMoveColor(Move move) {
    switch (move) {
      case Move.rock:
        return GameColors.rock;
      case Move.paper:
        return GameColors.paper;
      case Move.scissors:
        return GameColors.scissors;
    }
  }
}
