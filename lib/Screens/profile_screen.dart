import 'package:flutter/material.dart';
import '../services/subject_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final int userId;
  final String userName;
  final String userEmail;

  const ProfileScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.userEmail,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SubjectService _service = SubjectService();

  List<Map<String, dynamic>> history = [];
  bool isLoading = true;
  String? errorMessage;

  int totalQuizzes = 0;
  double avgScore = 0;
  int bestScore = 0;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final data = await _service.getQuizHistory(widget.userId);
      _computeStats(data);
      setState(() {
        history = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load quiz history';
        isLoading = false;
      });
    }
  }

  void _computeStats(List<Map<String, dynamic>> data) {
    totalQuizzes = data.length;
    if (data.isEmpty) return;
    double totalPct = 0;
    int best = 0;
    for (final item in data) {
      final pct = (item['percentage'] ?? 0).toDouble();
      totalPct += pct;
      if (pct > best) best = pct.toInt();
    }
    avgScore = totalPct / totalQuizzes;
    bestScore = best;
  }

  Color _getDifficultyColor(String d) {
    switch (d.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Icon(Icons.logout, color: Colors.red),
          SizedBox(width: 10),
          Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
        ]),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
                    (route) => false,
              );
            },
            child: Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Icon(Icons.info_outline, color: Color(0xFF1565C0)),
          SizedBox(width: 10),
          Text('About App'),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Barani Quiz Generator',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 8),
            Text('Version 1.0.0', style: TextStyle(color: Colors.grey)),
            SizedBox(height: 8),
            Text('AI-powered quiz generation for university students.'),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF1565C0),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F6FA),
      body: isLoading
          ? Center(
          child: CircularProgressIndicator(color: Color(0xFF1565C0)))
          : errorMessage != null
          ? _buildErrorWidget()
          : CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: _buildStatsRow()),
          SliverToBoxAdapter(child: _buildSettingsSection()),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Row(children: [
                Icon(Icons.history, color: Color(0xFF1565C0), size: 20),
                SizedBox(width: 8),
                Text('Quiz History',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E))),
                Spacer(),
                Text('${history.length} attempts',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
              ]),
            ),
          ),
          history.isEmpty
              ? SliverToBoxAdapter(child: _buildEmptyWidget())
              : SliverList(
            delegate: SliverChildBuilderDelegate(
                  (ctx, i) => Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: _buildHistoryCard(history[i]),
              ),
              childCount: history.length,
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
              color: Color(0xFF1565C0).withOpacity(0.3),
              blurRadius: 20,
              offset: Offset(0, 10)),
        ],
      ),
      padding: EdgeInsets.fromLTRB(24, 52, 24, 32),
      child: Column(
        children: [
          // ── Back button row ──
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
          ),
          SizedBox(height: 16),

          // ── Avatar ──
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    offset: Offset(0, 8))
              ],
            ),
            child: Center(
              child: Text(
                widget.userName.isNotEmpty
                    ? widget.userName[0].toUpperCase()
                    : 'U',
                style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1565C0)),
              ),
            ),
          ),
          SizedBox(height: 14),
          Text(widget.userName,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text(widget.userEmail,
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          SizedBox(height: 16),

          // ── Student badge ──
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.school, color: Colors.white70, size: 16),
                SizedBox(width: 6),
                Text('Student',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          Expanded(
              child: _statCard(
                  'Total\nQuizzes', '$totalQuizzes', Icons.quiz, Color(0xFF1565C0))),
          SizedBox(width: 12),
          Expanded(
              child: _statCard('Avg\nScore',
                  '${avgScore.toStringAsFixed(0)}%', Icons.trending_up, Colors.orange)),
          SizedBox(width: 12),
          Expanded(
              child: _statCard(
                  'Best\nScore', '$bestScore%', Icons.emoji_events, Colors.green)),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4))
        ],
      ),
      child: Column(children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration:
          BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 20),
        ),
        SizedBox(height: 8),
        Text(value,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E))),
        SizedBox(height: 2),
        Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 11)),
      ]),
    );
  }

  Widget _buildSettingsSection() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 4))
          ],
        ),
        child: Column(
          children: [
            _settingsTile(
              icon: Icons.person_outline,
              color: Color(0xFF1565C0),
              title: 'Account Info',
              subtitle: widget.userEmail,
              onTap: () {},
              showArrow: false,
            ),
            Divider(height: 1, indent: 56),
            _settingsTile(
              icon: Icons.info_outline,
              color: Colors.teal,
              title: 'About App',
              subtitle: 'Version 1.0.0',
              onTap: _showAboutDialog,
            ),
            Divider(height: 1, indent: 56),
            _settingsTile(
              icon: Icons.logout,
              color: Colors.red,
              title: 'Logout',
              subtitle: 'Sign out of your account',
              onTap: _showLogoutDialog,
              showArrow: false,
              titleColor: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool showArrow = true,
    Color? titleColor,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title,
          style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: titleColor ?? Color(0xFF1A1A2E))),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: showArrow
          ? Icon(Icons.chevron_right, color: Colors.grey[400], size: 20)
          : null,
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> item) {
    final topicName = item['topicName'] ?? 'Unknown';
    final difficulty = item['difficulty'] ?? '';
    final quizType = item['quizType'] ?? '';
    final score = item['score'] ?? 0;
    final total = item['total'] ?? 0;
    final percentage = (item['percentage'] ?? 0).toDouble();
    final date = item['date'] ?? '';
    final isPassed = percentage >= 60;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 5))
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(14),
        child: Row(
          children: [
            // Score circle
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: isPassed
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('$score/$total',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isPassed ? Colors.green : Colors.red)),
                Text('${percentage.toStringAsFixed(0)}%',
                    style: TextStyle(
                        fontSize: 11,
                        color: isPassed ? Colors.green : Colors.red)),
              ]),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(topicName,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF1A1A2E))),
                SizedBox(height: 6),
                Row(children: [
                  _pill(difficulty, _getDifficultyColor(difficulty)),
                  SizedBox(width: 6),
                  if (quizType.isNotEmpty) _pill(quizType, Colors.blueGrey),
                ]),
                SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.calendar_today, size: 11, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(date, style: TextStyle(color: Colors.grey, fontSize: 11)),
                ]),
              ]),
            ),
            // Pass/fail icon
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isPassed
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(isPassed ? Icons.check : Icons.close,
                  color: isPassed ? Colors.green : Colors.red, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.error_outline, color: Colors.red, size: 48),
        SizedBox(height: 16),
        Text(errorMessage ?? 'Something went wrong!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600])),
        SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _loadHistory,
          icon: Icon(Icons.refresh),
          label: Text('Retry'),
          style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF1565C0), foregroundColor: Colors.white),
        ),
      ]),
    );
  }

  Widget _buildEmptyWidget() {
    return Padding(
      padding: EdgeInsets.only(top: 40),
      child: Center(
        child: Column(children: [
          Icon(Icons.history, color: Colors.grey[300], size: 64),
          SizedBox(height: 16),
          Text('No quiz history yet',
              style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Complete a quiz to see your results here',
              style: TextStyle(color: Colors.grey, fontSize: 14)),
        ]),
      ),
    );
  }
}