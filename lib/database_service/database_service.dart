import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:desafio_fabrica/api_client/api_service.dart';
import 'package:desafio_fabrica/model/task_model.dart';

class DatabaseService {
  static DatabaseService databaseService = DatabaseService._instance();
  Database? _db;
  DatabaseService._instance();

  Future<Database?> get database async {
    if (_db != null) return _db;
    _db = await _getDatabase();
    return _db;
  }

  static const String _taskIdCol = "id";
  static const String _taskTitleCol = "title";
  static const String _taskCompletedCol = "completed";
  static const String _taskTableName = "task";
  static const String _taskIsSyncedCol = "is_synced";
  static const String _taskSyncMethodCol = "sync_method";

  static const String SQL_CREATE_TASK_TABLE = '''
  CREATE TABLE  $_taskTableName (
    $_taskIdCol INTEGER PRIMARY KEY,
    $_taskTitleCol TEXT NOT NULL,
    $_taskCompletedCol INTEGER NOT NULL,
    $_taskIsSyncedCol INTEGER NOT NULL,
    $_taskSyncMethodCol TEXT NOT NULL
  )
  ''';

  ///This Method will return us the Instance of database by gettoing the db path and opening it and creating the Table as well
  static Future<Database> _getDatabase() async {
    try {
      Database database;
      String databasePath = await getDBPath();
      database = await openDatabase(
        databasePath,
        version: 1,
        onCreate: (db, version) async {
          await db.execute(SQL_CREATE_TASK_TABLE);
          print("Created Table $_taskTableName");
        },
      );
      print("Database is open");
      return database;
    } catch (e) {
      print("Error while opening anf getting the Database");
      print("Exception is- $e");
      rethrow;
    }
  }

  Future<void> addTaskToDatabase(List<Task> tasks) async {
    try {
      List<int> ids = [];
      Database? db = await database;
      for (Task currentTask in tasks) {
        int taskId = await db?.insert(_taskTableName, {
              _taskTitleCol: currentTask.title,
              _taskCompletedCol: currentTask.completed,
              _taskIsSyncedCol: 1,
              _taskSyncMethodCol: "UPDATE"
            }) ??
            0;
        ids.add(taskId);
      }
      print("Ids- inserted are $ids");
    } catch (e) {
      print(
          "Error occurred while inserting the data into database addTaskToDatabase");
      print("Error is $e");
      // rethrow;
    }
  }

  Future<List<Task>> getAllTask() async {
    print("Called getAllTasks()");
    List<Task> tasks;
    try {
      Database? db = await database;
      var data = await db?.query(_taskTableName);
      tasks = data
              ?.map(
                (e) => Task(
                    isSynced: e[_taskIsSyncedCol] as int,
                    syncMethod: e[_taskSyncMethodCol] as String,
                    id: e[_taskIdCol] as int,
                    title: e[_taskTitleCol] as String,
                    completed: e[_taskCompletedCol] as int),
              )
              .toList() ??
          [];
      print("Task length from getAllTask() is ${tasks.length}");
      return tasks;
    } catch (e) {
      print("Error while getting the Data from the database ");
      rethrow;
    }
  }

  ///This method will add new task to db and update with the help of POST Api as well
  Future<int> addNewTask(String task) async {
    try {
      Database? _db = await database;

      ///Inserting the new Task to the database
      int newTaskId = await _db?.insert(_taskTableName, {
            _taskTitleCol: task,
            _taskCompletedCol: 0,
            _taskIsSyncedCol: 0,
            _taskSyncMethodCol: "ADD"
          }) ??
          0;

      ///If newTaskId is not 0 means insertion is successfull
      if (newTaskId != 0) {
        print(
            "The id of the new Task which got inserted into db is $newTaskId");

        ///After  the insertion is successful we can call POST Api and which will sync out new Task
        int statusResonse = await ApiService.syncAddNewTask(
            Task(id: newTaskId, title: task, completed: 0));

        ///If status code is 201 we can consider it as success response
        if (statusResonse == 201) {
          ///Because we have successfully hit POST API we have to update it in database and change the value of isSynced and syncMethod as well
          await _db?.update(_taskTableName,
              {_taskSyncMethodCol: "UPDATE", _taskIsSyncedCol: 1},
              where: "id=?", whereArgs: [newTaskId]);
        } else {
          ///If something went wrong when hitting the POST Api we will get status code other than 201
          print(
              "The status response is not 201 when we hit the POST Api but it is-$statusResonse");
        }
        print("Tried syncing the newly added task (Hit PUT Api)");
      }
      return newTaskId;
    } catch (e) {
      print("Error whi;le adding new Task into the Database");
      rethrow;
    }
  }

