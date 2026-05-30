import 'package:flutter/material.dart';
import '../../services/subject_service.dart';
import 'admin_questions_screen.dart';
import 'admin_upload_pdf_screen.dart';

class AdminTopicsScreen extends StatefulWidget {
  final int subjectId;
  final String subjectName;

  const AdminTopicsScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
  });

  @override
  State<AdminTopicsScreen> createState() => _AdminTopicsScreenState();
}

class _AdminTopicsScreenState extends State<AdminTopicsScreen>
    with SingleTickerProviderStateMixin {
  final SubjectService _service = SubjectService();

  List<Map<String, dynamic>> _topics = [];
  bool _loading = true;

  // Track which topics are currently generating questions
  final Set<int> _generatingTopics = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ═══════════════════════════════════════════════════════════════════
  //  DATA
  // ═══════════════════════════════════════════════════════════════════

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _service.getAdminTopics(widget.subjectId);
      if (mounted) setState(() {
        _topics = list;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _snack(e.toString(), isError: true);
      }
    }
  }

  Future<void> _delete(int topicId, String topicName) async {
    final ok = await _confirmDialog(
      title: 'Delete Topic',
      message: 'Delete "$topicName"? All questions and content will be permanently removed.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (!ok) return;

    try {
      await _service.deleteTopic(topicId);
      _snack('Topic deleted successfully', isError: false);
      _load();
    } catch (e) {
      _snack(e.toString(), isError: true);
    }
  }

  /// Called when admin taps a topic with no questions — shows bottom sheet
  Future<void> _onNoQuestionsTap(Map<String, dynamic> topic) async {
    final topicId = topic['topicId'] as int;
    final topicName = topic['topicName'] as String? ?? '';
    final hasContent = topic['hasContent'] as bool? ?? false;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _GenerateQuestionsSheet(
        topicName: topicName,
        hasContent: hasContent,
        onGenerate: () async {
          Navigator.pop(context);
          await _generateQuestionsForTopic(topicId, topicName);
        },
      ),
    );
  }

  Future<void> _generateQuestionsForTopic(int topicId, String topicName) async {
    setState(() => _generatingTopics.add(topicId));

    try {
      // Call backend endpoint: generates 60 questions from stored content
      await _service.generateQuestionsForTopic(widget.subjectId, topicName);
      _snack('60 questions generated for "$topicName"!', isError: false);
      await _load(); // Refresh list so qCount updates
    } catch (e) {
      _snack(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _generatingTopics.remove(topicId));
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════════════════════════════

  Future<bool> _confirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required bool isDestructive,
  }) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message,
            style: const TextStyle(fontSize: 14, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              confirmLabel,
              style: TextStyle(
                color: isDestructive
                    ? Colors.red
                    : const Color(0xFF1565C0),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ) ??
        false;
  }

  void _snack(String msg, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          Icon(
            isError
                ? Icons.error_outline_rounded
                : Icons.check_circle_outline_rounded,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(msg)),
        ],
      ),
      backgroundColor:
      isError ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32),
      behavior: SnackBarBehavior.floating,
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ═══════════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final readyCount = _topics.where((t) => (t['questionCount'] ?? 0) > 0).length;
    final pendingCount = _topics.length - readyCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FF),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.subjectName,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const Text('Topics Manager',
                style: TextStyle(fontSize: 11, color: Colors.white60)),
          ],
        ),
        backgroundColor: const Color(0xFF0D2B6E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0D2B6E),
        foregroundColor: Colors.white,
        elevation: 2,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminUploadPdfScreen(
              subjectId: widget.subjectId,
              subjectName: widget.subjectName,
            ),
          ),
        ).then((_) => _load()),
        icon: const Icon(Icons.upload_file_rounded, size: 20),
        label: const Text('Upload PDF',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: const Color(0xFF1565C0),
        child: _loading
            ? const Center(
            child: CircularProgressIndicator(color: Color(0xFF1565C0)))
            : CustomScrollView(
          slivers: [
            // Stats header
            if (_topics.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _StatsHeader(
                    total: _topics.length,
                    ready: readyCount,
                    pending: pendingCount,
                  ),
                ),
              ),

            // Info banner
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: _InfoBanner(hasPending: pendingCount > 0),
              ),
            ),

            // Topics list
            _topics.isEmpty
                ? SliverFillRemaining(child: _buildEmpty())
                : SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (_, i) => _buildCard(_topics[i]),
                  childCount: _topics.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.upload_file_rounded,
                size: 52, color: const Color(0xFF1565C0).withOpacity(0.3)),
          ),
          const SizedBox(height: 20),
          const Text('No Topics Yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E))),
          const SizedBox(height: 8),
          Text('Upload a lecture PDF to auto-extract topics',
              style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> t) {
    final topicId = t['topicId'] as int? ?? 0;
    final topicName = t['topicName'] as String? ?? '';
    final qCount = t['questionCount'] as int? ?? 0;
    final hasContent = t['hasContent'] as bool? ?? false;
    final bool ready = qCount > 0;
    final bool isGenerating = _generatingTopics.contains(topicId);

    return _TopicCard(
      topicName: topicName,
      questionCount: qCount,
      hasContent: hasContent,
      isReady: ready,
      isGenerating: isGenerating,
      onTap: ready
          ? () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AdminQuestionsScreen(
            topicName: topicName,
            subjectId: widget.subjectId,
          ),
        ),
      )
          : () => _onNoQuestionsTap(t),
      onDelete: () => _delete(topicId, topicName),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  COMPONENTS
// ═══════════════════════════════════════════════════════════════════

class _StatsHeader extends StatelessWidget {
  final int total;
  final int ready;
  final int pending;

  const _StatsHeader({
    required this.total,
    required this.ready,
    required this.pending,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            value: '$total',
            label: 'Total Topics',
            color: const Color(0xFF1565C0),
            icon: Icons.topic_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            value: '$ready',
            label: 'Ready',
            color: const Color(0xFF2E7D32),
            icon: Icons.check_circle_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            value: '$pending',
            label: 'Need Questions',
            color: pending > 0 ? const Color(0xFFE65100) : Colors.grey,
            icon: Icons.pending_actions_rounded,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData icon;

  const _StatTile({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 20, color: color)),
          Text(label,
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final bool hasPending;

  const _InfoBanner({required this.hasPending});

  @override
  Widget build(BuildContext context) {
    if (!hasPending) {
      return Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF2E7D32).withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: const Color(0xFF2E7D32).withOpacity(0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded,
                color: Color(0xFF2E7D32), size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'All topics have questions ready. Tap any topic to manage.',
                style:
                TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE65100).withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border:
        Border.all(color: const Color(0xFFE65100).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.touch_app_rounded,
              color: Color(0xFFE65100), size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tap any orange topic to generate 60 AI questions from its stored content.',
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  final String topicName;
  final int questionCount;
  final bool hasContent;
  final bool isReady;
  final bool isGenerating;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TopicCard({
    required this.topicName,
    required this.questionCount,
    required this.hasContent,
    required this.isReady,
    required this.isGenerating,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final Color accentColor = isReady
        ? const Color(0xFF2E7D32)
        : isGenerating
        ? const Color(0xFF1565C0)
        : const Color(0xFFE65100);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGenerating
              ? const Color(0xFF1565C0).withOpacity(0.3)
              : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: isGenerating ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Icon / status
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: isGenerating
                      ? Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: accentColor,
                      ),
                    ),
                  )
                      : Icon(
                    isReady
                        ? Icons.check_circle_rounded
                        : Icons.auto_awesome_rounded,
                    color: accentColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topicName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _Chip(
                            label: isGenerating
                                ? 'Generating...'
                                : isReady
                                ? '$questionCount questions'
                                : 'Tap to generate',
                            color: accentColor,
                          ),
                          if (hasContent) ...[
                            const SizedBox(width: 6),
                            _Chip(
                              label: 'Has notes',
                              color: const Color(0xFF1565C0),
                            ),
                          ],
                          if (!hasContent && !isReady) ...[
                            const SizedBox(width: 6),
                            _Chip(
                              label: 'No content',
                              color: Colors.grey,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Delete button
                if (!isGenerating)
                  GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.delete_outline_rounded,
                          color: Colors.red, size: 18),
                    ),
                  ),

                // Arrow for ready topics
                if (isReady && !isGenerating) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right_rounded,
                      color: Colors.grey[300], size: 22),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;

  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  GENERATE QUESTIONS BOTTOM SHEET
// ═══════════════════════════════════════════════════════════════════

class _GenerateQuestionsSheet extends StatelessWidget {
  final String topicName;
  final bool hasContent;
  final VoidCallback onGenerate;

  const _GenerateQuestionsSheet({
    required this.topicName,
    required this.hasContent,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
        child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D2B6E), Color(0xFF1565C0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1565C0).withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 32),
          ),
          const SizedBox(height: 20),

          // Title
          const Text(
            'Generate Questions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D2B6E),
            ),
          ),
          const SizedBox(height: 8),

          // Topic name
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              topicName,
              style: const TextStyle(
                color: Color(0xFF1565C0),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            hasContent
                ? 'AI will use the stored lecture notes for this topic to generate 60 multiple-choice questions.'
                : 'No stored content found for this topic. Questions will be generated using topic name only — quality may be lower.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Question breakdown
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.quiz_rounded,
                        color: Color(0xFF1565C0), size: 16),
                    SizedBox(width: 6),
                    Text('60 Questions Breakdown',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF1565C0))),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _BreakdownItem(
                        label: 'Easy',
                        count: '20',
                        color: const Color(0xFF2E7D32)),
                    _BreakdownItem(
                        label: 'Medium',
                        count: '20',
                        color: const Color(0xFFE65100)),
                    _BreakdownItem(
                        label: 'Hard',
                        count: '20',
                        color: const Color(0xFFD32F2F)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '10 Conceptual + 10 Numerical per difficulty level',
                  style:
                  TextStyle(fontSize: 11, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          if (!hasContent) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border:
                Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.amber, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Upload the PDF again to store content for better results.',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.grey)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: onGenerate,
                  icon: const Icon(Icons.auto_awesome_rounded,
                      color: Colors.white, size: 18),
                  label: const Text(
                    'Generate 60 Questions',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D2B6E),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    )
    );
  }
}

class _BreakdownItem extends StatelessWidget {
  final String label;
  final String count;
  final Color color;

  const _BreakdownItem({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(count,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: color)),
          Text(label,
              style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        ],
      ),
    );
  }
}