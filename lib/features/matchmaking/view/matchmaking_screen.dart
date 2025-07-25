import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../viewmodel/matchmaking_provider.dart';
import '../../../core/constants.dart';

class MatchmakingScreen extends ConsumerWidget {
  const MatchmakingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchmakingState = ref.watch(matchmakingProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Find Opponent'), elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Header
            Text(
              'Choose Game Mode',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Play against random players or invite friends',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),

            // Game Mode Cards
            Expanded(
              child: Column(
                children: [
                  // Random Matchmaking Card
                  Card(
                    elevation: 4,
                    child: InkWell(
                      onTap: matchmakingState.isLoading
                          ? null
                          : () => ref
                              .read(matchmakingProvider.notifier)
                              .startMatchmaking(),
                      borderRadius: BorderRadius.circular(
                        AppConstants.cardRadius,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.shuffle,
                              size: 64,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Quick Match',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Find a random opponent instantly',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: Colors.grey[600]),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            if (matchmakingState.isLoading)
                              const CircularProgressIndicator()
                            else
                              ElevatedButton(
                                onPressed: () {
                                  ref
                                      .read(matchmakingProvider.notifier)
                                      .startMatchmaking();
                                },
                                child: const Text('Find Match'),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3),

                  const SizedBox(height: 24),

                  // Friend Invite Card
                  Card(
                    elevation: 4,
                    child: InkWell(
                      onTap: () {
                        Navigator.pushNamed(context, '/invite');
                      },
                      borderRadius: BorderRadius.circular(
                        AppConstants.cardRadius,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.people,
                              size: 64,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Play with Friends',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Invite friends with a game code',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: Colors.grey[600]),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/invite');
                              },
                              child: const Text('Invite Friends'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 200.ms)
                      .slideY(begin: 0.3),
                ],
              ),
            ),

            // Status Messages
            if (matchmakingState.isLoading)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const CircularProgressIndicator(strokeWidth: 2),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Searching for opponent...',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: 0.5),

            if (matchmakingState.error != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        matchmakingState.error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: 0.5),
          ],
        ),
      ),
    );
  }
}
