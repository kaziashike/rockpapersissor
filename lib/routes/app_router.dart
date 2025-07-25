import 'package:flutter/material.dart';
import '../features/auth/view/auth_screen.dart';
import '../features/home/view/home_screen.dart';
import '../features/matchmaking/view/matchmaking_screen.dart';
import '../features/game/view/game_screen.dart';
import '../features/invite/view/invite_screen.dart';

class AppRouter {
  static const String home = '/home';
  static const String auth = '/auth';
  static const String matchmaking = '/matchmaking';
  static const String game = '/game';
  static const String invite = '/invite';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case auth:
        return MaterialPageRoute(builder: (_) => const AuthScreen());
      case matchmaking:
        return MaterialPageRoute(builder: (_) => const MatchmakingScreen());
      case game:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => GameScreen(
            gameId: args?['gameId'] as String?,
            lobbyId: args?['lobbyId'] as String?,
            isBotMatch: args?['isBotMatch'] as bool? ?? false,
          ),
        );
      case invite:
        return MaterialPageRoute(builder: (_) => const InviteScreen());
      default:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('Page not found'))),
        );
    }
  }
}
