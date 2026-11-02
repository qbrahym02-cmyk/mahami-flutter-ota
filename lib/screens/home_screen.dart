import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/remote_config_service.dart';
import '../services/task_repository.dart';
import '../services/update_service.dart';
import '../widgets/announcement_banner.dart';
import '../widgets/task_editor.dart';
import '../widgets/update_banner.dart';
import 'about_screen.dart';

enum Filter { all, active, done }

class HomeScreen extends StatefulWidget {
  final RemoteConfigService remoteConfig;
  final UpdateService updates;
  final TaskRepository repository;

  const HomeScreen({
    super.key,
    required this.remoteConfig,
    required this.updates,
    required this.repository,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Task> _tasks = [];
  bool _loading = true;
  Filter _filter = Filter.all;

  RemoteConfig get cfg => widget.remoteConfig.config;

  @override
  void initState() {
    super.initState();
    widget.remoteConfig.addListener(_onConfig);
    _load();
  }

  @override
  void dispose() {
    widget.remoteConfig.removeListener(_onConfig);
    super.dispose();
  }

  void _onConfig() => setState(() {});

  Future<void> _load() async {
    final tasks = await widget.repository.load();
    if (!mounted) return;
    setState(() {
      _tasks = tasks;
      _loading = false;
    });
  }

  Future<void> _persist() => widget.repository.save(_tasks);

  List<Task> get _visible {
    final list = switch (_filter) {
      Filter.all => _tasks,
      Filter.active => _tasks.where((t) => !t.done).toList(),
      Filter.done => _tasks.where((t) => t.done).toList(),
    };
    // غير المكتملة أولاً، ثم حسب الأولوية، ثم الأحدث
    final sorted = [...list]..sort((a, b) {
        if (a.done != b.done) return a.done ? 1 : -1;
        final p = b.priority.index.compareTo(a.priority.index);
        if (p != 0) return p;
        return b.createdAt.compareTo(a.createdAt);
      });
    return sorted;
  }

  Future<void> _add() async {
    final task = await showTaskEditor(context,
        showPriority: cfg.showPriority, quickTasks: cfg.quickTasks);
    if (task == null) return;
    setState(() => _tasks.add(task));
    _persist();
  }

  Future<void> _edit(Task t) async {
    final updated = await showTaskEditor(context,
        existing: t, showPriority: cfg.showPriority);
    if (updated == null) return;
    setState(() {
      final i = _tasks.indexWhere((x) => x.id == t.id);
      if (i != -1) _tasks[i] = updated;
    });
    _persist();
  }

  void _toggle(Task t) {
    setState(() {
      final i = _tasks.indexWhere((x) => x.id == t.id);
      if (i != -1) _tasks[i] = t.copyWith(done: !t.done);
    });
    _persist();
  }

  Future<bool> _confirmDelete(Task t) async {
    if (!cfg.confirmDelete) return true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('حذف المهمة؟'),
        content: Text(t.title),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('إلغاء')),
          FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('حذف')),
        ],
      ),
    );
    return ok ?? false;
  }

  void _delete(Task t) {
    final index = _tasks.indexWhere((x) => x.id == t.id);
    if (index == -1) return;
    setState(() => _tasks.removeAt(index));
    _persist();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('تم حذف "${t.title}"'),
        action: SnackBarAction(
          label: 'تراجع',
          onPressed: () {
            setState(() => _tasks.insert(index.clamp(0, _tasks.length), t));
            _persist();
          },
        ),
      ));
  }

  void _clearCompleted() {
    final removed = _tasks.where((t) => t.done).length;
    if (removed == 0) return;
    setState(() => _tasks.removeWhere((t) => t.done));
    _persist();
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم حذف $removed مهمة مكتملة')));
  }

  Future<void> _pullToRefresh() async {
    await Future.wait([
      widget.remoteConfig.refresh(),
      widget.updates.check(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    if (cfg.maintenanceEnabled) return _Maintenance(message: cfg.maintenanceMessage);

    final done = _tasks.where((t) => t.done).length;
    final visible = _visible;

    return Scaffold(
      appBar: AppBar(
        title: Text(cfg.appTitle),
        actions: [
          IconButton(
            tooltip: 'حذف المكتملة',
            onPressed: done == 0 ? null : _clearCompleted,
            icon: const Icon(Icons.cleaning_services_outlined),
          ),
          IconButton(
            tooltip: 'حول التطبيق والتحديثات',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AboutScreen(
                    remoteConfig: widget.remoteConfig,
                    updates: widget.updates),
              ),
            ),
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: const Text('مهمة'),
      ),
      body: RefreshIndicator(
        onRefresh: _pullToRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: UpdateBanner(updates: widget.updates)),
            if (cfg.announcementEnabled && cfg.announcementText.isNotEmpty)
              SliverToBoxAdapter(
                child: AnnouncementBanner(
                    text: cfg.announcementText, type: cfg.announcementType),
              ),
            if (cfg.showStats && _tasks.isNotEmpty)
              SliverToBoxAdapter(
                  child: _StatsCard(total: _tasks.length, done: done)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: SegmentedButton<Filter>(
                  segments: const [
                    ButtonSegment(value: Filter.all, label: Text('الكل')),
                    ButtonSegment(value: Filter.active, label: Text('النشطة')),
                    ButtonSegment(value: Filter.done, label: Text('المكتملة')),
                  ],
                  selected: {_filter},
                  onSelectionChanged: (s) => setState(() => _filter = s.first),
                ),
              ),
            ),
            if (_loading)
              const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()))
            else if (visible.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.checklist_rtl,
                            size: 72,
                            color: Theme.of(context).colorScheme.outline),
                        const SizedBox(height: 12),
                        Text(
                          _tasks.isEmpty ? cfg.emptyMessage : 'لا شيء هنا',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 96),
                sliver: SliverList.builder(
                  itemCount: visible.length,
                  itemBuilder: (context, i) {
                    final t = visible[i];
                    return Dismissible(
                      key: ValueKey(t.id),
                      background: Container(
                        color: Theme.of(context).colorScheme.errorContainer,
                        alignment: AlignmentDirectional.centerStart,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete_outline),
                      ),
                      confirmDismiss: (_) => _confirmDelete(t),
                      onDismissed: (_) => _delete(t),
                      child: _TaskTile(
                        task: t,
                        showPriority: cfg.showPriority,
                        onToggle: () => _toggle(t),
                        onEdit: () => _edit(t),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final Task task;
  final bool showPriority;
  final VoidCallback onToggle;
  final VoidCallback onEdit;

  const _TaskTile({
    required this.task,
    required this.showPriority,
    required this.onToggle,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (task.priority) {
      Priority.high => scheme.error,
      Priority.medium => scheme.primary,
      Priority.low => scheme.outline,
    };
    return ListTile(
      leading: Checkbox(value: task.done, onChanged: (_) => onToggle()),
      title: Text(
        task.title,
        style: TextStyle(
          decoration: task.done ? TextDecoration.lineThrough : null,
          color: task.done ? scheme.outline : null,
        ),
      ),
      subtitle: showPriority
          ? Row(children: [
              Icon(Icons.flag, size: 14, color: color),
              const SizedBox(width: 4),
              Text('أولوية ${task.priority.label}',
                  style: TextStyle(color: color, fontSize: 12)),
            ])
          : null,
      trailing: IconButton(
          onPressed: onEdit, icon: const Icon(Icons.edit_outlined)),
      onTap: onToggle,
    );
  }
}

class _StatsCard extends StatelessWidget {
  final int total;
  final int done;
  const _StatsCard({required this.total, required this.done});

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : done / total;
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          SizedBox(
            width: 52,
            height: 52,
            child: Stack(alignment: Alignment.center, children: [
              CircularProgressIndicator(value: ratio, strokeWidth: 6),
              Text('${(ratio * 100).round()}%',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('أنجزت $done من $total',
                    style: Theme.of(context).textTheme.titleMedium),
                Text(
                  done == total ? 'رائع! أنهيت كل شيء 🎉' : 'متبقي ${total - done}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _Maintenance extends StatelessWidget {
  final String message;
  const _Maintenance({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.construction, size: 72),
            const SizedBox(height: 16),
            Text(message.isEmpty ? 'التطبيق تحت الصيانة' : message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium),
          ]),
        ),
      ),
    );
  }
}
