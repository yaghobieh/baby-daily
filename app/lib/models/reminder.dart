class ReminderModel {
  final String id;
  final String babyId;
  final String kind; // AFTER_LAST, DAILY_AT
  final String title;
  final String? entryType;
  final int? intervalMinutes;
  final int? timeOfDay; // minutes from midnight
  final bool enabled;
  final String? taggedUserId;
  final String? taggedUserName;
  final DateTime? nextAt;

  ReminderModel({
    required this.id,
    required this.babyId,
    required this.kind,
    required this.title,
    this.entryType,
    this.intervalMinutes,
    this.timeOfDay,
    this.enabled = true,
    this.taggedUserId,
    this.taggedUserName,
    this.nextAt,
  });

  factory ReminderModel.fromJson(Map<String, dynamic> json) {
    return ReminderModel(
      id: json['id'] as String,
      babyId: json['babyId'] as String,
      kind: json['kind'] as String,
      title: json['title'] as String,
      entryType: json['entryType'] as String?,
      intervalMinutes: json['intervalMinutes'] as int?,
      timeOfDay: json['timeOfDay'] as int?,
      enabled: json['enabled'] as bool? ?? true,
      taggedUserId: json['taggedUserId'] as String?,
      taggedUserName: json['taggedUserName'] as String?,
      nextAt: json['nextAt'] != null ? DateTime.tryParse(json['nextAt'] as String) : null,
    );
  }
}

class NotificationItemModel {
  final String id;
  final String? babyId;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final DateTime? readAt;
  final DateTime createdAt;

  NotificationItemModel({
    required this.id,
    this.babyId,
    required this.title,
    required this.body,
    this.data = const {},
    this.readAt,
    required this.createdAt,
  });

  bool get isRead => readAt != null;

  factory NotificationItemModel.fromJson(Map<String, dynamic> json) {
    return NotificationItemModel(
      id: json['id'] as String,
      babyId: json['babyId'] as String?,
      title: json['title'] as String,
      body: json['body'] as String,
      data: (json['data'] as Map<String, dynamic>?) ?? {},
      readAt: json['readAt'] != null ? DateTime.tryParse(json['readAt'] as String) : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
