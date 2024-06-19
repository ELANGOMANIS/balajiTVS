import 'dart:convert';
import 'dart:html';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:printing/printing.dart';
import '../../main.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pdfWidgets;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show ByteData, Uint8List, rootBundle;
import 'dart:convert';
import 'dart:io';

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
        data.forEach((item) {
          suggestions.add(item[field]);
        });
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
    final headers = ['S.No', 'Date', 'Emp Code', 'Name', 'Shift', 'Check-in', 'Check-out', 'Total Hrs', 'Remark'];

    const int rowsPerPage = 18; // Define the number of rows per page
    int totalPages = (data.length / rowsPerPage).ceil();

    for (int page = 0; page < totalPages; page++) {
      final startRow = page * rowsPerPage;
      final endRow = (startRow + rowsPerPage) > data.length ? data.length : (startRow + rowsPerPage);
      final pageData = data.sublist(startRow, endRow);

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Table.fromTextArray(
              headers: headers,
              data: pageData.map((attendance) {
                return [
                  '${data.indexOf(attendance) + 1}',
                  attendance["inDate"] != null ? DateFormat('dd-MM-yyyy').format(DateTime.parse("${attendance["inDate"]}").toLocal()) : "",
                  attendance['emp_code'] ?? '',
                  attendance['first_name'] ?? '',
                  attendance['shiftType'] ?? '',
                  attendance['check_in'] ?? '',
                  attendance['check_out'] ?? '',
                  attendance['act_time'] ?? '',
                  attendance['remark'] ?? '',
                ];
              }).toList(),
            );
          },
        ),
      );
    }

    final Uint8List bytes = await pdf.save();
    await Printing.sharePdf(bytes: bytes, filename: 'attendance_report.pdf');
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
                                      labelText: 'From',
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
                                      labelText: 'To',
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
                              Flexible(
                                child: SizedBox(
                                  height:50,
                                  width: 240,
                                  child: TypeAheadFormField(
                                    textFieldConfiguration: TextFieldConfiguration(
                                      style: TextStyle(fontSize: 12),
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
                                      empCodeController.text = suggestion;
                                    },
                                  ),
                                ),
                              ),
                              Flexible(
                                child: SizedBox(
                                  height:50,
                                  width: 240,
                                  child: TypeAheadFormField(
                                    textFieldConfiguration: TextFieldConfiguration(
                                      style: TextStyle(fontSize: 12),
                                      controller: firstNameController,
                                      decoration: InputDecoration(labelText: 'First Name',
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
                                      firstNameController.text = suggestion;
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
                              rowsPerPage: 18,
                              columns: const [
                                DataColumn(label: Center(child: Text("S.No", style: TextStyle(fontWeight: FontWeight.bold),))),
                                DataColumn(label: Center(child: Text("Date", style: TextStyle(fontWeight: FontWeight.bold),))),
                               // DataColumn(label: Center(child: Text("Emp Code", style: TextStyle(fontWeight: FontWeight.bold),))),
                                DataColumn(label: Center(child: Text("Name", style: TextStyle(fontWeight: FontWeight.bold),))),
                                DataColumn(label: Center(child: Text("Shift", style: TextStyle(fontWeight: FontWeight.bold),))),
                                DataColumn(label: Center(child: Text("Check-in", style: TextStyle(fontWeight: FontWeight.bold),))),
                                DataColumn(label: Center(child: Text("Check-out", style: TextStyle(fontWeight: FontWeight.bold),))),
                                DataColumn(label: Center(child: Text("Total Hrs", style: TextStyle(fontWeight: FontWeight.bold),))),
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
        //DataCell(Center(child: Text(attendance['emp_code'] ?? ''))),
        DataCell(Center(child: Text(attendance['first_name'] ?? ''))),
        DataCell(Center(child: Text(attendance['shiftType'] ?? ''))),
        DataCell(Center(child: Text(attendance['check_in'] ?? ''))),
        DataCell(Center(child: Text(attendance['check_out'] ?? ''))),
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
