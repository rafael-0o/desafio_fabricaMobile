import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:desafio_fabrica/database_service/database_service.dart';
import 'package:desafio_fabrica/model/task_model.dart';
import 'package:desafio_fabrica/screen/add_edit_task_screen.dart';
import 'package:desafio_fabrica/screen/login_screen.dart';
import 'package:desafio_fabrica/task_manager_bloc/task_manager_bloc.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    print("Calling init() ");
    context.read<TaskManagerBloc>().add(LoadTaskEvent());
  }

  @override
  Widget build(BuildContext context) {
    print("Started HomeScreen or task loading screen");
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.cyanAccent,
        title: const Text("Task Manager"),
        actions: [
          logoutButton(context),
        ],
      ),
      body: BlocBuilder<TaskManagerBloc, TaskManagerState>(
        builder: (context, state) {
          print("Entered bloc builder");

          ///If the Tasks are fetching from api or db or getting added into db we will emit TaskLoading state
          if (state is TaskLoadingState) {
            print("Loading screen Appired");
            return getLoadingScreen(state.loadingReason);
          }

          ///If fetching or adding task is done we will emit the Task Loaded state
          else if (state is TaskLoadedState) {
            print("${state.tasks.length} number of Tasks came into UI");
            return getListView(state.tasks, context);
          }

          ///If there are any error or exception occured while loading the data we will emit the TaskErrorState
          else if (state is TaskErrorState) {
            print("App is facing some error");
            return getTaskErrorScreen(state.error);
          }

          ///If there are no data in the state we will show no data found or tasks to show
          else {
            print("There are no task in the database");
            return const Center(child: Text("No Task to show"));
          }
        },
      ),
      floatingActionButton: getFloatingActionButton(context),
    );
  }

  Widget getTaskErrorScreen(String error) {
    return Center(
      child: Text(error),
    );
  }
}

///Uses the List given form the TaskLoadedState instance and build the List View with a Refresh Indicator
Widget getListView(List<Task> tasks, BuildContext context) {
  return ListView.builder(
    itemCount: tasks.length,
    itemBuilder: (context, index) {
      Task? currentTask = tasks[index];
      return Container(
        color: currentTask.completed == 1
            ? const Color(0xffB6EDB8)
            : Colors.white70,
        child: ListTile(
          contentPadding: const EdgeInsets.only(left: 16.0),
          title: Text(
            currentTask.title,
            textAlign: TextAlign.start,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: SizedBox(
              child: Container(
            color: getSyncColor(currentTask),
            width: 10.0,
            height: double.infinity,
          )),
          onTap: () async {
            var updatedTask = await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        AddOrEditTaskScreen(currentTask: currentTask)));
            context
                .read<TaskManagerBloc>()
                .add(UpdateTaskEvent(task: updatedTask));
          },
        ),
      );
    },
  );
}

///If the UI is in TaskLoading State it will take the appropriate reason and
///show the loading screen in UI so that User will get to know something is happening in the background
Widget getLoadingScreen(String loadingReason) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(
          color: Colors.black45,
        ),
        Text(loadingReason)
      ],
    ),
  );
}

Widget logoutButton(BuildContext context) {
  return MaterialButton(
    onPressed: () async {
      DatabaseService databaseService = DatabaseService.databaseService;
      print("Please wait while logging out");
      SharedPreferences sharedPreferences =
          await SharedPreferences.getInstance();
      await sharedPreferences.setBool("isLoggedIn", false);
      print("Deleting all the data from the database");
      await databaseService.deleteAllTaskFromDb();
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ));
    },
    highlightColor: Colors.black,
    shape: const CircleBorder(),
    child: const Icon(
      Icons.logout_outlined,
    ),
  );
}

Widget getFloatingActionButton(BuildContext context) {
  return FloatingActionButton(
    onPressed: () async {
      final task = await Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => AddOrEditTaskScreen(),
      ));
      context.read<TaskManagerBloc>().add(AddTaskEvent(task: task));
      print("New task came from add new screen is $task");
    },
    child: const Icon(Icons.add),
  );
}

Color? getSyncColor(Task task) {
  Color? syncColor;
  if (task.isSynced == 0) {
    syncColor = Colors.orange;
  } else if (task.isSynced == 1) {
    syncColor = null;
  } else {
    syncColor = Colors.red;
  }
  return syncColor;
}
