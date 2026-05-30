import 'package:flutter/material.dart';
import '../services/subject_service.dart';
import 'quiz_setup_screen.dart';

class TopicsScreen extends StatefulWidget {
  final int subjectId;
  final String subjectName;
  final int userId;
  final String userEmail;
  final String userName;

  const TopicsScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
    required this.userId,
    required this.userEmail,
    required this.userName,
  });

  @override
  State<TopicsScreen> createState() => _TopicsScreenState();
}

class _TopicsScreenState extends State<TopicsScreen> {
  final SubjectService _subjectService = SubjectService();

  List<Map<String, dynamic>> topics = [];
  bool isLoading = true;
  String? errorMessage;
  String? selectedTopicName;

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  Future<void> _loadTopics() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await _subjectService.getTopicsBySubject(widget.subjectId);
      setState(() {
        topics = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load topics. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          _buildHeader(),
          if (selectedTopicName != null) _buildSelectedTopicBar(),
          Expanded(
            child: isLoading
                ? Center(
                    child: CircularProgressIndicator(color: Color(0xFF1565C0)),
                  )
                : errorMessage != null
                ? _buildErrorWidget()
                : _buildTopicsList(),
          ),
          if (selectedTopicName != null) _buildBottomBar(),
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
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.subjectName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${topics.length} Topics Available',
                      style: TextStyle(color: Color(0xFF90CAF9), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            'Tap a topic to select it',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedTopicBar() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Color(0xFF1565C0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.white, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Selected: $selectedTopicName',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                selectedTopicName = null;
              });
            },
            child: Icon(Icons.close, color: Colors.white70, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicsList() {
    return RefreshIndicator(
      onRefresh: _loadTopics,
      color: Color(0xFF1565C0),
      child: ListView.builder(
        padding: EdgeInsets.all(20),
        itemCount: topics.length,
        itemBuilder: (context, index) {
          final topic = topics[index];
          return _buildTopicCard(topic);
        },
      ),
    );
  }

  Widget _buildTopicCard(Map<String, dynamic> topic) {
    final topicName = topic['topicName'] ?? 'Unknown Topic';
    final isSelected = selectedTopicName == topicName;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTopicName = topicName;
        });
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: isSelected
              ? Border.all(color: Color(0xFF1565C0), width: 2)
              : null,
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isSelected ? Color(0xFF1565C0) : Color(0xFFE8F4FD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isSelected ? Icons.check : Icons.book_outlined,
              color: isSelected ? Colors.white : Color(0xFF1565C0),
            ),
          ),
          title: Text(
            topicName,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Color(0xFF1A1A2E),
            ),
          ),
          trailing: isSelected
              ? null
              : Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
        ),
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
            onPressed: _loadTopics,
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

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QuizSetupScreen(
                  subjectId: widget.subjectId,
                  subjectName: widget.subjectName,
                  userId: widget.userId,
                  userEmail: widget.userEmail,
                  userName: widget.userName,
                  preselectedTopic: selectedTopicName,
                ),
              ),
            );
          },
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF1565C0).withOpacity(0.3),
                  blurRadius: 15,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_arrow, color: Colors.white, size: 28),
                SizedBox(width: 8),
                Text(
                  'Start Quiz',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
