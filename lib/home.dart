
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:intl/intl.dart';
import 'package:vinayaga_project/main.dart';
import 'package:http/http.dart' as http;
import '../../home.dart';
import 'Attendance/attandance_pdf.dart';


class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);
  @override
  State<Home> createState() => _HomeState();

}
class _HomeState extends State<Home> {
  int totalEmployees = 0;
  int present = 0;
  int absent = 0;

  @override
  void initState() {
    super.initState();
    fetchAttendanceSummary();

  }
  Future<void> fetchAttendanceSummary() async {
    final response = await http.get(Uri.parse('http://localhost:3309/attendance-summary'));
    print("response ${response.statusCode}");
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        totalEmployees = data['totalEmployees'];
        present = data['present'];
        absent = data['absent'];
      });
    } else {
      // Handle the error
      throw Exception('Failed to load attendance summary');
    }
  }
  @override
  Widget build(BuildContext context) {
    return MyScaffold(
      route: "attendance_report",backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            TotalEmployeesHeader(totalEmployees: totalEmployees), // Example total students
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Wrap(

                children: [
                  AttendanceCard(
                    color: Colors.green,
                    icon: Icons.check_circle_outline,
                    title: 'Present',
                    count: present,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => PresentEmployeesPage(),));
                    }, // Example count
                  ),
                  SizedBox(height: 16),
                  AttendanceCard(
                    color: Colors.red,
                    icon: Icons.cancel_outlined,
                    title: 'Absent',
                    count: absent, onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => AbsentEmployeesPage(),));

                  }, // Example count
                  ),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TotalEmployeesHeader extends StatelessWidget {
  final int totalEmployees;

  TotalEmployeesHeader({required this.totalEmployees});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueAccent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group,
            color: Colors.white,
            size: 40,
          ),
          SizedBox(width: 16),
          Text(
            'Total Employees: $totalEmployees',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
class AttendanceCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final int count;
  final VoidCallback onTap;

  AttendanceCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.count,
    required this.onTap,
  });

  void _navigateToPage(BuildContext context, String routeName) {
    Navigator.pushNamed(context, routeName);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '$count Employees',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}



class PresentEmployeesPage extends StatefulWidget {
  @override
  _PresentEmployeesPageState createState() => _PresentEmployeesPageState();
}

class _PresentEmployeesPageState extends State<PresentEmployeesPage> {
  List<dynamic> presentEmployees = [];

  @override
  void initState() {
    super.initState();
    fetchPresentEmployees();
  }

  Future<void> fetchPresentEmployees() async {
    final response = await http.get(Uri.parse('http://localhost:3309/present-employees'));
    if (response.statusCode == 200) {
      setState(() {
        presentEmployees = json.decode(response.body);
      });
    } else {
      throw Exception('Failed to load present employees');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     // route: "",backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Present Employees'),
      ),
      body: ListView.builder(
        itemCount: presentEmployees.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: Text((index + 1).toString()),
            title: Text(presentEmployees[index]['first_name']),
            subtitle: Text('Emp Code: ${presentEmployees[index]['emp_code']} | Mobile: ${presentEmployees[index]['empMobile']}'),
          );
        },
      ),
    );
  }
}

class AbsentEmployeesPage extends StatefulWidget {
  @override
  _AbsentEmployeesPageState createState() => _AbsentEmployeesPageState();
}

class _AbsentEmployeesPageState extends State<AbsentEmployeesPage> {
  List<dynamic> absentEmployees = [];

  @override
  void initState() {
    super.initState();
    fetchAbsentEmployees();
  }

  Future<void> fetchAbsentEmployees() async {
    final response = await http.get(Uri.parse('http://localhost:3309/absent-employees'));
    if (response.statusCode == 200) {
      setState(() {
        absentEmployees = json.decode(response.body);
      });
    } else {
      throw Exception('Failed to load absent employees');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     // route: '',backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Absent Employees'),
      ),

      body: ListView.builder(
        itemCount: absentEmployees.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: Text((index + 1).toString()),
            title: Text(absentEmployees[index]['first_name']),
            subtitle: Text('Emp Code: ${absentEmployees[index]['emp_code']} | Mobile: ${absentEmployees[index]['empMobile']}'),
          );
        },
      ),
    );
  }
}


