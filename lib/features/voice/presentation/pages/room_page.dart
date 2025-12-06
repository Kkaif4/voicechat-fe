import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/room_bloc.dart';
import '../../../../core/network/socket_service.dart';
import '../../data/voice_repository.dart';

class RoomPage extends StatelessWidget {
  final String roomId;
  final String roomName;

  const RoomPage({super.key, required this.roomId, required this.roomName});

  @override
  Widget build(BuildContext context) {
    final socketService = RepositoryProvider.of<SocketService>(context);

    return BlocProvider(
      create: (context) =>
          RoomBloc(VoiceRepository(socketService), socketService)
            ..add(JoinRoomRequested(roomId)),
      child: RoomView(roomName: roomName),
    );
  }
}

class RoomView extends StatelessWidget {
  final String roomName;
  const RoomView({super.key, required this.roomName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(roomName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.read<RoomBloc>().add(LeaveRoomRequested());
            Navigator.of(context).pop();
          },
        ),
      ),
      body: BlocConsumer<RoomBloc, RoomState>(
        listener: (context, state) {
          if (state is RoomError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is RoomConnecting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is RoomConnected) {
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: state.peers.length + 1, // +1 for Me
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const _UserAvatar(
                    name: 'Me',
                    isSpeaking: false,
                  ); // Connect to local mic status later
                }
                final peer = state.peers[index - 1];
                return _UserAvatar(
                  name: peer.username,
                  isSpeaking: peer.isSpeaking,
                );
              },
            );
          }

          return const Center(child: Text("Initializing..."));
        },
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.mic),
              ), // Toggle Mute
              IconButton(
                onPressed: () {
                  // Open Chat Bottom Sheet
                },
                icon: const Icon(Icons.chat),
              ),
              IconButton(
                onPressed: () {
                  context.read<RoomBloc>().add(LeaveRoomRequested());
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.call_end, color: Colors.red),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final String name;
  final bool isSpeaking;

  const _UserAvatar({required this.name, required this.isSpeaking});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        shape: BoxShape.circle,
        border: isSpeaking
            ? Border.all(color: Theme.of(context).colorScheme.primary, width: 4)
            : null,
      ),
      child: Center(
        child: Text(
          name[0].toUpperCase(),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
