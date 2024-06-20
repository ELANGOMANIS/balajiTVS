import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:vinayaga_project/Attendance/salary.dart';
import 'package:vinayaga_project/Attendance/salary_weekly_pdf.dart';


import '../home.dart';
import '../main.dart';

class CumulativeSalaryCalculation extends StatefulWidget {
  const CumulativeSalaryCalculation({Key? key}) : super(key: key);

  @override
  State<CumulativeSalaryCalculation> createState() =>
      _CumulativeSalaryCalculationState();
}

class _CumulativeSalaryCalculationState
    extends State<CumulativeSalaryCalculation> {
  String? selectedShiftType;
  DateTime? fromDate;
  DateTime? toDate;
  bool isCardVisible = false;

  List<Map<String, dynamic>> reportData = [];
  final List<String> _shiftTypes = [];
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
        // Handle successful response
        print('Report fetched successfully');
        final List<dynamic> responseData = json.decode(response.body);
        setState(() {
          reportData = responseData.cast<Map<String, dynamic>>();
        });
        reportData.forEach((data) {
          int totalLate = int.parse(data['total_late'].toString());
          double totalSalary = double.parse(data['total_salary'].toString());
          double salary = totalSalary;
          String shiftType = data['shift_type'].toString();
        });
        print('Report Data: $reportData'); // Print the list of data with updated salaries
      } else {
        print('Failed to fetch report. Status Code: ${response.statusCode}');
      }
    } catch (error) {
      // Handle errors
      print('Error fetching report: $error');
    }
  }



