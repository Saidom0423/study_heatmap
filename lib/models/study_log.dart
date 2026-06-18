class StudyLog {
  final String id;
  final String userId;
  final DateTime loggedDate;
  final double hours;
  final String? notes;

  StudyLog({
    required this.id,
    required this.userId,
    required this.loggedDate,
    required this.hours,
    this.notes,
  });

  factory StudyLog.fromMap(Map<String, dynamic> map) {
    return StudyLog(
      id: map['id'],
      userId: map['user_id'],
      loggedDate: DateTime.parse(map['logged_date']),
      hours: (map['hours'] as num).toDouble(),
      notes: map['notes'],
    );
  }
}