enum WeightPeriod {
  morning,
  evening,
}

class WeightRecord {
  final String id;
  final String userId;
  final String date;
  final WeightPeriod period;
  final double weight;
  final String? note;
  final String createdAt;
  final String updatedAt;
  final double? weightDiff;

  WeightRecord({
    required this.id,
    required this.userId,
    required this.date,
    required this.period,
    required this.weight,
    this.note,
    required this.createdAt,
    required this.updatedAt,
    this.weightDiff,
  });

  factory WeightRecord.fromJson(Map<String, dynamic> json) {
    return WeightRecord(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      date: json['date'] ?? '',
      period: json['period'] == 'evening' ? WeightPeriod.evening : WeightPeriod.morning,
      weight: (json['weight'] as num).toDouble(),
      note: json['note'],
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      weightDiff: json['weightDiff'] != null ? (json['weightDiff'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'date': date,
      'period': period == WeightPeriod.evening ? 'evening' : 'morning',
      'weight': weight,
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
  final double? avgWeightDiff;

  WeightStats({
    this.avgMorningWeight,
    this.avgEveningWeight,
    this.minWeight,
    this.maxWeight,
    this.change,
    this.avgWeightDiff,
  });

  factory WeightStats.fromJson(Map<String, dynamic> json) {
    return WeightStats(
      avgMorningWeight: json['avgMorningWeight']?.toDouble(),
      avgEveningWeight: json['avgEveningWeight']?.toDouble(),
      minWeight: json['minWeight']?.toDouble(),
      maxWeight: json['maxWeight']?.toDouble(),
      change: json['change']?.toDouble(),
      avgWeightDiff: json['avgWeightDiff']?.toDouble(),
    );
  }
}