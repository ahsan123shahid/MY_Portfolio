import 'dart:async';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/subject_service.dart';

// ═══════════════════════════════════════════════════════════════════
//  AdminUploadPdfScreen — Full-featured PDF manager
// ═══════════════════════════════════════════════════════════════════

class AdminUploadPdfScreen extends StatefulWidget {
  final int subjectId;
  final String subjectName;

  const AdminUploadPdfScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
  });

  @override
  State<AdminUploadPdfScreen> createState() => _AdminUploadPdfScreenState();
}

class _AdminUploadPdfScreenState extends State<AdminUploadPdfScreen>
    with TickerProviderStateMixin {
  final SubjectService _service = SubjectService();

  // ── Background question generation polling ────────────────────────
  bool _questionsGenerating = false;
  Timer? _pollTimer;

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      await _checkGenerationStatus();
    });
  }

  Future<void> _checkGenerationStatus() async {
    try {
      final status = await _service.getGenerationStatus(widget.subjectId);
      final allReady = status['allReady'] as bool? ?? false;
      final totalQuestions = status['totalQuestions'] as int? ?? 0;

      if (allReady || totalQuestions > 0) {
        _pollTimer?.cancel();
        if (mounted) {
          setState(() {
            _questionsGenerating = !allReady;
            _lastQuestionsSaved = totalQuestions;
          });
          if (allReady) {
            _snack('$totalQuestions questions ready!', isError: false);
            await _loadChunks();
          }
        }
      }
    } catch (_) {
      // Polling errors are silent — just retry next tick
    }
  }

  // ── Upload State ──────────────────────────────────────────────────
  String? _filePath;
  String? _fileName;
  bool _uploading = false;
  String? _errorMessage;
  List<String> _lastExtractedTopics = [];
  int _lastQuestionsSaved = 0;
  bool _showSuccess = false;

  // ── Data ──────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _chunks = [];
  bool _loadingChunks = true;

  Map<String, List<Map<String, dynamic>>> _topicQuestions = {};
  Map<String, bool> _loadingQuestions = {};
  Map<String, bool> _expandedTopics = {};
  Map<String, bool> _expandedQuestions = {};
  Map<String, bool> _regenerating = {};

  // ── Tab ───────────────────────────────────────────────────────────
  int _tab = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() => _tab = _tabController.index));
    _loadChunks();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════
  //  DATA LOADING
  // ═══════════════════════════════════════════════════════════════════

  Future<void> _loadChunks() async {
    setState(() => _loadingChunks = true);
    try {
      final list = await _service.getKnowledgeChunks(widget.subjectId);
      if (mounted) {
        setState(() {
          _chunks = list;
          _loadingChunks = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingChunks = false);
    }
  }

  Future<void> _loadQuestionsForTopic(String topicName) async {
    if (_loadingQuestions[topicName] == true) return;
    setState(() => _loadingQuestions[topicName] = true);
    try {
      final qs = await _service.getQuestionsForTopic(widget.subjectId, topicName);
      if (mounted) {
        setState(() {
          _topicQuestions[topicName] = qs;
          _loadingQuestions[topicName] = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingQuestions[topicName] = false);
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  //  ACTIONS
  // ═══════════════════════════════════════════════════════════════════

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _filePath = result.files.single.path;
        _fileName = result.files.single.name;
        _showSuccess = false;
        _errorMessage = null;
      });
    }
  }

  Future<void> _upload() async {
    if (_filePath == null) return;
    setState(() {
      _uploading = true;
      _errorMessage = null;
      _showSuccess = false;
    });
    try {
      final result = await _service.uploadPdf(
        widget.subjectId,
        _filePath!,
        _fileName!,
      );
      if (mounted) {
        final questionsGenerating = result['questionsGenerating'] == true;
        setState(() {
          _uploading = false;
          _showSuccess = true;
          _lastExtractedTopics = List<String>.from(result['topicsExtracted'] ?? []);
          _lastQuestionsSaved = result['questionsSaved'] ?? 0;
          _questionsGenerating = questionsGenerating;
          _filePath = null;
          _fileName = null;
        });
        await _loadChunks();

        if (questionsGenerating) {
          _startPolling();
        }

        _tabController.animateTo(1);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _uploading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _deleteChunk(int chunkId, String topicName) async {
    final confirmed = await _confirmDialog(
      title: 'Delete Topic Notes',
      message: 'Are you sure you want to delete notes for "$topicName"? This cannot be undone.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (!confirmed) return;
    try {
      await _service.deleteKnowledgeChunk(chunkId);
      _snack('Notes deleted successfully', isError: false);
      _loadChunks();
    } catch (e) {
      _snack(e.toString(), isError: true);
    }
  }

  Future<void> _regenerateQuestions(String topicName) async {
    final confirmed = await _confirmDialog(
      title: 'Regenerate Questions',
      message: 'This will delete existing questions for "$topicName" and generate new ones. Continue?',
      confirmLabel: 'Regenerate',
      isDestructive: false,
    );
    if (!confirmed) return;
    setState(() => _regenerating[topicName] = true);
    try {
      await _service.regenerateQuestionsForTopic(widget.subjectId, topicName);
      _snack('Questions regenerated!', isError: false);
      _topicQuestions.remove(topicName);
      await _loadQuestionsForTopic(topicName);
    } catch (e) {
      _snack(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _regenerating[topicName] = false);
    }
  }

  Future<void> _deleteQuestion(int questionId, String topicName) async {
    final confirmed = await _confirmDialog(
      title: 'Delete Question',
      message: 'Delete this question permanently?',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (!confirmed) return;
    try {
      await _service.deleteQuestion(questionId);
      _snack('Question deleted', isError: false);
      _topicQuestions.remove(topicName);
      await _loadQuestionsForTopic(topicName);
    } catch (e) {
      _snack(e.toString(), isError: true);
    }
  }

  Future<void> _viewFullContent(String topicName, String content) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ContentBottomSheet(topicName: topicName, content: content),
    );
  }

  Future<void> _viewQuestion(Map<String, dynamic> q, String topicName) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QuestionBottomSheet(question: q, topicName: topicName),
    );
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
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
                color: isDestructive ? Colors.red : const Color(0xFF1565C0),
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(msg)),
        ],
      ),
      backgroundColor: isError ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ═══════════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FF),
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            backgroundColor: const Color(0xFF0D2B6E),
            foregroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 56, bottom: 56),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.subjectName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const Text(
                    'PDF Manager',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0D2B6E), Color(0xFF1565C0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.upload_file_rounded, size: 16),
                      SizedBox(width: 6),
                      Text('Upload'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_stories_rounded, size: 16),
                      const SizedBox(width: 6),
                      Text('Topics${_chunks.isNotEmpty ? ' (${_chunks.length})' : ''}'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.quiz_rounded, size: 16),
                      SizedBox(width: 6),
                      Text('Questions'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildUploadTab(),
            _buildTopicsTab(),
            _buildQuestionsTab(),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  TAB 0: UPLOAD
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildUploadTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Generating banner
        if (_questionsGenerating) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF1565C0).withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1565C0)),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Questions are being generated in the background… check the Questions tab in a few minutes.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF1565C0)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Success banner
        if (_showSuccess) ...[
          _SuccessBanner(
            topics: _lastExtractedTopics,
            questionsSaved: _lastQuestionsSaved,
            questionsGenerating: _questionsGenerating,
            onDismiss: () => setState(() => _showSuccess = false),
          ),
          const SizedBox(height: 16),
        ],

        // Error banner
        if (_errorMessage != null) ...[
          _ErrorBanner(
            message: _errorMessage!,
            onDismiss: () => setState(() => _errorMessage = null),
          ),
          const SizedBox(height: 16),
        ],

        // Upload card
        _UploadCard(
          fileName: _fileName,
          uploading: _uploading,
          onPick: _pickFile,
          onClear: () => setState(() {
            _filePath = null;
            _fileName = null;
          }),
          onUpload: _upload,
        ),

        const SizedBox(height: 20),

        // Info card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded,
                        color: Color(0xFF1565C0), size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Text('What happens after upload?',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 14),
              const _InfoStep(
                step: '1',
                icon: Icons.find_in_page_rounded,
                title: 'Topic Extraction',
                desc: 'AI reads Objectives section and extracts all topic names',
              ),
              const _InfoStep(
                step: '2',
                icon: Icons.psychology_rounded,
                title: 'Content Mapping',
                desc: "Each topic's full content is extracted and cleaned",
              ),
              const _InfoStep(
                step: '3',
                icon: Icons.quiz_rounded,
                title: 'Question Generation',
                desc: '60 MCQs per topic: Easy/Medium/Hard × Conceptual/Numerical (background)',
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  TAB 1: TOPICS & CONTENT
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildTopicsTab() {
    if (_loadingChunks) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF1565C0)),
            SizedBox(height: 12),
            Text('Loading topics...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (_chunks.isEmpty) {
      return _EmptyState(
        icon: Icons.auto_stories_outlined,
        title: 'No Topics Yet',
        subtitle: 'Upload a PDF to extract topics and content',
        actionLabel: 'Upload PDF',
        onAction: () => _tabController.animateTo(0),
      );
    }

    final Map<int, List<Map<String, dynamic>>> byWeek = {};
    for (final c in _chunks) {
      final w = c['week'] as int? ?? 0;
      byWeek.putIfAbsent(w, () => []).add(c);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StatsRow(chunks: _chunks),
        const SizedBox(height: 16),

        for (final week in byWeek.keys.toList()..sort()) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10, top: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D2B6E),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Week $week',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${byWeek[week]!.length} topic${byWeek[week]!.length > 1 ? 's' : ''}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          for (final chunk in byWeek[week]!)
            _TopicChunkCard(
              chunk: chunk,
              isExpanded: _expandedTopics[chunk['topicName']] == true,
              onToggle: () => setState(() {
                final t = chunk['topicName'] as String;
                _expandedTopics[t] = !(_expandedTopics[t] ?? false);
              }),
              onViewFull: () async {
                final content =
                await _service.getTopicContent(chunk['topicName'] as String);
                if (mounted) _viewFullContent(chunk['topicName'], content);
              },
              onDelete: () => _deleteChunk(
                chunk['chunkId'] as int,
                chunk['topicName'] as String,
              ),
              onRegenerate: () =>
                  _regenerateQuestions(chunk['topicName'] as String),
              isRegenerating: _regenerating[chunk['topicName'] as String] == true,
            ),
        ],
        const SizedBox(height: 20),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  TAB 2: QUESTIONS
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildQuestionsTab() {
    if (_loadingChunks) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF1565C0)));
    }

    if (_chunks.isEmpty) {
      return _EmptyState(
        icon: Icons.quiz_outlined,
        title: 'No Questions Yet',
        subtitle: 'Upload a PDF to auto-generate questions',
        actionLabel: 'Upload PDF',
        onAction: () => _tabController.animateTo(0),
      );
    }

    // Show "generating" state if still in background
    if (_questionsGenerating && _topicQuestions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFF6A1B9A)),
              const SizedBox(height: 20),
              const Text(
                'Generating Questions...',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF6A1B9A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This runs in the background.\nCome back in a few minutes.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    final topics = _chunks.map((c) => c['topicName'] as String).toSet().toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final topic in topics) ...[
          _QuestionTopicSection(
            topicName: topic,
            questions: _topicQuestions[topic],
            isLoading: _loadingQuestions[topic] == true,
            isRegenerating: _regenerating[topic] == true,
            isExpanded: _expandedQuestions[topic] == true,
            onToggle: () {
              final wasExpanded = _expandedQuestions[topic] == true;
              setState(() => _expandedQuestions[topic] = !wasExpanded);
              if (!wasExpanded && _topicQuestions[topic] == null) {
                _loadQuestionsForTopic(topic);
              }
            },
            onRegenerate: () => _regenerateQuestions(topic),
            onViewQuestion: (q) => _viewQuestion(q, topic),
            onDeleteQuestion: (qId) => _deleteQuestion(qId, topic),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 20),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  COMPONENTS
// ═══════════════════════════════════════════════════════════════════

// ── Upload Card ────────────────────────────────────────────────────

class _UploadCard extends StatelessWidget {
  final String? fileName;
  final bool uploading;
  final VoidCallback onPick;
  final VoidCallback onClear;
  final VoidCallback onUpload;

  const _UploadCard({
    required this.fileName,
    required this.uploading,
    required this.onPick,
    required this.onClear,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D2B6E), Color(0xFF1565C0)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.picture_as_pdf_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Upload Lecture PDF',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('AI will extract topics & generate questions',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          GestureDetector(
            onTap: uploading ? null : onPick,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              decoration: BoxDecoration(
                color: fileName != null
                    ? const Color(0xFF1565C0).withOpacity(0.06)
                    : Colors.grey[50],
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: fileName != null
                      ? const Color(0xFF1565C0).withOpacity(0.4)
                      : Colors.grey.shade200,
                  width: fileName != null ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    fileName != null
                        ? Icons.description_rounded
                        : Icons.cloud_upload_outlined,
                    color: fileName != null ? const Color(0xFF1565C0) : Colors.grey[400],
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fileName ?? 'Tap to choose a PDF',
                          style: TextStyle(
                            color: fileName != null
                                ? const Color(0xFF0D2B6E)
                                : Colors.grey[400],
                            fontWeight: fileName != null
                                ? FontWeight.w600
                                : FontWeight.normal,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (fileName == null)
                          Text(
                            'Supports text-based PDFs only',
                            style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                          ),
                      ],
                    ),
                  ),
                  if (fileName != null)
                    GestureDetector(
                      onTap: onClear,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded,
                            color: Colors.grey, size: 16),
                      ),
                    ),
                ],
              ),
            ),
          ),

          if (fileName != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: uploading ? null : onUpload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D2B6E),
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: uploading
                    ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    ),
                    SizedBox(width: 12),
                    Text('Processing PDF...',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ],
                )
                    : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.rocket_launch_rounded,
                        color: Colors.white, size: 18),
                    SizedBox(width: 10),
                    Text(
                      'Upload & Process',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Info Step ──────────────────────────────────────────────────────

class _InfoStep extends StatelessWidget {
  final String step;
  final IconData icon;
  final String title;
  final String desc;

  const _InfoStep({
    required this.step,
    required this.icon,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                step,
                style: const TextStyle(
                  color: Color(0xFF1565C0),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 2),
                Text(desc,
                    style:
                    TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Success Banner ─────────────────────────────────────────────────

class _SuccessBanner extends StatelessWidget {
  final List<String> topics;
  final int questionsSaved;
  final bool questionsGenerating;
  final VoidCallback onDismiss;

  const _SuccessBanner({
    required this.topics,
    required this.questionsSaved,
    required this.questionsGenerating,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B5E20).withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF2E7D32), size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'PDF processed successfully!',
                  style: TextStyle(
                    color: Color(0xFF2E7D32),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onDismiss,
                child: const Icon(Icons.close_rounded, color: Colors.grey, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _StatChip(
                icon: Icons.topic_rounded,
                label: '${topics.length} topics',
                color: const Color(0xFF1565C0),
              ),
              const SizedBox(width: 8),
              _StatChip(
                icon: Icons.quiz_rounded,
                label: questionsGenerating ? 'Generating...' : '$questionsSaved questions',
                color: const Color(0xFF6A1B9A),
              ),
            ],
          ),
          if (topics.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: topics
                  .map(
                    (t) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    t,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Error Banner ───────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _ErrorBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style:
                const TextStyle(color: Colors.red, fontSize: 13, height: 1.4)),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: const Icon(Icons.close_rounded, color: Colors.grey, size: 18),
          ),
        ],
      ),
    );
  }
}

// ── Stats Row ──────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final List<Map<String, dynamic>> chunks;

  const _StatsRow({required this.chunks});

  @override
  Widget build(BuildContext context) {
    final weeks = chunks.map((c) => c['week']).toSet().length;
    final totalChars =
    chunks.fold<int>(0, (sum, c) => sum + (c['contentLength'] as int? ?? 0));

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.topic_rounded,
            value: '${chunks.length}',
            label: 'Topics',
            color: const Color(0xFF1565C0),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.calendar_today_rounded,
            value: '$weeks',
            label: 'Weeks',
            color: const Color(0xFF6A1B9A),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.text_snippet_rounded,
            value: '${(totalChars / 1000).toStringAsFixed(1)}k',
            label: 'Chars',
            color: const Color(0xFF00695C),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Topic Chunk Card ───────────────────────────────────────────────

class _TopicChunkCard extends StatelessWidget {
  final Map<String, dynamic> chunk;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onViewFull;
  final VoidCallback onDelete;
  final VoidCallback onRegenerate;
  final bool isRegenerating;

  const _TopicChunkCard({
    required this.chunk,
    required this.isExpanded,
    required this.onToggle,
    required this.onViewFull,
    required this.onDelete,
    required this.onRegenerate,
    required this.isRegenerating,
  });

  @override
  Widget build(BuildContext context) {
    final topicName = chunk['topicName'] as String? ?? '';
    final chars = chunk['contentLength'] as int? ?? 0;
    final preview = chunk['preview'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.auto_stories_rounded,
                        color: Color(0xFF1565C0), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          topicName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$chars characters of content',
                          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            Divider(height: 1, color: Colors.grey[100]),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Text(
                      preview.isNotEmpty ? '$preview...' : 'No preview available',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        height: 1.5,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.open_in_full_rounded,
                          label: 'View Full',
                          color: const Color(0xFF1565C0),
                          onTap: onViewFull,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ActionButton(
                          icon: isRegenerating
                              ? Icons.hourglass_top_rounded
                              : Icons.refresh_rounded,
                          label: isRegenerating ? 'Regenerating...' : 'Regen Qs',
                          color: const Color(0xFF6A1B9A),
                          onTap: isRegenerating ? null : onRegenerate,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _ActionButton(
                        icon: Icons.delete_outline_rounded,
                        label: 'Delete',
                        color: Colors.red,
                        onTap: onDelete,
                        small: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool small;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 9, horizontal: small ? 12 : 0),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: onTap == null ? Colors.grey : color),
            if (!small) ...[
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: onTap == null ? Colors.grey : color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Question Topic Section ─────────────────────────────────────────

class _QuestionTopicSection extends StatelessWidget {
  final String topicName;
  final List<Map<String, dynamic>>? questions;
  final bool isLoading;
  final bool isRegenerating;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onRegenerate;
  final void Function(Map<String, dynamic> q) onViewQuestion;
  final void Function(int qId) onDeleteQuestion;

  const _QuestionTopicSection({
    required this.topicName,
    required this.questions,
    required this.isLoading,
    required this.isRegenerating,
    required this.isExpanded,
    required this.onToggle,
    required this.onRegenerate,
    required this.onViewQuestion,
    required this.onDeleteQuestion,
  });

  @override
  Widget build(BuildContext context) {
    final count = questions?.length ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6A1B9A).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.quiz_rounded,
                        color: Color(0xFF6A1B9A), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          topicName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isLoading
                              ? 'Loading...'
                              : questions == null
                              ? 'Tap to load questions'
                              : '$count questions',
                          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: isRegenerating ? null : onRegenerate,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6A1B9A).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: isRegenerating
                          ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF6A1B9A),
                        ),
                      )
                          : const Icon(Icons.refresh_rounded,
                          color: Color(0xFF6A1B9A), size: 16),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            Divider(height: 1, color: Colors.grey[100]),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFF6A1B9A))),
              )
            else if (questions == null || questions!.isEmpty)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.quiz_outlined, color: Colors.grey[300], size: 40),
                    const SizedBox(height: 8),
                    Text('No questions found',
                        style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: onRegenerate,
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Generate Questions'),
                      style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF6A1B9A)),
                    ),
                  ],
                ),
              )
            else
              _QuestionsList(
                questions: questions!,
                onView: onViewQuestion,
                onDelete: onDeleteQuestion,
              ),
          ],
        ],
      ),
    );
  }
}

