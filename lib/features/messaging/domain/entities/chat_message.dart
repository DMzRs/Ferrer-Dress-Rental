/// Single chat message sent by a customer or an admin.
class ChatMessage {
/// Message document id.
  final String id;
/// Uid of the message sender.
  final String senderId;
/// Role of the sender, either customer or admin.
  final String senderRole;
/// Trimmed message body.
  final String text;
/// Send time, null while a server timestamp is pending.
  final DateTime? createdAt;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderRole,
    required this.text,
    this.createdAt,
  });

  /// Returns true when the given uid sent this message.
  bool isMine(String uid) => senderId == uid;
}
