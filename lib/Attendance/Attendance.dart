/*

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'Attendance_edit.dart';
import 'General.dart';
import 'Morning.dart';
import 'Night.dart';



class Attendance extends StatefulWidget {
  const Attendance({Key? key}) : super(key: key);
  @override
  State<Attendance> createState() => _AttendanceState();
}
class _AttendanceState extends State<Attendance> {
  Future<void> _showPasswordDialog(BuildContext context) async {
    String enteredPassword = "";
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Password'),
          content: TextField(
            obscureText: true,
            onChanged: (value) {
              enteredPassword = value;
            },
            decoration: InputDecoration(
              hintText: 'Password',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (enteredPassword == 'admin') {
                  Navigator.of(context).pop(); // Close the password dialog
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AttendanceAlter()),
                  );
                } else {
                  // Incorrect password, you can show an error message or do other actions
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: MyScaffold(
        route: "attendance_entry",
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blue, Colors.white],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                TabBar(
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.black,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.blue,
                  ),
                  indicatorSize: TabBarIndicatorSize.label,
                  indicatorWeight: 2.0,
                  tabs: const [
                    Tab(
                      text: 'Morning',
                      icon: Icon(Icons.wb_sunny),
                    ),
                    Tab(
                      text: 'Night',
                      icon: Icon(Icons.nightlight_round),
                    ),
                    Tab(
                      text: 'General',
                      icon: Icon(Icons.dashboard),
                    ),
                    Tab(
                      text: 'Alter',
                      icon: Icon(Icons.edit_attributes),
                    ),
                  ],
                ),
                SizedBox(height: 30),
                 Expanded(
                  child: TabBarView(
                    children: [
                      const Morning(),
                      const NightShift(),
                      const General(),
                      GestureDetector(
                        onTap: () {
                          _showPasswordDialog(context);
                        },
                        child: const AttendanceAlter(),
                      ),                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



class MyScaffold extends StatelessWidget {
  final String route;
  final Widget body;

  const MyScaffold({required this.route, required this.body, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Attendance Entry",style: TextStyle(color: Colors.black),),
          backgroundColor: Colors.white,
      ),
      body: body,
    );
  }
}
*/


import 'package:flutter/material.dart';
import 'Attendance_edit.dart';
import 'General.dart';
import 'Morning.dart';
import 'Night.dart';

class Attendance extends StatefulWidget {
  const Attendance({Key? key}) : super(key: key);

  @override
  State<Attendance> createState() => _AttendanceState();
}

class _AttendanceState extends State<Attendance> {
  final TextEditingController _passwordController = TextEditingController();

  void _showPasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Enter Password"),
          content: TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: "Password"),
          ),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel",style: TextStyle(color: Colors.white),),
            ),
            ElevatedButton(
              onPressed: () {
                if (_passwordController.text == "admin123") {
                  Navigator.of(context).pop(); // Close the password dialog
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AttendanceAlter()),
                  );
                } else {
                  // Show an error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Incorrect password. Try again."),
                    ),
                  );
                }
              },
              child: Text("Submit",style: TextStyle(color: Colors.white),),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: MyScaffold(
        route: "attendance_entry",
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blue, Colors.white],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                TabBar(
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.black,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.blue,
                  ),
                  indicatorSize: TabBarIndicatorSize.label,
                  indicatorWeight: 2.0,
                  tabs: const [
                    Tab(
                      text: 'Morning',
                      icon: Icon(Icons.wb_sunny),
                    ),
                    Tab(
                      text: 'Night',
                      icon: Icon(Icons.nightlight_round),
                    ),
                    Tab(
                      text: 'General',
                      icon: Icon(Icons.dashboard),
                    ),
                    Tab(
                      text: 'Alter',
                      icon: Icon(Icons.edit_attributes),
                    ),
                  ],
                ),
                SizedBox(height: 30),
                Expanded(
                  child: TabBarView(
                    children: [
                      const Morning(),
                      const NightShift(),
                      const General(),
                      ElevatedButton(
                        onPressed: () {
                          _showPasswordDialog(context);
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.black, backgroundColor: Colors.white, // Text color
                          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8), // Adjust the border radius as needed
                          ),
                          elevation: 0, // Set elevation to 0 to remove the button shadow
                        ),
                        child:
                        const Column(
                          children: [
                            Icon(Icons.edit_attributes),
                            Text('Open Attendance Alter'),
                          ],
                        ),
                      ),

                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyScaffold extends StatelessWidget {
  final String route;
  final Widget body;

  const MyScaffold({required this.route, required this.body, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Attendance Entry",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
      ),
      body: body,
    );
  }
}
