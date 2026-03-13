class Player {
  const Player({
    required this.id,
    required this.nickname,
    this.email,
    required this.createdAt,
    this.xp = 0,
  });

  final String id;
  final String nickname;
  final String? email;
  final DateTime createdAt;
  final int xp;

  Player copyWith({
    String? id,
    String? nickname,
    String? email,
    DateTime? createdAt,
    int? xp,
  }) =>
      Player(
        id: id ?? this.id,
        nickname: nickname ?? this.nickname,
        email: email ?? this.email,
        createdAt: createdAt ?? this.createdAt,
        xp: xp ?? this.xp,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nickname': nickname,
        if (email != null) 'email': email,
        'createdAt': createdAt.toIso8601String(),
        'xp': xp,
      };

  factory Player.fromJson(Map<String, dynamic> json) => Player(
        id: json['id'] as String,
        nickname: json['nickname'] as String,
        email: json['email'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        xp: json['xp'] as int? ?? 0,
      );
}
