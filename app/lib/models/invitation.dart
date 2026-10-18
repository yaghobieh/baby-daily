class InvitationModel {
  final String id;
  final String babyId;
  final String? email;
  final String? phone;
  final String role; // CAREGIVER, VIEWER
  final String status; // PENDING, ACCEPTED, DECLINED, REVOKED
  final String? babyName;
  final String? babyAvatarColor;
  final String? invitedByName;
  final DateTime? createdAt;

  InvitationModel({
    required this.id,
    required this.babyId,
    this.email,
    this.phone,
    required this.role,
    required this.status,
    this.babyName,
    this.babyAvatarColor,
    this.invitedByName,
    this.createdAt,
  });

  factory InvitationModel.fromJson(Map<String, dynamic> json) {
    final baby = json['baby'] as Map<String, dynamic>?;
    final invitedBy = json['invitedBy'] as Map<String, dynamic>?;

    return InvitationModel(
      id: json['id'] as String,
      babyId: json['babyId'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'CAREGIVER',
      status: json['status'] as String? ?? 'PENDING',
      babyName: baby?['name'] as String?,
      babyAvatarColor: baby?['avatarColor'] as String?,
      invitedByName: invitedBy?['name'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
    );
  }
}
