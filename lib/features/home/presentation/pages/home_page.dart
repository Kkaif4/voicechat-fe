import 'package:flutter/material.dart';

import '../../../voice/presentation/pages/room_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  final List<String> _channels = const ['General', 'Gaming', 'Music', 'Coding'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Channels'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Settings or Logout
            },
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _channels.length,
        separatorBuilder: (_, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final channel = _channels[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Icon(Icons.mic, color: Colors.white),
              ),
              title: Text(
                channel,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('0 Online'),
              trailing: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RoomPage(
                        roomId: channel.toLowerCase(),
                        roomName: channel,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                child: const Text('Join'),
              ),
            ),
          );
        },
      ),
    );
  }
}
