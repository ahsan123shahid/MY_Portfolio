import 'package:flutter/material.dart';
import '../../services/subject_service.dart';

class AdminQuestionsScreen extends StatefulWidget {
  final String topicName;
  final int    subjectId;

  const AdminQuestionsScreen({super.key, required this.topicName, required this.subjectId});

  @override
  State<AdminQuestionsScreen> createState() => _AdminQuestionsScreenState();
}

class _AdminQuestionsScreenState extends State<AdminQuestionsScreen> {
  final SubjectService _service = SubjectService();

  List<Map<String, dynamic>> _all       = [];
  bool                       _loading   = true;
  String                     _difficulty = 'All';
  String                     _type       = 'All';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _service.getPoolQuestions(widget.topicName, subjectId: widget.subjectId);
      if (mounted) setState(() { _all = list; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _snack(e.toString(), Colors.red);
      }
    }
  }

  Future<void> _delete(int questionId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Question'),
        content: const Text('Remove this question from the pool?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ??
        false;
    if (!ok) return;
    try {
      await _service.deleteQuestion(questionId);
      _snack('Question deleted', Colors.green);
      _load();
    } catch (e) { _snack(e.toString(), Colors.red); }
  }

  void _snack(String msg, Color color) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));

  List<Map<String, dynamic>> get _filtered {
    return _all.where((q) {
      if (_difficulty != 'All' && (q['difficulty'] ?? '').toString().toLowerCase() != _difficulty.toLowerCase()) return false;
      if (_type != 'All'       && (q['type']       ?? '').toString().toLowerCase() != _type.toLowerCase())       return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: Text(widget.topicName, overflow: TextOverflow.ellipsis),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${filtered.length} / ${_all.length}',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                  ? _buildEmpty()
                  : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: filtered.length,
                itemBuilder: (_, i) => _buildCard(filtered[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterRow(
            label: 'Difficulty',
            options: ['All', 'Easy', 'Medium', 'Hard'],
            selected: _difficulty,
            onSelect: (v) => setState(() => _difficulty = v),
          ),
          const SizedBox(height: 8),
          _buildFilterRow(
            label: 'Type',
            options: ['All', 'Conceptual', 'Numerical'],
            selected: _type,
            onSelect: (v) => setState(() => _type = v),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow({
    required String label,
    required List<String> options,
    required String selected,
    required void Function(String) onSelect,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
        ),
        ...options.map((o) => Padding(
          padding: const EdgeInsets.only(right: 6),
          child: GestureDetector(
            onTap: () => onSelect(o),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: selected == o ? const Color(0xFF1565C0) : Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                o,
                style: TextStyle(
                  fontSize: 12,
                  color: selected == o ? Colors.white : Colors.grey[700],
                  fontWeight: selected == o ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.quiz_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No questions match filters', style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> q) {
    final diff  = (q['difficulty'] ?? '').toString();
    final type  = (q['type']       ?? '').toString();
    final Color diffColor;
    switch (diff.toLowerCase()) {
      case 'easy':   diffColor = const Color(0xFF2E7D32); break;
      case 'medium': diffColor = Colors.orange;           break;
      case 'hard':   diffColor = Colors.red;              break;
      default:       diffColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            q['questionText'] ?? '',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, height: 1.4),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          // Options
          ..._buildOptions(q),
          const SizedBox(height: 10),
          Row(
            children: [
              _Chip(label: diff,  color: diffColor),
              const SizedBox(width: 6),
              _Chip(label: type,  color: const Color(0xFF1565C0)),
              const SizedBox(width: 6),
              _Chip(label: '✓ ${q['correctOption'] ?? ''}', color: const Color(0xFF2E7D32)),
              const Spacer(),
              InkWell(
                onTap: () => _showExplanation(q),
                child: const Icon(Icons.info_outline_rounded, size: 20, color: Color(0xFF1565C0)),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _delete(q['questionId']),
                child: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildOptions(Map<String, dynamic> q) {
    final correctOpt = (q['correctOption'] ?? '').toString().toUpperCase();
    final options = [
      ('A', q['optionA'] ?? ''),
      ('B', q['optionB'] ?? ''),
      ('C', q['optionC'] ?? ''),
      ('D', q['optionD'] ?? ''),
    ];
    return options.map((o) {
      final isCorrect = o.$1 == correctOpt;
      return Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Row(
          children: [
            Container(
              width: 20, height: 20,
              decoration: BoxDecoration(
                color: isCorrect ? const Color(0xFF2E7D32) : Colors.grey[200],
                borderRadius: BorderRadius.circular(5),
              ),
              child: Center(
                child: Text(o.$1,
                  style: TextStyle(fontSize: 11, color: isCorrect ? Colors.white : Colors.grey[600], fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(o.$2.toString(), style: TextStyle(fontSize: 12, color: Colors.grey[700]))),
          ],
        ),
      );
    }).toList();
  }

  void _showExplanation(Map<String, dynamic> q) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Explanation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1565C0))),
            const SizedBox(height: 12),
            Text(q['explanation'] ?? 'No explanation provided.', style: const TextStyle(fontSize: 14, height: 1.5)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color  color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}