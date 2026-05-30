import 'package:flutter/material.dart';
import '../../services/subject_service.dart';
import 'admin_add_subject_screen.dart';
import 'admin_topics_screen.dart';

class AdminSubjectsScreen extends StatefulWidget {
  const AdminSubjectsScreen({super.key});

  @override
  State<AdminSubjectsScreen> createState() => _AdminSubjectsScreenState();
}

class _AdminSubjectsScreenState extends State<AdminSubjectsScreen> {
  final SubjectService _service = SubjectService();
  List<Map<String, dynamic>> _subjects = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _service.getAdminSubjects();
      if (mounted) setState(() { _subjects = list; _loading = false; });
    } catch (e) {
      if (mounted) { setState(() => _loading = false); _snack(e.toString(), Colors.red); }
    }
  }

  Future<void> _delete(int id) async {
    final ok = await _confirm(
      title:   'Delete Subject',
      message: 'This will permanently delete all topics, PDFs, and questions under this subject.',
    );
    if (!ok) return;
    try {
      await _service.deleteSubject(id);
      _snack('Subject deleted', Colors.green);
      _load();
    } catch (e) { _snack(e.toString(), Colors.red); }
  }

  Future<bool> _confirm({required String title, required String message}) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title),
        content: Text(message),
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
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: const Text('Subjects'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1565C0),
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminAddSubjectScreen()));
          _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Subject'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _subjects.isEmpty
            ? _buildEmpty()
            : ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: _subjects.length,
          itemBuilder: (_, i) => _buildCard(_subjects[i]),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.book_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No subjects yet', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
          const SizedBox(height: 8),
          Text('Tap + to add your first subject', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> s) {
    final qCount = s['questionCount'] ?? 0;
    final tCount = s['topicCount']    ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF1565C0).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.book_rounded, color: Color(0xFF1565C0)),
        ),
        title: Text(s['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              _Badge(label: '$tCount topics',    color: const Color(0xFF1565C0)),
              const SizedBox(width: 8),
              _Badge(label: '$qCount questions', color: const Color(0xFF2E7D32)),
            ],
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
          tooltip: 'Delete',
          onPressed: () => _delete(s['subjectId']),
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminTopicsScreen(
              subjectId:   s['subjectId'],
              subjectName: s['name'],
            ),
          ),
        ).then((_) => _load()),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}