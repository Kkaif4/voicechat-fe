import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/models/message_model.dart';
import '../../../../core/network/socket_service.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();
  @override
  List<Object> get props => [];
}

class SendMessage extends ChatEvent {
  final String content;
  const SendMessage(this.content);
}

class NewMessageReceived extends ChatEvent {
  final Message message;
  const NewMessageReceived(this.message);
}

abstract class ChatState extends Equatable {
  const ChatState();
  @override
  List<Object> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoaded extends ChatState {
  final List<Message> messages;
  const ChatLoaded(this.messages);
  @override
  List<Object> get props => [messages];
}

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final SocketService _socketService;

  ChatBloc(this._socketService) : super(ChatInitial()) {
    on<SendMessage>((event, emit) {
      _socketService.socket.emit('send_message', {'content': event.content});
      // Optimistic update could happen here
    });

    on<NewMessageReceived>((event, emit) {
      final currentState = state;
      if (currentState is ChatLoaded) {
        emit(ChatLoaded([...currentState.messages, event.message]));
      } else {
        emit(ChatLoaded([event.message]));
      }
    });

    // Listen to socket
    _socketService.socket.on('new_message', (data) {
      add(NewMessageReceived(Message.fromJson(data)));
    });
  }
}
