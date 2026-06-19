import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase_client.dart';

class StudyRoomScreen extends StatefulWidget {
  const StudyRoomScreen({super.key});

  @override
  State<StudyRoomScreen> createState() => _StudyRoomScreenState();
}

class _StudyRoomScreenState extends State<StudyRoomScreen> {
  RealtimeChannel? _roomChannel;
  final List<Map<String, dynamic>> _onlineUsers = [];
  bool _isStudying = false;
  String _currentTopic = '';
  final _topicCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _joinRoom();
  }

  Future<void> _joinRoom() async {
    final user = supabase.auth.currentUser!;
    final email = user.email ?? 'Anonymous';

    _roomChannel = supabase.channel(
      'study_room',
      opts: const RealtimeChannelConfig(
        key: 'study_room_presence',
      ),
    );

    _roomChannel!
        .onPresenceSync((payload) {
      _updateOnlineUsers();
    })
        .onPresenceJoin((payload) {
      debugPrint('👋 User joined');
      _updateOnlineUsers();
    })
        .onPresenceLeave((payload) {
      debugPrint('👋 User left');
      _updateOnlineUsers();
    })
        .subscribe((status, [error]) async {
      if (status == RealtimeSubscribeStatus.subscribed) {
        await _roomChannel!.track({
          'user_id': user.id,
          'email': email,
          'is_studying': false,
          'topic': '',
          'joined_at': DateTime.now().toIso8601String(),
        });
      }
    });
  }

  void _updateOnlineUsers() {
    final state = _roomChannel?.presenceState();

    if (state == null) return;

    final users = <Map<String, dynamic>>[];

    for (final presenceState in state) {
      final presences = presenceState.presences;

      for (final presence in presences) {
        users.add(
          Map<String, dynamic>.from(
            presence.payload,
          ),
        );
      }
    }

    setState(() {
      _onlineUsers
        ..clear()
        ..addAll(users);
    });

    debugPrint('ONLINE USERS: $_onlineUsers');
  }
  Future<void> _toggleStudying() async {
    final user = supabase.auth.currentUser!;
    final email = user.email ?? 'Anonymous';

    setState(() {
      _isStudying = !_isStudying;
      if (_isStudying) {
        _currentTopic = _topicCtrl.text.trim();
      } else {
        _currentTopic = '';
        _topicCtrl.clear();
      }
    });

    await _roomChannel?.track({
      'user_id': user.id,
      'email': email,
      'is_studying': _isStudying,
      'topic': _currentTopic,
      'joined_at': DateTime.now().toIso8601String(),
    });
  }

  String _getStudyDuration(String? joinedAt) {
    if (joinedAt == null) return '';
    final joined = DateTime.tryParse(joinedAt);
    if (joined == null) return '';
    final diff = DateTime.now().difference(joined);
    if (diff.inHours > 0) {
      return '${diff.inHours}h ${diff.inMinutes % 60}m';
    }
    return '${diff.inMinutes}m';
  }

  @override
  void dispose() {
    _roomChannel?.unsubscribe();
    _topicCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studyingUsers =
    _onlineUsers.where((u) => u['is_studying'] == true).toList();
    final onlineCount = _onlineUsers.length;
    final studyingCount = studyingUsers.length;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Study Room 👥'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Live stats banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF39D97E), Color(0xFF1FAF61)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$studyingCount',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'people studying right now',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$onlineCount online in room',
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Your status card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF16213E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isStudying
                      ? const Color(0xFF39D97E)
                      : Colors.white10,
                  width: _isStudying ? 2 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Your Status',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _isStudying
                              ? const Color(0xFF39D97E)
                              .withValues(alpha: 0.2)
                              : Colors.white10,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _isStudying ? '📖 Studying' : '💤 Idle',
                          style: TextStyle(
                            fontSize: 12,
                            color: _isStudying
                                ? const Color(0xFF39D97E)
                                : Colors.white38,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!_isStudying) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _topicCtrl,
                      decoration: InputDecoration(
                        hintText: 'What are you studying? (optional)',
                        hintStyle:
                        const TextStyle(color: Colors.white24),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                  if (_isStudying && _currentTopic.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      '📌 $_currentTopic',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _toggleStudying,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isStudying
                            ? Colors.redAccent
                            : const Color(0xFF39D97E),
                        foregroundColor: _isStudying
                            ? Colors.white
                            : Colors.black,
                        padding: const EdgeInsets.symmetric(
                            vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _isStudying
                            ? '⏹ Stop Studying'
                            : '▶ Start Studying',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Who's studying
            Row(
              children: [
                const Text(
                  'Currently Studying',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF39D97E)
                        .withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$studyingCount',
                    style: const TextStyle(
                      color: Color(0xFF39D97E),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            studyingUsers.isEmpty
                ? Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF16213E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text(
                  'No one is studying yet.\nBe the first! 🚀',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white38),
                ),
              ),
            )
                : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: studyingUsers.length,
              separatorBuilder: (_, __) =>
              const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final user = studyingUsers[i];
                final email =
                    user['email'] as String? ?? 'Anonymous';
                final topic = user['topic'] as String? ?? '';
                final joinedAt = user['joined_at'] as String?;
                final duration = _getStudyDuration(joinedAt);

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16213E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF39D97E)
                          .withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor:
                        const Color(0xFF39D97E),
                        child: Text(
                          email[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              email.split('@')[0],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (topic.isNotEmpty)
                              Text(
                                '📌 $topic',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white54,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.end,
                        children: [
                          const Text('🟢',
                              style:
                              TextStyle(fontSize: 10)),
                          if (duration.isNotEmpty)
                            Text(
                              duration,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white38,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Everyone online
            Row(
              children: [
                const Text(
                  'Everyone Online',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$onlineCount',
                    style: const TextStyle(color: Colors.white54),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _onlineUsers.map((u) {
                final email = u['email'] as String? ?? '?';
                final isStudying = u['is_studying'] == true;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isStudying
                        ? const Color(0xFF39D97E)
                        .withValues(alpha: 0.15)
                        : Colors.white10,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isStudying
                          ? const Color(0xFF39D97E)
                          .withValues(alpha: 0.4)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isStudying ? '📖' : '💤',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        email.split('@')[0],
                        style: TextStyle(
                          fontSize: 13,
                          color: isStudying
                              ? const Color(0xFF39D97E)
                              : Colors.white54,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}