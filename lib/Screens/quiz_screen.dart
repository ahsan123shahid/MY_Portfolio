import 'package:flutter/material.dart';
import '../services/subject_service.dart';
import 'result_screen.dart';

class QuizScreen extends StatefulWidget {
  final int quizId;
  final List<Map<String, dynamic>> questions;
  final int userId;
  final String topicName;
  final String userEmail;
  final String userName;

  const QuizScreen({
    super.key,
    required this.quizId,
    required this.questions,
    required this.userId,
    required this.topicName,
    required this.userEmail,
    required this.userName,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final SubjectService _service = SubjectService();
  int currentIndex = 0;
  String? selectedOption;
  Map<int, String> answers = {};
  bool isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          _buildHeader(),
          _buildProgressBar(),
          Expanded(
            child: isSubmitting
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1565C0)))
                : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildQuestionCard(),
                  const SizedBox(height: 20),
                  _buildOptions(),
                  const SizedBox(height: 24),
                  _buildNavButton(),
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
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [BoxShadow(color: const Color(0xFF1565C0).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      padding: const EdgeInsets.fromLTRB(24, 52, 24, 24),
      child: Row(
        children: [
          GestureDetector(
            onTap: _confirmExit,
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.close, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.topicName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const Text('Quiz Mode', style: TextStyle(color: Color(0xFF90CAF9), fontSize: 12)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
            child: Text('${currentIndex + 1} / ${widget.questions.length}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Question ${currentIndex + 1} of ${widget.questions.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFE8F4FD), borderRadius: BorderRadius.circular(12)),
                child: Text('${answers.length}/${widget.questions.length} answered',
                    style: const TextStyle(color: Color(0xFF1565C0), fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (currentIndex + 1) / widget.questions.length,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1565C0)),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard() {
    final question = widget.questions[currentIndex];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1565C0).withOpacity(0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _tag('Q${currentIndex + 1}', bg: const Color(0xFF1565C0), fg: Colors.white),
            const SizedBox(width: 8),
            _tag(widget.topicName, bg: Colors.white, fg: const Color(0xFF1565C0)),
          ]),
          const SizedBox(height: 16),
          Text(
            question['questionText'] ?? '',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
              fontFamily: 'monospace',
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptions() {
    final question = widget.questions[currentIndex];
    final options = [
      {'key': 'A', 'value': question['optionA'] ?? ''},
      {'key': 'B', 'value': question['optionB'] ?? ''},
      {'key': 'C', 'value': question['optionC'] ?? ''},
      {'key': 'D', 'value': question['optionD'] ?? ''},
    ];

    return Column(
      children: options.map((opt) {
        final isSelected = selectedOption == opt['key'];
        return GestureDetector(
          onTap: () => setState(() => selectedOption = opt['key']),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF1565C0) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? const Color(0xFF1565C0) : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [BoxShadow(
                color: isSelected ? const Color(0xFF1565C0).withOpacity(0.25) : Colors.black.withOpacity(0.04),
                blurRadius: 10, offset: const Offset(0, 4),
              )],
            ),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white.withOpacity(0.25) : const Color(0xFFE8F4FD),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(child: Text(opt['key']!, style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF1565C0),
                    fontWeight: FontWeight.bold, fontSize: 16,
                  ))),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(
                  opt['value']!,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF1A1A2E),
                    fontSize: 15,
                    fontFamily: 'monospace',
                    height: 1.4,
                  ),
                )),
                if (isSelected) const Icon(Icons.check_circle, color: Colors.white, size: 22),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNavButton() {
    final isLast = currentIndex == widget.questions.length - 1;
    return GestureDetector(
      onTap: _submitAnswer,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF0D47A1)]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: const Color(0xFF1565C0).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isLast ? Icons.check_circle_outline : Icons.arrow_forward, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            Text(isLast ? 'Submit Quiz' : 'Next Question',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _submitAnswer() {
    if (selectedOption == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an option'), backgroundColor: Colors.orange));
      return;
    }
    answers[widget.questions[currentIndex]['questionId']] = selectedOption!;
    if (currentIndex < widget.questions.length - 1) {
      setState(() { currentIndex++; selectedOption = null; });
    } else {
      _submitQuiz();
    }
  }

  Future<void> _submitQuiz() async {
    setState(() => isSubmitting = true);
    try {
      final result = await _service.submitQuiz({
        'userId': widget.userId,
        'quizId': widget.quizId,
        'answers': answers.entries.map((e) => {'questionId': e.key, 'selectedOption': e.value}).toList(),
      });
      setState(() => isSubmitting = false);
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => ResultScreen(
          resultData: result, userId: widget.userId,
          topicName: widget.topicName, userEmail: widget.userEmail, userName: widget.userName,
        ),
      ));
    } catch (e) {
      setState(() => isSubmitting = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red));
    }
  }

  void _confirmExit() {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Exit Quiz?'),
      content: const Text('Your progress will be lost.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(
          onPressed: () { Navigator.pop(context); Navigator.pop(context); },
          child: const Text('Exit', style: TextStyle(color: Colors.red)),
        ),
      ],
    ));
  }

  Widget _tag(String label, {required Color bg, required Color fg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}