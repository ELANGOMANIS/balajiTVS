import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vinayaga_project/home.dart';
class Morning extends StatefulWidget {
  const Morning({Key? key}) : super(key: key);
  @override
  State<Morning> createState() => _MorningState();
}
class _MorningState extends State<Morning> {
  late DateTime? fromDateAsDateTime;
  late DateTime? toDateAsDateTime;

  @override
  void initState() {
    super.initState();
    customerDataToDatabase();
    daysInMonth = DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day;
    Map<String, List<Map<String, dynamic>>> groupedEntries = {};
    for (var empEntry in groupedEntries.entries) {
      List<Map<String, dynamic>> empData = empEntry.value;
      fromDateAsDateTime = empData.first['fromDate'] != null ? DateTime.parse(empData.first['fromDate'].toString()) : null;
      toDateAsDateTime = empData.first['toDate'] != null ? DateTime.parse(empData.first['toDate'].toString()) : null;

    }

  }
  @override
  void dispose() {
    // Dispose logic if needed
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> fetchUnitEntries() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:3309/attendance_view_morning'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Error loading unit entries: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load unit entries: $e');
    }
  }
  Object calculateLateLunch(List<Map<String, dynamic>> entries) {
    if (entries.length < 1){
      return('');
    }
    if (entries.length < 2){
      return('');
    }
    if (entries.length < 3){
      return('');
    }
    if (entries.length >= 2) {
      DateTime lunchOut = DateTime.parse(entries[1]['punch_time'].toString()).toLocal();
      DateTime lunchIn = DateTime.parse(entries[2]['punch_time'].toString()).toLocal();

      int lateMinutes = lunchIn.difference(lunchOut).inMinutes - 30; // Subtract default lunch time
      return lateMinutes > 0 ? lateMinutes : 0;

    }

    return '0';
  }

  String calculateLate(List<Map<String, dynamic>> punches) {
    if (punches.length < 1) {
      return (''); // No check-in data
    }

    DateTime shiftStart;
    DateTime checkIn = DateTime.parse(punches[0]['punch_time'].toString());

    switch (punches[0]['shiftType']) {
      case 'Morning':
        shiftStart = DateTime(checkIn.year, checkIn.month, checkIn.day, 8, 0, 0);
        break;
      case 'Night':
        shiftStart = DateTime(checkIn.year, checkIn.month, checkIn.day, 20, 0, 0);
        break;
      case 'General':
        shiftStart = DateTime(checkIn.year, checkIn.month, checkIn.day, 9, 0, 0);
        break;
      default:
        return ('');
    }

    // Calculate late minutes
    int lateMinutes = checkIn.isAfter(shiftStart) ? checkIn.difference(shiftStart).inMinutes : 0;

    return (lateMinutes.toString());
  }
  String calculateEarlyLeave(List<Map<String, dynamic>> punches) {
    if (punches.length < 4) {
      return ('');
    }

    DateTime shiftEnd;
    DateTime checkOut = DateTime.parse(punches[3]['punch_time'].toString());

    switch (punches[0]['shiftType']) {
      case 'Morning':
        shiftEnd = DateTime(checkOut.year, checkOut.month, checkOut.day, 20, 0, 0);
        break;
      case 'Night':
        shiftEnd = DateTime(checkOut.year, checkOut.month, checkOut.day, 8, 0, 0);
        break;
      case 'General':
        shiftEnd = DateTime(checkOut.year, checkOut.month, checkOut.day, 18, 0, 0);
        break;
      default:
        return ('');
    }

    // Calculate early leave minutes
    int earlyLeaveMinutes = checkOut.isBefore(shiftEnd) ? shiftEnd.difference(checkOut).inMinutes : 0;

    return (earlyLeaveMinutes.toString());
  }


  int calculateActTime(List<Map<String, dynamic>> entries) {
    if (entries.isEmpty || entries.length % 2 != 0) {
      return 0;
    }

    int actTime = 0;

    for (int i = 0; i < entries.length; i += 2) {
      DateTime checkIn = DateTime.parse(entries[i]['punch_time'].toString());
      DateTime lunchOut = DateTime.parse(entries[i + 1]['punch_time'].toString());

      actTime += lunchOut.difference(checkIn).inMinutes;
    }

    return actTime;
  }

