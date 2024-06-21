import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:vinayaga_project/Attendance/salary.dart';
import '../home.dart';
import '../main.dart';
class CumulativeSalaryCalculation extends StatefulWidget {
  const CumulativeSalaryCalculation({Key? key}) : super(key: key);

  @override
  State<CumulativeSalaryCalculation> createState() =>
      _CumulativeSalaryCalculationState();
}
class _CumulativeSalaryCalculationState extends State<CumulativeSalaryCalculation> {
  String? selectedShiftType;
  DateTime? fromDate;
  DateTime? toDate;
  bool isCardVisible = false;

  List<Map<String, dynamic>> reportData = [];
  final List<String> _shiftTypes = [];
  final TextEditingController _typeAheadController = TextEditingController();
  Future<void> fetchReport() async {
    if (fromDate == null || toDate == null) {
      print("Please select both From Date and To Date");
      return;
    }
    final formattedFromDate = DateFormat('yyyy-MM-dd').format(fromDate!);
    final formattedToDate = DateFormat('yyyy-MM-dd').format(toDate!);
    final url = Uri.parse('http://localhost:3309/get_cumulative_salary?fromDate=$formattedFromDate&toDate=$formattedToDate&shiftType=$selectedShiftType');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        print('Report fetched successfully');
        final List<dynamic> responseData = json.decode(response.body);
        setState(() {
          reportData = responseData.cast<Map<String, dynamic>>();
        });
      } else {
        print('Failed to fetch report. Status Code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching report: $error');
    }
  }
  @override
  void dispose() {
    _typeAheadController.dispose();
    super.dispose();
  }

  double calculateTotalExtraProduction(List<Map<String, dynamic>> filteredData) {
    double totalExtraProduction = 0;
    for (var row in filteredData) {
      totalExtraProduction += double.tryParse(row['calculated_extraproduction'].toString()) ?? 0;
    }
    return totalExtraProduction;
  }

  Future<void> _selectFromDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != fromDate) {
      setState(() {
        fromDate = picked;
      });
    }
  }

  Future<void> _selectToDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != toDate) {
      setState(() {
        toDate = picked;
      });
    }
  }

  Future<void> _generatePdfAndDownload() async {
    final pdf = pw.Document();

    final companyData = await Utils.fetchCompanyData(); // Fetch company data

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

    final headers = ['S.No', 'Employee', 'No of Work Days', 'Total Req Time', 'Total Act Time', 'Monthly Salary', 'Deduction Salary', 'Total Salary'];
    const int rowsPerPage = 20;
    int totalPages = (reportData.length / rowsPerPage).ceil();

    for (int page = 0; page < totalPages; page++) {
      final startRow = page * rowsPerPage;
      final endRow = (startRow + rowsPerPage) > reportData.length ? reportData.length : (startRow + rowsPerPage);
      final pageData = reportData.sublist(startRow, endRow);

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

                },
                data: pageData.map((data) {
                  return [
                    '${reportData.indexOf(data) + 1}',
                    data['employee'] ?? '',
                    data['no_of_work_days']?.toString() ?? '',
                    formatDuration(data['total_req_time']?.toString()) ?? '',
                    formatDuration(data['total_act_time']?.toString()) ?? '',
                    '${data['monthly_salary']?.toString() ?? ''}',
                    '${data['deduction_salary']?.toString() ?? ''}',
                    '${data['total_salary']?.toString() ?? ''}',
                  ];
                }).toList(),
              ),
            ];
          },
        ),
      );
    }

    final Uint8List bytes = await pdf.save();
    await Printing.sharePdf(bytes: bytes, filename: 'Employee_salary_report.pdf');
  }

  String formatDuration(String? duration) {
    // Implement duration formatting logic here
    return duration ?? '';
  }


  @override
  Widget build(BuildContext context) {
    final formattedFromDate = DateFormat('dd-MM-yyyy (EEEE)').format(fromDate ?? DateTime.now());
    final formattedToDate = DateFormat('dd-MM-yyyy (EEEE)').format(toDate ?? DateTime.now());
    return MyScaffold(
      route: "salary_report",backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              SizedBox(height: 10),
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
                              SizedBox(width: 10),
                              Text(
                                'Salary Report - Weekly',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 10),
                              MaterialButton(onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SalaryCalculation(),
                                  ),
                                );
                              },
                                child: Text('Individual',style: TextStyle(color: Colors.blue),),
                              ),
                            ],
                          ),
                          SizedBox(height: 15,),

                          Padding(
                            padding: const EdgeInsets.only(right: 15),
                            child: Wrap(
                              children: [
                                SizedBox(
                                  height:50,
                                  width: 240,
                                  child: TextFormField(
                                    style: const TextStyle(fontSize: 13),
                                    readOnly: true,
                                    onTap: () async {
                                      await _selectFromDate(context);
                                    },
                                    controller: fromDate != null
                                        ? TextEditingController(
                                        text: DateFormat('yyyy-MM-dd')
                                            .format(fromDate!))
                                        : TextEditingController(),
                                    decoration: const InputDecoration(
                                      suffixIcon: Icon(Icons.calendar_month),
                                      filled: true,
                                      fillColor: Colors.white,
                                      labelText: "From Date",
                                      labelStyle: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 20,),
                                SizedBox(
                                  height:50,
                                  width: 240,
                                  child: TextFormField(
                                    style: TextStyle(fontSize: 13),
                                    readOnly: true,
                                    onTap: () async {
                                      await _selectToDate(context);
                                    },
                                    controller: toDate != null
                                        ? TextEditingController(
                                        text: DateFormat('yyyy-MM-dd')
                                            .format(toDate!))
                                        : TextEditingController(),
                                    decoration: const InputDecoration(
                                      suffixIcon: Icon(Icons.calendar_month),
                                      fillColor: Colors.white,
                                      filled: true,
                                      labelText: "To Date",
                                      labelStyle: TextStyle(fontSize: 12),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 20,),

                                SizedBox(
                                  height:50,
                                  width: 240,
                                  child: TypeAheadFormField(
                                    textFieldConfiguration: TextFieldConfiguration(
                                      controller: _typeAheadController, // Use the controller here.
                                      decoration: const InputDecoration(
                                        labelText: 'Shift Type',
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
                                        title: Text(suggestion.toString()),
                                      );
                                    },
                                    onSuggestionSelected: (suggestion) {
                                      setState(() {
                                        selectedShiftType = suggestion.toString();
                                        _typeAheadController.text = selectedShiftType!; // Update the controller text when an item is selected.
                                      });
                                    },
                                    validator: (value) {
                                      if (value!.isEmpty) {
                                        return 'Please select a shift type';
                                      }
                                      return null;
                                    },
                                    onSaved: (value) => selectedShiftType = value,
                                  ),
                                ),
                                SizedBox(width: 20,),

                                Card(
                                  child: IconButton(
                                    icon: Icon(Icons.search),
                                    onPressed: () {
                                      fetchReport();
                                      setState(() {
                                        isCardVisible = true;
                                      });
                                    },
                                  ),
                                ),
                                Card(
                                  child: IconButton(
                                    icon: Icon(Icons.file_download),
                                    onPressed: (){
                                      _generatePdfAndDownload();
                                    },                                  ),
                                ),
                                Card(
                                  child: IconButton(
                                    icon: Icon(Icons.refresh),
                                    onPressed: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (context)=>CumulativeSalaryCalculation()));
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
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Text("Report Details", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                              const Spacer(),
                              Visibility(
                                visible: isCardVisible,
                                child: Card(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text("$formattedFromDate -"),
                                          Text(" $formattedToDate -"),
                                          Text(" $selectedShiftType"),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20,),
                          PaginatedDataTable(
                            columnSpacing: 50.0,
                            rowsPerPage: 25,
                            columns: const [
                              DataColumn(label: Center(child: Text("S.No", style: TextStyle(fontWeight: FontWeight.bold)))),
                              DataColumn(label: Center(child: Text("Employee/code", style: TextStyle(fontWeight: FontWeight.bold)))),
                              DataColumn(label: Center(child: Text("Present/Absent", style: TextStyle(fontWeight: FontWeight.bold)))),
                              DataColumn(label: Center(child: Text("Total Hrs", style: TextStyle(fontWeight: FontWeight.bold)))),
                              DataColumn(label: Center(child: Text("Worked Hrs", style: TextStyle(fontWeight: FontWeight.bold)))),
                              DataColumn(label: Center(child: Text("Shortage Hrs", style: TextStyle(fontWeight: FontWeight.bold)))),
                              DataColumn(label: Center(child: Text("Monthly Salary", style: TextStyle(fontWeight: FontWeight.bold)))),
                              // DataColumn(label: Center(child: Text("Deduction Amount", style: TextStyle(fontWeight: FontWeight.bold)))),
                              DataColumn(label: Center(child: Text("Total Salary\n(With Deduction)", style: TextStyle(fontWeight: FontWeight.bold)))),
                              DataColumn(label: Center(child: Text("Total Salary\n(Without Deduction)", style: TextStyle(fontWeight: FontWeight.bold)))),
                            ],
                            source: _DataSource(reportData, fromDate, toDate),
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
class _DataSource extends DataTableSource {
  final List<Map<String, dynamic>> reportData;
  final DateTime? fromDate;
  final DateTime? toDate;

  _DataSource(this.reportData, this.fromDate, this.toDate);

  @override
  DataRow getRow(int index) {
    if (index >= reportData.length) return null!;
    final data = reportData[index];
    return DataRow.byIndex(index: index, cells: [
      DataCell(Center(child: Text((index + 1).toString()))),
      DataCell(Center(child: Text(data['employee'] ?? ''))),
      DataCell(Center(child: Text("${data['no_of_work_days']?.toString() ?? ''}${data['no_of_absent_days']?.toString() ?? ''}"))),
      DataCell(Center(child: Text(formatDuration(data['total_req_time']!.toString()) ?? ''))),
      DataCell(Center(child: Text(formatDuration(data['total_act_time']!.toString()) ?? ''))),
      DataCell(Center(child: Text(formatDuration(data['total_late']!.toString()) ?? ''))),
      DataCell(Center(child: Text('₹ ${data['monthly_salary']?.toString() ?? ''}'))),
      //DataCell(Center(child: Text('₹ ${data['deduction_salary']?.toString() ?? ''}'))),
      DataCell(Center(child: Text('₹ ${data['total_act_salary']?.toString() ?? ''}'))),
      DataCell(Center(child: Text('₹ ${data['total_salary']?.toString() ?? ''}'))),
    ]);
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => reportData.length;

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
