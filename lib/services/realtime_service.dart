import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';

class RealtimeService {
  RealtimeChannel? _logsChannel;
  RealtimeChannel? _badgesChannel;

  void subscribeToStudyLogs({
    required String userId,
    required VoidCallback onchange,
  }) {
    _logsChannel = supabase
        .channel('study_logs_$userId')
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'study_logs',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: userId,
      ),
      callback: (payload) {
        debugPrint(' study_logs changed: ${payload.eventType}');
        onchange();
      },
    )
        .subscribe();
  }

  void subscribeToBadges({
    required String userId,
    required Function(Map<String, dynamic>) onNewBadge,
  }) {
    _badgesChannel = supabase
        .channel('badges_$userId')
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'badges',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: userId,
      ),
      callback: (payload) {
        debugPrint(' new badge: ${payload.newRecord}');
        onNewBadge(payload.newRecord);
      },
    )
        .subscribe();
  }

  void dispose() {
    _logsChannel?.unsubscribe();
    _badgesChannel?.unsubscribe();
  }
}