class _QuestionsList extends StatelessWidget {
  final List<Map<String, dynamic>> questions;
  final void Function(Map<String, dynamic> q) onView;
  final void Function(int qId) onDelete;

  const _QuestionsList({
    required this.questions,
    required this.onView,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final q in questions) {
      final diff = q['difficulty'] as String? ?? 'Medium';
      grouped.putIfAbsent(diff, () => []).add(q);
    }

    const order = ['Easy', 'Medium', 'Hard'];
    final diffColors = {
      'Easy': const Color(0xFF2E7D32),
      'Medium': const Color(0xFFE65100),
      'Hard': const Color(0xFFD32F2F),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final diff in order)
            if (grouped.containsKey(diff)) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: diffColors[diff]!.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$diff (${grouped[diff]!.length})',
                      style: TextStyle(
                        color: diffColors[diff],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              for (int i = 0; i < grouped[diff]!.length; i++)
                _QuestionTile(
                  index: i + 1,
                  question: grouped[diff]![i],
                  color: diffColors[diff]!,
                  onView: () => onView(grouped[diff]![i]),
                  onDelete: () {
                    final id = grouped[diff]![i]['questionId'] as int?;
                    if (id != null) onDelete(id);
                  },
                ),
            ],
        ],
      ),
    );
  }
}