/*
  num calculateWorkingSalary(int actTime, int reqTime, int monthlySalary) {
    int daysInMonth = DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day;

    if (actTime >= reqTime) {
      return calculateDailySalary(monthlySalary, daysInMonth);
    }

    double salaryPerMinute = calculateDailySalary(monthlySalary, daysInMonth) / reqTime;
    double pointValue = salaryPerMinute * actTime;
    int workingSalary = pointValue.round();

    return workingSalary;
  }
*/
  String calculateReqTime(List<Map<String, dynamic>> punches) {
    if (punches.length < 2) {
      return ('');
    }

    switch (punches[0]['shiftType']) {
      case 'Morning':
        return ('690');
      case 'General':
        return ('540');
      case 'Night':
        return ('720');
      default:
        return ('');
    }
  }
  Future<void> customerDataToDatabase() async {
    List<Map<String, dynamic>> entries = await fetchUnitEntries();

    Map<String, List<Map<String, dynamic>>> groupedEntries = {};
    for (var entry in entries) {
      String empCode = entry['emp_code'].toString();
      if (!groupedEntries.containsKey(empCode)) {
        groupedEntries[empCode] = [];
      }
      groupedEntries[empCode]!.add(entry);
    }

    List<Future<void>> insertFutures = [];

    for (var empEntry in groupedEntries.entries) {
      bool isPresent = groupedEntries[empEntry.key]!.length <= 4;

      List<Map<String, dynamic>> empData = empEntry.value;
      if (empData.length >= 3 &&
          empData[1]['punch_time'] == empData[2]['punch_time']) {
        print('Error: Lunch Out and Lunch In times are the same for emp_code ${empEntry.key}');
        continue; // Skip this entry
      }
      Map<String, dynamic> dataToInsertcustomer = {
        "emp_code": empEntry.key,
        "first_name": empData.first['first_name'].toString(),
        'inDate': DateFormat('yyyy-MM-dd').format(
            DateTime.parse(empData.first['punch_time'].toString())),
        'shiftType': empData.first['shiftType'],
        'check_in': empData.isNotEmpty
            ? DateFormat('HH:mm:ss').format(
            DateTime.parse(empData[0]['punch_time'].toString()).toLocal())
            : '',
        'lunch_out': empData.length >= 2
            ? DateFormat('HH:mm:ss').format(
            DateTime.parse(empData[1]['punch_time'].toString()).toLocal())
            : '',
        'lunch_in': empData.length >= 3
            ? DateFormat('HH:mm:ss').format(
            DateTime.parse(empData[2]['punch_time'].toString()).toLocal())
            : '',
        'check_out': empData.length >= 4
            ? DateFormat('HH:mm:ss').format(
            DateTime.parse(empData[3]['punch_time'].toString()).toLocal())
            : '',
        'latecheck_in': calculateLate(groupedEntries[empEntry.key]!),
        'late_lunch': calculateLateLunch(groupedEntries[empEntry.key]!),
        'earlycheck_out': calculateEarlyLeave(
            groupedEntries[empEntry.key]!),
        //'req_time': calculateReqTime(groupedEntries[empEntry.key]!),
        'req_time': "690",
        'act_time': isPresent ? calculateActTime(groupedEntries[empEntry.key]!)
            .toString():'0',
        // 'working_salary': calculateWorkingSalary(
        //   calculateActTime(groupedEntries[empEntry.key]!),
        //   int.parse(calculateReqTime(groupedEntries[empEntry.key]!)),
        //   empData.first['salary'],
        // )?.toString() ?? '',
        // 'salary': calculateSalary(
        //     empData.first['salary'], empData.first['salaryType'],
        //     daysInMonth),
        'salaryType': isPresent ? empData.first['salaryType'].toString():'',
        'salary': isPresent ? empData.first['salary'].toString():"0",
        //'salaryType': widget.shiftType.toString(),
        'remark': isPresent ? 'P' : 'A',
      };

      insertFutures.add(insertDatacustomer(dataToInsertcustomer));

      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString("key", "Your data here");

      print("Data auto-saved at ${DateTime.now()}");

      print('Check-In: ${dataToInsertcustomer["check_in"]}');
      print('Lunch_out: ${dataToInsertcustomer["lunch_out"]}');

    }

    try {
      await Future.wait(insertFutures);
      print('All data inserted successfully');
    } catch (e) {
      print('Error inserting data: $e');
    }
  }

  // double calculateDailySalary(int monthlySalary, int daysInMonth) {
  //   double dailySalary = monthlySalary / daysInMonth;
  //   return (dailySalary >= 50) ? dailySalary.ceilToDouble() : dailySalary.floorToDouble();
  // }
  late int daysInMonth;

  Map<String, dynamic> dataToInsertcustomer = {};
  bool isDialogShowing = false;

  Future<void> insertDatacustomer(Map<String, dynamic> dataToInsertcustomer) async {
    const String apiUrl = 'http://localhost:3309/attandance_entry'; // Replace with your server details
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({'dataToInsertcustomer': dataToInsertcustomer}),
      );
      if (response.statusCode == 200) {
        print('TableData inserted successfully');

        // Show the dialog only if it's not already showing
        if (!isDialogShowing) {
          isDialogShowing = true;
          showSuccessDialog();
        }
      } else {
        print('Failed to Table insert data');
        throw Exception('Failed to Table insert data');
      }
    } catch (e) {
      print('Error: $e');
      throw Exception('Error: $e');
    }
  }
  void showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: const Text('Save Successfully'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                //emp_code.clear();
                isDialogShowing = false; // Reset the flag when the dialog is closed
                Navigator.of(context).pop(); // Close the dialog
              },
              child:const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  double calculateSalary(int monthlySalary, String? salaryType, int daysInMonth) {
    if (salaryType == 'Daily') {
      return monthlySalary.toDouble();
    }
    /* else if (salaryType == 'Weekly'){
      // return (monthlySalary / 7).floorToDouble();
      return monthlySalary.toDouble();
    }*/
    else if (salaryType == 'Monthly') {
      return monthlySalary.toDouble();

      // double dailySalary = monthlySalary / daysInMonth;
      // return (dailySalary >= 50) ? dailySalary.ceilToDouble() : dailySalary.floorToDouble();
    }
    else {
      return 0.0;
    }
  }


  @override
  Widget build(BuildContext context) {
    return MyScaffold(
      route: "morning_shift",
      body: Form(
        key: GlobalKey<FormState>(),
        child: SingleChildScrollView(
          child: Wrap(
            children: [
              SizedBox(height: 20,),
              SingleChildScrollView(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: fetchUnitEntries(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (snapshot.data != null && snapshot.data!.isNotEmpty) {
                      Map<String, List<Map<String, dynamic>>> groupedEntries = {};
                      for (var entry in snapshot.data!) {
                        String empAndDateKey = '${entry['emp_code']}_${entry['punch_date']}';
                        if (!groupedEntries.containsKey(empAndDateKey)) {
                          groupedEntries[empAndDateKey] = [];
                        }
                        groupedEntries[empAndDateKey]!.add(entry);
                      }

                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: DataTable(
                          columnSpacing: 130.0,
                          columns: const [
                            DataColumn(label: Text('Emp Code', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
                            DataColumn(label: Text('Emp Name', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
                            DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
                            DataColumn(label: Text('Check In', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
                            DataColumn(label: Text('Lunch Out', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
                            DataColumn(label: Text('Lunch In', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
                            DataColumn(label: Text('Check Out', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
                          ],
                          rows: groupedEntries.entries.map<DataRow>((empEntry) {
                            return DataRow(
                              cells: [
                                DataCell(Center(child: Text(empEntry.value.first['emp_code'].toString()))),
                                DataCell(Center(child: Text(empEntry.value.first['first_name'].toString()))),
                                DataCell(Center(child: Text(
                                  empEntry.value.isNotEmpty
                                      ? DateFormat('yyyy-MM-dd').format(DateTime.parse(empEntry.value[0]['punch_time'].toString()).toLocal())
                                      : '',
                                ))),
                                DataCell(Center(child: Text(
                                  empEntry.value.isNotEmpty
                                      ? DateFormat('HH:mm:ss').format(DateTime.parse(empEntry.value[0]['punch_time'].toString()).toLocal())
                                      : '',
                                ))),
                                DataCell(Center(child: Text(
                                  empEntry.value.length >= 2
                                      ? DateFormat('HH:mm:ss').format(DateTime.parse(empEntry.value[1]['punch_time'].toString()).toLocal())
                                      : '',
                                ))),
                                DataCell(Center(child: Text(
                                  empEntry.value.length >= 3
                                      ? DateFormat('HH:mm:ss').format(DateTime.parse(empEntry.value[2]['punch_time'].toString()).toLocal())
                                      : '',
                                ))),
                                DataCell(Center(child: Text(
                                  empEntry.value.length >= 4
                                      ? DateFormat('HH:mm:ss').format(DateTime.parse(empEntry.value[3]['punch_time'].toString()).toLocal())
                                      : '',
                                ))),
                              ],
                            );
                          }).toList(),
                        ),
                      );
                    } else {
                      return const Center(
                        child: Column(
                          children: [
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'No Data Available',
                                style: TextStyle(
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  /*Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: MaterialButton(
                      color: Colors.green.shade600,
                      onPressed: (){
                        customerDataToDatabase();
                      },
                      child: const Text("SAVE",style: TextStyle(color: Colors.white),),),
                  ),*/
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: MaterialButton(
                      color: Colors.green.shade600,
                      onPressed: (){
                        //Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (context)=> const Home()));
                      },
                      child: const Text("BACK",style: TextStyle(color: Colors.white),),),

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
class MyScaffold extends StatelessWidget {
  final String route;
  final Widget body;

  const MyScaffold({required this.route, required this.body});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text(route),
      // ),
      body: body,
    );
  }
}