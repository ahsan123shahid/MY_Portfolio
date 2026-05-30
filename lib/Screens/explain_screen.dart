import 'package:flutter/material.dart';
import '../services/subject_service.dart';
import '../utils/text_cleaner.dart';

class ExplainScreen extends StatefulWidget {
  final int userId;
  final List<Map<String, dynamic>> subjects;

  const ExplainScreen({
    super.key,
    required this.userId,
    required this.subjects,
  });

  @override
  State<ExplainScreen> createState() => _ExplainScreenState();
}

class _ExplainScreenState extends State<ExplainScreen> {
  final SubjectService _service = SubjectService();

  int? selectedSubjectId;
  String? selectedTopic;
  String selectedType = 'Conceptual';
  bool isLoading = false;
  String? explanation;
  List<Map<String, dynamic>> topics = [];
  bool isTopicsLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSubjectDropdown(),
                  SizedBox(height: 20),
                  if (topics.isNotEmpty) _buildTopicDropdown(),
                  if (isTopicsLoading)
                    Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF1565C0),
                        ),
                      ),
                    ),
                  SizedBox(height: 20),
                  _buildTypeSelector(),
                  SizedBox(height: 24),
                  _buildExplainButton(),
                  if (explanation != null) ...[
                    SizedBox(height: 24),
                    _buildExplanationCard(),
                  ],
                ],
              ),
            ),
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
          Text(
            'AI Tutor',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.white70, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Get AI-powered explanations for any topic',
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

  Widget _buildSubjectDropdown() {
    return Container(
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
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButtonFormField<int>(
        value: selectedSubjectId,
        decoration: InputDecoration(
          labelText: 'Select Subject',
          border: InputBorder.none,
          prefixIcon: Icon(Icons.school, color: Color(0xFF1565C0)),
        ),
        items: widget.subjects.map((subject) {
          return DropdownMenuItem<int>(
            value: subject['subjectId'] as int,
            child: Text(
              subject['name']?.toString() ?? 'Unknown',
              style: TextStyle(fontSize: 14),
            ),
          );
        }).toList(),
        onChanged: (value) async {
          setState(() {
            selectedSubjectId = value;
            selectedTopic = null;
            topics = [];
            explanation = null;
          });
          if (value != null) {
            await _loadTopics(value);
          }
        },
      ),
    );
  }

  Future<void> _loadTopics(int subjectId) async {
    setState(() {
      isTopicsLoading = true;
    });

    try {
      final data = await _service.getTopicsBySubject(subjectId);
      setState(() {
        topics = data;
        isTopicsLoading = false;
      });
    } catch (e) {
      setState(() {
        isTopicsLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load topics'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildTopicDropdown() {
    return Container(
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
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButtonFormField<String>(
        value: selectedTopic,
        decoration: InputDecoration(
          labelText: 'Select Topic',
          border: InputBorder.none,
          prefixIcon: Icon(Icons.book_outlined, color: Color(0xFF1565C0)),
        ),
        items: topics.map((topic) {
          return DropdownMenuItem<String>(
            value: topic['topicName']?.toString(),
            child: Text(
              topic['topicName']?.toString() ?? 'Unknown',
              style: TextStyle(fontSize: 14),
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            selectedTopic = value;
            explanation = null;
          });
        },
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
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
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.category, color: Color(0xFF1565C0)),
              SizedBox(width: 8),
              Text(
                'Explanation Type',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => selectedType = 'Conceptual'),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selectedType == 'Conceptual'
                          ? Color(0xFF1565C0)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selectedType == 'Conceptual'
                            ? Color(0xFF1565C0)
                            : Colors.grey[300]!,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Conceptual',
                        style: TextStyle(
                          color: selectedType == 'Conceptual'
                              ? Colors.white
                              : Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => selectedType = 'Numerical'),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selectedType == 'Numerical'
                          ? Color(0xFF1565C0)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selectedType == 'Numerical'
                            ? Color(0xFF1565C0)
                            : Colors.grey[300]!,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Numerical',
                        style: TextStyle(
                          color: selectedType == 'Numerical'
                              ? Colors.white
                              : Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExplainButton() {
    return GestureDetector(
      onTap: isLoading ? null : _getExplanation,
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
        child: isLoading
            ? Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'AI is explaining...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome, color: Colors.white, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Get Explanation',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildExplanationCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFFE8F4FD),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.lightbulb,
                  color: Color(0xFF1565C0),
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedTopic ?? '',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    Text(
                      selectedType,
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Divider(),
          SizedBox(height: 16),
          Text(
            explanation!,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Color(0xFF1A1A2E),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _getExplanation() async {
    if (selectedSubjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a subject'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (selectedTopic == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a topic'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final result = await _service.getExplanation({
        'userId': widget.userId,
        'subjectId': selectedSubjectId,
        'topicName': selectedTopic,
        'type': selectedType,
      });

      setState(() {
        explanation = TextCleaner.clean(result['explanation'] ?? '');
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
