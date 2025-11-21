class Command {
  final int? id;
  final String topic;
  final String payload;
  final String status; // pending/sent/failed
  final DateTime createdAt;
  final DateTime? sentAt;

  Command({
    this.id,
    required this.topic,
    required this.payload,
    required this.status,
    required this.createdAt,
    this.sentAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'topic': topic,
      'payload': payload,
      'status': status,
      'created_at': createdAt.millisecondsSinceEpoch,
      'sent_at': sentAt?.millisecondsSinceEpoch,
    };
  }

  factory Command.fromMap(Map<String, dynamic> map) {
    return Command(
      id: map['id'],
      topic: map['topic'],
      payload: map['payload'],
      status: map['status'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      sentAt: map['sent_at'] != null ? DateTime.fromMillisecondsSinceEpoch(map['sent_at']) : null,
    );
  }
}