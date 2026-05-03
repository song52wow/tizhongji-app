class UserSettings {
  final String id;
  final String? nickname;
  final double? heightCm;
  final String unit; // 'kg' or 'lb'
  final double? targetWeightKg;
  final bool morningReminderEnabled;
  final String? morningReminderTime; // 'HH:mm'
  final bool eveningReminderEnabled;
  final String? eveningReminderTime; // 'HH:mm'
  final String createdAt;
  final String updatedAt;

  UserSettings({
    required this.id,
    this.nickname,
    this.heightCm,
    required this.unit,
    this.targetWeightKg,
    required this.morningReminderEnabled,
    this.morningReminderTime,
    required this.eveningReminderEnabled,
    this.eveningReminderTime,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      id: json['id'] ?? '',
      nickname: json['nickname'],
      heightCm: json['heightCm']?.toDouble(),
      unit: json['unit'] ?? 'kg',
      targetWeightKg: json['targetWeightKg']?.toDouble(),
      morningReminderEnabled: json['morningReminderEnabled'] ?? false,
      morningReminderTime: json['morningReminderTime'],
      eveningReminderEnabled: json['eveningReminderEnabled'] ?? false,
      eveningReminderTime: json['eveningReminderTime'],
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nickname': nickname,
      'heightCm': heightCm,
      'unit': unit,
      'targetWeightKg': targetWeightKg,
      'morningReminderEnabled': morningReminderEnabled,
      'morningReminderTime': morningReminderTime,
      'eveningReminderEnabled': eveningReminderEnabled,
      'eveningReminderTime': eveningReminderTime,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  UserSettings copyWith({
    String? id,
    String? nickname,
    double? heightCm,
    String? unit,
    double? targetWeightKg,
    bool? morningReminderEnabled,
    String? morningReminderTime,
    bool? eveningReminderEnabled,
    String? eveningReminderTime,
    String? createdAt,
    String? updatedAt,
  }) {
    return UserSettings(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      heightCm: heightCm ?? this.heightCm,
      unit: unit ?? this.unit,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      morningReminderEnabled: morningReminderEnabled ?? this.morningReminderEnabled,
      morningReminderTime: morningReminderTime ?? this.morningReminderTime,
      eveningReminderEnabled: eveningReminderEnabled ?? this.eveningReminderEnabled,
      eveningReminderTime: eveningReminderTime ?? this.eveningReminderTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String formatWeight(double weightKg) {
    if (unit == 'lb') {
      final lbs = weightKg * 2.20462;
      return '${lbs.toStringAsFixed(1)} lb';
    }
    return '${weightKg.toStringAsFixed(1)} kg';
  }

  double parseWeight(double weight) {
    if (unit == 'lb') {
      return weight / 2.20462;
    }
    return weight;
  }

  String get unitLabel => unit == 'lb' ? 'lb' : 'kg';
}