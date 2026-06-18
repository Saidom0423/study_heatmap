import 'package:flutter/material.dart';
import '../../widgets/heatmap_widget.dart';
import '../../widgets/log_hours_sheet.dart';
import '../../services/study_service.dart';
import '../../models/study_log.dart';
import '../stats/stats_screen.dart';
import '../profile/profile_screen.dart';
import '../../core/supabase_client.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final _service = StudyService();

  List<StudyLog> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _loading = true);

    final logs = await _service.fetchLogs();

    setState(() {
      _logs = logs;
      _loading = false;
    });
  }

  void _showLogSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LogHoursSheet(
        onLogged: _loadLogs,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _DashboardTab(
        logs: _logs,
        loading: _loading,
        onRefresh: _loadLogs,
      ),
      StatsScreen(logs: _logs),
      ProfileScreen(
        logs: _logs,
        onRefresh: _loadLogs,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: screens[_currentIndex],

      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
        onPressed: _showLogSheet,
        backgroundColor: const Color(0xFF39D97E),
        foregroundColor: Colors.black,
        elevation: 8,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Log Today',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      )
          : null,

      floatingActionButtonLocation:
      FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          color: const Color(0xFF16213E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white10,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
            backgroundColor: const Color(0xFF16213E),
            elevation: 0,
            selectedItemColor: const Color(0xFF39D97E),
            unselectedItemColor: Colors.white38,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.local_fire_department),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart),
                label: 'Stats',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  final List<StudyLog> logs;
  final bool loading;
  final VoidCallback onRefresh;

  const _DashboardTab({
    required this.logs,
    required this.loading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final service = StudyService();

    final streak = service.calculateStreak(logs);
    final totalHours = logs.fold(0.0, (sum, log) => sum + log.hours);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),

      body: loading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF39D97E),
        ),
      )
          : RefreshIndicator(
        color: const Color(0xFF39D97E),
        onRefresh: () async => onRefresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// HEADER
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF39D97E),
                        Color(0xFF1FAF61),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📚 Study Heatmap',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Track consistency. Build streaks. Stay disciplined.',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                const Text(
                  'Overview',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _statCard(
                        icon: Icons.local_fire_department,
                        title: 'Streak',
                        value: '$streak',
                        subtitle: 'Days',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statCard(
                        icon: Icons.schedule,
                        title: 'Hours',
                        value: totalHours.toStringAsFixed(1),
                        subtitle: 'Total',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                _wideStatCard(
                  icon: Icons.calendar_month,
                  title: 'Study Sessions',
                  value: '${logs.length}',
                  subtitle: 'Days Logged',
                ),

                const SizedBox(height: 30),

                const Text(
                  'Activity Heatmap',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 14),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16213E),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white10,
                    ),
                  ),
                  child: HeatmapWidget(logs: logs),
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.send),
                    label: const Text('send-daily-report'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF39D97E),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: () async {
                      try {
                        final response =
                        await supabase.functions.invoke(
                          'send-daily-report',
                        );

                        debugPrint(response.data.toString());

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                response.data.toString(),
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        debugPrint(e.toString());

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Error: $e',
                              ),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white10,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: const Color(0xFF39D97E),
            size: 28,
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$title • $subtitle',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _wideStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white10,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF39D97E).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF39D97E),
            ),
          ),
          const SizedBox(width: 18),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$title • $subtitle',
                style: const TextStyle(
                  color: Colors.white54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}