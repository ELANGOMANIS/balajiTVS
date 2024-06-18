import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../../main.dart';

class AttendanceBalaji extends StatefulWidget {
  const AttendanceBalaji({Key? key}) : super(key: key);

  @override
  State<AttendanceBalaji> createState() =>
      _AttendanceBalajiState();
}

class _AttendanceBalajiState extends State<AttendanceBalaji> {
  @override
  initState() {
    super.initState();
    fetchAttendanceDetails();
  }

  Future<List<Map<String, dynamic>>> fetchAttendanceDetails() async {
    final url = Uri.parse('http://localhost:3309/get_attendance_overall/');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> responseData = json.decode(response.body);
        print("Response: $responseData");
        // Use a Set to ensure unique records
        Set<String> uniqueIdentifiers = Set();
        List<Map<String, dynamic>> uniqueData = [];

        for (var item in responseData) {
          String custName = item['check_in']?.toString() ?? '';
          String inDate = item['inDate']?.toString() ?? '';
          String uniqueIdentifier = '$custName-$inDate';

          if (!uniqueIdentifiers.contains(uniqueIdentifier)) {
            uniqueIdentifiers.add(uniqueIdentifier);
            uniqueData.add(Map<String, dynamic>.from(item));
          }
        }

        return uniqueData;
      } else {
        throw Exception('Failed to load attendance details');
      }
    } catch (e) {
      print('Error fetching data: $e');
      throw Exception('Error fetching data');
    }
  }

  @override
  Widget build(BuildContext context) {

    return MyScaffold(
      route: "attendancebalaji_report",backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Center(
          child: Column(
        children: [
        const SizedBox(height: 10,),
        Padding(
          padding: const EdgeInsets.all(0.0),
          child: Container(
            child:   Padding(
              padding: const EdgeInsets.all(3.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border.all(color: Colors.grey),
                ),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.report,),
                        SizedBox(width:10,),
                        Text(
                          'Attendance Report',
                          style: TextStyle(
                            fontSize:20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),


        ],
      ),
        ),
      ),
    );
  }
}

