import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../home.dart';

class NightShift extends StatefulWidget {
  const NightShift({Key? key}) : super(key: key);
  @override
  State<NightShift> createState() => _NightShiftState();
}
class _NightShiftState extends State<NightShift> {
  double calculateDailySalary(int monthlySalary, int daysInMonth) {
    double dailySalary = monthlySalary / daysInMonth;
    return (dailySalary >= 50) ? dailySalary.ceilToDouble() : dailySalary.floorToDouble();
  }
  late int daysInMonth;
  @override
  void dispose() {
    super.dispose();
  }

  double dailySalary = 0.0;
  late DateTime checkout;
  late DateTime checkin;
  @override
  late DateTime? fromDateAsDateTime;
  late DateTime? toDateAsDateTime;
  @override
  void initState() {
    super.initState();
    daysInMonth = DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day;
  }

  Map<String, dynamic> dataToInsertcustomer = {};
  bool isDialogShowing = false;

  Future<void> insertDatacustomer(List<Map<String, dynamic>> dataToInsert) async {
    const String apiUrl = 'http://localhost:3309/attandance_entry'; // Replace with your server details
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({'dataToInsertcustomer': dataToInsert}),
      );
      if (response.statusCode == 200) {
        print('TableData inserted successfully');

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

  void onSaveButtonPressed() async {
    try {
      List<Map<String, dynamic>> entries = await fetchUnitEntries();

      if (entries.isNotEmpty) {
        List<Map<String, dynamic>> nightShiftEntries = [];
        for (var entry in entries) {
          if (entry['shiftType'] == 'Night') {
            nightShiftEntries.add(entry);
          }
        }
        List<Map<String, dynamic>> processedNightShiftEntries = processNightShiftEntries(nightShiftEntries);
        for (var processedEntry in processedNightShiftEntries) {
          await insertDatacustomer([processedEntry]);
        }
        if (!isDialogShowing) {
          isDialogShowing = true;
          showSuccessDialog();
        }
      } else {
        print('No data available to insert.');
      }
    } catch (e) {
      print('Error inserting data: $e');
    }
  }


  void showSuccessDialog() {
    showDialog(
      context: context, // Make sure to have access to the BuildContext
      builder: (BuildContext context) {
        return AlertDialog(
          content: Text('Save Successfully'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                emp_code.clear();
                isDialogShowing = false; // Reset the flag when the dialog is closed
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
  int calculateLateMinutes(String checkInTime, String loginTime) {
    DateTime checkIn = DateFormat('HH:mm:ss').parse(checkInTime);
    DateTime login = DateFormat('HH:mm:ss').parse(loginTime);

    if (checkIn.isAfter(login)) {
      Duration lateDuration = checkIn.difference(login);
      return lateDuration.inMinutes;
    } else {
      return 0;
    }
  }
  int calculateEarlyCheckout(String checkOutTime, String logoutTime) {
    DateTime checkOut = DateFormat('HH:mm:ss').parse(checkOutTime);
    DateTime logout = DateFormat('HH:mm:ss').parse(logoutTime);

    if (checkOut.isBefore(logout) || checkOut.isAtSameMomentAs(logout)) {
      Duration earlyDuration = logout.difference(checkOut);
      return earlyDuration.inMinutes;
    } else {
      return 0;
    }
  }
  int timeToMinutes(String time) {
    List<String> parts = time.split(':');
    int hours = int.parse(parts[0]);
    int minutes = int.parse(parts[1]);
    return hours * 60 + minutes;
  }
  double calculateSalary(int monthlySalary, String? salaryType, int daysInMonth) {
    if (salaryType == 'Daily') {
      return monthlySalary.toDouble();
    }
    else if (salaryType == 'Monthly') {
      return monthlySalary.toDouble();
    }
    else {
      return 0.0;
    }
  }

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
  bool isCheckInTime(String punchTime, String currentDate) {
    DateTime dateTime = DateTime.parse('$currentDate $punchTime');
    DateTime checkInStartTime = DateTime.parse('$currentDate 18:00:00');
    DateTime checkInEndTime = DateTime.parse('$currentDate 22:00:00');
    return dateTime.isAfter(checkInStartTime) && dateTime.isBefore(checkInEndTime);
  }
  bool isCheckOutTime(String punchTime, String currentDate) {
    DateTime dateTime = DateTime.parse('$currentDate $punchTime');
    DateTime checkOutStartTime = DateTime.parse('$currentDate 00:00:00');
    DateTime checkOutEndTime = DateTime.parse('$currentDate 12:00:00');
    return dateTime.isAfter(checkOutStartTime) && dateTime.isBefore(checkOutEndTime);
  }
  List<Map<String, dynamic>> processNightShiftEntries(List<Map<String, dynamic>> nightShiftEntries) {
    List<Map<String, dynamic>> processedEntries = [];

    int i = 0;
    while (i < nightShiftEntries.length) {
      Map<String, dynamic> entry1 = nightShiftEntries[i];
      DateTime? dateTime1 = entry1['punch_time'] != null ? DateTime.tryParse(entry1['punch_time'].toString()) : null;

      String combinedDate = dateTime1 != null ? DateFormat('yyyy-MM-dd').format(dateTime1) : '';

      String chkin = '';
      String chkout = '';

      if (dateTime1 != null && entry1['punch_time']?.toString().isNotEmpty == true) {
        chkin = DateFormat('HH:mm:ss').format(dateTime1.toLocal());
      }

      int checkInMinutes = timeToMinutes(chkin);
      int checkOutMinutes = 0;
      DateTime? lastPunchTime = dateTime1;

      // Find consecutive punch times for the same employee and consider them part of the same shift
      while (i + 1 < nightShiftEntries.length &&
          nightShiftEntries[i + 1]['emp_code'] == entry1['emp_code'] &&
          DateTime.tryParse(nightShiftEntries[i + 1]['punch_time']!.toString()) != null) {
        Map<String, dynamic> entry2 = nightShiftEntries[i + 1];
        DateTime? dateTime2 = DateTime.tryParse(entry2['punch_time'].toString());

        if (dateTime2 != null) {
          chkout = DateFormat('HH:mm:ss').format(dateTime2.toLocal());
          checkOutMinutes = timeToMinutes(chkout);
          lastPunchTime = dateTime2;
        }

        i++;
      }

      int expectedCheckInMinutes = timeToMinutes('20:00:00');
      int expectedCheckOutMinutes = timeToMinutes('08:00:00');
      int firstHalfEndMinutes = timeToMinutes('24:00:00');
      int secondHalfStartMinutes = timeToMinutes('00:00:00');

      int firstHalfDuration = firstHalfEndMinutes - checkInMinutes;
      int secondHalfDuration = checkOutMinutes - secondHalfStartMinutes;

      int actTime = firstHalfDuration + secondHalfDuration;

      int lateCheckIn = (checkInMinutes > expectedCheckInMinutes) ? (checkInMinutes - expectedCheckInMinutes) : 0;
      int earlyCheckOut = (checkOutMinutes < expectedCheckOutMinutes) ? (expectedCheckOutMinutes - checkOutMinutes) : 0;

      Map<String, dynamic> processedEntry = {
        'emp_code': entry1['emp_code'],
        'first_name': entry1['first_name'],
        'inDate': combinedDate,
        'outDate': lastPunchTime != null ? DateFormat('yyyy-MM-dd').format(lastPunchTime) : combinedDate,
        'shiftType': 'Night',
        'check_in': chkin,
        'check_out': chkout,
        'lunch_out': '0',
        'lunch_in': '0',
        'latecheck_in': formatMinutes(lateCheckIn),
        'earlycheck_out': formatMinutes(earlyCheckOut),
        'req_time': '720',
        'act_time': (chkin.isNotEmpty && chkout.isNotEmpty && chkout != '00:00') ? actTime.toString():'0',
        //'salary': calculateSalary(entry1['salary'], entry1['salaryType'], daysInMonth),
        'salaryType': (chkin.isNotEmpty && chkout.isNotEmpty && chkout != '00:00') ? entry1['salaryType'].toString():'',
        'salary': (chkin.isNotEmpty && chkout.isNotEmpty && chkout != '00:00') ? entry1['salary'].toString() : '0',
        //'remark': (chkin.isNotEmpty && chkout.isNotEmpty && chkout != '00:00') ? 'P' : 'A',
        'remark': 'P',
      };

      processedEntries.add(processedEntry);

      i++;
    }

    return processedEntries;
  }


  String formatMinutes(int minutes) {
    return minutes.toString();
  }


  Future<List<Map<String, dynamic>>> fetchUnitEntries() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:3309/attendance_view_night'));

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

  List<Map<String, dynamic>> filteredCodeData = [];
  TextEditingController emp_code = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  List<Map<String, dynamic>> filteredData = [];
  List<Map<String, dynamic>> data = [];
  bool showInitialData = true;








  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

  }




  @override
  Widget build(BuildContext context) {
    return  MyScaffold(
        route: "Night Shift",
        body: Form(
            key: _formKey,
            child:SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(
                      child: Column(
                        children: [
                          Wrap(
                              children: [
                                SizedBox(height: 20,),
                                Padding(
                                  padding: const EdgeInsets.all(2.0),
                                  child: Container(
                                    width: double.infinity, // Set the width to full page width
                                    padding: EdgeInsets.all(16.0), // Add padding for spacing
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      border: Border.all(color: Colors.grey), // Add a border for the box
                                      borderRadius: BorderRadius.circular(10.0), // Add border radius for rounded corners
                                    ),
                                    child: Column(
                                      children: [
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
                                                List<Map<String, dynamic>> nightShiftEntries = [];
                                                for (var entry in snapshot.data!) {
                                                  if (entry['shiftType'] == 'Night') {
                                                    nightShiftEntries.add(entry);
                                                  } else {
                                                    String date = DateFormat('yyyy-MM-dd').format(DateTime.parse(entry['punch_time'].toString()));
                                                    if (!groupedEntries.containsKey(date)) {
                                                      groupedEntries[date] = [];
                                                    }
                                                    groupedEntries[date]!.add(entry);
                                                  }
                                                }
                                                DateTime currentDate = DateTime.now().toLocal();
                                                DateTime previousDate = currentDate.subtract(Duration(days: 1));
                                                List<Map<String, dynamic>> processedNightShiftEntries = processNightShiftEntries(nightShiftEntries);
                                                for (var processedEntry in processedNightShiftEntries) {
                                                  String date = processedEntry['date'].toString();
                                                  if (!groupedEntries.containsKey(date)) {
                                                    groupedEntries[date] = [];
                                                  }
                                                  groupedEntries[date]!.add(processedEntry);
                                                }

                                                return Container(
                                                  padding: const EdgeInsets.all(4.0),
                                                  child: SingleChildScrollView(
                                                    scrollDirection: Axis.horizontal,
                                                    child: DataTable(
                                                      columnSpacing: 130.0,
                                                      columns: const [
                                                        DataColumn(label: Text('Emp Code', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
                                                        DataColumn(label: Text('Emp Name', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
                                                        DataColumn(label: Text('IN Date', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
                                                        DataColumn(label: Text('Out Date', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
                                                        DataColumn(label: Text('Check In', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
                                                        DataColumn(label: Text('Check Out', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
                                                      ],
                                                      rows: processedNightShiftEntries.map<DataRow>((entry) {
                                                        return DataRow(
                                                          cells: [
                                                            DataCell(Center(child: Text(entry['emp_code'].toString()))),
                                                            DataCell(Center(child: Text(entry['first_name'].toString()))),
                                                            DataCell(Center(child: Text(entry['inDate'].toString()))),
                                                            DataCell(Center(child: Text(entry['outDate'].toString()))),
                                                            DataCell(Center(child: Text(entry['check_in'].toString()))),
                                                            DataCell(Center(child: Text(entry['check_out'].toString()))),
                                                          ],
                                                        );
                                                      }).toList(),
                                                    ),
                                                  ),
                                                );
                                              }
                                              else {
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
                                      ],
                                    ),

                                  ),
                                ),
                              ]
                          ),
                        ],
                      ),
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                       /* Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: MaterialButton(
                            color: Colors.green.shade600,
                            onPressed: () async {
                              onSaveButtonPressed();
                            },

                            child: const Text("Save",style: TextStyle(color: Colors.white),),),

                        ),*/
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: MaterialButton(
                            color: Colors.green.shade600,
                            onPressed: (){
                              //Navigator.pop(context);
                              Navigator.push(context, MaterialPageRoute(builder: (context)=> const Home()));

                            },
                            child: const Text("Back",style: TextStyle(color: Colors.white),),),

                        ),
                      ],
                    ),
                  ],
                )
            )
        ));
  }
}
class MyScaffold extends StatelessWidget {
  final String route;
  final Widget body;

  MyScaffold({required this.route, required this.body});

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