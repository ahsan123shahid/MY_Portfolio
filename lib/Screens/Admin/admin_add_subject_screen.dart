import 'package:flutter/material.dart';
import '../../services/subject_service.dart';

class AdminAddSubjectScreen extends StatefulWidget {
  const AdminAddSubjectScreen({super.key});

  @override
  State<AdminAddSubjectScreen> createState() => _AdminAddSubjectScreenState();
}

class _AdminAddSubjectScreenState extends State<AdminAddSubjectScreen> {
  final SubjectService _service = SubjectService();
  final _formKey   = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  bool _loading    = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _service.addSubject(_nameCtrl.text.trim());
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: const Text('Add Subject'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withOpacity(0.07),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF1565C0).withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Color(0xFF1565C0)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'After creating a subject, you can upload lecture PDFs.\nAI will automatically extract topics and generate quiz questions.',
                        style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Input card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Subject Name',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A237E)),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameCtrl,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        hintText: 'e.g. Statistics, Calculus, Physics',
                        prefixIcon: const Icon(Icons.book_rounded, color: Color(0xFF1565C0)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF1565C0), width: 2),
                        ),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a subject name' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                      : const Text(
                    'Create Subject',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}