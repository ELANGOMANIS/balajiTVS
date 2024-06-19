
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';
import '../../main.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show ByteData, Uint8List, rootBundle;
import 'package:pdf/widgets.dart' as pw;
class AttendanceBalaji extends StatefulWidget {
  const AttendanceBalaji({Key? key}) : super(key: key);

  @override
  State<AttendanceBalaji> createState() => _AttendanceBalajiState();
}
class _AttendanceBalajiState extends State<AttendanceBalaji> {
  late Future<List<Map<String, dynamic>>> attendanceDetailsFuture;
  final TextEditingController fromDateController = TextEditingController();
  final TextEditingController toDateController = TextEditingController();
  final TextEditingController empCodeController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  String selectedSuggestion = ''; // Track selected suggestion
  @override
  void initState() {
    super.initState();
    attendanceDetailsFuture = fetchAttendanceBalaji();
  }
  void _applyFilters() {
    setState(() {
      attendanceDetailsFuture = fetchAttendanceBalaji(
        fromDate: fromDateController.text,
        toDate: toDateController.text,
        empCode: empCodeController.text,
        firstName: firstNameController.text,
      );
    });
  }
  Future<List<Map<String, dynamic>>> fetchAttendanceBalaji({String? fromDate, String? toDate, String? empCode, String? firstName,}) async {
    try {
      final queryParameters = {
        if (fromDate != null) 'fromDate': fromDate,
        if (toDate != null) 'toDate': toDate,
        if (empCode != null) 'emp_code': empCode,
        if (firstName != null) 'first_name': firstName,
      };

      final uri = Uri.http(
        'localhost:3309',
        '/get_attendance_overall',
        queryParameters,
      );

      final response = await http.get(uri);
      print("response ${response.statusCode}");

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Failed to load attendance summary');
      }
    } catch (error) {
      print('Error fetching attendance summary: $error');
      throw Exception('Failed to load attendance summary');
    }
  }

  Future<List<String>> getSuggestions(String field, String pattern) async {
    final List<String> suggestions = [];
    try {
      final response = await http.get(
        Uri.http('localhost:3309', '/get_employee', {'field': field, 'pattern': pattern}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        suggestions.addAll(data
            .where((item) =>
        item['emp_code'].toString().toLowerCase().contains(pattern.toLowerCase()) ||
            item['first_name'].toString().toLowerCase().contains(pattern.toLowerCase()))
            .map((item) => '${item['emp_code']} - ${item['first_name']}'));
      } else {
        throw Exception('Failed to fetch suggestions');
      }
    } catch (error) {
      print('Error fetching suggestions: $error');
      throw Exception('Failed to fetch suggestions');
    }

    return suggestions;
  }

  Future<void> _generatePdfAndDownload(List<Map<String, dynamic>> data) async {
    final pdf = pw.Document();
    final columnWidths = <int, pw.TableColumnWidth>{
      0: pw.FixedColumnWidth(40),
      1: pw.FixedColumnWidth(90),
      2: pw.FixedColumnWidth(80),
      3: pw.FixedColumnWidth(90),
      4: pw.FixedColumnWidth(80),
      5: pw.FixedColumnWidth(75),
      6: pw.FixedColumnWidth(75),
      7: pw.FixedColumnWidth(80),
      8: pw.FixedColumnWidth(75),

    };
    // final imageData = await rootBundle.load('TVS_Motor_Company-Logo.wine.png');
    // final imageBytes = imageData.buffer.asUint8List();

    final headers = ['S.No', 'In Date', 'Emp Code', 'Name', 'Shift', 'Check\nin', 'Check\nout', 'Late\nin','Early\nout', 'required\nTime', 'Total Hrs', 'Remark'];

    const int rowsPerPage = 20; // Define the number of rows per page
    int totalPages = (data.length / rowsPerPage).ceil();

    for (int page = 0; page < totalPages; page++) {
      final startRow = page * rowsPerPage;
      final endRow = (startRow + rowsPerPage) > data.length ? data.length : (startRow + rowsPerPage);
      final pageData = data.sublist(startRow, endRow);


      pdf.addPage(
        pw.MultiPage(
          header: (pw.Context context) {
            return pw.Container(
                alignment: pw.Alignment.center,
                padding: pw.EdgeInsets.all(10),
                child: pw.Column(
                  children: [
                    pw.Row(
                      children: [
                        pw.Text('Attendance Report', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                        pw.Spacer(),
                        //  pw.Image(pw.MemoryImage(imageBytes), width: 50, height: 50)


                      ],

                    ),

                    pw.Divider(),
                  ],

                )

            );
          },
          build: (pw.Context context) {
            return [
              pw.Table.fromTextArray(
                // columnWidths: columnWidths,
                headers: headers,
                cellStyle: pw.TextStyle(fontSize: 6),
                headerStyle: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold),
                data: pageData.map((attendance) {
                  return [
                    '${data.indexOf(attendance) + 1}',
                    attendance["inDate"] != null ? DateFormat('dd-MM-yyyy').format(DateTime.parse("${attendance["inDate"]}").toLocal()) : "",
                    attendance['emp_code'] ?? '',
                    attendance['first_name'] ?? '',
                    attendance['shiftType'] ?? '',
                    attendance['check_in'] ?? '',
                    attendance['check_out'] ?? '',
                    formatDuration(attendance['latecheck_in'] ?? '') ?? '',
                    formatDuration(attendance['earlycheck_out'] ?? '') ?? '',
                    attendance['req_time'] ?? '',
                    attendance['act_time'] ?? '',

                    attendance['remark'] ?? '',
                  ];
                }).toList(),
              )
            ];
          },
        ),
      );
    }

    final Uint8List bytes = await pdf.save();
    await Printing.sharePdf(bytes: bytes, filename: 'attendance_report.pdf');
  }

  String extractEmpCode(String suggestion) {
    final parts = suggestion.split(' - ');
    if (parts.length >= 2) {
      return parts[1]; /// Get the first part (emp_code) use parts 0 & get a first name use 1
    }
    return ''; // Return empty string if separation fails
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
                          SizedBox(height: 10,),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: SizedBox(
                                  height:50,
                                  width: 240,

                                  child: TextFormField(

                                    controller: fromDateController,
                                    onTap: () {
                                      showDatePicker(
                                        context: context,
                                        initialDate: DateTime.now(),
                                        firstDate: DateTime(2015, 8),
                                        lastDate: DateTime(2101),
                                      ).then((value) {
                                        if (value != null) {
                                          setState(() {
                                            fromDateController.text = DateFormat('yyyy-MM-dd').format(value);
                                          });
                                        }
                                      });
                                    },
                                    decoration: InputDecoration(
                                      labelText: 'From Date (YYYY-MM-DD)',
                                      labelStyle: TextStyle(fontSize: 12),
                                      suffixIcon: IconButton(
                                        icon: Icon(Icons.date_range),
                                        onPressed: () async {
                                          final DateTime? picked = await showDatePicker(
                                            context: context,
                                            initialDate: DateTime.now(),
                                            firstDate: DateTime(2015, 8),
                                            lastDate: DateTime(2101),
                                          );
                                          if (picked != null && picked != DateTime.parse(fromDateController.text)) {
                                            setState(() {
                                              fromDateController.text = DateFormat('yyyy-MM-dd').format(picked);
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Flexible(
                                child: SizedBox(
                                  height:50,
                                  width: 240,
                                  child: TextFormField(
                                    controller: toDateController,
                                    onTap: () {
                                      showDatePicker(
                                        context: context,
                                        initialDate: DateTime.now(),
                                        firstDate: DateTime(2015, 8),
                                        lastDate: DateTime(2101),
                                      ).then((value) {
                                        if (value != null) {
                                          setState(() {
                                            toDateController.text = DateFormat('yyyy-MM-dd').format(value);
                                          });
                                        }
                                      });
                                    },
                                    decoration: InputDecoration(
                                      labelText: 'To Date (YYYY-MM-DD)',
                                      labelStyle: TextStyle(fontSize: 12),
                                      suffixIcon: IconButton(
                                        icon: Icon(Icons.date_range),
                                        onPressed: () async {
                                          final DateTime? picked = await showDatePicker(
                                            context: context,
                                            initialDate: DateTime.now(),
                                            firstDate: DateTime(2015, 8),
                                            lastDate: DateTime(2101),
                                          );
                                          if (picked != null && picked != DateTime.parse(toDateController.text)) {
                                            setState(() {
                                              toDateController.text = DateFormat('yyyy-MM-dd').format(picked);
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              /*   Flexible(
                                child: SizedBox(
                                  height:50,
                                  width: 240,
                                  child: TypeAheadFormField(
                                    textFieldConfiguration: TextFieldConfiguration(
                                      controller: empCodeController,
                                      decoration: InputDecoration(labelText: 'Employee Code',                                      labelStyle: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    suggestionsCallback: (pattern) async {
                                      return getSuggestions('emp_code', pattern);
                                    },
                                    itemBuilder: (context, suggestion) {
                                      return ListTile(
                                        title: Text(suggestion),
                                      );
                                    },
                                    onSuggestionSelected: (suggestion) {
                                      setState(() {
                                        selectedSuggestion = suggestion;
                                        empCodeController.text = extractEmpCode(suggestion); // Set empCodeController
                                      });
                                    },
                                  ),
                                ),
                              ),*/
                              Flexible(
                                child: SizedBox(
                                  height:50,
                                  width: 240,
                                  child: TypeAheadFormField(
                                    textFieldConfiguration: TextFieldConfiguration(
                                      controller: firstNameController,
                                      decoration: InputDecoration(labelText: 'First Name / Employee Code',
                                        labelStyle: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    suggestionsCallback: (pattern) async {
                                      return getSuggestions('first_name', pattern);
                                    },
                                    itemBuilder: (context, suggestion) {
                                      return ListTile(
                                        title: Text(suggestion),
                                      );
                                    },
                                    onSuggestionSelected: (suggestion) {
                                      setState(() {
                                        selectedSuggestion = suggestion;
                                        firstNameController.text = extractEmpCode(suggestion); // Set empCodeController
                                      });
                                    },
                                  ),
                                ),
                              ),
                              Flexible(
                                child: ElevatedButton(
                                  onPressed: _applyFilters,
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white, backgroundColor: Colors.blue, // text color
                                    // padding: EdgeInsets.symmetric(vertical: 1, horizontal: 40),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    textStyle: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.filter_alt_outlined), // Optional: Add an icon
                                      SizedBox(width: 10), // Optional: Add space between icon and text
                                      Text('Apply Filters'),
                                    ],
                                  ),
                                ),
                              ),

                            ],
                          ),
                          SizedBox(height: 10,),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Flexible(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final data = await attendanceDetailsFuture;
                                    await _generatePdfAndDownload(data);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white, backgroundColor: Colors.red, // text color
                                    // padding: EdgeInsets.symmetric(vertical: 1, horizontal: 40),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    textStyle: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.download), // Optional: Add an icon
                                      SizedBox(width: 10), // Optional: Add space between icon and text
                                      Text('pdf'),
                                    ],
                                  ),
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
                            return Center(child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return Text('No data available');
                          } else {
                            return PaginatedDataTable(
                              columnSpacing: 52.5,
                              rowsPerPage: 20,
                              columns: const [
                                DataColumn(label: Center(child: Text("S.No", style: TextStyle(fontWeight: FontWeight.bold),))),
                                DataColumn(label: Center(child: Text("Date", style: TextStyle(fontWeight: FontWeight.bold),))),
                                DataColumn(label: Center(child: Text("Name", style: TextStyle(fontWeight: FontWeight.bold),))),
                                DataColumn(label: Center(child: Text("Shift", style: TextStyle(fontWeight: FontWeight.bold),))),
                                DataColumn(label: Center(child: Text("Check-in", style: TextStyle(fontWeight: FontWeight.bold),))),
                                DataColumn(label: Center(child: Text("Check-out", style: TextStyle(fontWeight: FontWeight.bold),))),
                                DataColumn(label: Center(child: Text("latecheck-in", style: TextStyle(fontWeight: FontWeight.bold),))),
                                DataColumn(label: Center(child: Text("earlycheck-out", style: TextStyle(fontWeight: FontWeight.bold),))),
                                DataColumn(label: Center(child: Text("Total Hrs", style: TextStyle(fontWeight: FontWeight.bold),))),
                                DataColumn(label: Center(child: Text("Worked Hrs", style: TextStyle(fontWeight: FontWeight.bold),))),
                                DataColumn(label: Center(child: Text("Remark", style: TextStyle(fontWeight: FontWeight.bold),))),
                              ],
                              source: AttendanceDataSource(snapshot.data!),
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

        DataCell(Center(child: Text(attendance['first_name'] + ' - ' + attendance['emp_code'] ?? '')),),
        DataCell(Center(child: Text(attendance['shiftType'] ?? ''))),
        DataCell(Center(child: Text(attendance['check_in'] ?? ''))),
        DataCell(Center(child: Text(attendance['check_out'] ?? ''))),
        DataCell(Center(child: Text(formatDuration(attendance['latecheck_in'] ?? '')))),
        DataCell(Center(child: Text(formatDuration(attendance['earlycheck_out'] ?? '')))),
        DataCell(Center(child: Text(attendance['req_time'] ?? ''))),
        DataCell(Center(child: Text(attendance['act_time'] ?? ''))),
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

String formatDuration(String durationInMinutes) {
  try {
    if (durationInMinutes != null) {
      int minutes = int.tryParse(durationInMinutes) ?? 0; // Use int.tryParse with a fallback value of 0
      Duration duration = Duration(minutes: minutes);

      int hours = duration.inHours;
      int remainingMinutes = duration.inMinutes.remainder(60);

      String formattedDuration = '';

      if (hours > 0) {
        formattedDuration += '$hours h';
      }

      if (remainingMinutes > 0) {
        if (hours > 0) {
          formattedDuration += ' ';
        }
        formattedDuration += '$remainingMinutes m';
      }

      return formattedDuration.trim();
    }
  } catch (e) {
    // Handle the exception, e.g., log the error or return a default value
    print('Error formatting duration: $e');
  }

  return ""; // Return a default value if there's an error
}