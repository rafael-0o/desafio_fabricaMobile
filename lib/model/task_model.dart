class Task {
  int id;
  String title;
  int completed;
  int? isSynced;
  String? syncMethod;

  Task(
      {required this.id,
      required this.title,
      required this.completed,
      this.isSynced,
      this.syncMethod});
  @override
  String toString() {
    return "Task Id-$id title is- $title  completed-${completed == 0 ? "No" : "Yes"}  "
        "isSynced-$isSynced  syncMethod-$syncMethod";
  }

  static Map<String, dynamic> taskToMap(Task task) {
    return {
      "id": task.id,
      "title": task.title,
      "completed": task.completed,
      "sync_method": task.syncMethod,
      "is_synced": task.isSynced
    };
  }
}
