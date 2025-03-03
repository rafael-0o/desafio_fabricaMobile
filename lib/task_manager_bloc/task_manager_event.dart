part of 'task_manager_bloc.dart';

@immutable
sealed class TaskEvent {}

class LoadTaskEvent extends TaskEvent {}

class AddTaskEvent extends TaskEvent {
  String task;
  AddTaskEvent({required this.task});
}

class UpdateTaskEvent extends TaskEvent {
  Task task;
  UpdateTaskEvent({required this.task});
}

class SyncTaskEvent extends TaskEvent {
  SendPort syncSendPort;
  SyncTaskEvent({required this.syncSendPort});
}

class SyncRefreshEvent extends TaskEvent {}

class CheckboxEvent extends TaskEvent {
  int completed;
  CheckboxEvent({required this.completed});
}
