import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/voice_repository.dart';
import '../../domain/models/peer_model.dart';
import '../../../../core/network/socket_service.dart';

// Events
abstract class RoomEvent extends Equatable {
  const RoomEvent();
  @override
  List<Object?> get props => [];
}

class JoinRoomRequested extends RoomEvent {
  final String roomId;
  const JoinRoomRequested(this.roomId);
  @override
  List<Object?> get props => [roomId];
}

class LeaveRoomRequested extends RoomEvent {}

class PeerJoined extends RoomEvent {
  final Peer peer;
  final String producerId;
  const PeerJoined(this.peer, {required this.producerId});
  @override
  List<Object?> get props => [peer, producerId];
}

class PeerLeft extends RoomEvent {
  final String peerId;
  const PeerLeft(this.peerId);
  @override
  List<Object?> get props => [peerId];
}

// States
abstract class RoomState extends Equatable {
  const RoomState();
  @override
  List<Object?> get props => [];
}

class RoomInitial extends RoomState {}

class RoomConnecting extends RoomState {}

class RoomConnected extends RoomState {
  final String roomId;
  final List<Peer> peers;
  const RoomConnected({required this.roomId, this.peers = const []});
  @override
  List<Object?> get props => [roomId, peers];
}

class RoomError extends RoomState {
  final String message;
  const RoomError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class RoomBloc extends Bloc<RoomEvent, RoomState> {
  final VoiceRepository _voiceRepository;
  final SocketService _socketService; // Check dependency handling

  RoomBloc(this._voiceRepository, this._socketService) : super(RoomInitial()) {
    on<JoinRoomRequested>(_onJoinRoom);
    on<LeaveRoomRequested>(_onLeaveRoom);
    on<PeerJoined>((event, emit) {
      if (state is RoomConnected) {
        final current = state as RoomConnected;
        emit(
          RoomConnected(
            roomId: current.roomId,
            peers: [...current.peers, event.peer],
          ),
        );
        // Also trigger consume
        _voiceRepository.consume(
          event.peer.id,
          event.producerId,
        ); // Wait, peer.id here is usually ProducerId from signal?
        // Logic gap: The signal 'new_peer' usually gives peerId. Then we assume they produce audio?
        // Mediasoup flow: new_peer -> wait for new_consumer or just try to consume if we know they have producer.
        // For simplification, assuming new_peer has producerId or we call consume flow.
      }
    });

    // Setup listeners
    _socketService.onNewPeer = (data) {
      // data usually { 'id': '...', 'producerId': '...' }
      // We add PeerJoined event
      add(
        PeerJoined(
          Peer(id: data['id'] ?? 'unknown'),
          producerId: data['producerId'] ?? 'unknown',
        ),
      ); // Updated to pass producerId
    };
  }

  Future<void> _onJoinRoom(
    JoinRoomRequested event,
    Emitter<RoomState> emit,
  ) async {
    emit(RoomConnecting());
    try {
      await _voiceRepository.joinRoom(event.roomId);
      await _voiceRepository.produceAudio();
      emit(RoomConnected(roomId: event.roomId, peers: []));
    } catch (e) {
      emit(RoomError(e.toString()));
    }
  }

  Future<void> _onLeaveRoom(
    LeaveRoomRequested event,
    Emitter<RoomState> emit,
  ) async {
    _voiceRepository.leaveRoom();
    emit(RoomInitial());
  }

  @override
  Future<void> close() {
    _voiceRepository.leaveRoom();
    return super.close();
  }
}
