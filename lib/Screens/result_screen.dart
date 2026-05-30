import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'quiz_setup_screen.dart';

class ResultScreen extends StatelessWidget {
  final Map<String, dynamic> resultData;
  final int userId;
  final String topicName;
  final String userEmail;
  final String userName;
  final int subjectId;
  final String subjectName;

  const ResultScreen({
    super.key,
    required this.resultData,
    required this.userId,
    required this.topicName,
    required this.userEmail,
    required this.userName,
    this.subjectId  = 0,
    this.subjectName = '',
  });

  @override
  Widget build(BuildContext context) {
    final score      = resultData['score']      ?? 0;
    final total      = resultData['total']      ?? 0;
    final percentage = (resultData['percentage'] ?? 0).toDouble();
    final results    = resultData['results']    as List? ?? [];
    final isPassed   = percentage >= 60;

    return Scaffold(
      backgroundColor: Color(0xFFF5F6FA),
      body: Column(
        children: [
          _buildHeader(score, total, percentage, isPassed),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(children: [
                _buildSummaryCards(score, total, percentage),
                SizedBox(height: 20),
                _buildActionButtons(context, isPassed),
                SizedBox(height: 24),
                _buildResultsList(results),
                SizedBox(height: 20),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(int score, int total, double percentage, bool isPassed) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: isPassed
              ? [Color(0xFF2E7D32), Color(0xFF1B5E20)]
              : [Color(0xFFC62828), Color(0xFF7F0000)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
        boxShadow: [
          BoxShadow(
            color: (isPassed ? Colors.green : Colors.red).withOpacity(0.3),
            blurRadius: 20, offset: Offset(0, 10),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(24, 56, 24, 36),
      child: Column(children: [
        // Result icon
        Container(
          padding: EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Text(
            isPassed ? '🎉' : '📚',
            style: TextStyle(fontSize: 32),
          ),
        ),
        SizedBox(height: 12),
        Text(
          isPassed ? 'Well Done!' : 'Keep Practicing!',
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 4),
        Text(
          topicName,
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 24),
        // Score circle
        Container(
          width: 130, height: 130,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: Offset(0, 8))],
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('$score/$total',
                style: TextStyle(
                  fontSize: 34, fontWeight: FontWeight.bold,
                  color: isPassed ? Color(0xFF2E7D32) : Color(0xFFC62828),
                )),
            Text('${percentage.toStringAsFixed(0)}%',
                style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w500)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildSummaryCards(int score, int total, double percentage) {
    return Row(children: [
      Expanded(child: _statCard('Correct', '$score', Icons.check_circle_outline, Colors.green, Colors.green[50]!)),
      SizedBox(width: 12),
      Expanded(child: _statCard('Wrong', '${total - score}', Icons.cancel_outlined, Colors.red, Colors.red[50]!)),
      SizedBox(width: 12),
      Expanded(child: _statCard('Score', '${percentage.toStringAsFixed(0)}%',
          Icons.percent, Colors.blue, Colors.blue[50]!)),
    ]);
  }

  Widget _statCard(String label, String value, IconData icon, Color color, Color bg) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 24),
        SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(color: color.withOpacity(0.8), fontSize: 12)),
      ]),
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isPassed) {
    return Row(children: [
      // Home button
      Expanded(
        child: GestureDetector(
          onTap: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => HomeScreen(
                userEmail: userEmail, userId: userId, userName: userName)),
                (r) => false,
          ),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Color(0xFF1565C0).withOpacity(0.3)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: Offset(0, 4))],
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.home_outlined, color: Color(0xFF1565C0), size: 20),
              SizedBox(width: 8),
              Text('Home', style: TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.bold)),
            ]),
          ),
        ),
      ),
      SizedBox(width: 12),
      // Try again button
      Expanded(
        child: GestureDetector(
          onTap: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => QuizSetupScreen(
              subjectId:   subjectId,
              subjectName: subjectName,
              userId:      userId,
              userEmail:   userEmail,
              userName:    userName,
              preselectedTopic: topicName,
            )),
          ),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF0D47A1)]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Color(0xFF1565C0).withOpacity(0.3), blurRadius: 12, offset: Offset(0, 6))],
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.refresh, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Try Again', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ]),
          ),
        ),
      ),
    ]);
  }

  Widget _buildResultsList(List results) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Icons.list_alt, color: Color(0xFF1565C0), size: 20),
          SizedBox(width: 8),
          Text('Review Answers',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
        ]),
        SizedBox(height: 16),
        ...results.asMap().entries.map((e) => _buildResultCard(e.key + 1, e.value as Map<String, dynamic>)),
      ],
    );
  }

  Widget _buildResultCard(int number, Map<String, dynamic> result) {
    final isCorrect = result['isCorrect']      ?? false;
    final selected  = result['selectedOption'] ?? '';
    final correct   = result['correctOption']  ?? '';
    final explain   = result['explanation']    ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCorrect ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Card header
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isCorrect ? Colors.green[50] : Colors.red[50],
            borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
          ),
          child: Row(children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isCorrect ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Q$number',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
            SizedBox(width: 8),
            Icon(isCorrect ? Icons.check_circle : Icons.cancel,
                color: isCorrect ? Colors.green : Colors.red, size: 18),
            Spacer(),
            Text(isCorrect ? '✓ Correct' : '✗ Incorrect',
                style: TextStyle(
                  color: isCorrect ? Colors.green[700] : Colors.red[700],
                  fontWeight: FontWeight.bold, fontSize: 13,
                )),
          ]),
        ),
        // Question text
        Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: Text(
            result['questionText'] ?? '',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E), height: 1.6),
          ),
        ),
        // Options
        Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Column(
            children: ['A', 'B', 'C', 'D']
                .map((l) => _optionRow(l, result['option$l'] ?? '', selected, correct))
                .toList(),
          ),
        ),
        // Explanation
        if (explain.isNotEmpty)
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _buildExplanation(explain),
          ),
      ]),
    );
  }

  Widget _optionRow(String letter, String text, String selected, String correct) {
    final isSel  = selected.toUpperCase() == letter;
    final isCorr = correct.toUpperCase()  == letter;

    Color bg = Colors.grey[50]!;
    Color bd = Colors.grey[200]!;
    Color tc = Color(0xFF1A1A2E);

    if (isCorr)       { bg = Colors.green[50]!; bd = Colors.green;  tc = Colors.green[800]!; }
    else if (isSel)   { bg = Colors.red[50]!;   bd = Colors.red;    tc = Colors.red[800]!; }

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: bd, width: 1.5),
      ),
      child: Row(children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(color: bd, borderRadius: BorderRadius.circular(6)),
          child: Center(
            child: Text(letter,
                style: TextStyle(
                  color: (isSel || isCorr) ? Colors.white : Colors.grey[600],
                  fontWeight: FontWeight.bold, fontSize: 13,
                )),
          ),
        ),
        SizedBox(width: 10),
        Expanded(child: Text(text, style: TextStyle(color: tc, fontSize: 13, height: 1.4))),
        if (isCorr)            Icon(Icons.check,  color: Colors.green, size: 16),
        if (isSel && !isCorr)  Icon(Icons.close,  color: Colors.red,   size: 16),
      ]),
    );
  }

  Widget _buildExplanation(String explanation) {
    final lines = explanation.replaceAll(r'\n', '\n').split('\n')
        .map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.lightbulb_outline, color: Colors.orange, size: 16),
          SizedBox(width: 6),
          Text('Solution',
              style: TextStyle(color: Colors.orange[700], fontWeight: FontWeight.bold, fontSize: 13)),
        ]),
        SizedBox(height: 8),
        ...lines.map((line) => Padding(
          padding: EdgeInsets.only(bottom: 4),
          child: Text(line,
              style: TextStyle(color: Colors.orange[900], fontSize: 13, height: 1.5)),
        )),
      ]),
    );
  }
}