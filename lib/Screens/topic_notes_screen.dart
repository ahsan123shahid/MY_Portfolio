import 'package:flutter/material.dart';
import '../services/subject_service.dart';
import 'note_detail_screen.dart';

class TopicNotesScreen extends StatefulWidget {
  final int subjectId;
  final String subjectName;

  const TopicNotesScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
  });

  @override
  State<TopicNotesScreen> createState() => _TopicNotesScreenState();
}

class _TopicNotesScreenState extends State<TopicNotesScreen> {
  final SubjectService _service = SubjectService();

  List<Map<String, dynamic>> topics = [];
  bool isLoading = true;
  String? errorMessage;

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
      final data = await _service.getTopicsBySubject(widget.subjectId);
      setState(() {
        topics = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load topics';
        isLoading = false;
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
          Expanded(
            child: isLoading
                ? Center(
                    child: CircularProgressIndicator(color: Color(0xFF1565C0)),
                  )
                : errorMessage != null
                ? _buildErrorWidget()
                : _buildTopicsList(),
          ),
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
                      'Study Notes',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.subjectName,
                      style: TextStyle(color: Color(0xFF90CAF9), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.book_outlined, color: Colors.white70, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Select a topic to view lecture notes',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
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
          child: Icon(Icons.description_outlined, color: Color(0xFF1565C0)),
        ),
        title: Text(
          topicName,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: Color(0xFF1A1A2E),
          ),
        ),
        trailing: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Color(0xFFE8F4FD),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.arrow_forward_ios,
            color: Color(0xFF1565C0),
            size: 14,
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NoteDetailScreen(
                subjectId: widget.subjectId,
                topicName: topicName,
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
}
