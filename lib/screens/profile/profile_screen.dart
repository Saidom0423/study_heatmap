import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../../core/supabase_client.dart';
import '../../models/study_log.dart';
import '../../services/study_service.dart';
import '../auth/login_screen.dart';


class ProfileScreen extends StatefulWidget {
  final List<StudyLog> logs;
  final VoidCallback onRefresh;

  const ProfileScreen({
    super.key,
    required this.logs,
    required this.onRefresh,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _service = StudyService();
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _badges = [];
  bool _loading = true;
  bool _uploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final profile = await _service.fetchProfile();
      final badges = await _service.fetchBadges();
      setState(() {
        _profile = profile;
        _badges = badges;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 256,
      maxHeight: 256,
      imageQuality: 70,
    );
    if (picked == null) return;

    setState(() => _uploadingAvatar = true);
    try {
      final bytes = await picked.readAsBytes();
      final base64String = base64Encode(bytes);
      final userId = supabase.auth.currentUser!.id;

      await supabase
          .from('profiles')
          .update({'avatar_base64': base64String})
          .eq('id', userId);

      await _loadProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated! ✅')),
        );
      }
    } catch (e) {
      debugPrint('Upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _logout() async {
    await supabase.auth.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (_) => false,
      );
    }
  }

  void _showGoalDialog() {
    double goal = (_profile?['daily_goal_hours'] ?? 2.0).toDouble();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Set Daily Goal'),
        content: StatefulBuilder(
          builder: (ctx, setInner) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${goal.toStringAsFixed(1)} hours',
                style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF39D97E)),
              ),
              Slider(
                value: goal,
                min: 0.5,
                max: 12,
                divisions: 23,
                activeColor: const Color(0xFF39D97E),
                onChanged: (v) => setInner(() => goal = v),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              _service.updateDailyGoal(goal).then((_) {
                _loadProfile();
              });
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = supabase.auth.currentUser?.email ?? 'User';
    final avatarBase64 = _profile?['avatar_base64'] as String?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile 👤'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 12),

              // Avatar with edit button
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF39D97E),
                        width: 3,
                      ),
                    ),
                    child: ClipOval(
                      child: _uploadingAvatar
                          ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF39D97E),
                        ),
                      )
                          : avatarBase64 != null &&
                          avatarBase64.isNotEmpty
                          ? Image.memory(
                        base64Decode(avatarBase64),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _defaultAvatar(email),
                      )
                          : _defaultAvatar(email),
                    ),
                  ),
                  GestureDetector(
                    onTap: _uploadingAvatar
                        ? null
                        : _pickAndUploadAvatar,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFF39D97E),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.black,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Text(email,
                  style: const TextStyle(
                      fontSize: 16, color: Colors.white70)),
              const SizedBox(height: 8),

              // Daily goal chip
              GestureDetector(
                onTap: _showGoalDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16213E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFF39D97E)),
                  ),
                  child: Text(
                    '🎯 Daily Goal: ${(_profile?['daily_goal_hours'] ?? 2.0).toStringAsFixed(1)}h  ✏️',
                    style: const TextStyle(
                        color: Color(0xFF39D97E)),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Stats grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _statCard('🔥 Current Streak',
                      '${_profile?['current_streak'] ?? 0} days'),
                  _statCard('🏆 Longest Streak',
                      '${_profile?['longest_streak'] ?? 0} days'),
                  _statCard('⏱ Total Hours',
                      '${(_profile?['total_hours'] ?? 0.0).toStringAsFixed(1)}h'),
                  _statCard('📅 Days Studied',
                      '${_profile?['total_days'] ?? 0}'),
                ],
              ),
              const SizedBox(height: 28),

              // Badges
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Badges (${_badges.length})',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              _badges.isEmpty
                  ? Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF16213E),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text(
                    'Log your first study session\nto earn badges! 🌱',
                    textAlign: TextAlign.center,
                    style:
                    TextStyle(color: Colors.white38),
                  ),
                ),
              )
                  : GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics:
                const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: _badges
                    .map((b) => _badgeCard(
                    b['badge_emoji'], b['badge_name']))
                    .toList(),
              ),
              const SizedBox(height: 32),

              // Logout
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout,
                      color: Colors.redAccent),
                  label: const Text('Log Out',
                      style:
                      TextStyle(color: Colors.redAccent)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16),
                    side: const BorderSide(
                        color: Colors.redAccent),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _defaultAvatar(String email) {
    return Container(
      color: const Color(0xFF39D97E),
      child: Center(
        child: Text(
          email[0].toUpperCase(),
          style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.black),
        ),
      ),
    );
  }

  Widget _statCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF39D97E))),
          const SizedBox(height: 6),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 11, color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _badgeCard(String emoji, String name) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFF39D97E).withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 6),
          Text(name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 10, color: Colors.white70)),
        ],
      ),
    );
  }
}