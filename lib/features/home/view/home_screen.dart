import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../auth/viewmodel/auth_provider.dart';
import '../../matchmaking/viewmodel/matchmaking_provider.dart';
import '../../../core/constants.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Reset matchmaking state when returning to home
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(matchmakingProvider.notifier).resetState();
      _handleMatchmakingState();
    });
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _handleMatchmakingState();
  }

  void _handleMatchmakingState() {
    final matchmakingState = ref.read(matchmakingProvider);

    print('DEBUG: _handleMatchmakingState called');
    print('DEBUG: isBotMatch: ${matchmakingState.isBotMatch}');
    print('DEBUG: isLoading: ${matchmakingState.isLoading}');
    print('DEBUG: currentLobby: ${matchmakingState.currentLobby?.id}');
    print('DEBUG: botName: ${matchmakingState.botName}');

    if (matchmakingState.isBotMatch) {
      print('DEBUG: Navigating to bot game');
      // Navigate to bot game
      Navigator.pushNamed(
        context,
        '/game',
        arguments: {'isBotMatch': true, 'botName': matchmakingState.botName},
      );
    } else if (matchmakingState.currentLobby != null) {
      print(
          'DEBUG: Navigating to multiplayer game with lobby: ${matchmakingState.currentLobby!.id}');
      // Navigate to multiplayer game (even if lobby is not full yet)
      Navigator.pushNamed(
        context,
        '/game',
        arguments: {'lobbyId': matchmakingState.currentLobby!.id},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<MatchmakingState>(matchmakingProvider, (previous, next) {
      _handleMatchmakingState();
    });
    final user = ref.watch(currentUserProvider).value;
    final matchmakingState = ref.watch(matchmakingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rock Paper Scissors'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authNotifierProvider.notifier).signOut();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context)
                      .colorScheme
                      .primary
                      .withAlpha((255 * 0.1).toInt()),
                  Theme.of(context)
                      .colorScheme
                      .secondary
                      .withAlpha((255 * 0.1).toInt()),
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Welcome Section
                    Expanded(
                      flex: 2,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.sports_esports,
                            size: 80,
                            color: Theme.of(context).colorScheme.primary,
                          ).animate().scale(duration: 600.ms),
                          const SizedBox(height: 16),
                          Text(
                            'Welcome!',
                            style: Theme.of(context)
                                .textTheme
                                .headlineLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ).animate().fadeIn(delay: 200.ms),
                          const SizedBox(height: 8),
                          Text(
                            user?.displayName ?? 'Player',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(color: Colors.grey[600]),
                          ).animate().fadeIn(delay: 400.ms),
                        ],
                      ),
                    ),

                    // Game Options
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          // Quick Match Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                print('DEBUG: Quickplay button pressed');
                                ref
                                    .read(matchmakingProvider.notifier)
                                    .startQuickplay();
                              },
                              icon: const Icon(Icons.shuffle),
                              label: const Text('Quickplay'),
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 20),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3),

                          const SizedBox(height: 16),

                          // Play with Friends Button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(context, '/invite');
                              },
                              icon: const Icon(Icons.people),
                              label: const Text('Play with Friends'),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 20),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.3),

                          const SizedBox(height: 16),

                          // Practice vs Bot Button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/game',
                                  arguments: {
                                    'isBotMatch': true,
                                    'botName': 'Smart Bot'
                                  },
                                );
                              },
                              icon: const Icon(Icons.smart_toy),
                              label: const Text('Practice vs Bot'),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 20),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.3),
                        ],
                      ),
                    ),

                    // Stats Section (placeholder for future)
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha((255 * 0.8).toInt()),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatItem('Wins', '0'),
                            _buildStatItem('Losses', '0'),
                            _buildStatItem('Draws', '0'),
                          ],
                        ),
                      ).animate().fadeIn(delay: 1200.ms).slideY(begin: 0.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Matchmaking overlay
          if (matchmakingState.isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Card(
                  margin: const EdgeInsets.all(32),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Finding opponent...',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${matchmakingState.searchTime}s / ${AppConstants.matchmakingTimeoutSeconds}s',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            ref
                                .read(matchmakingProvider.notifier)
                                .cancelMatchmaking();
                          },
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}
