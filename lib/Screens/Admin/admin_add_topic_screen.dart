import 'package:flutter/material.dart';
import '../../services/subject_service.dart';
import 'admin_questions_screen.dart';
import 'admin_upload_pdf_screen.dart';

class AdminTopicsScreen extends StatefulWidget {
  final int    subjectId;
  final String subjectName;

  const AdminTopicsScreen({super.key, required this.subjectId, required this.subjectName});

  @override
  State<AdminTopicsScreen> createState() => _AdminTopicsScreenState();
}

class _AdminTopicsScreenState extends State<AdminTopicsScreen> {
  final SubjectService _service = SubjectService();
  List<Map<String, dynamic>> _topics = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _service.getAdminTopics(widget.subjectId);
      if (mounted) setState(() { _topics = list; _loading = false; });
    } catch (e) {
      if (mounted) { setState(() => _loading = false); _snack(e.toString(), Colors.red); }
    }
  }

  Future<void> _delete(int topicId, String topicName) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Topic'),
        content: Text('Delete "$topicName"? All questions and content will be removed.'),
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
      await _service.deleteTopic(topicId);
      _snack('Topic deleted', Colors.green);
      _load();
    } catch (e) { _snack(e.toString(), Colors.red); }
  }

  void _snack(String msg, Color color) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: Text(widget.subjectName),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1565C0),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminUploadPdfScreen(
              subjectId:   widget.subjectId,
              subjectName: widget.subjectName,
            ),
          ),
        ).then((_) => _load()),
        icon: const Icon(Icons.upload_file_rounded),
        label: const Text('Upload PDF'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            _buildBanner(),
            Expanded(
              child: _topics.isEmpty
                  ? _buildEmpty()
                  : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                itemCount: _topics.length,
                itemBuilder: (_, i) => _buildCard(_topics[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1565C0).withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1565C0).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.tips_and_updates_rounded, color: Color(0xFF1565C0), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Upload a PDF to automatically extract topics and generate 60 questions per topic.',
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.upload_file_rounded, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No topics yet', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
          const SizedBox(height: 8),
          Text('Upload a lecture PDF to get started', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> t) {
    final qCount      = t['questionCount'] ?? 0;
    final hasContent  = t['hasContent']    ?? false;
    final bool ready  = qCount > 0;

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
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: ready
                ? const Color(0xFF2E7D32).withOpacity(0.1)
                : Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            ready ? Icons.check_circle_rounded : Icons.hourglass_empty_rounded,
            color: ready ? const Color(0xFF2E7D32) : Colors.orange,
          ),
        ),
        title: Text(
          t['topicName'] ?? '',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              if (ready)
                _buildChip('$qCount questions', const Color(0xFF2E7D32))
              else
                _buildChip('No questions yet', Colors.orange),
              if (hasContent) ...[
                const SizedBox(width: 6),
                _buildChip('Has notes', const Color(0xFF1565C0)),
              ],
            ],
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 22),
          onPressed: () => _delete(t['topicId'], t['topicName']),
        ),
        onTap: ready
            ? () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminQuestionsScreen(
              topicName:  t['topicName'],
              subjectId:  widget.subjectId,
            ),
          ),
        )
            : null,

      ),
    );
  }

  Widget _buildChip(String label, Color color) {
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