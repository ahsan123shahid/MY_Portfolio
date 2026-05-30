import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/subject_service.dart';
import 'admin_subjects_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final SubjectService _service = SubjectService();

  int _subjects  = 0;
  int _topics    = 0;
  int _questions = 0;
  bool _loading  = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    try {
      final s = await _service.getAdminStats();
      if (mounted) {
        setState(() {
          _subjects  = s['totalSubjects']  ?? 0;
          _topics    = s['totalTopics']    ?? 0;
          _questions = s['totalQuestions'] ?? 0;
          _loading   = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadStats,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildHeader(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _loading
                        ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    )
                        : _buildStatsRow(),
                    const SizedBox(height: 28),
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildActionCard(
                      icon: Icons.menu_book_rounded,
                      title: 'Manage Subjects & PDFs',
                      subtitle: 'Add subjects, upload lecture PDFs, view topics and questions',
                      color: const Color(0xFF1565C0),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AdminSubjectsScreen()),
                        );
                        _loadStats();
                      },
                    ),
                    const SizedBox(height: 32),
                    _buildHowItWorksCard(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft:  Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Admin Panel',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.white70),
                tooltip: 'Logout',
                onPressed: _logout,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Manage subjects, upload PDFs, and generate quizzes',
            style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _StatCard(label: 'Subjects',  value: _subjects,  icon: Icons.book_rounded,        color: const Color(0xFF1565C0)),
        const SizedBox(width: 12),
        _StatCard(label: 'Topics',    value: _topics,    icon: Icons.topic_rounded,        color: const Color(0xFF2E7D32)),
        const SizedBox(width: 12),
        _StatCard(label: 'Questions', value: _questions, icon: Icons.quiz_rounded,         color: const Color(0xFF6A1B9A)),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      shadowColor: color.withOpacity(0.15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHowItWorksCard() {
    final steps = [
      _WorkflowStep(number: '1', title: 'Add a Subject', desc: 'e.g. Statistics, Calculus'),
      _WorkflowStep(number: '2', title: 'Upload PDF',    desc: 'Lecture notes for that subject'),
      _WorkflowStep(number: '3', title: 'AI Processes',  desc: 'Extracts topics & generates 60 questions per topic'),
      _WorkflowStep(number: '4', title: 'Students Practice', desc: 'Quiz questions available for students'),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1565C0).withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Color(0xFF1565C0), size: 20),
              SizedBox(width: 8),
              Text(
                'How It Works',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...steps.map((s) => _buildWorkflowRow(s)),
        ],
      ),
    );
  }

  Widget _buildWorkflowRow(_WorkflowStep s) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(s.number, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(s.desc,  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkflowStep {
  final String number, title, desc;
  const _WorkflowStep({required this.number, required this.title, required this.desc});
}

// ─── Stat Card ───────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              value.toString(),
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
            ),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}