import 'package:intl/intl.dart';

import '../core/supabase_client.dart';
import '../models/study_log.dart';

class StudyService {
  final _dateFormat = DateFormat('yyyy-MM-dd');

  Future<List<StudyLog>> fetchLogs({int days = 365}) async {
    final userId = supabase.auth.currentUser!.id;
    final from = DateTime.now().subtract(Duration(days: days));

    final res = await supabase
        .from('study_logs')
        .select()
        .eq('user_id', userId)
        .gte('logged_date', _dateFormat.format(from))
        .order('logged_date');

    return (res as List).map((e) => StudyLog.fromMap(e)).toList();
  }

  Future<Map<String, dynamic>> fetchProfile() async {
    final userId = supabase.auth.currentUser!.id;
    final res = await supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    return res;
  }

  Future<List<Map<String, dynamic>>> fetchBadges() async {
    final userId = supabase.auth.currentUser!.id;
    final res = await supabase
        .from('badges')
        .select()
        .eq('user_id', userId)
        .order('earned_at');
    return (res as List).cast<Map<String, dynamic>>();
  }

  Future<void> updateDailyGoal(double hours) async {
    final userId = supabase.auth.currentUser!.id;
    await supabase
        .from('profiles')
        .update({'daily_goal_hours': hours}).eq('id', userId);
  }

  Future<void> logHours(double hours, {String? notes}) async {
    final userId = supabase.auth.currentUser!.id;
    final today = _dateFormat.format(DateTime.now());

    await supabase.from('study_logs').upsert({
      'user_id': userId,
      'logged_date': today,
      'hours': hours,
      'notes': notes,
    }, onConflict: 'user_id,logged_date');
  }

  int calculateStreak(List<StudyLog> logs) {
    if (logs.isEmpty) return 0;
    final loggedDates = logs
        .map((l) => DateTime(
        l.loggedDate.year, l.loggedDate.month, l.loggedDate.day))
        .toSet();

    int streak = 0;
    DateTime check = DateTime.now();
    final today = DateTime(check.year, check.month, check.day);
    if (!loggedDates.contains(today)) {
      check = check.subtract(const Duration(days: 1));
    }
    while (true) {
      final d = DateTime(check.year, check.month, check.day);
      if (loggedDates.contains(d)) {
        streak++;
        check = check.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  Map<String, double> weeklyHours(List<StudyLog> logs) {
    final result = <String, double>{};
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final key = DateFormat('EEE').format(day);
      result[key] = 0;
    }
    for (final log in logs) {
      final diff = now.difference(log.loggedDate).inDays;
      if (diff <= 6) {
        final key = DateFormat('EEE').format(log.loggedDate);
        result[key] = (result[key] ?? 0) + log.hours;
      }
    }
    return result;
  }
}