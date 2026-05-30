import 'package:flutter/material.dart';
import '../services/subject_service.dart';
import 'quiz_screen.dart';

class QuizSetupScreen extends StatefulWidget {
  final int subjectId;
  final String subjectName;
  final int userId;
  final String userEmail;
  final String userName;
  final String? preselectedTopic;

  const QuizSetupScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
    required this.userId,
    required this.userEmail,
    required this.userName,
    this.preselectedTopic,
  });

  @override
  State<QuizSetupScreen> createState() => _QuizSetupScreenState();
}

class _QuizSetupScreenState extends State<QuizSetupScreen> {
  final SubjectService _service = SubjectService();

  List<Map<String, dynamic>> topics = [];
  String? selectedTopic;
  String? selectedDifficulty;
  String selectedType = 'Numerical';
  int questionCount = 5;
  bool isLoading = false;
  bool isTopicsLoading = true;
  String? errorMessage;

  final List<String> difficulties = ['Easy', 'Medium', 'Hard'];

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  Future<void> _loadTopics() async {
    setState(() {
      isTopicsLoading = true;
      errorMessage = null;
    });

    try {
      final data = await _service.getTopicsBySubject(widget.subjectId);
      setState(() {
        topics = data;
        isTopicsLoading = false;
        if (widget.preselectedTopic != null) {
          selectedTopic = widget.preselectedTopic;
        }
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load topics';
        isTopicsLoading = false;
      });
    }
  }

  Future<void> _generateQuiz() async {
    if (selectedTopic == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a topic'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (selectedDifficulty == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a difficulty'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final result = await _service.generateQuiz({
        'userId': widget.userId,
        'subjectId': widget.subjectId,
        'topicName': selectedTopic,
        'difficulty': selectedDifficulty,
        'quizType': selectedType,
        'questionCount': questionCount,
      });

      setState(() {
        isLoading = false;
      });

      if (result['questions'] != null &&
          (result['questions'] as List).isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuizScreen(
              quizId: result['quizId'],
              questions: List<Map<String, dynamic>>.from(result['questions']),
              userId: widget.userId,
              topicName: selectedTopic!,
              userEmail: widget.userEmail,
              userName: widget.userName,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No questions generated. Try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: isLoading
                ? _buildLoadingWidget()
                : isTopicsLoading
                ? _buildTopicsLoadingWidget()
                : _buildForm(),
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
                      'Quiz Setup',
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
                Icon(Icons.info_outline, color: Colors.white70, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI will generate questions based on your selection',
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

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              color: Color(0xFF1565C0),
              strokeWidth: 4,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'AI is generating questions...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1565C0),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'This may take 30-60 seconds',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicsLoadingWidget() {
    return Center(child: CircularProgressIndicator(color: Color(0xFF1565C0)));
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopicDropdown(),
          SizedBox(height: 20),
          _buildDifficultyDropdown(),
          SizedBox(height: 20),
          _buildTypeToggle(),
          SizedBox(height: 20),
          _buildQuestionCountSelector(),
          SizedBox(height: 32),
          _buildGenerateButton(),
        ],
      ),
    );
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
          });
        },
      ),
    );
  }

  Widget _buildDifficultyDropdown() {
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
        value: selectedDifficulty,
        decoration: InputDecoration(
          labelText: 'Select Difficulty',
          border: InputBorder.none,
          prefixIcon: Icon(Icons.speed, color: Color(0xFF1565C0)),
        ),
        items: difficulties.map((difficulty) {
          IconData icon;
          Color color;
          switch (difficulty) {
            case 'Easy':
              icon = Icons.sentiment_satisfied;
              color = Colors.green;
              break;
            case 'Medium':
              icon = Icons.sentiment_neutral;
              color = Colors.orange;
              break;
            case 'Hard':
              icon = Icons.sentiment_dissatisfied;
              color = Colors.red;
              break;
            default:
              icon = Icons.help;
              color = Colors.grey;
          }
          return DropdownMenuItem<String>(
            value: difficulty,
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                SizedBox(width: 8),
                Text(difficulty),
              ],
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            selectedDifficulty = value;
          });
        },
      ),
    );
  }

  Widget _buildTypeToggle() {
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
                'Question Type',
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
              SizedBox(width: 12),
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCountSelector() {
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
              Icon(Icons.numbers, color: Color(0xFF1565C0)),
              SizedBox(width: 8),
              Text(
                'Number of Questions',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: questionCount > 3
                    ? () => setState(() => questionCount--)
                    : null,
                icon: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.remove,
                    color: questionCount > 3 ? Color(0xFF1565C0) : Colors.grey,
                  ),
                ),
              ),
              SizedBox(width: 24),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    '$questionCount',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 24),
              IconButton(
                onPressed: questionCount < 10
                    ? () => setState(() => questionCount++)
                    : null,
                icon: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.add,
                    color: questionCount < 10 ? Color(0xFF1565C0) : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Center(
            child: Text(
              'Min: 3 | Max: 10',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateButton() {
    return GestureDetector(
      onTap: isLoading ? null : _generateQuiz,
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
            Icon(Icons.bolt, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text(
              'Generate Quiz & Attempt',
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
}