  static Future<String> getDBPath() async {
    try {
      String databaseDirectoryPath = await getDatabasesPath();
      String databasePath = join(databaseDirectoryPath, "myDatabse.db");
      return databasePath;
    } catch (e) {
      print("Error while getting the databasePath");
      rethrow;
    }
  }

  Future<void> deleteAllTaskFromDb() async {
    try {
      Database? db = await database;
      await db?.delete(_taskTableName);
      print("Deleted all Tasks");
    } catch (e) {
      print("Error ocurred while deleting the task table");
    }
  }

  Future<void> updateTaskInDB(Task task) async {
    try {
      Map<String, dynamic> mapOfTask = Task.taskToMap(task);
      print("Map of task you want to update- $mapOfTask");
      Database? db = await database;
      await db?.update(_taskTableName, mapOfTask,
          where: "id=?", whereArgs: [task.id]);
      print("Updated Task in DB Successfully ");

      ///Once we update the task changes in the Database we have to hit the PUT Api so that we can update there also
      int statusCode = await ApiService.syncUpdatedTask(task);

      ///If status is not 200 we must update the isSynced=0 in the db because it will be a failure case
      if (statusCode != 200) {
        print(
            "Something happened while hitting the PUT Api for task with ID-${task.id} please check for internet connection");
        int count = await db?.update(_taskTableName, {_taskIsSyncedCol: 0},
                where: "id=?", whereArgs: [task.id]) ??
            0;
        if (count == 0) {
          print("Updating in the database for isSynced=0 not successful");
        } else {
          print("Updating in the database for isSynced=0 successful");
        }
      }

      ///If status is 200 we must update the isSynced and syncMethod column in the db because it will be a success case
      else {
        int? count = await db?.update(_taskTableName, {_taskIsSyncedCol: 1},
            where: "id=?", whereArgs: [task.id]);

        ///If count is 1 then the update isSynced is successful
        if (count == 1) {
          print("Updated the column isSynced successfully");
        }

        ///If count is not 1 updating isSynced is not successful
        else {
          print(
              "There was an error while updating the isSynced of task with TaskId- ${task.id}");
        }
      }
    } catch (e) {
      print("Error occurred while updating the task with ID-${task.id}");
      rethrow;
    }
  }

  Future<List<Task>> unSyncedTasks() async {
    List<Task> tasks;
    try {
      Database? db = await database;
      List<Map<String, Object?>>? result = await db
          ?.query(_taskTableName, where: "$_taskIsSyncedCol=?", whereArgs: [0]);
      tasks = result
              ?.map(
                (e) => Task(
                    isSynced: e[_taskIsSyncedCol] as int,
                    syncMethod: e[_taskSyncMethodCol] as String,
                    id: e[_taskIdCol] as int,
                    title: e[_taskTitleCol] as String,
                    completed: e[_taskCompletedCol] as int),
              )
              .toList() ??
          [];
      return tasks;
    } catch (e) {
      print("Exception occurred while getting the unSyncedTasks");
      rethrow;
    }
  }

  Future<void> updateIsSynced(Task task, int isSynced) async {
    try {
      Database? db = await database;
      db?.update(_taskTableName, {_taskIsSyncedCol: isSynced},
          where: "id=?", whereArgs: [task.id]);
    } catch (e) {
      print(
          "There was an exception while updating the IsSynced of the Task with taskId-${task.id}");
    }
  }

  Future<void> updateSyncMethodAndIsSynced(Task task) async {
    try {
      Database? db = await database;
      db?.update(
          _taskTableName, {_taskIsSyncedCol: 1, _taskSyncMethodCol: "UPDATE"},
          where: "id=?", whereArgs: [task.id]);
    } catch (e) {
      print(
          "There was an exception while updating the syncMethod and IsSynced of the Task with taskId-${task.id}");
    }
  }
}
