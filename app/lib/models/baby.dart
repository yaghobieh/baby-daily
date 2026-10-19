class BabyModel {
  final String id;
  final String name;
  final DateTime? birthDate;
  final String? gender;
  final String avatarColor;
  final String role; // OWNER, CAREGIVER, VIEWER
  final int memberCount;

  BabyModel({
    required this.id,
    required this.name,
    this.birthDate,
    this.gender,
    required this.avatarColor,
    required this.role,
    this.memberCount = 1,
  });

  bool get isOwner => role == 'OWNER';
  bool get canLog => role == 'OWNER' || role == 'CAREGIVER';

  factory BabyModel.fromJson(Map<String, dynamic> json) {
    return BabyModel(
      id: json['id'] as String,
      name: json['name'] as String,
      birthDate: json['birthDate'] != null ? DateTime.tryParse(json['birthDate'] as String) : null,
      gender: json['gender'] as String?,
      avatarColor: json['avatarColor'] as String? ?? '#F7A8C4',
      role: json['role'] as String? ?? 'CAREGIVER',
      memberCount: json['memberCount'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'birthDate': birthDate?.toIso8601String(),
    'gender': gender,
    'avatarColor': avatarColor,
  };
}

class BabyMemberModel {
  final String id;
  final String userId;
  final String role;
  final String name;
  final String email;
  final String? phone;
  final DateTime? createdAt;

  BabyMemberModel({
    required this.id,
    required this.userId,
    required this.role,
    required this.name,
    required this.email,
    this.phone,
    this.createdAt,
  });

  factory BabyMemberModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? {};
    final uId = (json['userId'] as String?) ?? (user['id'] as String?) ?? (json['id'] as String);
    return BabyMemberModel(
      id: json['id'] as String,
      userId: uId,
      role: json['role'] as String? ?? 'CAREGIVER',
      name: user['name'] as String? ?? (json['name'] as String? ?? ''),
      email: user['email'] as String? ?? (json['email'] as String? ?? ''),
      phone: user['phone'] as String? ?? json['phone'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
    );
  }
}
