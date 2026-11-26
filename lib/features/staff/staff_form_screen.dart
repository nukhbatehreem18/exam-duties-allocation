import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/input_rules.dart';
import '../../models/staff.dart';
import 'staff_controller.dart';

class StaffFormScreen extends ConsumerStatefulWidget {
  /// If null, the form adds a new staff member. Otherwise it edits one.
  final String? staffId;
  const StaffFormScreen({super.key, this.staffId});

  @override
  ConsumerState<StaffFormScreen> createState() => _StaffFormScreenState();
}

class _StaffFormScreenState extends ConsumerState<StaffFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _dutiesCtrl = TextEditingController();
  final _hoursCtrl = TextEditingController();
  Staff? _existing;

  @override
  void initState() {
    super.initState();
    if (widget.staffId != null) {
      final list = ref.read(staffProvider);
      _existing = list.firstWhere((s) => s.id == widget.staffId);
      _nameCtrl.text = _existing!.name;
      _emailCtrl.text = _existing!.email;
      _dutiesCtrl.text = _existing!.maxDuties.toString();
      _hoursCtrl.text = (_existing!.maxMinutes ~/ 60).toString();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _dutiesCtrl.dispose();
    _hoursCtrl.dispose();
    super.dispose();
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'This field is required' : null;

  String? _emailRule(String? v) {
    final format = validateEmailFormat(v);
    if (format != null) return format;
    final taken =
        isEmailTaken(v!, ref.read(staffProvider), exceptId: _existing?.id);
    return taken ? 'This email is already used by another staff member' : null;
  }

  String? _dutiesRule(String? v) {
    final n = int.tryParse(v ?? '');
    if (n == null || n <= 0) return 'Enter a whole number above 0';
    if (n > maxAllowedDuties) {
      return 'Max duties cannot be more than $maxAllowedDuties';
    }
    return null;
  }

  String? _hoursRule(String? v) {
    final h = int.tryParse(v ?? '');
    if (h == null || h <= 0) return 'Enter a whole number above 0';
    final d = int.tryParse(_dutiesCtrl.text);
    if (d == null || d < 1 || d > maxAllowedDuties) return null;
    return validateDutyLimits(maxDuties: d, maxMinutes: h * 60);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final staff = Staff(
      id: _existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      maxDuties: int.parse(_dutiesCtrl.text),
      maxMinutes: int.parse(_hoursCtrl.text) * 60, // hours -> integer minutes
      availability: _existing?.availability ?? const [],
    );

    final controller = ref.read(staffProvider.notifier);
    _existing == null ? controller.add(staff) : controller.update(staff);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = _existing != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Staff' : 'Add Staff')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Name', border: OutlineInputBorder()),
                  validator: _required,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                      labelText: 'Email', border: OutlineInputBorder()),
                  validator: _emailRule,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _dutiesCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Max duties', border: OutlineInputBorder()),
                  validator: _dutiesRule,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _hoursCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Max duty hours',
                      border: OutlineInputBorder()),
                  validator: _hoursRule,
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