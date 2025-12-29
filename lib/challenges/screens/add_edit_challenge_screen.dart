import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/challenge_controller.dart';
import '../models/challenge_model.dart';

class AddEditChallengeScreen extends StatefulWidget {
  final String categoryId;
  final ChallengeModel? challenge;

  const AddEditChallengeScreen({super.key, required this.categoryId, this.challenge});

  @override
  State<AddEditChallengeScreen> createState() => _AddEditChallengeScreenState();
}

class _AddEditChallengeScreenState extends State<AddEditChallengeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _types = const ['daily', 'weekly', 'monthly', 'yearly', 'custom'];
  late String _selectedType;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.challenge?.type ?? 'daily';
    _titleCtrl.text = widget.challenge?.title ?? '';
    _startDate = widget.challenge?.startDate;
    _endDate = widget.challenge?.endDate;
  }

  void _resetForm() {
    _titleCtrl.clear();
    _selectedType = 'daily';
    _startDate = null;
    _endDate = null;
    _formKey.currentState?.reset();
    setState(() {});
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ChallengeController>();
    final isEdit = widget.challenge != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Challenge' : 'Create Challenge')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Challenge Title', hintText: 'e.g. 30-Day Deen Revival'),
              validator: (v) {
                if (v == null || v.trim().length < 3) return 'Enter a title (min 3 chars)';
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedType,
              items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t.toUpperCase()))).toList(),
              onChanged: (v) => setState(() => _selectedType = v ?? _selectedType),
              decoration: const InputDecoration(labelText: 'Type'),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _DatePickerField(label: 'Start Date', date: _startDate, onPick: (d) => setState(() => _startDate = d))),
              const SizedBox(width: 12),
              Expanded(child: _DatePickerField(label: 'End Date', date: _endDate, onPick: (d) => setState(() => _endDate = d))),
            ]),
            const SizedBox(height: 24),
            Obx(() {
              final loading = controller.isLoading;
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: loading ? null : () async {
                    if (!_formKey.currentState!.validate()) return;
                    if (_startDate != null && _endDate != null && _endDate!.isBefore(_startDate!)) {
                      Get.snackbar('Invalid dates', 'End date cannot be before start date', snackPosition: SnackPosition.BOTTOM);
                      return;
                    }
                    if (isEdit) {
                      final ok = await controller.updateChallenge(
                        challengeId: widget.challenge!.id,
                        title: _titleCtrl.text.trim(),
                        type: _selectedType,
                        startDate: _startDate,
                        endDate: _endDate,
                      );
                      if (ok) {
                        await Future.delayed(const Duration(milliseconds: 1500));
                        Get.back();
                      }
                    } else {
                      final ok = await controller.create(
                        categoryId: widget.categoryId,
                        title: _titleCtrl.text.trim(),
                        type: _selectedType,
                        startDate: _startDate,
                        endDate: _endDate,
                      );
                      if (ok) {
                        // Reset the form for the next input
                        _resetForm();
                        await Future.delayed(const Duration(milliseconds: 1500));
                        Get.back();
                      }
                    }
                  },
                  icon: Icon(isEdit ? Icons.save : Icons.add_task),
                  label: Text(isEdit ? 'Save Changes' : 'Create Challenge'),
                ),
              );
            }),
          ]),
        ),
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final ValueChanged<DateTime?> onPick;

  const _DatePickerField({required this.label, required this.date, required this.onPick});

  @override
  Widget build(BuildContext context) {
    String text;
    if (date == null) {
      text = 'Select';
    } else {
      text = '${date!.year}-${date!.month.toString().padLeft(2, '0')}-${date!.day.toString().padLeft(2, '0')}';
    }
    return InputDecorator(
      decoration: const InputDecoration(labelText: 'Date', border: OutlineInputBorder()),
      child: InkWell(
        onTap: () async {
          final now = DateTime.now();
          final picked = await showDatePicker(
            context: context,
            initialDate: date ?? now,
            firstDate: DateTime(now.year - 5),
            lastDate: DateTime(now.year + 5),
          );
          onPick(picked);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, size: 18),
              const SizedBox(width: 8),
              Text(text),
            ],
          ),
        ),
      ),
    );
  }
}
