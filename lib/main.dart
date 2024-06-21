import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:balajitvs/profile.dart';
import 'package:balajitvs/settings/settings.dart';
import 'Attendance/Attendance_report.dart';
import 'Attendance/WeeklySalary.dart';
import 'employee/employee_profile_update.dart';
import 'employee/employee_report.dart';
import 'Attendance/salary.dart';
import 'home.dart';
import 'login_page.dart';



void startNodeServer() async {
  try {
    await Process.run('./start_server.sh', []);
    print('Node.js server started successfully.');
  } catch (e) {
    print('Error starting Node.js server: $e');
  }
}
void main() {
  runApp(MyApp());
  startNodeServer();
}
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}
class _MyAppState extends State<MyApp> {
  static const MaterialColor themeBlack = MaterialColor(
    _themeBlackPrimaryValue,
    <int, Color>{
      50: Color(_themeBlackPrimaryValue),
      100: Color(_themeBlackPrimaryValue),
      200: Color(_themeBlackPrimaryValue),
      300: Color(_themeBlackPrimaryValue),
      400: Color(_themeBlackPrimaryValue),
      500: Color(_themeBlackPrimaryValue),
      600: Color(_themeBlackPrimaryValue),
      700: Color(_themeBlackPrimaryValue),
      800: Color(_themeBlackPrimaryValue),
      900: Color(_themeBlackPrimaryValue),
    },
  );
  static const int _themeBlackPrimaryValue = 0xFF222222;
  static const Color themeTextPrimary = Color(0xFF9D9D9D);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sri Balaji TVS',

     home: const LoginPage(),

      theme: ThemeData (
        primaryColor: Colors.deepOrangeAccent,
        hintColor: Colors.indigoAccent,
        fontFamily: GoogleFonts.poppins().fontFamily,
        textTheme: const TextTheme(
          displayLarge: TextStyle(
              fontSize: 20.0,
              color: Colors.black,
              fontWeight: FontWeight.bold
          ),
          displayMedium: TextStyle(
            fontSize: 18.0,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
          displaySmall: TextStyle(fontSize: 17.0, color: Colors.blue),
          headlineMedium: TextStyle(
              fontSize: 20.0, color: Colors.green, fontStyle: FontStyle.italic),
          headlineSmall: TextStyle(fontSize: 19.0, color: Colors.black),
          bodyLarge: TextStyle(fontSize: 16.0, color: Colors.black),
          bodyMedium: TextStyle(fontSize: 13.0, color: Colors.black),
        ),

        /// input size
        inputDecorationTheme: const InputDecorationTheme(
          isCollapsed: false,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 13, horizontal: 10),
          border: OutlineInputBorder(),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.black),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blueAccent, width: 2.0),
          ),
          labelStyle: TextStyle(color: Colors.black),
        ),

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white, backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
            textStyle: const TextStyle(fontSize: 15),
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade800,
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 50),
            textStyle: const TextStyle(fontSize: 15),
          ),
        ),
      ),

    );
  }
}

class MyScaffold extends StatefulWidget {
  final Widget body;
  final String route;
  final Color backgroundColor;

  MyScaffold({
    Key? key,
    required this.route,
    required this.body,
    required this.backgroundColor,
  }) : super(key: key);

  @override
  _MyScaffoldState createState() => _MyScaffoldState();
}

class _MyScaffoldState extends State<MyScaffold> {
// Track the selected button

  final Map<String, bool> _hovering = {
    'Home': false,
    'Employee': false,
    'Attendance': false,
    'Salary': false,
    'Employee Report': false,
    'Settings': false,
    'Attendance Balaji': false,
  };
  final Map<String, bool> _clicked = {
    'Home': false,
    'Employee': false,
    'Attendance': false,
    'Salary': false,
    'Employee Report': false,
    'Settings': false,
    'Attendance Balaji': false,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.backgroundColor,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Text(
              "Sri Balaji",
              style: TextStyle(color: Colors.white),
            ),
            ClipOval(
              child: Image.asset(
                'assets/TVS_Motor_Company-Logo.wine.png',
                width: 100,
                height: 50,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
        automaticallyImplyLeading: false, // This removes the leading space including the back button area
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: (){
              Navigator.push(context, MaterialPageRoute(builder: (context) => const Profile()));
            },
            icon: Icon(Icons.person_outline_outlined),
          ),
          IconButton(
            icon: const Icon(Icons.login_outlined),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Do you want Logout?'),
                    content: Text(''),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage()));
                        },
                        child: Text('Logout', style: TextStyle(color: Colors.black)),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text('Cancel', style: TextStyle(color: Colors.black)),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(40.0),
          child: Container(
            color: Colors.blue.shade900,
            height: 40.0,
            alignment: Alignment.center,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  _buildHoverButton('Home', Icons.home),
                  _buildHoverButton('Employee', Icons.person_add_alt_rounded),
                  _buildHoverButton('Attendance', Icons.punch_clock_rounded),
                  _buildHoverButton('Salary', Icons.monetization_on),
                  _buildHoverButton('Employee Report', Icons.manage_accounts_sharp),
                  _buildHoverButton('Settings', Icons.settings),
                ],
              ),
            ),
          ),
        ),
      ),

      body: SingleChildScrollView(
        child: widget.body, // Use widget.body to display the body content
      ),
    );
  }

  Widget _buildHoverButton(String label, IconData icon) {
    return MouseRegion(
      onEnter: (_) => _onHover(label, true),
      onExit: (_) => _onHover(label, false),
      child: TextButton(
        onPressed: () => _onTap(label),
        child: Row(
          children: [
            Icon(
              icon,
              color: _clicked[label]! ? Colors.orange : (_hovering[label]! ? Colors.orange : Colors.white),
            ),
            SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: _clicked[label]! ? Colors.orange : (_hovering[label]! ? Colors.orange : Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onHover(String label, bool isHovering) {
    setState(() {
      _hovering[label] = isHovering;
    });
  }

  void _onTap(String label) {
    setState(() {
      // Reset all hovering states
      _hovering.updateAll((key, value) => false);

      // Reset all clicked states
      _clicked.updateAll((key, value) => false);

      // Set the clicked state of the tapped button to true
      _clicked[label] = true;
    });

    // Navigate based on the button tapped
    switch (label) {
      case 'Home':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const Home()));
        break;
      case 'Employee':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const EmployeeProfileUpdate()));
        break;
      case 'Attendance':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const AttendanceBalaji()));
        break;
      case 'Salary':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const CumulativeSalaryCalculation()));
        break;
      case 'Employee Report':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const EmployeeReport()));
        break;
      case 'Settings':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const Settings()));
        break;

    }
  }
}