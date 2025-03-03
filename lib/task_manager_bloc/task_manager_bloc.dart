import 'dart:isolate';

import 'package:bloc/bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:desafio_fabrica/api_client/api_service.dart';
import 'package:desafio_fabrica/database_service/database_service.dart';
import 'package:desafio_fabrica/model/task_model.dart';

part 'task_manager_event.dart';
part 'task_manager_state.dart';

class TaskManagerBloc extends Bloc<TaskEvent, TaskManagerState> {
  DatabaseService databaseService = DatabaseService.databaseService;
  TaskManagerBloc() : super(TaskManagerState()) {
    ///For the first time if we are opening the app and logging in
    on<LoadTaskEvent>((event, emit) async {
      try {
        List<Task> fetchedTasks = [];

        ///We will show loading screen to user when we will be getting the data from api and saving it in database
        emit(TaskLoadingState(
            loadingReason: 'Please wait till we get all Tasks from API'));

        fetchedTasks = await databaseService.getAllTask();
        print("Length of the fetched task is ${fetchedTasks.length}");

        if (fetchedTasks.isEmpty || fetchedTasks == []) {
          ///Fetching the Tasks from API
          fetchedTasks = await ApiService.fetchTasks();
          print("Got tasks from API and length is -${fetchedTasks.length}");

          if (fetchedTasks == [] || fetchedTasks.isEmpty) {
            emit(TaskErrorState(
                error:
                    "There was an error while fetching data check for the internet connection please"));
          } else {
            print(
                "Number of tasks getting inserted into db is ${fetchedTasks.length}");

            ///Inserting all the tasks which we got from API into the database
            await databaseService.addTaskToDatabase(fetchedTasks);
            print("Added all fetched tasks to the Database");
            print("Updating the state ");

            List<Task> allTasks = await databaseService.getAllTask();

            ///Once the insertion is done we will show the user all the tasks so emitting the LoadedState
            emit(TaskLoadedState(tasks: allTasks));
          }
        } else {
          ///Once data is present we will show the user all the tasks so emitting the LoadedState
          emit(TaskLoadedState(tasks: fetchedTasks));
        }
      }

      ///Just in case if we hvae any error we have to handle it using try and catch block
      catch (e) {
        print("Error while LoadTaskEvent error is- $e");
        emit(TaskErrorState(error: "No tasks found"));
      }
    });

    on<AddTaskEvent>((event, emit) async {
      print("Inside Add Task Event and emitting TaskLoadingState");
      try {
        ///Once we add a new Task into the List we must show loading screen until inserting into database is done
        emit(TaskLoadingState(
            loadingReason: "Please wait while we add new your task"));

        print("Adding this task to database");

        ///Adding the new Task entered into database
        int newTaskId = await databaseService.addNewTask(event.task);
        print("Id of the new Task got added into db is $newTaskId");

        ///after insertion is done we will fetch all data from the database
        List<Task>? tasks = await databaseService.getAllTask();
        print("Task length while emitting is ${tasks.length}");

        ///Once we got all Tasks we will now update it in UI so emitting TaskLoadedState
        emit(TaskLoadedState(tasks: tasks));
      } catch (e) {
        print("Error while Add Task Event");

        ///Justin case any exception occurs in this AddTaskEvent we will emit the TaskErrorState
        emit(TaskErrorState(error: e.toString()));
      }
    });

    on<UpdateTaskEvent>((event, emit) async {
      try {
        print("Calling UpdateTaskEvent");

        ///While updating the task we will show the loading screen to user
        emit(TaskLoadingState(
            loadingReason: "Please wait while updating the task"));
        // Future.delayed(const Duration(seconds: 2));
        print("Updating the data in DB");

        ///Saving the updated task into db and updating the same through the PUT API
        await databaseService.updateTaskInDB(event.task);
        List<Task> tasksFromDB = await databaseService.getAllTask();

        ///Emitting loaded state to show all updated tasks
        emit(TaskLoadedState(tasks: tasksFromDB));
      } catch (e) {
        print("Error occurred while updating the task in UpdateTasEvent");

        ///There is some error which occurred while UpdateTaskEvent so we will show user the error state
        emit(TaskErrorState(error: e.toString()));
      }
    });

    on<SyncTaskEvent>((event, emit) async {
      try {
        print("Inside bloc of SyncTaskEvent");

        ///We will check for unsynced tasks and return it
        List<Task> tasks = await databaseService.unSyncedTasks();
        print("Tasks came into the bloc are-$tasks");

        ///We will get 2 types of unsynced data where we will have newly added and updated unsynced tasks
        for (Task task in tasks) {
          ///task.syncMethod is "UPDATE" means it is the Updated task and we need only to update isSynced database
          if (task.syncMethod == "UPDATE") {
            ///Hit PUT Api and update in database
            int statusCode = await ApiService.syncUpdatedTask(task);

            ///If status code is 200 we can consider it as a positive case
            if (statusCode == 200) {
              await databaseService.updateIsSynced(
                  task, 1); //1 because it is synced
              event.syncSendPort.send("message");
            }

            ///If not the 200 we can consider it as a negative case so we can update it as a error state so isSynced is 2
            else {
              await databaseService.updateIsSynced(
                  task, 2); // 2 because it met with an error
              event.syncSendPort.send("message");
            }
          }

          ///task.syncMethod is not "UPDATE" means it is "ADD" so, it is the Newly added task and we need to update isSynced and syncMethod in the database
          else {
            int statusCode = await ApiService.syncAddNewTask(task);

            ///If status code is 201 It says created new entry using the POST api so this is considered as success response
            if (statusCode == 201) {
              ///Change the sync_method to UPDATE and isSynced as 1
              await databaseService.updateSyncMethodAndIsSynced(task);

              ///After the work is done we say the syncing is donne and we can update the UI accordingly
              event.syncSendPort.send("message");
            }

            ///If not 200 then an error occurred while hitting POST Api
            else {
              ///If not 200 then we will have to consider it as a negative response and and isSynced must get changed to 2
              print(
                  "There was an error in hitting the API and status code came is $statusCode");
              databaseService.updateIsSynced(task, 2);
            }
          }
        }
      } catch (e) {
        ///Justin case any exception occurs in this SyncTaskEvent we will not emit the TaskErrorState
        ///because it is running in background
      }
    });

    on<CheckboxEvent>((event, emit) {
      try {
        print("Entered CheckBoxEvent");

        ///Emit the completed as  0/1 respectively for checkbox changes
        print("In CheckBoxEvent-event.completed is -${event.completed}");
        emit(CheckBoxState(completed: event.completed));
      } catch (e) {
        ///Justin case any exception occurs in this AddTaskEvent we will emit the TaskErrorState
        emit(TaskErrorState(error: e.toString()));
      }
    });

    on<SyncRefreshEvent>((event, emit) async {
      try {
        ///After the internet connection is restored we can call Bloc
        ///which will sync all the unsynced tasks and we will update the UI after the work is done
        print("Called SyncRefreshEvent");
        DatabaseService databaseService = DatabaseService.databaseService;
        List<Task> tasks = await databaseService.getAllTask();
        print("Tasks length Emitting after Syncing all tasks-${tasks.length}");
        emit(TaskLoadedState(tasks: tasks));
      } catch (e) {
        print("Exception occurred while SyncRefreshEvent");
      }
    });
  }
}
