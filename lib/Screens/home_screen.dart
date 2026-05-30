import 'package:flutter/material.dart';
import '../services/subject_service.dart';
import 'topics_screen.dart';
import 'quiz_setup_screen.dart';
import 'explain_screen.dart';
import 'topic_notes_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userEmail;
  final int userId;
  final String userName;

  const HomeScreen({
    super.key,
    required this.userEmail,
    required this.userId,
    required this.userName,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;
  final SubjectService _subjectService = SubjectService();

  List<Map<String, dynamic>> subjects = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await _subjectService.getSubjects();
      setState(() {
        subjects = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load subjects. Please try again.';
      });
    }
  }

  String _getSubjectIcon(String name) {
    if (name.toLowerCase().contains('calculus')) {
      return '∫';
    } else if (name.toLowerCase().contains('linear')) {
      return 'M';
    }
    return 'A';
  }

  String _getSubjectSubtitle(String name) {
    if (name.toLowerCase().contains('calculus-i')) {
      return 'Limits, Derivatives, Integrals';
    } else if (name.toLowerCase().contains('calculus-ii')) {
      return 'Multivariable Calculus, Integration';
    } else if (name.toLowerCase().contains('linear')) {
      return 'Vectors, Matrices, Spaces';
    }
    return 'Math Subject';
  }

  void _onNavTap(int index) {
    if (index == 0 || index == 1 || index == 2 || index == 3) {
      setState(() => currentIndex = index);
    } else if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileScreen(
            userId: widget.userId,
            userName: widget.userName,
            userEmail: widget.userEmail,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          if (currentIndex == 0) _buildHeader(),
          if (currentIndex == 0) _buildSubjectHeading(),
          Expanded(
            child: isLoading && currentIndex == 0
                ? Center(
                    child: CircularProgressIndicator(color: Color(0xFF1565C0)),
                  )
                : errorMessage != null && currentIndex == 0
                ? _buildErrorWidget()
                : _buildTabContent(),
          ),
          _buildBottomNav(),
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
            offset: Offset(0, 10),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(24, 52, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Barani ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Quiz',
                        style: TextStyle(
                          color: Color(0xFF90CAF9),
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'GENERATOR',
                    style: TextStyle(
                      color: Color(0xFF90CAF9),
                      fontSize: 11,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      widget.userEmail.split('@').first,
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            'Hello, ${widget.userEmail.split('@').first}!',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Choose a subject to start learning',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectHeading() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          Text(
            'Choose a ',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          Text(
            'Subject',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1565C0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectList() {
    return RefreshIndicator(
      onRefresh: _loadSubjects,
      color: Color(0xFF1565C0),
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 20),
        itemCount: subjects.length,
        itemBuilder: (context, index) {
          final subject = subjects[index];
          return _buildSubjectCard(subject);
        },
      ),
    );
  }

  Widget _buildSubjectCard(Map<String, dynamic> subject) {
    final name = subject['name'] ?? 'Unknown';
    final icon = _getSubjectIcon(name);
    final subtitle = _getSubjectSubtitle(name);

    return Container(
      margin: EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              icon,
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(
          name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF1A1A2E),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        trailing: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Color(0xFFE8F4FD),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.arrow_forward_ios,
            color: Color(0xFF1565C0),
            size: 16,
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TopicsScreen(
                subjectId: subject['subjectId'],
                subjectName: name,
                userId: widget.userId,
                userEmail: widget.userEmail,
                userName: widget.userName,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 48),
          SizedBox(height: 16),
          Text(
            errorMessage ?? 'Something went wrong!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadSubjects,
            icon: Icon(Icons.refresh),
            label: Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF1565C0),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex,
        selectedItemColor: Color(0xFF1565C0),
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        elevation: 0,
        onTap: _onNavTap,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit_note_outlined),
            activeIcon: Icon(Icons.edit_note),
            label: 'Quiz',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb_outline),
            activeIcon: Icon(Icons.lightbulb),
            label: 'Explain',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_outlined),
            activeIcon: Icon(Icons.book),
            label: 'Notes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    switch (currentIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return _buildQuizTab();
      case 2:
        return _buildExplainTab();
      case 3:
        return _buildNotesTab();
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildQuizTab() {
    if (subjects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF1565C0)),
            SizedBox(height: 16),
            Text('Loading subjects...'),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.bolt, color: Colors.white, size: 28),
                    SizedBox(width: 8),
                    Text(
                      'AI Quiz Generator',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  'Select a subject to generate personalized quizzes powered by AI',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Choose a Subject',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          SizedBox(height: 12),
          ...subjects.map((subject) => _buildSubjectQuizCard(subject)),
        ],
      ),
    );
  }

  Widget _buildSubjectQuizCard(Map<String, dynamic> subject) {
    final name = subject['name'] ?? 'Unknown';
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Color(0xFFE8F4FD),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              _getSubjectIcon(name),
              style: TextStyle(
                color: Color(0xFF1565C0),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Color(0xFF1565C0),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QuizSetupScreen(
                subjectId: subject['subjectId'],
                subjectName: name,
                userId: widget.userId,
                userEmail: widget.userEmail,
                userName: widget.userName,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildExplainTab() {
    if (subjects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF1565C0)),
            SizedBox(height: 16),
            Text('Loading...'),
          ],
        ),
      );
    }

    return ExplainScreen(userId: widget.userId, subjects: subjects);
  }

  Widget _buildNotesTab() {
    if (subjects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF1565C0)),
            SizedBox(height: 16),
            Text('Loading...'),
          ],
        ),
      );
    }

    return _buildNotesSubjectList();
  }

  Widget _buildNotesSubjectList() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Study Notes',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Select a subject to view lecture notes',
            style: TextStyle(color: Colors.grey),
          ),
          SizedBox(height: 20),
          ...subjects.map((subject) => _buildSubjectNoteCard(subject)),
        ],
      ),
    );
  }

  Widget _buildSubjectNoteCard(Map<String, dynamic> subject) {
    final name = subject['name'] ?? 'Unknown';
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Color(0xFFE8F4FD),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.book_outlined, color: Color(0xFF1565C0)),
        ),
        title: Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Tap to view topics'),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Color(0xFF1565C0),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TopicNotesScreen(
                subjectId: subject['subjectId'],
                subjectName: name,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHomeContent() {
    return RefreshIndicator(
      onRefresh: _loadSubjects,
      color: Color(0xFF1565C0),
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 20),
        itemCount: subjects.length,
        itemBuilder: (context, index) {
          final subject = subjects[index];
          return _buildSubjectCard(subject);
        },
      ),
    );
  }
}
