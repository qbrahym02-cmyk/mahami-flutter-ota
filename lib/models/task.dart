enum Priority { low, medium, high }

extension PriorityLabel on Priority {
  String get label => switch (this) {
        Priority.low => 'منخفضة',
        Priority.medium => 'متوسطة',
        Priority.high => 'عالية',
      };
}

class Task {
  final String id;
  final String title;
  final bool done;
  final Priority priority;
  final DateTime createdAt;

  const Task({
    required this.id,
    required this.title,
    this.done = false,
    this.priority = Priority.medium,
    required this.createdAt,
  });

  factory Task.create(String title, {Priority priority = Priority.medium}) {
    final now = DateTime.now();
    return Task(
      id: '${now.microsecondsSinceEpoch}',
      title: title.trim(),
      priority: priority,
      createdAt: now,
    );
  }

  Task copyWith({String? title, bool? done, Priority? priority}) => Task(
        id: id,
        title: title ?? this.title,
        done: done ?? this.done,
        priority: priority ?? this.priority,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'done': done,
        'priority': priority.index,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'] as String,
        title: json['title'] as String,
        done: json['done'] as bool? ?? false,
        priority: Priority.values[
            ((json['priority'] as int?) ?? 1).clamp(0, Priority.values.length - 1)],
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}
