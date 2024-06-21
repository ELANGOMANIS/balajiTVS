
import   'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:vinayaga_project/Attendance/salarypdf.dart';
import 'package:vinayaga_project/main.dart';
import 'package:http/http.dart' as http;
import '../../home.dart';
import 'package:flutter/services.dart' show ByteData, Uint8List, rootBundle;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';



class SalaryCalculation extends StatefulWidget {
  const SalaryCalculation({Key? key}) : super(key: key);
  @override
  State<SalaryCalculation> createState() => _SalaryCalculationState();

}
class _SalaryCalculationState extends State<SalaryCalculation> {
  String? errorMessage;


  String toLate="";
  double calculateTotalLate(List<Map<String, dynamic>> filteredData) {
    double totalLate = 0;

    for (var row in filteredData) {
      try {
        double reqTime = double.parse(row['req_time'] ?? '0');
        double workTime = double.parse(row['act_time'] ?? '0');

        if (reqTime < workTime) {

        } else {
          totalLate += reqTime - workTime;
        }
      } catch (e) {
        print('Error parsing double: $e');
      }
    }

    setState(() {
      toLate = formatDuration(totalLate);
    });

    return totalLate;
  }
  String formatDuration(double durationInMinutes) {
    Duration duration = Duration(minutes: durationInMinutes.round());

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
  String calculateReqWorkTime(List<Map<String, dynamic>> filteredData) {
    double reqWorkTime = 0;
    for (var row in filteredData) {
      reqWorkTime += double.parse(row['req_time'] ?? '0');
    }
    return formatDuration(reqWorkTime);
  }
  String calculateLateTime(List<Map<String, dynamic>> filteredData) {
    double reqWorkTime = 0;
    for (var row in filteredData) {
      reqWorkTime += double.parse(row['latecheck_in'] ?? '0');
    }
    return formatDuration(reqWorkTime);
  }
  String calculateEarlyTime(List<Map<String, dynamic>> filteredData) {
    double reqWorkTime = 0;
    for (var row in filteredData) {
      reqWorkTime += double.parse(row['earlycheck_out'] ?? '0');
    }
    return formatDuration(reqWorkTime);
  }
  double calculateTotalWorkTimeInHours(List<Map<String, dynamic>> filteredData) {
    double totalWorkTime = 0;
    for (var row in filteredData) {
      totalWorkTime += double.parse(row['act_time'] ?? '0');
    }
    return totalWorkTime;
  }
  String calculateTotalWorkTime(List<Map<String, dynamic>> filteredData) {
    double totalWorkTime = 0;
    for (var row in filteredData) {
      totalWorkTime += double.parse(row['act_time'] ?? '0');
    }
    return formatDuration(totalWorkTime);
  }

  List<String> supplierSuggestions = [];
  String selectedSupplier = "";
  bool isDateRangeValid=true;

  int currentPage = 1;
  int rowsPerPage = 10;

  void updateFilteredData() {
    final startIndex = (currentPage - 1) * rowsPerPage;
    final endIndex = currentPage * rowsPerPage;

    setState(() {
      filteredData = data.sublist(startIndex, endIndex);
    });
  }

  String capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text.substring(0, 1).toUpperCase() + text.substring(1);
  }

  bool generatedButton = false;
  DateTime? fromDate;
  DateTime? toDate;
  TextEditingController searchController = TextEditingController();
  TextEditingController emp_code = TextEditingController();

  List<String> itemGroupValues = [];
  List<String> invoiceNumber = [];
  String selectedCustomer="";
  List<Map<String, dynamic>> data = [];
  List<Map<String, dynamic>> filteredData = [];


  int calculateTotalDays(List<Map<String, dynamic>> filteredData) {
    return filteredData.length;
  }
  int calculateTotalDaysInRange(DateTime fromDate, DateTime toDate) {
    return toDate.difference(fromDate).inDays + 1;
  }


