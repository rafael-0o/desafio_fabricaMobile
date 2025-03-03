import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:desafio_fabrica/screen/home_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    TextEditingController? userNameController;
    TextEditingController? passwordController;

    print("Starting login screen");
    return Scaffold(
      backgroundColor: const Color(0xFF73B973),
      // appBar: AppBar(),
      body: Center(
          child: SizedBox(
        width: 300.0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Task Manager",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  // backgroundColor: Colors.blueGrey,
                  fontStyle: FontStyle.italic,
                  fontSize: 30.0),
            ),
            Container(
              color: Colors.white,
              child: TextField(
                controller: userNameController,
                decoration: const InputDecoration(
                  hintText: "username or email",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 5.0),
            Container(
              color: Colors.white,
              child: TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  hintText: "Password",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            MaterialButton(
              onPressed: () async {
                print("Logging In");
                print("Successfully LoggedIn");
                SharedPreferences pref = await SharedPreferences.getInstance();

                ///Databse

                pref.setBool("isLoggedIn", true);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HomeScreen(),
                    ));
              },
              color: Colors.teal,
              child: const Text("Login"),
            )
          ],
        ),
      )),
    );
  }
}
