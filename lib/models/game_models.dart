enum EnergyArea { labs, quarters, greenhouse }

class Candidate {
  final String id;
  final String name;
  final String position;
  final String company; // Yeni Alan
  final Map<String, double> scores;
  final List<String> behavioralFlags;
  final DateTime createdAt;

  Candidate({
    required this.id,
    required this.name,
    required this.position,
    required this.company,
    required this.scores,
    required this.behavioralFlags,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'position': position,
      'company': company,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Candidate.fromMap(Map<String, dynamic> map) {
    return Candidate(
      id: map['id'],
      name: map['name'],
      position: map['position'],
      company: map['company'] ?? "Bilinmiyor",
      scores: {},
      behavioralFlags: [],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}

class Decision {
  final String id;
  final String candidateId;
  final String moduleId;
  final String chapterId;
  final String choiceId;
  final int durationMs;
  final List<String> triggers;
  final DateTime timestamp;

  Decision({
    required this.id,
    required this.candidateId,
    required this.moduleId,
    required this.chapterId,
    required this.choiceId,
    required this.durationMs,
    required this.triggers,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'candidateId': candidateId,
      'moduleId': moduleId,
      'chapterId': chapterId,
      'choiceId': choiceId,
      'durationMs': durationMs,
      // Triggers will be handled as JSON string in DB service
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class ChapterMetric {
  final String id;
  final String candidateId;
  final String chapterId;
  final int totalTimeMs;
  final Map<String, dynamic>? additionalData;
  final DateTime timestamp;

  ChapterMetric({
    required this.id,
    required this.candidateId,
    required this.chapterId,
    required this.totalTimeMs,
    this.additionalData,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'candidateId': candidateId,
      'chapterId': chapterId,
      'totalTimeMs': totalTimeMs,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