  Future<void> fetchData() async {
    try {
      final url = Uri.parse('http://localhost:3309/get_individual_salary/');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        setState(() {
          data = List<Map<String, dynamic>>.from(responseData);
          filteredData = List<Map<String, dynamic>>.from(data);
          applySorting();
        });
      } else {
        print('Error: ${response.statusCode}');
      }
    } catch (error) {
      print('Error: $error');
    }
  }

  void applySorting() {
    filteredData.sort((a, b) {
      DateTime? dateA = DateTime.tryParse(a['inDate'] ?? '');
      DateTime? dateB = DateTime.tryParse(b['inDate'] ?? '');
      if (dateA == null || dateB == null) {
        return 0;
      }
      return dateB.compareTo(dateA);
    });
  }
  double calculateTotalSalary(List<Map<String, dynamic>> filteredData) {
    double totalWorkTime = 0;
    for (var row in filteredData) {
      totalWorkTime += double.parse(row['salary'] ?? '0');
    }
    return totalWorkTime;
  }
  double calculateTotalSalaryDeduction(List<Map<String, dynamic>> filteredData) {
    double totalWorkTime = 0;
    for (var row in filteredData) {
      totalWorkTime += double.parse(row['diff_salary'] ?? '0');
    }
    return totalWorkTime;
  }
  double calculateTotalActSalary(List<Map<String, dynamic>> filteredData) {
    double totalWorkTime = 0;
    for (var row in filteredData) {
      totalWorkTime += double.parse(row['act_salary'] ?? '0');
    }
    return totalWorkTime;
  }
  int calculateAbsentDays(List<Map<String, dynamic>> filteredData, DateTime fromDate, DateTime toDate) {
    int totalDaysInRange = calculateTotalDaysInRange(fromDate, toDate);
    int presentDays = calculateTotalDays(filteredData);
    return totalDaysInRange - presentDays;
  }

  void filterData(String searchText) {
    print("Search Text: $searchText");
    setState(() {
      if (searchText.isEmpty) {
        filteredData = List<Map<String, dynamic>>.from(data);
      } else {
        filteredData = data.where((item) {
          String supName = item['first_name']?.toString()?.toLowerCase() ?? '';
          String searchTextLowerCase = searchText.toLowerCase();

          return supName.contains(searchTextLowerCase);
        }).toList();
        if (filteredData.isNotEmpty) {
          Map<String, dynamic> order = filteredData.first;
          emp_code.text = order['emp_code']?.toString() ?? '';
        } else {
          emp_code.clear();
        }
      }
      filteredData.sort((a, b) {
        DateTime? dateA = DateTime.tryParse(a['inDate'] ?? '');
        DateTime? dateB = DateTime.tryParse(b['inDate'] ?? '');  // Change 'outDate' to 'inDate'
        if (dateA == null || dateB == null) {
          return 0;
        }
        return dateB.compareTo(dateA); // Compare in descending order
      });
    });
    print("Filtered Data Length: ${filteredData.length}");
  }

  double totalWorkTime = 0;
  double totalWorkSalary = 0;
  double totalWorkSalaryDeduction = 0;
  double totalWorkActSalary = 0;
  double reqWorkTime = 0;
  double totalLate = 0;

  void applyDateFilter() {
    setState(() {
      if (!isDateRangeValid) {
        return;

      }
      filteredData = data.where((item) {
        String dateStr = item['inDate']?.toString() ?? '';
        DateTime? itemDate = DateTime.tryParse(dateStr);

        if (itemDate != null &&
            itemDate.isAfter(fromDate!.subtract(Duration(days: 1))) &&
            itemDate.isBefore(toDate!.add(Duration(days: 1)))) {
          return true;
        }
        return false;
      }).toList();

      if (searchController.text.isNotEmpty) {
        String searchTextLowerCase = searchController.text.toLowerCase();
        filteredData = filteredData.where((item) {
          String id = item['first_name']?.toString()?.toLowerCase() ?? '';
          return id.contains(searchTextLowerCase);
        }).toList();
      }

      filteredData.sort((a, b) {
        DateTime? dateA = DateTime.tryParse(a['inDate'] ?? '');
        DateTime? dateB = DateTime.tryParse(b['inDate'] ?? '');

        if (dateA == null || dateB == null) {
          return 0;
        }
        return dateB.compareTo(dateA);
      });

      totalWorkTime = calculateTotalWorkTime(filteredData) as double;
      totalWorkSalary = calculateTotalSalary(filteredData);
      totalWorkSalaryDeduction = calculateTotalSalaryDeduction(filteredData);
      totalWorkActSalary = calculateTotalActSalary(filteredData);
      reqWorkTime = calculateReqWorkTime(filteredData) as double;
      totalLate = calculateTotalLate(filteredData);
    });
    applySorting();
  }


  @override
  void initState() {
    super.initState();
    fetchData();
    searchController.addListener(() {
      filterData(searchController.text);
    });
    _searchFocus.requestFocus();
    filteredData = List<Map<String, dynamic>>.from(data);

  }
  final FocusNode _searchFocus = FocusNode();


  Future<void> _generatePdfAndDownload() async {
    final companyData = await Utils.fetchCompanyData(); // Fetch company data
    final pdf = pw.Document();
    final headers = [
      'S.No',
      'Date',
      'Name',
      'Shift',
      'Total Hrs',
      'Shortage',
      'Worked Time',
      'Salary\n (Without Deduction)',
      'Deduction Amt',
      'Salary\n (With Deduction)',
    ];

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
                0: pw.FixedColumnWidth(40),
                1: pw.FixedColumnWidth(55),
                2: pw.FixedColumnWidth(50),
                3: pw.FixedColumnWidth(40),
                4: pw.FixedColumnWidth(50),
                5: pw.FixedColumnWidth(60),
                6: pw.FixedColumnWidth(60),
                7: pw.FixedColumnWidth(80),
                8: pw.FixedColumnWidth(80),
                9: pw.FixedColumnWidth(80),
                10: pw.FixedColumnWidth(80),

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

              },
              data: filteredData.map((row) {
                int totalTime = int.tryParse(row['req_time'] ?? '0') ?? 0;
                int workTime = int.tryParse(row['act_time'] ?? '0') ?? 0;
                int differentTime = workTime < totalTime ? totalTime - workTime : 0;
                return [
                  '${filteredData.indexOf(row) + 1}',
                  DateFormat('yyyy-MM-dd').format(DateTime.parse(row['inDate'] ?? "")),
                  '${row["first_name"]} - ${row["emp_code"]}',
                  '${row["shiftType"]}',
                  formatDuration(double.parse(row['req_time'] ?? '0')),
                  formatDuration(differentTime.toDouble()), // Include differentTime
                  row["check_out"] != "00:00:00"
                      ? formatDuration(double.parse(row['act_time'] ?? '0'))
                      : "",
                    '${row["salary"]}',
                  '${row["diff_salary"]}',
                  '${row["act_salary"]}',
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Summary',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              "Total Days: ${calculateTotalDays(filteredData)}",
              style: pw.TextStyle(fontSize: 12),
            ),
            pw.Text(
              "Total Hrs: ${calculateReqWorkTime(filteredData)}",
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              "Shortage: ${formatDuration(calculateTotalLate(filteredData))}",
              style: pw.TextStyle(fontSize: 12, color: PdfColors.red),
            ),
            pw.Text(
              "Work Time: ${calculateTotalWorkTime(filteredData)}",
              style: pw.TextStyle(fontSize: 12),
            ),
            pw.Text(
              "Total Salary (Without Deduction): ${calculateTotalSalary(filteredData)}",
              style: pw.TextStyle(fontSize: 12),
            ), pw.Text(
              "Total Deduction : ${calculateTotalSalaryDeduction(filteredData)}",
              style: pw.TextStyle(fontSize: 12),
            ),

            pw.Text(
              "Total Salary (With Deduction): ${calculateTotalActSalary(filteredData)}",
              style: const pw.TextStyle(fontSize: 12),
            ),
          ];
        },
      ),
    );

    final Uint8List bytes = await pdf.save();
    await Printing.sharePdf(bytes: bytes, filename: 'salary_report.pdf');
  }


  @override
  Widget build(BuildContext context) {

    final formattedDate = fromDate != null ? DateFormat("yyyy-MM-dd").format(fromDate!) : "";
    final formattedDate2 = toDate != null ? DateFormat("yyyy-MM-dd").format(toDate!) : "";

    searchController.addListener(() {
      filterData(searchController.text);
    });

    return MyScaffold(
      route: "salary_report",backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Form(
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
                            const Wrap(
                              children: [
                                Icon(Icons.report,),
                                SizedBox(width:10,),
                                Text(
                                  'Salary Report',
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
                                  child: TextFormField(style: const TextStyle(fontSize: 13),
                                    readOnly: true,
                                    validator: (value) {
                                      if (value!.isEmpty) {
                                        return '* Enter Date';
                                      }
                                      return null;
                                    },
                                    onTap: () {
                                      showDatePicker(
                                        context: context,
                                        initialDate: toDate ?? DateTime.now(),
                                        firstDate: DateTime(2000), // Set the range of selectable dates
                                        lastDate: DateTime(2100),
                                      ).then((date) {
                                        if (date != null) {
                                          setState(() {
                                            fromDate = date;
                                            // applyDateFilter();
                                          });
                                        }
                                      });
                                    },
                                    controller: TextEditingController(text: formattedDate.toString().split(' ')[0]), // Set the initial value of the field to the selected date
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
                                  width: 240,
                                  height: 50,
                                  child: TextFormField(style: TextStyle(fontSize: 13),
                                    readOnly: true,
                                    validator: (value) {
                                      if (value!.isEmpty) {
                                        return '* Enter Date';
                                      }
                                      return null;
                                    },
                                    onTap: () {
                                      showDatePicker(
                                        context: context,
                                        initialDate: toDate ?? DateTime.now(),
                                        firstDate: DateTime(2000), // Set the range of selectable dates
                                        lastDate: DateTime(2100),
                                      ).then((date) {
                                        if (date != null) {
                                          setState(() {
                                            toDate = date;
                                            //applyDateFilter();
                                          });
                                        }
                                      });
                                    },
                                    controller: TextEditingController(text: formattedDate2.toString().split(' ')[0]), // Set the initial value of the field to the selected date
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
                                  width: 240,
                                  height: 50,
                                  child:
                                  TypeAheadFormField<String>(
                                    textFieldConfiguration: TextFieldConfiguration(
                                      controller: searchController,
                                      onChanged: (value) {
                                        applyDateFilter();
                                        String capitalizedValue = capitalizeFirstLetter(value);
                                        searchController.value = searchController.value.copyWith(
                                          text: capitalizedValue,
                                          selection: TextSelection.collapsed(offset: capitalizedValue.length),
                                        );
                                      },
                                      style: const TextStyle(fontSize: 13),
                                      decoration: const InputDecoration(
                                        fillColor: Colors.white,
                                        filled: true,
                                        labelText: "Employee/Code",
                                        labelStyle: TextStyle(fontSize: 13),
                                        border: OutlineInputBorder(
                                          // borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                    suggestionsCallback: (pattern) async {
                                      if (pattern.isEmpty) {
                                        return [];
                                      }
                                      List<String> suggestions =data
                                          .where((item) =>
                                      (item['first_name']?.toString().toLowerCase() ?? '').contains(pattern.toLowerCase()) ||
                                          (item['emp_code']?.toString().toLowerCase() ?? '').contains(pattern.toLowerCase()))
                                          .map((item) => item['first_name'].toString())
                                          .toSet()
                                          .toList();
                                      return suggestions;
                                    },
                                    itemBuilder: (context, suggestion) {
                                      return ListTile(
                                        title: Text(suggestion),
                                      );
                                    },
                                    onSuggestionSelected: (suggestion) {
                                      setState(() {
                                        selectedCustomer = suggestion;
                                        searchController.text = suggestion;
                                        applyDateFilter();
                                      });
                                      print('Selected Customer: $selectedCustomer');
                                    },
                                  ),
                                ),
                                Card(
                                  child: IconButton(
                                    icon: Icon(Icons.search),
                                    onPressed: () {
                                      if (fromDate == null || toDate == null) {
                                        setState(() {
                                          errorMessage = '* Select both From and To Date.';
                                        });
                                      }
                                      else {
                                        setState(() {
                                          errorMessage = null;
                                          generatedButton = true;
                                        });
                                        applyDateFilter();
                                      }
                                    },
                                  ),
                                ),

                                Card(
                                  child: IconButton(
                                    icon: Icon(Icons.file_download),
                                    onPressed: () {
                                      _generatePdfAndDownload();
                                    },
                                  ),
                                ),
                                Card(
                                  child: IconButton(
                                    icon: Icon(Icons.refresh),
                                    onPressed: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (context)=>SalaryCalculation()));
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
                                if (generatedButton && searchController.text.isNotEmpty)
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: Card(
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Align(
                                          alignment: Alignment.topLeft,
                                          child: Column(
                                            children: [
                                              Text(
                                                "Present/Absent: ${calculateTotalDays(filteredData)}/${calculateAbsentDays(filteredData, fromDate!, toDate!)}",
                                                style: TextStyle(fontSize: 14),
                                              ),

                                              Text(
                                                "Total Hrs: ${calculateReqWorkTime(filteredData)}",
                                                style: const TextStyle(fontSize: 13, color: Colors.black, fontWeight: FontWeight.bold),
                                              ),
                                              Text(
                                                "Shortage: ${formatDuration(calculateTotalLate(filteredData))}",
                                                style: const TextStyle(fontSize: 13, color: Colors.red),
                                              ),
                                              Text(
                                                "Work Time: ${calculateTotalWorkTime(filteredData)}",
                                                style: const TextStyle(fontSize: 13, color: Colors.black),
                                              ), Text(
                                                "Total Salary (Without Deduction): ${calculateTotalSalary(filteredData)}",
                                                style: const TextStyle(fontSize: 13, color: Colors.black),
                                              ), Text(
                                                "Total Deduction: ${calculateTotalSalaryDeduction(filteredData)}",
                                                style: const TextStyle(fontSize: 13, color: Colors.black),
                                              ),
                                              Text(
                                                "Total Salary (With Deduction): ${calculateTotalActSalary(filteredData)}",
                                                style: const TextStyle(fontSize: 13, color: Colors.black),
                                              ),

                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                              ],
                            ),
                            if (errorMessage != null)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text(
                                    errorMessage!,
                                    style: TextStyle(color: Colors.red),
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
                        // borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Align(
                                alignment:Alignment.topLeft,
                                child: Padding(
                                  padding: EdgeInsets.only(left: 5),
                                  child: Row(

                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text("Report Details",style: TextStyle(fontSize:17,fontWeight: FontWeight.bold),),
                                        ],
                                      ),

                                    ],
                                  ),
                                )),

                            const SizedBox(height: 20,),
                            PaginatedDataTable(
                                columnSpacing:90.0,
                                rowsPerPage:25,
                                columns:   const [
                                  DataColumn(label: Center(child: Text("S.No",style: TextStyle(fontWeight: FontWeight.bold),))),
                                  DataColumn(label: Center(child: Text("Date",style: TextStyle(fontWeight: FontWeight.bold),))),
                                  DataColumn(label: Center(child: Text("    Name",style: TextStyle(fontWeight: FontWeight.bold),))),
                                  DataColumn(label: Center(child: Text("Shift",style: TextStyle(fontWeight: FontWeight.bold),))),
                                  DataColumn(label: Center(child: Text("Total Hrs",style: TextStyle(fontWeight: FontWeight.bold),))),
                                  DataColumn(label: Center(child: Text("Shortage",style: TextStyle(fontWeight: FontWeight.bold),))),
                                  DataColumn(label: Center(child: Text("Worked Time",style: TextStyle(fontWeight: FontWeight.bold),))),
                                   DataColumn(label: Center(child: Text("Salary\n (Without Deduction)",style: TextStyle(fontWeight: FontWeight.bold),))),
                                   DataColumn(label: Center(child: Text("Deduction Amt",style: TextStyle(fontWeight: FontWeight.bold),))),
                                   DataColumn(label: Center(child: Text("Salary\n (With Deduction)",style: TextStyle(fontWeight: FontWeight.bold),))),
                                ],
                                source: _YourDataTableSource(
                                  filteredData,
                                  context,
                                  generatedButton,
                                  onRowSelected: (Map<String, dynamic> selectedRow) {
                                    // Perform calculations or other actions for the selected row
                                    print("Selected Row: $selectedRow");
                                    // Call your salary calculation functions here using selectedRow data
                                  },
                                )                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 15.0,right: 15.0),
                        child: MaterialButton(
                          color: Colors.green.shade600,
                          height: 40,
                          onPressed: (){
                            Navigator.push(context, MaterialPageRoute(builder: (context)=>SalaryPdf(
                              customerData : filteredData,
                            )));
                          },child: const Text("PRINT",style: TextStyle(color: Colors.white),),),


                      ),
                      SizedBox(height: 20,),
                      Padding(
                        padding: const EdgeInsets.only(left: 15.0,right: 15.0),
                        child: MaterialButton(
                          color: Colors.red.shade600,
                          height: 40,
                          onPressed: (){
                            Navigator.push(context,
                                MaterialPageRoute(builder: (context) =>const Home()));
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Confirmation'),
                                  content: const Text('Do you want to cancel?'),
                                  actions: <Widget>[

                                    TextButton(
                                      child: const Text('Yes'),
                                      onPressed: () {
                                        Navigator.push(context,
                                            MaterialPageRoute(builder: (context) =>const Home()));// Close the alert box
                                      },
                                    ),
                                    TextButton(
                                      child: const Text('No'),
                                      onPressed: () {
                                        Navigator.of(context).pop(); // Close the alert box
                                      },
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: const Text("Cancel",style: TextStyle(color: Colors.white),),),
                      ),

                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
class _YourDataTableSource extends DataTableSource {
  final List<Map<String, dynamic>> data;
  final BuildContext context;
  final bool generatedButton;
  final Function(Map<String, dynamic> selectedRow) onRowSelected;

  final List<bool> selectedRows = [];

  _YourDataTableSource(this.data,this.context, this.generatedButton,  {required this.onRowSelected}){
    selectedRows.addAll(List<bool>.generate(data.length, (index) => false));
  }
  Container createBorderedContainer(Widget child) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: Colors.grey),
          // right: BorderSide(color: Colors.grey),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: child,
      ),
    );
  }

  @override
  DataRow? getRow(int index) {
    if (index >= data.length) {
      return null;
    }

    final row = data[index];
    int lateCheckIn = int.tryParse(row["latecheck_in"] ?? "0") ?? 0;
    int earlyCheckOut = int.tryParse(row["earlycheck_out"] ?? "0") ?? 0;
    int lateLunch = int.tryParse(row["late_lunch"] ?? "0") ?? 0;
    int totalLate = lateCheckIn + earlyCheckOut + lateLunch;

    int totalTime = int.tryParse(row["req_time"] ?? "0") ?? 0;
    int workTime = int.tryParse(row["act_time"] ?? "0") ?? 0;

    int differentTime = workTime < totalTime && totalTime != 0 ? totalTime - workTime : 0;


    return DataRow(
      selected: selectedRows[index],

      cells: [
        DataCell((Center(child: Text("${index + 1}")))),
        DataCell(Center(child: Text(
          row["inDate"] != null
              ? DateFormat('yyyy-MM-dd').format(
            DateTime.parse("${row["inDate"]}").toLocal(),
          )
              : "",
        ),)),

        DataCell(Center(child: Text("${row["first_name"]+' - '+row["emp_code"]} "))),
        DataCell(Center(child: Text("${row["shiftType"]}"))),
        DataCell(Center(child: Text(formatDuration(row["req_time"])))),
        DataCell(Center(child: Text(row["check_out"] != "00:00:00" ? formatDuration(differentTime.toString()) : ""))),
        DataCell(Center(child: Text(formatDuration(row["act_time"])))),
        DataCell(Center(child: Text("${row["salary"]}"))),
        DataCell(Center(child: Text("${row["diff_salary"]}"))),
        DataCell(Center(child: Text("${row["act_salary"]}"))),

      ],
    );
  }
  String formatTime(String timeString) {
    if (timeString != null) {
      DateTime dateTime = DateTime.parse("2023-01-01 $timeString");
      return DateFormat('h:mm a').format(dateTime);
    }
    return "";
  }
  String formatTimeOrZero(String timeString) {
    if (timeString != null && timeString != "0") {
      // Assuming timeString is in HH:mm:ss format
      DateTime dateTime = DateTime.parse("2023-01-01 $timeString");
      return DateFormat('h:mm a').format(dateTime);
    }
    return "0";
  }
  String formatDuration(String durationInMinutes) {
    if (durationInMinutes != null) {
      int minutes = int.parse(durationInMinutes);
      Duration duration = Duration(minutes: minutes);

      int hours = duration.inHours;
      int remainingMinutes = duration.inMinutes.remainder(60);

      String formattedDuration = '';

      if (hours > 0) {
        formattedDuration += '$hours h';
      }

      if (remainingMinutes > 0) {
        if (hours > 0) {
          formattedDuration += '';
        }
        formattedDuration += '$remainingMinutes m';
      }

      return formattedDuration.trim();
    }

    return "";
  }
  @override
  int get rowCount => data.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
}


