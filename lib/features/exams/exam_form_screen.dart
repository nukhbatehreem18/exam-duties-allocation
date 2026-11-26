import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/exam_session.dart';
import 'exam_controller.dart';

class ExamFormScreen extends ConsumerStatefulWidget {
  /// If null, the form adds a new exam. Otherwise it edits one.
  final String? examId;
  const ExamFormScreen({super.key, this.examId});

  @override
  ConsumerState<ExamFormScreen> createState() => _ExamFormScreenState();
}

class _ExamFormScreenState extends ConsumerState<ExamFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _courseCtrl = TextEditingController();
  final _roomCtrl = TextEditingController();
  final _requiredCtrl = TextEditingController();
  DateTime? _date;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  ExamSession? _existing;

  @override
  void initState() {
    super.initState();
    if (widget.examId != null) {
      final e =
          ref.read(examProvider).firstWhere((x) => x.id == widget.examId);
      _existing = e;
      _courseCtrl.text = e.course;
      _roomCtrl.text = e.room;
      _requiredCtrl.text = e.requiredInvigilators.toString();
      _date = DateTime(e.start.year, e.start.month, e.start.day);
      _startTime = TimeOfDay.fromDateTime(e.start);
      _endTime = TimeOfDay.fromDateTime(e.end);
    }
  }

  @override
  void dispose() {
    _courseCtrl.dispose();
    _roomCtrl.dispose();
    _requiredCtrl.dispose();
    super.dispose();
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'This field is required' : null;

  String? _positiveInt(String? v) {
    final n = int.tryParse(v ?? '');
    return (n == null || n <= 0) ? 'Enter a whole number above 0' : null;
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime(2026),
      lastDate: DateTime(2030),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickTime({required bool isStart}) async {
    final t = await showTimePicker(
      context: context,
      initialTime: (isStart ? _startTime : _endTime) ??
          const TimeOfDay(hour: 9, minute: 0),
    );
    if (t == null) return;
    setState(() {
      if (isStart) {
        _startTime = t;
      } else {
        _endTime = t;
      }
    });
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_date == null || _startTime == null || _endTime == null) {
      _showMessage('Please choose the date, start time and end time');
      return;
    }

    final start = DateTime(_date!.year, _date!.month, _date!.day,
        _startTime!.hour, _startTime!.minute);
    final end = DateTime(_date!.year, _date!.month, _date!.day,
        _endTime!.hour, _endTime!.minute);

    if (!end.isAfter(start)) {
      _showMessage('End time must be after start time');
      return;
    }

    final exam = ExamSession(
      id: _existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      course: _courseCtrl.text.trim(),
      room: _roomCtrl.text.trim(),
      start: start,
      end: end,
      requiredInvigilators: int.parse(_requiredCtrl.text),
    );

    final controller = ref.read(examProvider.notifier);
    _existing == null ? controller.add(exam) : controller.update(exam);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('EEE, d MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title:
            Text(_existing == null ? 'Add Exam Session' : 'Edit Exam Session'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                TextFormField(
                  controller: _courseCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Course', border: OutlineInputBorder()),
                  validator: _required,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _roomCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Room', border: OutlineInputBorder()),
                  validator: _required,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _requiredCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Required invigilators',
                      border: OutlineInputBorder()),
                  validator: _positiveInt,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                      _date == null ? 'Choose date' : dateFmt.format(_date!)),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _pickTime(isStart: true),
                  icon: const Icon(Icons.schedule),
                  label: Text(_startTime == null
                      ? 'Choose start time'
                      : 'Start: ${_startTime!.format(context)}'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _pickTime(isStart: false),
                  icon: const Icon(Icons.schedule),
                  label: Text(_endTime == null
                      ? 'Choose end time'
                      : 'End: ${_endTime!.format(context)}'),
                ),
                const SizedBox(height: 24),
                FilledButton(onPressed: _save, child: const Text('Save')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}