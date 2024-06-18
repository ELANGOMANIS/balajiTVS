import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../../main.dart';
import 'package:intl/intl.dart';

class AttendanceBalaji extends StatefulWidget {
  const AttendanceBalaji({Key? key}) : super(key: key);

  @override
  State<AttendanceBalaji> createState() => _AttendanceBalajiState();
}

class _AttendanceBalajiState extends State<AttendanceBalaji> {
  late Future<List<Map<String, dynamic>>> attendanceDetailsFuture;

  @override
  void initState() {
    super.initState();
    attendanceDetailsFuture = fetchAttendanceBalaji();
  }

  Future<List<Map<String, dynamic>>> fetchAttendanceBalaji() async {
    final response = await http.get(Uri.parse('http://localhost:3309/get_attendance_overall'));
    print("response ${response.statusCode}");
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      // Handle the error
      throw Exception('Failed to load attendance summary');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MyScaffold(
      route: "attendancebalaji_report",
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.all(0.0),
                child: Container(
                  child: Padding(
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
                              Icon(Icons.report),
                              SizedBox(width: 10),
                              Text(
                                'Attendance Report',
                                style: TextStyle(
                                  fontSize: 20,
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
              Padding(
                padding: const EdgeInsets.all(3.0),
                child: SingleChildScrollView(
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      border: Border.all(color: Colors.grey),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: FutureBuilder<List<Map<String, dynamic>>>(
                        future: attendanceDetailsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return CircularProgressIndicator();
                          } else if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return Text('No data available');
                          } else {
                            return PaginatedDataTable(
                              columnSpacing: 52.5,
                              rowsPerPage: 25,
                              columns: const [
                                DataColumn(label: Center(child: Text("S.No", style: TextStyle(fontWeight: FontWeight.bold),))),
                                DataColumn(label: Center(child: Text("In Date", style: TextStyle(fontWeight: FontWeight.bold),))),
                                DataColumn(label: Center(child: Text("Emp Code", style: TextStyle(fontWeight: FontWeight.bold),))),
                                DataColumn(label: Center(child: Text("Name", style: TextStyle(fontWeight: FontWeight.bold),))),
                                DataColumn(label: Center(child: Text("Shift", style: TextStyle(fontWeight: FontWeight.bold),))),
                                DataColumn(label: Center(child: Text("Check-in", style: TextStyle(fontWeight: FontWeight.bold),))),
                                DataColumn(label: Center(child: Text("Check-out", style: TextStyle(fontWeight: FontWeight.bold),))),
                                DataColumn(label: Center(child: Text("Total Hrs", style: TextStyle(fontWeight: FontWeight.bold),))),
                                DataColumn(label: Center(child: Text("Remark", style: TextStyle(fontWeight: FontWeight.bold),))),
                              ],
                              source: AttendanceDataSource(snapshot.data!),

                             // source: AttendanceDataSource(snapshot.data!),
                            );
                          }
                        },
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

class AttendanceDataSource extends DataTableSource {
  final List<Map<String, dynamic>> _data;

  AttendanceDataSource(this._data);
  String _formatDate(String dateStr) {
    try {
      DateTime date = DateFormat('yyyy-MM-dd').parse(dateStr);
      return DateFormat('MMMM-dd,yyyy').format(date);
    } catch (e) {
      return dateStr; // Return the original string if parsing fails
    }
  }


  @override
  DataRow? getRow(int index) {
    if (index >= _data.length) return null;
    final attendance = _data[index];

    return DataRow.byIndex(
      index: index,
      cells: [
        DataCell(Center(child: Text('${index + 1}'))),
        DataCell(Center(
          child: Text(
            attendance["inDate"] != null
                ? DateFormat('dd-MM-yyyy').format(
              DateTime.parse("${attendance["inDate"]}").toLocal(),
            )
                : "",
          ),
        )),
        DataCell(Center(child: Text(attendance['emp_code'] ?? ''))),
        DataCell(Center(child: Text(attendance['first_name'] ?? ''))),
        DataCell(Center(child: Text(attendance['shiftType'] ?? ''))),
        DataCell(Center(child: Text(attendance['check_in'] ?? ''))),
        DataCell(Center(child: Text(attendance['check_out'] ?? ''))),
        DataCell(Center(child: Text(attendance['total_hrs'] ?? ''))),
        DataCell(Center(child: Text(attendance['remark'] ?? ''))),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _data.length;

  @override
  int get selectedRowCount => 0;
}


