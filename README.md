# 🎮 Rock Paper Scissors - Multiplayer Game

A modern multiplayer Rock Paper Scissors game built with Flutter and Firebase, featuring real-time matchmaking, friend invites, and bot opponents.

## ✨ Features

- **🎯 Multiplayer Matchmaking**: Find random opponents or play with friends
- **🤖 Bot Opponents**: Practice against intelligent AI when no players are available
- **👥 Friend Invites**: Create private games with shareable codes
- **🔥 Real-time Gameplay**: Live updates using Firebase Firestore
- **📱 Cross-platform**: Works on Android and iOS
- **🎨 Modern UI**: Beautiful animations and responsive design
- **🔐 Authentication**: Anonymous and Google Sign-in support

## 🏗️ Architecture

- **State Management**: Riverpod for clean, testable state management
- **Backend**: Firebase (Auth, Firestore, Dynamic Links)
- **UI**: Flutter with Material Design 3
- **Animations**: Flutter Animate and Lottie
- **Architecture**: MVVM with layered architecture

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (latest stable)
- Firebase project
- Android Studio / VS Code

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd rockpapersissor
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Enable Authentication (Anonymous, Google)
   - Create Firestore Database
   - Enable Dynamic Links
   - Download `google-services.json` and `GoogleService-Info.plist`
   - Place them in `android/app/` and `ios/Runner/` respectively

4. **Run the app**
   ```bash
   flutter run
   ```

## 📁 Project Structure

```
lib/
├── core/
│   ├── constants.dart
│   ├── models/
│   │   └── game_models.dart
│   └── utils/
│       └── game_logic.dart
├── features/
│   ├── auth/
│   │   ├── view/
│   │   ├── viewmodel/
│   │   └── repository/
│   ├── home/
│   │   └── view/
│   ├── matchmaking/
│   │   ├── view/
│   │   ├── viewmodel/
│   │   └── repository/
│   ├── game/
│   │   ├── view/
│   │   ├── viewmodel/
│   │   ├── repository/
│   │   └── widgets/
│   ├── invite/
│   │   ├── view/
│   │   ├── viewmodel/
│   │   └── repository/
│   └── bot/
│       └── logic/
├── theme/
│   └── app_theme.dart
├── routes/
│   └── app_router.dart
├── app.dart
└── main.dart
```

## 🎯 How to Play

1. **Sign In**: Use anonymous or Google sign-in
2. **Choose Mode**:
   - **Quick Match**: Find random opponents
   - **Play with Friends**: Create or join private games
   - **Practice vs Bot**: Play against AI
3. **Make Your Move**: Choose Rock, Paper, or Scissors
4. **See Results**: View animated results and play again

## 🔧 Configuration

### Firebase Configuration

Update the following in your Firebase project:

1. **Authentication Rules**:
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /users/{userId} {
         allow read, write: if request.auth != null && request.auth.uid == userId;
       }
       match /lobbies/{lobbyId} {
         allow read, write: if request.auth != null;
       }
       match /games/{gameId} {
         allow read, write: if request.auth != null;
       }
     }
   }
   ```

2. **Dynamic Links Domain**: Configure in Firebase Console

### Environment Variables

Create a `.env` file for sensitive configuration:
```
FIREBASE_PROJECT_ID=your-project-id
DYNAMIC_LINKS_DOMAIN=your-domain.page.link
```

## 🧪 Testing

Run tests with:
```bash
flutter test
```

## 📦 Building for Production

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## 🔮 Future Enhancements

- [ ] Player profiles and avatars
- [ ] Win/loss statistics
- [ ] Leaderboards
- [ ] Emojis and reactions
- [ ] Tournament mode
- [ ] Custom themes
- [ ] Sound effects
- [ ] Push notifications

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

If you encounter any issues or have questions, please open an issue on GitHub.

---

**Happy Gaming! 🎮✂️📄🪨**
