import 'dart:convert';
import 'dart:io';

import 'package:desafio_fabrica/model/task_model.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static final API_URI =
      Uri.parse("https://jsonplaceholder.typicode.com/todos");

  ///Hits the GET Api and get us all th tasks for our app
  static Future<List<Task>> fetchTasks() async {
    try {
      print("Fetching the Tasks from the API");
      List<Task> tasks;
      var response = await http.get(API_URI);

      ///if status code returned is 200 the we cn assume it as a success case and
      /// we can get the response in JSON which we can use and decode it into desired form of data
      /// In our case we made it as List<Task>
      if (response.statusCode == 200) {
        List<dynamic> decodedData = jsonDecode(response.body);
        List<Map<String, dynamic>> listOfTasks =
            decodedData.cast<Map<String, dynamic>>();
        tasks = listOfTasks
            .map((e) => Task(
                id: e["id"] as int,
                title: e["title"] as String,
                completed: e["completed"] == true ? 1 : 0))
            .toList();
        return tasks;
      }

      ///If not the 200 we have to assume it as a failure response and we have to inform the user about the same
      ///that we did not get the data
      else {
        print(
            "Did not get any data from API status code= ${response.statusCode}");
        throw HttpException("${response.statusCode}", uri: API_URI);
      }
    } catch (e) {
      print("Error while getting the data from the API");
      return [];
    }
  }

  static Future<int> syncAddNewTask(Task task) async {
    var requestBody = {"title": task.title, "completed": task.completed == 1};

    try {
      print("Hitting POST Api for the newly added task");
      var response =
          await http.post(API_URI, body: jsonEncode(requestBody), headers: {
        "Content-Type": "application/json",
      });
      print("The response came from the POST Api is $response");
      return response.statusCode;
    } catch (e) {
      print(
          "Exception occurred while Hitting POST Api for task with id- ${task.id}");
      return 400;
    }
  }

  static Future<int> syncUpdatedTask(Task task) async {
    var requestBody = {"title": task.title, "completed": task.completed};
    final PUT_API_URI =
        Uri.parse('https://jsonplaceholder.typicode.com/todos/${task.id}');

    try {
      print("Hitting PUT Api for the updating task with is-${task.id}");

      ///Hitting the PUT Api
      var response =
          await http.put(PUT_API_URI, body: jsonEncode(requestBody), headers: {
        "Content-Type": "application/json",
      });
      print("The status code came from the PUT Api is ${response.statusCode}");
      return response.statusCode;
    } catch (e) {
      print(
          "Exception occurred while Hitting PUT Api for task with id- ${task.id}");
      return 400;
    }
  }
}
