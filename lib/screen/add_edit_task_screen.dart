import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:desafio_fabrica/screen/home_screen.dart';
import 'package:desafio_fabrica/task_manager_bloc/task_manager_bloc.dart';

import '../model/task_model.dart';

class AddOrEditTaskScreen extends StatelessWidget {
  Task? currentTask;

  AddOrEditTaskScreen({super.key, this.currentTask});

  @override
  Widget build(BuildContext context) {
    if (currentTask == null) {
      TextEditingController? textTileController = TextEditingController();
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.cyanAccent,
          title: const Text("Add new Task"),
          actions: [logoutButton(context)],
        ),
        body: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10.0),
              TextField(
                controller: textTileController,
                decoration: const InputDecoration(
                    hintText: "Enter the task", border: OutlineInputBorder()),
              ),
              const SizedBox(
                height: 10.0,
              ),
              MaterialButton(
                onPressed: () {
                  print(
                      "Current Task getting returned is ${textTileController.text}");
                  Navigator.pop(context, textTileController.text);
                },
                color: Colors.green,
                child: const Text("Add"),
              )
            ],
          ),
        ),
      );
    }

    ///If the current task is not null means We are updating the task (ref-Look in HomeScree() inside FloatingActionButton)
    else {
      TextEditingController textTileController =
          TextEditingController(text: currentTask?.title);
      return BlocProvider(
        create: (context) => TaskManagerBloc(),
        child: BlocBuilder<TaskManagerBloc, TaskManagerState>(
            builder: (context, state) {
          state.completed = currentTask?.completed ?? 0;
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.cyanAccent,
              title: const Text("Update Task"),
              actions: [logoutButton(context)],
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10.0),
                TextField(
                  controller: textTileController,
                  onChanged: (value) {
                    currentTask?.title = value;
                  },
                  decoration: const InputDecoration(
                      hintText: "Enter the task", border: OutlineInputBorder()),
                ),
                const SizedBox(
                  height: 10.0,
                ),
                CheckboxListTile(
                  value: state.completed == 1,
                  title: const Text("Completed -"),
                  onChanged: (value) {
                    currentTask?.completed =
                        currentTask?.completed == 1 ? 0 : 1;
                    print(
                        "CheckBox in update task sreen - ${currentTask?.completed}");
                    context
                        .read<TaskManagerBloc>()
                        .add(CheckboxEvent(completed: currentTask!.completed));
                  },
                ),
                MaterialButton(
                  onPressed: () {
                    print(
                        "textTileController.text is -${textTileController.text}");
                    print(
                        "Completed Before reassigning with state.completed ${currentTask?.completed}");
                    currentTask?.completed = state.completed!;
                    print(
                        "Completed after reassigning with state.completed ${currentTask?.completed}");
                    print(
                        "Current Task getting returned before popping the screen back is $currentTask");

                    Navigator.pop(context, currentTask);
                  },
                  color: Colors.green,
                  child: const Text("Update"),
                )
              ],
            ),
          );
        }),
      );
    }
  }
}
