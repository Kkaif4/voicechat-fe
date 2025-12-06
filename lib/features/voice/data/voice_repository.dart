import 'dart:async';
import 'package:mediasoup_client_flutter/mediasoup_client_flutter.dart';
import '../../../../core/network/socket_service.dart';

class VoiceRepository {
  final SocketService _socketService;
  final Device _device = Device();

  Transport? _sendTransport;
  Transport? _recvTransport;

  VoiceRepository(this._socketService);

  // Initialize and Join
  Future<void> joinRoom(String roomId) async {
    _socketService.joinRoom(roomId);

    // 1. Get Router Capabilities
    final routerRtpCapabilities = await _emitWithAck(
      'getRouterRtpCapabilities',
      {'roomId': roomId},
    );

    // 2. Load Device
    await _device.load(
      routerRtpCapabilities: RtpCapabilities.fromMap(routerRtpCapabilities),
    );

    // 3. Create Send Transport
    await _createSendTransport(roomId);

    // 4. Create Recv Transport
    await _createRecvTransport(roomId);
  }

  Future<void> produceAudio() async {
    if (_sendTransport == null) return;

    // Get Mic Stream
    final mediaConstraints = <String, dynamic>{'audio': true, 'video': false};
    final stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    final audioTrack = stream.getAudioTracks().first;

    _sendTransport!.produce(
      track: audioTrack,
      stream: stream,
      source: 'mic',
      codecOptions: ProducerCodecOptions(opusStereo: 1, opusDtx: 1),
      appData: {'source': 'mic'},
    );
  }

  Future<void> consume(String producerId, String peerId) async {
    if (_recvTransport == null) return;

    // Check if we can consume
    // In real app we check _device.rtpCapabilities.canConsume(producerRtpCapabilities)

    final response = await _emitWithAck('consume', {
      'producerId': producerId,
      'rtpCapabilities': _device.rtpCapabilities.toMap(),
    });

    _recvTransport!.consume(
      id: response['id'],
      producerId: response['producerId'],
      peerId: peerId,
      kind: RTCRtpMediaTypeExtension.fromString(response['kind']),
      rtpParameters: RtpParameters.fromMap(response['rtpParameters']),
    );

    // TODO: Track consumer if possible. Currently consume returns void.
    // _consumers[consumer.id] = consumer;
    // Resume consumer (sometimes needed if server creates it paused)
    // await _socketService.socket.emit('resumeConsumer', {'consumerId': consumer.id});
  }

  // Helpers
  Future<void> _createSendTransport(String roomId) async {
    final params = await _emitWithAck('createWebRtcTransport', {
      'roomId': roomId,
      'forceTcp': false,
    });

    _sendTransport = _device.createSendTransportFromMap(
      params,
      producerCallback: (kind, rtpParameters, appData) async {
        final producerId = await _emitWithAck('produce', {
          'transportId': _sendTransport!.id,
          'kind': kind.toString(), // or 'audio'
          'rtpParameters': rtpParameters.toMap(),
          'appData': appData,
        });
        return producerId;
      },
    );
  }

  Future<void> _createRecvTransport(String roomId) async {
    final params = await _emitWithAck('createWebRtcTransport', {
      'roomId': roomId,
      'forceTcp': false,
    });

    _recvTransport = _device.createRecvTransportFromMap(params);

    _recvTransport!.on('connect', (data) {
      _socketService.socket.emit('connectWebRtcTransport', {
        'transportId': _recvTransport!.id,
        'dtlsParameters': data['dtlsParameters'].toMap(),
      });
      data['callback']();
    });
  }

  Future<dynamic> _emitWithAck(String event, dynamic data) {
    final completer = Completer();
    _socketService.socket.emitWithAck(
      event,
      data,
      ack: (result) {
        completer.complete(result);
      },
    );
    return completer.future;
  }

  void leaveRoom() {
    _sendTransport?.close();
    _recvTransport?.close();
    _socketService.socket.emit('leave_room');
  }
}
