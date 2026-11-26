import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../domain/input_rules.dart';
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

  DateTime _combine(DateTime date, TimeOfDay t) =>
      DateTime(date.year, date.month, date.day, t.hour, t.minute);

  /// Past check for a start time. An unchanged start of an existing exam
  /// is always accepted, so old exams can still be edited.
  String? _checkPast(DateTime start) {
    if (_existing != null && start == _existing!.start) return null;
    return validateNotInPast(start, DateTime.now());
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Past dates cannot be chosen (except the date of an existing old exam).
    final first = (_date != null && _date!.isBefore(today)) ? _date! : today;

    final d = await showDatePicker(
      context: context,
      initialDate: _date ?? today,
      firstDate: first,
      lastDate: DateTime(2030),
    );
    if (d == null || !mounted) return;

    var cleared = false;
    setState(() {
      _date = d;
      if (_startTime != null && _checkPast(_combine(d, _startTime!)) != null) {
        _startTime = null;
        _endTime = null;
        cleared = true;
      }
    });
    if (cleared) {
      _showMessage('Times were cleared because they are in the past. '
          'Please choose them again.');
    }
  }

  Future<void> _pickTime({required bool isStart}) async {
    if (_date == null) {
      _showMessage('Please choose the date first');
      return;
    }
    if (!isStart && _startTime == null) {
      _showMessage('Please choose the start time first');
      return;
    }

    final t = await showTimePicker(
      context: context,
      initialTime: (isStart ? _startTime : _endTime) ??
          const TimeOfDay(hour: 9, minute: 0),
    );
    if (t == null || !mounted) return;

    final picked = _combine(_date!, t);

    if (isStart) {
      final pastError = _checkPast(picked);
      if (pastError != null) {
        _showMessage(pastError);
        return;
      }
      var cleared = false;
      setState(() {
        _startTime = t;
        if (_endTime != null && !_combine(_date!, _endTime!).isAfter(picked)) {
          _endTime = null;
          cleared = true;
        }
      });
      if (cleared) {
        _showMessage('End time was cleared. Please choose it again.');
      }
    } else {
      final start = _combine(_date!, _startTime!);
      final error = validateExamTimes(
          start: start, end: picked, now: DateTime.now(), checkPast: false);
      if (error != null) {
        _showMessage(error);
        return;
      }
      setState(() => _endTime = t);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_date == null || _startTime == null || _endTime == null) {
      _showMessage('Please choose the date, start time and end time');
      return;
    }

    final start = _combine(_date!, _startTime!);
    final end = _combine(_date!, _endTime!);

    final timeChanged =
        _existing == null || start != _existing!.start || end != _existing!.end;
    final timeError = validateExamTimes(
        start: start, end: end, now: DateTime.now(), checkPast: timeChanged);
    if (timeError != null) {
      _showMessage(timeError);
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

    final clash =
        validateRoomClash(candidate: exam, existing: ref.read(examProvider));
    if (clash != null) {
      _showMessage(clash);
      return;
    }

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