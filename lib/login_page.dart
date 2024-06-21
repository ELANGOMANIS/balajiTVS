import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:balajitvs/main.dart';
import 'package:http/http.dart' as http;
import 'package:balajitvs/profile.dart';
import 'home.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}



class _LoginPageState extends State<LoginPage> {
  TextEditingController username = TextEditingController();
  TextEditingController password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  List<Map<String, dynamic>> data = [];
  List<Map<String, dynamic>> filteredData = [];
  bool showWarning = false;
  bool _obscureText2 = true;
  String warningMessage = '';


  void _performLogin() {
    if (username.text.isEmpty && password.text.isEmpty) {
      setState(() {
        showWarning = true;
        warningMessage = "Enter username and password";
      });
    } else if (username.text.isEmpty) {
      setState(() {
        showWarning = true;
        warningMessage = "Enter username";
      });
    } else if (password.text.isEmpty) {
      setState(() {
        showWarning = true;
        warningMessage = "Enter password";
      });
    } else if (username.text == "admin" && password.text == "admin") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => Home()),
      );}
    // } else {
    //   setState(() {
    //     showWarning = true;
    //     warningMessage = "Incorrect username or password";
    //   });
    // }
  }

  List<Map<String, dynamic>> company= [];


  Future<void> fetchData() async {
    try {
      final url = Uri.parse('http://localhost:3309/company_fetch/');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final List<dynamic> itemGroups = responseData;
        setState(() {
          data = itemGroups.cast<Map<String, dynamic>>();
        });
        data[0]['companyName'].toString();
        print('Data767657: $data');
      } else {
        print('Error: ${response.statusCode}');
      }
    } catch (error) {
      // Handle any other errors, e.g., network issues
      print('Error: $error');
    }
  }


  Future<void> handleLogin() async {
    if (_formKey.currentState!.validate()) {
      if (username.text.isEmpty) {
        setState(() {
          showWarning = true;
          warningMessage = "Enter a username";
        });
      } else if (password.text.isEmpty) {
        setState(() {
          showWarning = true;
          warningMessage = "Enter a password";
        });
      } else if (username.text.isNotEmpty && password.text.isNotEmpty) {
        if (username.text == "admin" && password.text == "admin") {
          // Fetch UID from server
          try {
            var response = await http.get(Uri.parse('http://localhost:3309/company_fetch'));
            if (response.statusCode == 200) {
              var data = json.decode(response.body);
              if (data is List && data.isNotEmpty) {
                if (data[0]['uid'] == null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Profile()),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Home()),
                  );
                }
              } else {
                setState(() {
                  showWarning = true;
                 // warningMessage = "No data found";
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Profile()),
                  );
                });
              }
            } else {
              setState(() {
                showWarning = true;
                warningMessage = "Error fetching data from server";
              });
            }
          } catch (e) {
            setState(() {
              showWarning = true;
              warningMessage = "Error: $e";
              print(warningMessage);
            });
          }
        } else {
          setState(() {
            showWarning = true;
            warningMessage = "Incorrect username or password";
          });
        }
      }
    }
  }

  @override
  void initState() {
    fetchData();
    super.initState();
    barrierDismissible: false;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo,

      // route: "loginpage",
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: Container(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 100.0),
                        child: Container(
                          width: 400,
                          decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              border: Border.all(
                                color: Colors.grey,
                              ),
                              borderRadius: BorderRadius.circular(10)),
                          child: Column(
                            children: [
                              SizedBox(height: 20,),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "SRI BALAJI",
                                    style: TextStyle(color: Colors.indigo.shade900, fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  ClipOval(
                                    child: Image.asset(
                                      'assets/TVS_Motor_Company-Logo.wine.png',
                                      width: 100,
                                      height: 50,
                                      fit: BoxFit.cover, // Adjust how the image fits into the oval shape
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20,),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: SizedBox(
                                  width: 220,
                                  child: TextFormField(
                                    controller: username,
                                    textInputAction: TextInputAction.next,
                                    decoration: InputDecoration(
                                      fillColor: Colors.white,
                                      filled: true,
                                      labelText: "Username",
                                    ),
                                    onEditingComplete: () {
                                      FocusScope.of(context).nextFocus();
                                    },
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: SizedBox(
                                  width: 220,
                                  child: TextFormField(
                                    controller: password,
                                    textInputAction: TextInputAction.done, // Change to "done" for the last field
                                    obscureText: _obscureText2,
                                    decoration: InputDecoration(
                                      fillColor: Colors.white,
                                      filled: true,
                                      labelText: "Password",
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscureText2 ? Icons.visibility_off : Icons.visibility,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscureText2 = !_obscureText2;
                                          });
                                        },
                                      ),
                                    ),
                                    onEditingComplete: () {
                                      FocusScope.of(context).nextFocus();
                                    },
                                  ),
                                ),
                              ),
                              SizedBox(height: 10,),
                              MaterialButton(
                                color: Colors.blueAccent.shade400,
                                onPressed: handleLogin,
                                child: const Text(
                                  "LOGIN",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              /*    MaterialButton(
                                color: Colors.blueAccent.shade400,
                                onPressed: () {
                                  if(_formKey.currentState!.validate()){
                                  if (username.text.isEmpty) {
                                     setState(() {
                                      //showWarning = true;
                                      warningMessage = "Enter a username";
                                    });
                                  } else if (password.text.isEmpty) {
                                       setState(() {
                                     // showWarning = true;
                                      warningMessage = "Enter a password";
                                    });
                                  } else if(username.text.isNotEmpty&&password.text.isNotEmpty){
                                    if(username.text == "admin"&&password.text == "admin"){
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => Home()),
                                      );
                                    }else{
                                      setState(() {
                                        //showWarning = true;
                                        warningMessage = "Incorrect username or password";
                                      });
                                    }
                                  }
                                else if (username.text == "admin" && password.text == "admin") {
                                        Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => Home()),
                                    );
                                  }
                                  else {
                                    setState(() {
                                     // showWarning = true;
                                      warningMessage = "Incorrect username or password";
                                    });
                                  }}
                                },
                                child: Text(
                                  "LOGIN",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),*/

                              SizedBox(height: 10,),
                              //   if (showWarning)
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(warningMessage??"",
                                  //    "* The username or password is incorrect.",
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

      ),
    );
  }
}
