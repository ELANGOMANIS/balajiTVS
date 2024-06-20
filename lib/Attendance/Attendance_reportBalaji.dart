
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../../main.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show ByteData, Uint8List, rootBundle;
import 'package:pdf/widgets.dart' as pw;

import '../home.dart';
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
  final TextEditingController shiftController = TextEditingController();
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
        shiftType: shiftController.text,
      );
    });
  }
/*
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
*/


  Future<List<Map<String, dynamic>>> fetchAttendanceBalaji({
    String? fromDate,
    String? toDate,
    String? empCode,
    String? firstName,
    String? shiftType, // Add shiftType parameter
  }) async {
    try {
      final queryParameters = {
        if (fromDate != null) 'fromDate': fromDate,
        if (toDate != null) 'toDate': toDate,
        if (empCode != null) 'emp_code': empCode,
        if (firstName != null) 'first_name': firstName,
        if (shiftType != null) 'shiftType': shiftType, // Add shiftType to query parameters
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
    final companyData = await Utils.fetchCompanyData();

    // Function to format the address
    String formatAddress(String address) {
      return address.split(',').map((part) {
        final buffer = StringBuffer();
        final words = part.trim().split(' ');
        var line = '';
        for (var word in words) {
          if ((line + word).length > 40) {
            buffer.writeln(line.trim());
            line = '';
          }
          line += '$word ';
        }
        if (line.isNotEmpty) {
          buffer.writeln(line.trim());
        }
        return buffer.toString().trim();
      }).join('\n');
    }

    // Create header widget with formatted address
    pw.Widget createHeader(String companyName, String address, String contact) {
      String formattedAddress = Utils.formatAddress(address); // Format the address

      return pw.Container(
        padding: pw.EdgeInsets.all(10),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              companyName,
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              formattedAddress,
              style: pw.TextStyle(
                fontSize: 10,
              ),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              contact,
              style: pw.TextStyle(
                fontSize: 10,
              ),
            ),
            pw.Divider(thickness: 1),
            pw.SizedBox(height: 8),
            pw.Text(
              'Employee Salary Report',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    final headers = [
      'S.No', 'Date', 'Emp Code', 'Name', 'Shift', 'Check\nin',
      'Check\nout', 'Late\nin','Early\nout', 'Required\nTime',
      'Total Hrs', 'Remark'
    ];

    const int rowsPerPage = 20; // Define the number of rows per page
    int totalPages = (data.length / rowsPerPage).ceil();

    for (int page = 0; page < totalPages; page++) {
      final startRow = page * rowsPerPage;
      final endRow = (startRow + rowsPerPage) > data.length ? data.length : (startRow + rowsPerPage);
      final pageData = data.sublist(startRow, endRow);

      pdf.addPage(
        pw.MultiPage(
          header: (pw.Context context) {
            return createHeader(
              companyData['companyName'],
              companyData['address'],
              companyData['contact'],
            );
          },
          build: (pw.Context context) {
            return [
              pw.Table.fromTextArray(
                headers: headers,
                headerStyle: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),

                cellStyle: pw.TextStyle(fontSize: 7),
                cellHeight: 16,
                columnWidths: {
                  0: pw.FixedColumnWidth(20),
                  1: pw.FixedColumnWidth(55),
                  2: pw.FixedColumnWidth(50),
                  3: pw.FixedColumnWidth(60),
                  4: pw.FixedColumnWidth(50),
                  5: pw.FixedColumnWidth(40),
                  6: pw.FixedColumnWidth(40),
                  7: pw.FixedColumnWidth(40),
                  8: pw.FixedColumnWidth(40),
                  9: pw.FixedColumnWidth(50),
                  10: pw.FixedColumnWidth(50),
                  11: pw.FixedColumnWidth(42),
                },
                cellAlignments: {
                  0: pw.Alignment.center,
                  1: pw.Alignment.center,
                  2: pw.Alignment.center,
                  3: pw.Alignment.center,
                  4: pw.Alignment.center,
                  5: pw.Alignment.center,
                  6: pw.Alignment.center,
                  7: pw.Alignment.center,
                  8: pw.Alignment.center,
                  9: pw.Alignment.center,
                  10: pw.Alignment.center,
                  11: pw.Alignment.center,
                },
                data: pageData.map((attendance) {
                  return [
                    '${data.indexOf(attendance) + 1}',
                    attendance["inDate"] != null
                        ? DateFormat('dd-MM-yyyy').format(DateTime.parse("${attendance["inDate"]}").toLocal())
                        : "",
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
              ),
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
                            Wrap(
                             children: [
                               Icon(Icons.report),
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
                          SizedBox(height: 15,),
                          Wrap(
                            children: [
                              SizedBox(
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
                                    labelText: 'From Date ',
                                    labelStyle: TextStyle(fontSize: 12),
                                    suffixIcon: Icon(Icons.date_range),
                                  ),
                                ),
                              ),
                              SizedBox(width: 10,),
                              SizedBox(
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
                                    labelText: 'To Date ',
                                    labelStyle: TextStyle(fontSize: 12),
                                    suffixIcon: Icon(Icons.date_range),
                                  ),
                                ),
                              ),
                              SizedBox(width: 10,),
                              SizedBox(
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
                              SizedBox(width: 10,),
                              SizedBox(
                                height:50,
                                width: 240,
                                child: TypeAheadFormField(
                                  textFieldConfiguration: TextFieldConfiguration(
                                    controller: shiftController,
                                    decoration: InputDecoration(labelText: 'Shift',
                                      labelStyle: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  suggestionsCallback: (pattern) async {
                                    List<String> suggestions = [];
                                    if (pattern.isNotEmpty) {
                                      suggestions = await Utils.getSuggestions();
                                    }
                                    return suggestions;
                                  },
                                  itemBuilder: (context, suggestion) {
                                    return ListTile(
                                      title: Text(suggestion),
                                    );
                                  },
                                  onSuggestionSelected: (suggestion) {
                                    shiftController.text = suggestion;
                                  },
                                ),
                              ),
                              SizedBox(width: 10,),

                              Card(
                                child: IconButton(
                                  icon: Icon(Icons.search),
                                  onPressed: _applyFilters,
                                ),
                              ),
                              SizedBox(width: 10,),

                              Card(
                                child: IconButton(
                                  icon: Icon(Icons.file_download),
                                  onPressed: () async {
                                    final data = await attendanceDetailsFuture;
                                    await _generatePdfAndDownload(data);
                                  },
                                ),
                              ),
                              SizedBox(width: 10,),

                              Card(
                                child: IconButton(
                                  icon: Icon(Icons.refresh),
                                  onPressed: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context)=>AttendanceBalaji()));
                                  },
                                ),
                              ),
                              Card(
                                child: IconButton(
                                  icon: Icon(Icons.arrow_back),
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
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
        DataCell(Center(child: Text( attendance['check_out'] == '00:00:00' ? '-' : attendance['check_out'] ))),
        DataCell(Center(child: Text(formatDuration(attendance['latecheck_in'] ?? '')))),
        DataCell(Center(child: Text(formatDuration(attendance['earlycheck_out'] ?? '')))),
        DataCell(Center(child: Text(formatDuration(attendance['req_time'] ?? '')))),
        DataCell(Center(child: Text(formatDuration(attendance['act_time'] ?? '')))),
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