import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import '../viewmodel/invite_provider.dart';
import '../../../core/constants.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

class InviteScreen extends ConsumerStatefulWidget {
  const InviteScreen({super.key});

  @override
  ConsumerState<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends ConsumerState<InviteScreen> {
  final TextEditingController _inviteCodeController = TextEditingController();
  bool _isJoining = false;

  @override
  void dispose() {
    _inviteCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inviteState = ref.watch(inviteProvider);

    // Listen to lobby changes and navigate to game when full
    final currentLobby = inviteState.currentLobby;
    if (currentLobby != null && currentLobby.playerIds.length == 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/game',
          (route) => false,
          arguments: {'lobbyId': currentLobby.id},
        );
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Play with Friends'), elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Text(
                'Invite Friends',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create a private game or join with a code',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Create Private Lobby Card
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Create Private Game',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start a new game and invite friends',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      if (inviteState.isCreatingLobby)
                        const CircularProgressIndicator()
                      else if (inviteState.currentLobby != null &&
                          inviteState.inviteLink != null)
                        Column(
                          children: [
                            Text(
                              'Invite Code:',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SelectableText(
                                  inviteState.inviteLink!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 2,
                                      ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy),
                                  tooltip: 'Copy Code',
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(
                                        text: inviteState.inviteLink!));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Invite code copied!')),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (inviteState.currentLobby!.playerIds.length == 1)
                              Text('Waiting for friend to join...',
                                  style: TextStyle(color: Colors.grey[600])),
                            if (inviteState.currentLobby!.playerIds.length == 2)
                              Text('Friend joined! Starting game...',
                                  style: TextStyle(color: Colors.green)),
                          ],
                        )
                      else
                        ElevatedButton(
                          onPressed: () {
                            ref
                                .read(inviteProvider.notifier)
                                .createPrivateLobby();
                          },
                          child: const Text('Create Game'),
                        ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3),

              const SizedBox(height: 24),

              // Join with Code Card
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.qr_code,
                        size: 64,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Join with Code',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter a friend\'s invite code',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _inviteCodeController,
                        decoration: InputDecoration(
                          hintText: 'Enter 6-digit code',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppConstants.buttonRadius,
                            ),
                          ),
                          prefixIcon: const Icon(Icons.code),
                        ),
                        textCapitalization: TextCapitalization.characters,
                        maxLength: 6,
                        onChanged: (value) {
                          final upper = value.toUpperCase();
                          if (value != upper) {
                            final cursor = _inviteCodeController.selection;
                            _inviteCodeController.value = TextEditingValue(
                              text: upper,
                              selection: cursor,
                            );
                          }
                          setState(() {});
                        },
                      ),
                      if (inviteState.error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            inviteState.error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      const SizedBox(height: 16),
                      if (_isJoining)
                        const CircularProgressIndicator()
                      else
                        ElevatedButton(
                          onPressed: _inviteCodeController.text.trim().length ==
                                  6
                              ? () {
                                  setState(() => _isJoining = true);
                                  ref
                                      .read(inviteProvider.notifier)
                                      .joinLobbyWithCode(
                                        _inviteCodeController.text
                                            .trim()
                                            .toUpperCase(),
                                      )
                                      .then(
                                        (_) =>
                                            setState(() => _isJoining = false),
                                      );
                                }
                              : null,
                          child: const Text('Join Game'),
                        ),
                      if (inviteState.currentLobby != null &&
                          inviteState.currentLobby!.playerIds.length == 1)
                        Text('Waiting for host to start...',
                            style: TextStyle(color: Colors.grey[600])),
                      if (inviteState.currentLobby != null &&
                          inviteState.currentLobby!.playerIds.length == 2)
                        Text('Joined! Starting game...',
                            style: TextStyle(color: Colors.green)),
                    ],
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 200.ms)
                  .slideY(begin: 0.3),

              const SizedBox(height: 32),

              // Current Lobby Info
              if (inviteState.currentLobby != null) ...[
                Card(
                  color: Colors.green.withAlpha((255 * 0.1).toInt()),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green),
                            const SizedBox(width: 8),
                            Text(
                              'Lobby Created!',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Invite Code:',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: Colors.grey[600]),
                                    ),
                                    Text(
                                      inviteState.currentLobby!.inviteCode ??
                                          'N/A',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 2,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  Share.share(
                                    'Join my Rock Paper Scissors game! Code: \\${inviteState.currentLobby!.inviteCode}',
                                    subject: 'Rock Paper Scissors Invite',
                                  );
                                },
                                icon: const Icon(Icons.share),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Share this code with your friend to start playing!',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn().slideY(begin: 0.5),
              ],

              // Error Messages
              if (inviteState.error != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha((255 * 0.1).toInt()),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          inviteState.error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: 0.5),
            ],
          ),
        ),
      ),
    );
  }
}
