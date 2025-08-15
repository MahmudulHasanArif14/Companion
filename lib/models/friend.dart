class Friend {
  final String id;
  final String user1Id;
  final String user2Id;
  final DateTime createdAt;

  Friend({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.createdAt,
  });

  factory Friend.fromMap(Map<String, dynamic> map) {
    return Friend(
      id: map['id'] ?? '',
      user1Id: map['user1_id'] ?? '',
      user2Id: map['user2_id'] ?? '',
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}