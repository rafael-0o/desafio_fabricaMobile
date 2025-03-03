import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:desafio_fabrica/main.dart';
import 'package:desafio_fabrica/screen/home_screen.dart';
import 'package:desafio_fabrica/screen/login_screen.dart';
import 'package:desafio_fabrica/task_manager_bloc/task_manager_bloc.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    print("Splash Screen Started");
    return BlocProvider(
      create: (context) => TaskManagerBloc(),
      child: FutureBuilder(
        future: getIsLoggedIn(),
        builder: (context, snapshot) {
          ///Gets new Isolate which will track internet connectivity changes and
          ///Trigger SyncTaskEvent which will sync the UnSynced tasks in the Database
          startConnectivityIsolate(context);
          bool data = snapshot.data ?? false;
          if (snapshot.hasData) {
            if (data == true) {
              return const MaterialApp(
                debugShowCheckedModeBanner: false,
                home: HomeScreen(),
              );
            } else {
              return const MaterialApp(
                debugShowCheckedModeBanner: false,
                home: LoginScreen(),
              );
            }
          } else if (snapshot.hasError) {
            return Center(
              child: Text(snapshot.error.toString()),
            );
          } else {
            return Center(
                widthFactor: 30.0,
                heightFactor: 30.0,
                child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  home: Scaffold(
                      appBar: AppBar(
                        backgroundColor: Colors.cyan,
                      ),
                      body: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            getLoadingScreen(
                                "Please wait till we get login details"),
                          ],
                        ),
                      )),
                ));
          }
        },
      ),
    );
  }
}

///will return true and false according the Login details
Future<bool> getIsLoggedIn() async {
  print("Wait while getting the login details");
  var sharedPreferences = await SharedPreferences.getInstance();
  return sharedPreferences.getBool("isLoggedIn") ?? false;
}
