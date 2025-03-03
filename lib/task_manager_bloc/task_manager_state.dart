part of 'task_manager_bloc.dart';

class TaskManagerState {
  int? completed;
  TaskManagerState({this.completed});
}

final class TaskInitialState extends TaskManagerState {
  List<Task>? tasks;
  TaskInitialState({required this.tasks});
}

final class TaskLoadingState extends TaskManagerState {
  String loadingReason;

  TaskLoadingState({required this.loadingReason});
}

final class TaskLoadedState extends TaskManagerState {
  List<Task> tasks;
  TaskLoadedState({required this.tasks});
}

final class TaskErrorState extends TaskManagerState {
  String error;
  TaskErrorState({required this.error});
}

final class CheckBoxState extends TaskManagerState {
  int? completed;
  CheckBoxState({required this.completed}) : super(completed: completed);
}
