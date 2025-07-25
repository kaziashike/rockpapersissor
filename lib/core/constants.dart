class AppConstants {
  // Firebase Collections
  static const String usersCollection = 'users';
  static const String lobbiesCollection = 'lobbies';
  static const String gamesCollection = 'games';

  // Game Constants
  static const int matchmakingTimeoutSeconds = 30;
  static const int gameTimeoutSeconds = 30;
  static const int maxPlayersPerLobby = 2;

  // Animation Durations
  static const Duration choiceAnimationDuration = Duration(milliseconds: 800);
  static const Duration resultAnimationDuration = Duration(milliseconds: 1200);
  static const Duration loadingAnimationDuration = Duration(milliseconds: 1500);

  // UI Constants
  static const double buttonRadius = 12.0;
  static const double cardRadius = 16.0;
  static const double iconSize = 24.0;
  static const double largeIconSize = 48.0;

  // Colors
  static const int primaryColorValue = 0xFF6200EE;
  static const int secondaryColorValue = 0xFF03DAC6;
  static const int backgroundColorValue = 0xFFF5F5F5;
  static const int surfaceColorValue = 0xFFFFFFFF;
  static const int errorColorValue = 0xFFB00020;

  // Font Sizes
  static const double headline1Size = 32.0;
  static const double headline2Size = 24.0;
  static const double headline3Size = 20.0;
  static const double body1Size = 16.0;
  static const double body2Size = 14.0;
  static const double captionSize = 12.0;
}
