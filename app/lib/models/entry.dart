class EntryModel {
  final String id;
  final String babyId;
  final String type; // FEED, SLEEP, DIAPER, GROWTH, MEDICINE, NOTE
  final DateTime startedAt;
  final DateTime? endedAt;
  final Map<String, dynamic> data;
  final String? note;
  final String? authorName;
  final String? authorId;

  EntryModel({
    required this.id,
    required this.babyId,
    required this.type,
    required this.startedAt,
    this.endedAt,
    this.data = const {},
    this.note,
    this.authorName,
    this.authorId,
  });

  bool get isSleepActive => type == 'SLEEP' && endedAt == null;

  int? get durationMinutes {
    if (endedAt == null) return null;
    return endedAt!.difference(startedAt).inMinutes;
  }

  factory EntryModel.fromJson(Map<String, dynamic> json) {
    final createdBy = json['createdBy'] as Map<String, dynamic>?;
    return EntryModel(
      id: json['id'] as String,
      babyId: json['babyId'] as String,
      type: json['type'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: json['endedAt'] != null ? DateTime.parse(json['endedAt'] as String) : null,
      data: (json['data'] as Map<String, dynamic>?) ?? {},
      note: json['note'] as String?,
      authorName: createdBy?['name'] as String?,
      authorId: createdBy?['id'] as String? ?? json['createdById'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'startedAt': startedAt.toUtc().toIso8601String(),
    if (endedAt != null) 'endedAt': endedAt!.toUtc().toIso8601String(),
    'data': data,
    if (note != null) 'note': note,
  };
}

class DailySummaryModel {
  final int feeds;
  final int bottleMl;
  final int breastMinutes;
  final int sleepMinutes;
  final int diapersTotal;
  final int diapersWet;
  final int diapersDirty;
  final EntryModel? activeSleep;
  final EntryModel? lastFeed;
  final EntryModel? lastSleep;
  final EntryModel? lastDiaper;
  final EntryModel? lastGrowth;
  final EntryModel? lastMedicine;

  DailySummaryModel({
    this.feeds = 0,
    this.bottleMl = 0,
    this.breastMinutes = 0,
    this.sleepMinutes = 0,
    this.diapersTotal = 0,
    this.diapersWet = 0,
    this.diapersDirty = 0,
    this.activeSleep,
    this.lastFeed,
    this.lastSleep,
    this.lastDiaper,
    this.lastGrowth,
    this.lastMedicine,
  });

  factory DailySummaryModel.fromJson(Map<String, dynamic> json) {
    final diapers = json['diapers'] as Map<String, dynamic>? ?? {};
    final last = json['last'] as Map<String, dynamic>? ?? {};

    return DailySummaryModel(
      feeds: (json['feeds'] as num?)?.toInt() ?? 0,
      bottleMl: (json['bottleMl'] as num?)?.toInt() ?? 0,
      breastMinutes: (json['breastMinutes'] as num?)?.toInt() ?? 0,
      sleepMinutes: (json['sleepMinutes'] as num?)?.toInt() ?? 0,
      diapersTotal: (diapers['total'] as num?)?.toInt() ?? 0,
      diapersWet: (diapers['wet'] as num?)?.toInt() ?? 0,
      diapersDirty: (diapers['dirty'] as num?)?.toInt() ?? 0,
      activeSleep: json['activeSleep'] != null ? EntryModel.fromJson(json['activeSleep']) : null,
      lastFeed: last['feed'] != null ? EntryModel.fromJson(last['feed']) : null,
      lastSleep: last['sleep'] != null ? EntryModel.fromJson(last['sleep']) : null,
      lastDiaper: last['diaper'] != null ? EntryModel.fromJson(last['diaper']) : null,
      lastGrowth: last['growth'] != null ? EntryModel.fromJson(last['growth']) : null,
      lastMedicine: last['medicine'] != null ? EntryModel.fromJson(last['medicine']) : null,
    );
  }
}
