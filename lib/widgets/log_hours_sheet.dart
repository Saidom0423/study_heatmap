import 'package:flutter/material.dart';
import '../services/study_service.dart';

class LogHoursSheet extends StatefulWidget {
  final VoidCallback onLogged;
  const LogHoursSheet({super.key, required this.onLogged});

  @override
  State<LogHoursSheet> createState() => _LogHoursSheetState();
}

class _LogHoursSheetState extends State<LogHoursSheet> {
  double _hours = 1.0;
  final _notesCtrl = TextEditingController();
  bool _loading = false;
  final _service = StudyService();

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await _service.logHours(_hours, notes: _notesCtrl.text);
      widget.onLogged();
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(
        color: Color(0xFF16213E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Log Today's Study",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              '${_hours.toStringAsFixed(1)} hours',
              style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF39D97E)),
            ),
          ),
          Slider(
            value: _hours,
            min: 0.5,
            max: 12,
            divisions: 23,
            activeColor: const Color(0xFF39D97E),
            onChanged: (v) => setState(() => _hours = v),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesCtrl,
            decoration: const InputDecoration(
              labelText: 'What did you study? (optional)',
              prefixIcon: Icon(Icons.notes),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loading ? null : _save,
            child: _loading
                ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2))
                : const Text(
              'Save',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}