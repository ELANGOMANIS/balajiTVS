
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
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor:Colors.deepOrangeAccent,
        title: Text('Present Employees',style: TextStyle(color: Colors.white,fontSize: 16),),
      ),
      body: ListView.builder(
        itemCount: presentEmployees.length,
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              leading: Text((index + 1).toString(),style: TextStyle(fontWeight: FontWeight.bold),),
              title: Text(presentEmployees[index]['first_name'],style: TextStyle(fontWeight: FontWeight.bold),),
              subtitle: Text('Emp Code: ${presentEmployees[index]['emp_code']} | Mobile: ${presentEmployees[index]['empMobile']}',style: TextStyle(fontWeight: FontWeight.bold),),
            ),
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
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor:Colors.deepOrangeAccent,
        title: Text('Absent Employees',style: TextStyle(color: Colors.white,fontSize: 16),),
      ),
      body: ListView.builder(
        itemCount: absentEmployees.length,
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              leading: Text((index + 1).toString(),style: TextStyle(fontWeight: FontWeight.bold),),
              title: Text(absentEmployees[index]['first_name'],style: TextStyle(fontWeight: FontWeight.bold),),
              subtitle: Text('Emp Code: ${absentEmployees[index]['emp_code']} | Mobile: ${absentEmployees[index]['empMobile']}',style: TextStyle(fontWeight: FontWeight.bold),),
            ),
          );
        },
      ),
    );
  }
}

class Utils {
  static Future<List<String>> getSuggestions() async {
    List<String> _shiftTypes = [];

    try {
      final response = await http.get(Uri.http('localhost:3309', '/get_shift_type'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        data.forEach((item) {
          _shiftTypes.add(item['shiftType']);
        });
      } else {
        throw Exception('Failed to fetch suggestions');
      }
    } catch (error) {
      print('Error fetching suggestions: $error');
      throw Exception('Failed to fetch suggestions');
    }

    return _shiftTypes;
  }
  static  Future<Map<String, dynamic>> fetchCompanyData() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:3309/fetch_company_details?id=1'));

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic dataCompany = json.decode(response.body);
        if (dataCompany != null && dataCompany is Map<String, dynamic>) {
          print('Company Name: ${dataCompany['companyName']}');
          print('Address: ${dataCompany['address']}');
          print('Contact: ${dataCompany['contact']}');
          return dataCompany;
        } else {
          throw Exception('Unexpected response format');
        }
      } else {
        throw Exception('Error loading company data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load company data: $e');
    }
  }
  static  String formatAddress(String address) {
    final words = address.split(' ');
    final buffer = StringBuffer();
    var line = '';
    var lineCount = 0;

    for (var word in words) {
      if ((line + word).length > 100) {
        if (lineCount == 1) {
          break;
        }
        buffer.writeln(line.trim());
        line = '';
        lineCount++;
      }
      line += '$word ';
    }
    if (line.isNotEmpty && lineCount < 2) {
      buffer.writeln(line.trim());
    }
    return buffer.toString().trim();
  }


}