/*
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
        // Handle successful response
        print('Report fetched successfully');
        final List<dynamic> responseData = json.decode(response.body);
        setState(() {
          reportData = responseData.cast<Map<String, dynamic>>();
        });
        reportData.forEach((data) {
          int totalLate = int.parse(data['total_late'].toString());
          double totalSalary = double.parse(data['total_salary'].toString());
          double salary = totalSalary; // Assuming the salary is not changed initially
        });
        print('Report Data: $reportData'); // Print the list of data with updated salaries
      } else {
        print('Failed to fetch report. Status Code: ${response.statusCode}');
      }
    } catch (error) {
      // Handle errors
      print('Error fetching report: $error');
    }
  }
*/
  final TextEditingController _typeAheadController = TextEditingController();
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

                           Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.arrow_back),
                                onPressed: () {
                                  // Navigator.push(context, MaterialPageRoute(builder: (context)=>SalaryCalculation()));
                                  Navigator.pop(context);
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.refresh),
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context)=>CumulativeSalaryCalculation()));
                                },
                              ),


                              SizedBox(width: 20,),
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
                          Padding(
                            padding: const EdgeInsets.only(right: 15),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 180,
                                  height: 34,
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
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                SizedBox(
                                  width: 180,
                                  height: 34,
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
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 10),
                                SizedBox(
                                  width: 180,
                                  height: 34,
                                  child: TypeAheadFormField(
                                    textFieldConfiguration: TextFieldConfiguration(
                                      controller: _typeAheadController, // Use the controller here.
                                      decoration: const InputDecoration(
                                        labelText: 'Shift Type',
                                        border: OutlineInputBorder(),
                                        suffixIcon: Icon(Icons.arrow_drop_down),
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

                                Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: MaterialButton(
                                    color: Colors.green.shade500,
                                    height: 40,
                                    onPressed: () {
                                      fetchReport();
                                      setState(() {
                                        isCardVisible = true;
                                      });
                                    },
                                    child: const Text(
                                      "Calculate",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 15.0,right: 15.0),
                                  child: MaterialButton(
                                    color: Colors.green.shade600,
                                    height: 40,
                                    onPressed: (){
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => SalaryWeeklyPdf(customerData: reportData, fromDate: fromDate, toDate: toDate,),
                                        ),
                                      );

                                    },child: const Text("PRINT",style: TextStyle(color: Colors.white),),),
                                ),
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
                          Row(
                            children: [
                              const Text("Report Details", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                              const Spacer(),
                              Visibility(
                                visible: isCardVisible,
                                child: Card(
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
                            ],
                          ),

                          const SizedBox(height: 20,),
                          PaginatedDataTable(
                            columnSpacing: 90.0,
                            rowsPerPage: 25,
                            columns: const [
                              DataColumn(label: Center(child: Text("S.No", style: TextStyle(fontWeight: FontWeight.bold)))),
                              DataColumn(label: Center(child: Text("Employee", style: TextStyle(fontWeight: FontWeight.bold)))),
                              DataColumn(label: Center(child: Text("No of Days", style: TextStyle(fontWeight: FontWeight.bold)))),
                              DataColumn(label: Center(child: Text("Total Hrs", style: TextStyle(fontWeight: FontWeight.bold)))),
                              DataColumn(label: Center(child: Text("Worked Hrs", style: TextStyle(fontWeight: FontWeight.bold)))),
                              DataColumn(label: Center(child: Text("Salary", style: TextStyle(fontWeight: FontWeight.bold)))),
                              DataColumn(label: Center(child: Text("Deduction", style: TextStyle(fontWeight: FontWeight.bold)))),
                               DataColumn(label: Center(child: Text("Total Salary", style: TextStyle(fontWeight: FontWeight.bold)))),
                              // DataColumn(label: Center(child: Text("Salary per Day", style: TextStyle(fontWeight: FontWeight.bold)))),
                              // DataColumn(label: Center(child: Text("Salary", style: TextStyle(fontWeight: FontWeight.bold)))),
                              // DataColumn(label: Center(child: Text("Extra\nProduction", style: TextStyle(fontWeight: FontWeight.bold)))),
                              // DataColumn(label: Center(child: Text("Total Salary", style: TextStyle(fontWeight: FontWeight.bold)))),
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
  final List<Map<String, dynamic>> _data;
  final DateTime? _fromDate;
  final DateTime? _toDate;

  _DataSource(this._data, this._fromDate, this._toDate);

  @override
  DataRow? getRow(int index) {
    if (index >= _data.length) {
      return null;
    }
    final data = _data[index];
    String shiftType = data['shift_type'].toString();
    //double totalWorkSalary = calculateSalary(data) + double.parse(data['calculated_extraproduction'].toString());

    return DataRow(cells: [
      DataCell(Text((index + 1).toString())),
      DataCell(Text(data['employee'])),
      // DataCell(Text(_fromDate != null ? DateFormat('yyyy-MM-dd').format(_fromDate!) : '')),
      // DataCell(Text(_toDate != null ? DateFormat('yyyy-MM-dd').format(_toDate!) : '')),
     // DataCell(Text(shiftType)),
      DataCell(Text((data['no_of_work_days'].toString()))),
      DataCell(Text(formatDuration(data['total_req_time'].toString()))),
      DataCell(Text(formatDuration(data['total_act_time'].toString()))),
      //DataCell(Text(formatDuration(data['total_late'].toString()))),
      DataCell(Text('\u20B9 ${data['monthly_salary']}')),
      DataCell(Text('\u20B9 ${data['deduction_salary']}')),
      DataCell(Text('\u20B9 ${data['total_salary']}')), // Display per day salary with rupee symbol
      // DataCell(Text(calculateSalary(data).toString())),
      // DataCell(Text(double.parse(data['calculated_extraproduction']).toInt().toString())),
      // DataCell(Text(totalWorkSalary.toStringAsFixed(2))), // Display total work salary with two decimal places
// Display the calculated extra production without decimal places
    ]);
  }


  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _data.length;

  @override
  int get selectedRowCount => 0;
}
double calculateSalary(Map<String, dynamic> data) {
  double totalSalary = double.parse(data['total_salary'].toString());
  double perDaySalary = double.parse(data['perDaySalary'].toString());
  double totalLate = double.parse(data['total_late'].toString());
  String shiftType = data['shift_type'].toString();

  double salary = totalSalary; // Assuming the salary is not changed initially

  // Apply deduction logic based on shift type and late arrival time
  if (shiftType == 'Morning') {
    if (totalLate < 5.75 * 60) {
      salary = totalSalary;
    } else if (totalLate >= 5.75 * 60 && totalLate < 11.5 * 60) {
      salary = totalSalary - (perDaySalary / 2);
    } else if (totalLate >= 11.5 * 60 && totalLate < 17.25 * 60) {
      salary = totalSalary - perDaySalary;
    } else if (totalLate >= 17.25 * 60 && totalLate < 23 * 60) {
      salary = totalSalary - (2.5 * perDaySalary);
    } else if (totalLate >= 23 * 60 && totalLate < 28.75 * 60) {
      salary = totalSalary - (3 * perDaySalary);
    } else if (totalLate >= 28.75 * 60 && totalLate < 34.5 * 60) {
      salary = totalSalary - (3.5 * perDaySalary);
    } else if (totalLate >= 34.5 * 60 && totalLate < 40.25 * 60) {
      salary = totalSalary - (4 * perDaySalary);
    } else if (totalLate >= 40.25 * 60 && totalLate < 46 * 60) {
      salary = totalSalary - (4.5 * perDaySalary);
    } else if (totalLate >= 46 * 60 && totalLate < 51.75 * 60) {
      salary = totalSalary - (5 * perDaySalary);
    } else if (totalLate >= 51.75 * 60 && totalLate < 57.5 * 60) {
      salary = totalSalary - (5.5 * perDaySalary);
    }
  }
  else if (shiftType == 'General') {
    if (totalLate < 4.25 * 60) {
      salary = totalSalary;
    } else if (totalLate >= 4.25 * 60 && totalLate < 8.5 * 60) {
      salary = totalSalary - (perDaySalary / 2);
    } else if (totalLate >= 8.5 * 60 && totalLate < 12.75 * 60) {
      salary = totalSalary - perDaySalary;
    } else if (totalLate >= 12.75 * 60 && totalLate < 17 * 60) {
      salary = totalSalary - (2.5 * perDaySalary);
    } else if (totalLate >= 17 * 60 && totalLate < 21.25 * 60) {
      salary = totalSalary - (3 * perDaySalary);
    } else if (totalLate >= 21.25 * 60 && totalLate < 25.5 * 60) {
      salary = totalSalary - (3.5 * perDaySalary);
    } else if (totalLate >= 25.5 * 60 && totalLate < 29.75 * 60) {
      salary = totalSalary - (4 * perDaySalary);
    } else if (totalLate >= 29.75 * 60 && totalLate < 34 * 60) {
      salary = totalSalary - (4.5 * perDaySalary);
    } else if (totalLate >= 34 * 60 && totalLate < 38.25 * 60) {
      salary = totalSalary - (5 * perDaySalary);
    } else if (totalLate >= 38.25 * 60 && totalLate < 42.5 * 60) {
      salary = totalSalary - (5.5 * perDaySalary);
    }
  }
  else if (shiftType == 'Night') {
    if (totalLate < 6 * 60) {
      salary = totalSalary;
    } else if (totalLate >= 6 * 60 && totalLate < 12 * 60) {
      salary = totalSalary - (perDaySalary / 2);
    } else if (totalLate >= 12 * 60 && totalLate < 18 * 60) {
      salary = totalSalary - perDaySalary;
    } else if (totalLate >= 18 * 60 && totalLate < 24 * 60) {
      salary = totalSalary - (2.5 * perDaySalary);
    } else if (totalLate >= 24 * 60 && totalLate < 30 * 60) {
      salary = totalSalary - (3 * perDaySalary);
    } else if (totalLate >= 30 * 60 && totalLate < 36 * 60) {
      salary = totalSalary - (3.5 * perDaySalary);
    } else if (totalLate >= 36 * 60 && totalLate < 42 * 60) {
      salary = totalSalary - (4 * perDaySalary);
    } else if (totalLate >= 42 * 60 && totalLate < 48 * 60) {
      salary = totalSalary - (4.5 * perDaySalary);
    } else if (totalLate >= 48 * 60 && totalLate < 54 * 60) {
      salary = totalSalary - (5 * perDaySalary);
    } else if (totalLate >= 54 * 60 && totalLate < 60 * 60) {
      salary = totalSalary - (5.5 * perDaySalary);
    }
  }

  if (salary < 0) {
    salary = 0; // Ensure salary does not go below 0
  }

  return salary;
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
        formattedDuration += ' ';
      }
      formattedDuration += '$remainingMinutes m';
    }

    return formattedDuration.trim();
  }

  return "";
}
