import 'package:flutter/material.dart';

import '../models/task.dart';

/// نافذة سفلية لإضافة مهمة أو تعديلها.
/// تُرجع Task جديدة/معدّلة أو null عند الإلغاء.
Future<Task?> showTaskEditor(
  BuildContext context, {
  Task? existing,
  bool showPriority = true,
  List<String> quickTasks = const [],
}) {
  return showModalBottomSheet<Task>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _TaskEditor(
      existing: existing,
      showPriority: showPriority,
      quickTasks: quickTasks,
    ),
  );
}

class _TaskEditor extends StatefulWidget {
  final Task? existing;
  final bool showPriority;
  final List<String> quickTasks;
  const _TaskEditor(
      {this.existing, required this.showPriority, required this.quickTasks});

  @override
  State<_TaskEditor> createState() => _TaskEditorState();
}

class _TaskEditorState extends State<_TaskEditor> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.existing?.title ?? '');
  late Priority _priority = widget.existing?.priority ?? Priority.medium;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    final result = widget.existing == null
        ? Task.create(text, priority: _priority)
        : widget.existing!.copyWith(title: text, priority: _priority);
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 0, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(isEdit ? 'تعديل المهمة' : 'مهمة جديدة',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: const InputDecoration(
              hintText: 'ماذا تريد أن تنجز؟',
              border: OutlineInputBorder(),
            ),
          ),
          if (!isEdit && widget.quickTasks.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final q in widget.quickTasks)
                  ActionChip(
                    avatar: const Icon(Icons.bolt, size: 16),
                    label: Text(q),
                    onPressed: () => setState(() => _ctrl.text = q),
                  ),
              ],
            ),
          ],
          if (widget.showPriority) ...[
            const SizedBox(height: 12),
            SegmentedButton<Priority>(
              segments: [
                for (final p in Priority.values)
                  ButtonSegment(value: p, label: Text(p.label)),
              ],
              selected: {_priority},
              onSelectionChanged: (s) => setState(() => _priority = s.first),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _submit,
            child: Text(isEdit ? 'حفظ' : 'إضافة'),
          ),
        ],
      ),
    );
  }
}
