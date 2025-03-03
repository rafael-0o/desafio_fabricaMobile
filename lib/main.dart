import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:isolate';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:desafio_fabrica/screen/splash_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:desafio_fabrica/model/sync_isolate_model.dart';
import 'package:desafio_fabrica/task_manager_bloc/task_manager_bloc.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  ///Runs the Application in main thread
  runApp(const TaskManagerApp());
}

class TaskManagerApp extends StatelessWidget {
  const TaskManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}

void startConnectivityIsolate(BuildContext context) {
  print("Called startConnectivityIsolate function");

  ///To enable the communication between main and new isolate
  final rootIsolateToken = RootIsolateToken.instance;

  ///As there is a chances of getting null value from -RootIsolateToken.instance
  if (rootIsolateToken == null) {
    print(
        "Error: RootIsolateToken is null. Ensure WidgetsFlutterBinding.ensureInitialized() is called.");
    return;
  }

  /// Create a ReceivePort for Listening message from isolate
  final receivePort = ReceivePort();
  SendPort? backgroundSendPort;

  ///Create a recoverPort to listen and refresh the UI once the isSynced is updated
  ReceivePort syncReceivePort = ReceivePort();

  print("Spawning the new Isolate");

  /// Spawn the background isolate and new isolate will call our connectivityIsolate function
  /// with SyncIsolateModel as parameter for the function
  Isolate.spawn<SyncIsolateModel>(
    connectivityIsolate,
    SyncIsolateModel(
        rootIsolateToken: rootIsolateToken,
        sendPort: receivePort.sendPort,
        syncSendPort: syncReceivePort.sendPort),
  );

  /// Handle messages from the isolate
  receivePort.listen((message) {
    print("Listening in main thread if message is send port");
    if (message is SendPort) {
      /// Save the SendPort for communication
      backgroundSendPort = message;

      /// Start monitoring connectivity in the main isolate
      final connectivity = Connectivity();
      connectivity.onConnectivityChanged.listen((result) {
        final isConnected = result == ConnectivityResult.mobile ||
            result == ConnectivityResult.wifi;
        print("Sending isConnected from main thread to isolate $isConnected");

        /// Send updates to the background isolate
        backgroundSendPort?.send(isConnected);
      });
    } else {
      print("Message from Background Isolate: $message, not the Sender port");
    }
  });

  ///Once the syncing of tasks is done in the isolate it will send a message
  ///which we will listen here in the main thread and update the UI using the SyncRefreshEvent
  syncReceivePort.listen(
    (message) async {
      print("Listening in syncReceivePort $message");
      context.read<TaskManagerBloc>().add(SyncRefreshEvent());
    },
  );
}

void connectivityIsolate(SyncIsolateModel model) {
  /// Initialize the background messenger with the RootIsolateToken
  BackgroundIsolateBinaryMessenger.ensureInitialized(model.rootIsolateToken);

  final receivePort = ReceivePort();

  /// Send a SendPort to the main isolate for communication
  model.sendPort.send(receivePort.sendPort);

  bool? isConnected;

  /// Listen for connectivity updates from the main isolate
  receivePort.listen((message) async {
    if (message is bool) {
      if (isConnected != message) {
        isConnected = message;

        ///The connectivity is restored
        if (isConnected == true) {
          SendPort syncSendPort = model.syncSendPort;
          print(
              "Background Isolate: Connectivity restored. Triggering SyncTaskEvent.");
          TaskManagerBloc taskBloc = TaskManagerBloc();
          taskBloc.add(SyncTaskEvent(syncSendPort: syncSendPort));
        }

        ///Connection is lost so waiting until connectivity is restored
        else {
          print(
              "Background Isolate: Connectivity lost. Waiting for reconnection.");
        }
      }
    }
  });
}
