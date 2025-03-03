import 'dart:isolate';
import 'package:flutter/services.dart'; // For RootIsolateToken

class SyncIsolateModel {
  final RootIsolateToken rootIsolateToken;
  final SendPort sendPort;

  final SendPort syncSendPort;
  SyncIsolateModel(
      {required this.rootIsolateToken,
      required this.sendPort,
      required this.syncSendPort});
}
