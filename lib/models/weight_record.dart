class WeightRecord {
  final String id;
  final String userId;
  final String date;
  final double? morningWeight;
  final double? eveningWeight;
  final String? note;
  final String createdAt;
  final String updatedAt;

  WeightRecord({
    required this.id,
    required this.userId,
    required this.date,
    this.morningWeight,
    this.eveningWeight,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WeightRecord.fromJson(Map<String, dynamic> json) {
    return WeightRecord(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      date: json['date'] ?? '',
      morningWeight: json['morningWeight']?.toDouble(),
      eveningWeight: json['eveningWeight']?.toDouble(),
      note: json['note'],
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'date': date,
      'morningWeight': morningWeight,
      'eveningWeight': eveningWeight,
      'note': note,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

class WeightStats {
  final double? avgMorningWeight;
  final double? avgEveningWeight;
  final double? minWeight;
  final double? maxWeight;
  final double? change;

  WeightStats({
    this.avgMorningWeight,
    this.avgEveningWeight,
    this.minWeight,
    this.maxWeight,
    this.change,
  });

  factory WeightStats.fromJson(Map<String, dynamic> json) {
    return WeightStats(
      avgMorningWeight: json['avgMorningWeight']?.toDouble(),
      avgEveningWeight: json['avgEveningWeight']?.toDouble(),
      minWeight: json['minWeight']?.toDouble(),
      maxWeight: json['maxWeight']?.toDouble(),
      change: json['change']?.toDouble(),
    );
  }
}