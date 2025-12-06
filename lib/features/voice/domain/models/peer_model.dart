class Peer {
  final String id;
  final String username; // Optional, might just be ID initially
  final bool isSpeaking;
  final bool isMuted;

  Peer({
    required this.id,
    this.username = 'User',
    this.isSpeaking = false,
    this.isMuted = false,
  });

  Peer copyWith({
    String? id,
    String? username,
    bool? isSpeaking,
    bool? isMuted,
  }) {
    return Peer(
      id: id ?? this.id,
      username: username ?? this.username,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      isMuted: isMuted ?? this.isMuted,
    );
  }
}
