class Message {
  final String id;
  final String senderId;
  final String recipientId;
  final String message;
  final DateTime createdAt;
  final bool read;

  // Helper fields populated from joins
  String? senderName;
  String? recipientName;

  Message({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.message,
    required this.createdAt,
    required this.read,
    this.senderName,
    this.recipientName,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      senderId: json['sender_id'],
      recipientId: json['recipient_id'],
      message: json['message'],
      createdAt: DateTime.parse(json['created_at']),
      read: json['read'] ?? false,
      senderName: json['sender_name'],
      recipientName: json['recipient_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'recipient_id': recipientId,
      'message': message,
      'created_at': createdAt.toIso8601String(),
      'read': read,
    };
  }
}
