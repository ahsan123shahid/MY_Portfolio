import 'package:flutter/material.dart';
import '../services/subject_service.dart';

class NoteDetailScreen extends StatefulWidget {
  final int subjectId;
  final String topicName;

  const NoteDetailScreen({
    super.key,
    required this.subjectId,
    required this.topicName,
  });

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  final SubjectService _service = SubjectService();

  List<Map<String, dynamic>> notes = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await _service.getNotes(widget.subjectId, widget.topicName);
      setState(() {
        notes = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load notes';
        isLoading = false;
      });
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
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

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'conceptual':
        return Colors.blue;
      case 'numerical':
        return Colors.purple;
      default:
        return Colors.grey;
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
                : notes.isEmpty
                ? _buildEmptyWidget()
                : _buildNotesList(),
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
                      widget.topicName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${notes.length} note chunks',
                      style: TextStyle(color: Color(0xFF90CAF9), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.book, color: Colors.white70, size: 16),
                SizedBox(width: 6),
                Text(
                  'Lecture Notes',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesList() {
    return RefreshIndicator(
      onRefresh: _loadNotes,
      color: Color(0xFF1565C0),
      child: ListView.builder(
        padding: EdgeInsets.all(20),
        itemCount: notes.length,
        itemBuilder: (context, index) {
          final note = notes[index];
          return _buildNoteCard(note, index);
        },
      ),
    );
  }

  Widget _buildNoteCard(Map<String, dynamic> note, int index) {
    final difficulty = note['difficulty'] ?? '';
    final type = note['type'] ?? '';
    final content = note['content'] ?? '';
    final week = note['week'] ?? 0;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
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
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFFF5F5F5),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getDifficultyColor(difficulty).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getDifficultyColor(difficulty).withOpacity(0.5),
                    ),
                  ),
                  child: Text(
                    difficulty,
                    style: TextStyle(
                      color: _getDifficultyColor(difficulty),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getTypeColor(type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getTypeColor(type).withOpacity(0.5),
                    ),
                  ),
                  child: Text(
                    type,
                    style: TextStyle(
                      color: _getTypeColor(type),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (week > 0) ...[
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Week $week',
                      style: TextStyle(color: Colors.grey[700], fontSize: 12),
                    ),
                  ),
                ],
                Spacer(),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Color(0xFF1565C0).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: Color(0xFF1565C0),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              content,
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ),
        ],
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
            onPressed: _loadNotes,
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

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notes, color: Colors.grey, size: 64),
          SizedBox(height: 16),
          Text(
            'No notes found for this topic',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }
}