class _QuestionTile extends StatelessWidget {
  final int index;
  final Map<String, dynamic> question;
  final Color color;
  final VoidCallback onView;
  final VoidCallback onDelete;

  const _QuestionTile({
    required this.index,
    required this.question,
    required this.color,
    required this.onView,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final text = question['questionText'] as String? ??
        question['question'] as String? ??
        '';
    final qtype = question['type'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: InkWell(
        onTap: onView,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$index',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, height: 1.4),
                    ),
                    if (qtype.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        qtype,
                        style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onDelete,
                child: Icon(Icons.delete_outline_rounded,
                    color: Colors.grey[400], size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty State ────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withOpacity(0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  size: 48,
                  color: const Color(0xFF1565C0).withOpacity(0.4)),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A237E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style:
              TextStyle(color: Colors.grey[500], fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.upload_file_rounded, size: 18),
              label: Text(actionLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  BOTTOM SHEETS
// ═══════════════════════════════════════════════════════════════════

class _ContentBottomSheet extends StatelessWidget {
  final String topicName;
  final String content;

  const _ContentBottomSheet({required this.topicName, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_stories_rounded,
                      color: Color(0xFF1565C0), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    topicName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Divider(color: Colors.grey[100], height: 20),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SelectableText(
                content.isNotEmpty ? content : 'No content available.',
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.7,
                  color: Color(0xFF2C2C2C),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionBottomSheet extends StatefulWidget {
  final Map<String, dynamic> question;
  final String topicName;

  const _QuestionBottomSheet({required this.question, required this.topicName});

  @override
  State<_QuestionBottomSheet> createState() => _QuestionBottomSheetState();
}

class _QuestionBottomSheetState extends State<_QuestionBottomSheet> {
  String? _selected;
  bool _showAnswer = false;

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final text =
        q['questionText'] as String? ?? q['question'] as String? ?? '';
    final options = {
      'A': q['optionA'] as String? ?? q['option_a'] as String? ?? '',
      'B': q['optionB'] as String? ?? q['option_b'] as String? ?? '',
      'C': q['optionC'] as String? ?? q['option_c'] as String? ?? '',
      'D': q['optionD'] as String? ?? q['option_d'] as String? ?? '',
    };
    final correct = (q['correctOption'] as String? ??
        q['correct'] as String? ??
        'A')
        .toUpperCase();
    final explanation = q['explanation'] as String? ?? '';
    final difficulty = q['difficulty'] as String? ?? 'Medium';
    final qtype = q['type'] as String? ?? '';

    final diffColors = {
      'Easy': const Color(0xFF2E7D32),
      'Medium': const Color(0xFFE65100),
      'Hard': const Color(0xFFD32F2F),
    };
    final diffColor = diffColors[difficulty] ?? Colors.grey;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: diffColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    difficulty,
                    style: TextStyle(
                        color: diffColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                if (qtype.isNotEmpty)
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      qtype,
                      style: const TextStyle(
                          color: Color(0xFF1565C0),
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                  ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Divider(color: Colors.grey[100], height: 20),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  for (final entry in options.entries) ...[
                    _OptionTile(
                      letter: entry.key,
                      text: entry.value,
                      selected: _selected == entry.key,
                      isCorrect: entry.key == correct,
                      showAnswer: _showAnswer,
                      onTap: _showAnswer
                          ? null
                          : () => setState(() => _selected = entry.key),
                    ),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 16),
                  if (!_showAnswer)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _selected == null
                            ? null
                            : () => setState(() => _showAnswer = true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0),
                          disabledBackgroundColor: Colors.grey[200],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('Check Answer',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    )
                  else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _selected == correct
                            ? const Color(0xFF2E7D32).withOpacity(0.08)
                            : Colors.red.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selected == correct
                              ? const Color(0xFF2E7D32).withOpacity(0.3)
                              : Colors.red.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _selected == correct
                                ? Icons.check_circle_rounded
                                : Icons.cancel_rounded,
                            color: _selected == correct
                                ? const Color(0xFF2E7D32)
                                : Colors.red,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _selected == correct
                                  ? 'Correct!'
                                  : 'Incorrect. Answer is $correct',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _selected == correct
                                    ? const Color(0xFF2E7D32)
                                    : Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (explanation.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.amber.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.lightbulb_outline_rounded,
                                    color: Colors.amber, size: 16),
                                SizedBox(width: 6),
                                Text('Explanation',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Colors.amber,
                                    )),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              explanation,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String letter;
  final String text;
  final bool selected;
  final bool isCorrect;
  final bool showAnswer;
  final VoidCallback? onTap;

  const _OptionTile({
    required this.letter,
    required this.text,
    required this.selected,
    required this.isCorrect,
    required this.showAnswer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor = Colors.grey.shade200;
    Color bgColor = Colors.grey.shade50;
    Color textColor = Colors.black87;
    Color letterBg = Colors.grey.shade200;
    Color letterFg = Colors.grey.shade600;

    if (showAnswer) {
      if (isCorrect) {
        borderColor = const Color(0xFF2E7D32).withOpacity(0.5);
        bgColor = const Color(0xFF2E7D32).withOpacity(0.08);
        textColor = const Color(0xFF2E7D32);
        letterBg = const Color(0xFF2E7D32);
        letterFg = Colors.white;
      } else if (selected && !isCorrect) {
        borderColor = Colors.red.withOpacity(0.5);
        bgColor = Colors.red.withOpacity(0.06);
        textColor = Colors.red;
        letterBg = Colors.red;
        letterFg = Colors.white;
      }
    } else if (selected) {
      borderColor = const Color(0xFF1565C0).withOpacity(0.5);
      bgColor = const Color(0xFF1565C0).withOpacity(0.06);
      textColor = const Color(0xFF1565C0);
      letterBg = const Color(0xFF1565C0);
      letterFg = Colors.white;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(color: letterBg, shape: BoxShape.circle),
              child: Center(
                child: Text(
                  letter,
                  style: TextStyle(
                    color: letterFg,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(fontSize: 13, color: textColor, height: 1.4),
              ),
            ),
            if (showAnswer && isCorrect)
              const Icon(Icons.check_rounded,
                  color: Color(0xFF2E7D32), size: 18),
            if (showAnswer && selected && !isCorrect)
              const Icon(Icons.close_rounded, color: Colors.red, size: 18),
          ],
        ),
      ),
    );
  }
}