class UserModel {
  final String id;
  final String email;
  final String? phone;
  final String name;
  final String locale;
  final bool isPremium;
  final String subscriptionPlan;
  final int aiQueriesToday;
  final int aiDailyLimit;
  final bool dailySummaryEmail;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.email,
    this.phone,
    required this.name,
    required this.locale,
    this.isPremium = false,
    this.subscriptionPlan = 'FREE',
    this.aiQueriesToday = 0,
    this.aiDailyLimit = 3,
    this.dailySummaryEmail = true,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      name: json['name'] as String,
      locale: json['locale'] as String? ?? 'en',
      isPremium: json['isPremium'] as bool? ?? false,
      subscriptionPlan: json['subscriptionPlan'] as String? ?? 'FREE',
      aiQueriesToday: json['aiQueriesToday'] as int? ?? 0,
      aiDailyLimit: json['aiDailyLimit'] as int? ?? 3,
      dailySummaryEmail: json['dailySummaryEmail'] as bool? ?? true,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'phone': phone,
    'name': name,
    'locale': locale,
    'isPremium': isPremium,
    'subscriptionPlan': subscriptionPlan,
    'aiQueriesToday': aiQueriesToday,
    'aiDailyLimit': aiDailyLimit,
    'dailySummaryEmail': dailySummaryEmail,
  };
}
