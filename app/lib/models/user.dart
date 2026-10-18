class UserModel {
  final String id;
  final String email;
  final String? phone;
  final String name;
  final String locale;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.email,
    this.phone,
    required this.name,
    required this.locale,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      name: json['name'] as String,
      locale: json['locale'] as String? ?? 'en',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'phone': phone,
    'name': name,
    'locale': locale,
  };
}
