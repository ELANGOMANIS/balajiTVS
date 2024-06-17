
import   'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:intl/intl.dart';
import 'package:vinayaga_project/Attendance/salarypdf.dart';
import 'package:vinayaga_project/main.dart';
import 'package:http/http.dart' as http;
import '../../home.dart';



class SalaryCalculation extends StatefulWidget {
  const SalaryCalculation({Key? key}) : super(key: key);
  @override
  State<SalaryCalculation> createState() => _SalaryCalculationState();

}
class _SalaryCalculationState extends State<SalaryCalculation> {
  String? errorMessage;

  ScrollController _scrollController = ScrollController();
  double calculateTotalWorkingSalary(List<Map<String, dynamic>> filteredData) {
    double totalLate = calculateTotalLate(filteredData);
    double totalSalary = calculateTotalWorkSalary(filteredData);
    double totalWorkSalary = 0 ;
    print("totalSalary$totalSalary");

    for (var row in filteredData) {
      double salary = double.parse(row['salary'] ?? '0');
      String shiftType = row['shiftType'] ?? '';
      if (shiftType == 'Morning') {
        if (totalLate < 5.75 * 60) {
          totalWorkSalary =  totalSalary;
        } else if (totalLate >= 5.75 * 60 && totalLate < 11.5 * 60) {
          totalWorkSalary = totalSalary - (salary - (salary / 2));
        }
        else if (totalLate >= 11.5 * 60 && totalLate < 17.25 * 60) {
          totalWorkSalary = totalSalary - (salary);
        } else if (totalLate >= 17.25 && totalLate < 23 * 60) {
          totalWorkSalary = totalSalary - ((2.5 * salary)-salary);
        } else if (totalLate >= 23 * 60 && totalLate < 28.75 * 60) {
          totalWorkSalary = totalSalary - ((3 * salary)-salary);
        }
      }
      else if (shiftType == 'General') {
        if (totalLate < 4.25 * 60) {
          totalWorkSalary =  totalSalary;
        } else if (totalLate >= 4.25 && totalLate < 8.50 * 60) {
          totalWorkSalary = totalSalary - (salary - (salary / 2));
        }
        else if (totalLate >= 8.50 * 60 && totalLate < 12.75 * 60) {
          totalWorkSalary = totalSalary - (salary);
        } else if (totalLate >= 12.75 * 60 && totalLate < 17 * 60) {
          totalWorkSalary = totalSalary - ((2.5 * salary)-salary);
        } else if (totalLate >= 17 * 60 && totalLate < 21.25 * 60) {
          totalWorkSalary = totalSalary - ((3 * salary)-salary);
        }
      }
      else if (shiftType == 'Night') {
        if (totalLate < 6 * 60) {
          totalWorkSalary =  totalSalary;
        } else if (totalLate >= 6 && totalLate < 12 * 60) {
          totalWorkSalary = totalSalary - (salary - (salary / 2));
        }
        else if (totalLate >= 12 * 60 && totalLate < 24 * 60) {
          totalWorkSalary = totalSalary - (salary);
        } else if (totalLate >= 24 * 60 && totalLate < 30 * 60) {
          totalWorkSalary = totalSalary - ((2.5 * salary)-salary);
        } else if (totalLate >= 30 * 60 && totalLate < 36 * 60) {
          totalWorkSalary = totalSalary - ((3 * salary)-salary);
        }
      }
      totalWorkSalary += calculateTotalExtraProduction(filteredData);
    }
    return totalWorkSalary;
  }
  double parseTimeToHours(String timeString) {
    if (timeString != null) {
      DateTime dateTime = DateFormat('hh:mm a').parse(timeString);
      return dateTime.hour + (dateTime.minute / 60);
    }
    return 0;
  }
  String calculateTotalWorkTime(List<Map<String, dynamic>> filteredData) {
    double totalWorkTime = 0;
    for (var row in filteredData) {
      totalWorkTime += double.parse(row['act_time'] ?? '0');
    }
    return formatDuration(totalWorkTime);
  }
  double calculateTotalWorkTimeInHours(List<Map<String, dynamic>> filteredData) {
    double totalWorkTime = 0;
    for (var row in filteredData) {
      totalWorkTime += double.parse(row['act_time'] ?? '0');
    }
    return totalWorkTime;
  }

  double calculateTotalExtraProduction(List<Map<String, dynamic>> filteredData) {
    double totalExtraProduction = 0;
    for (var row in filteredData) {
      totalExtraProduction += double.parse(row['calculated_extraproduction'] ?? '0');
    }
    return totalExtraProduction;
  }
  double calculateTotalWorkSalary(List<Map<String, dynamic>> filteredData) {
    double totalWorkSalary = 0;
    for (var row in filteredData) {
      totalWorkSalary += double.parse(row['salary'] ?? '0');
    }
    return totalWorkSalary;
  }
  String calculateReqWorkTime(List<Map<String, dynamic>> filteredData) {
    double reqWorkTime = 0;
    for (var row in filteredData) {
      reqWorkTime += double.parse(row['req_time'] ?? '0');
    }
    return formatDuration(reqWorkTime);
  }

  String toLate="";

  double calculateTotalLate(List<Map<String, dynamic>> filteredData) {
    double totalLate = 0;

    for (var row in filteredData) {
      try {
        double reqTime = double.parse(row['req_time'] ?? '0');
        double workTime = double.parse(row['act_time'] ?? '0');

        if (reqTime < workTime) {
          // If workTime is greater than reqTime, this means the task was completed before required time.
          // We should not subtract anything from totalLate in this case.
          // You can add a condition here if you need to handle this case differently.
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
  String convertToHoursAndMinutes(int minutes) {
    int hours = minutes ~/ 60;
    int remainingMinutes = minutes % 60;

    String formattedTime = "${hours}h${remainingMinutes}m";
    return formattedTime;
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

  int calculateTotalDays(List<Map<String, dynamic>> filteredData) {
    return filteredData.length;
  }


  void fetchData() async {
    try {
      final url = Uri.parse('http://localhost:3309/get_attendance_overall/');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final List<dynamic> itemGroups = responseData;
        Set<String> uniqueCustNames = Set();
        final List uniqueData = itemGroups
            .where((item) {
          String custName = item['check_in']?.toString() ?? '';
          String inDate = item['inDate']?.toString() ?? '';
          String uniqueIdentifier = '$custName-$inDate';

          if (!uniqueCustNames.contains(uniqueIdentifier)) {
            uniqueCustNames.add(uniqueIdentifier);
            return true;
          }
          return false;
        })
            .toList();

        setState(() {
          data = uniqueData.cast<Map<String, dynamic>>();
          filteredData = List<Map<String, dynamic>>.from(data);
          applySorting();
        });

        print('Data: $data');
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

  List<Map<String, dynamic>> data = [];
  List<Map<String, dynamic>> filteredData = [];

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
  double totalWorkingSalary = 0;
  double totalExtraProduction = 0;
  double totalWorkTime = 0;
  double reqWorkTime = 0;
  double totalLate = 0;
/*
  void applyDateFilter() {
    setState(() {
      if (!isDateRangeValid) {
        return;
      }
      filteredData = data.where((item) {
        String dateStr = item['inDate']?.toString() ?? '';
        DateTime? itemDate = DateTime.tryParse(dateStr);

        if (itemDate != null &&
            !itemDate.isBefore(fromDate!) &&
            !itemDate.isAfter(toDate!.add(const Duration(days: 1)))) {
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
        DateTime? dateB = DateTime.tryParse(b['outDate'] ?? '');
        if (dateA == null || dateB == null) {
          return 0;
        }
        return dateB.compareTo(dateA);
      });
      totalWorkingSalary = calculateTotalWorkingSalary(filteredData);
      totalWorkTime = calculateTotalWorkTime(filteredData) as double;
      reqWorkTime = calculateReqWorkTime(filteredData) as double;
      totalLate = calculateTotalLate(filteredData);
    });
  }
*/
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

      totalWorkingSalary = calculateTotalWorkingSalary(filteredData);
      totalExtraProduction = calculateTotalExtraProduction(filteredData);
      totalWorkTime = calculateTotalWorkTime(filteredData) as double;
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
    _scrollController = ScrollController();

  }
  final FocusNode _searchFocus = FocusNode();

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
                            Padding(
                              padding: const EdgeInsets.only(right: 15),
                              child: Wrap(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: 180,
                                        height: 34,
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
                                            border: OutlineInputBorder(
                                              // borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                      ),const SizedBox(width: 10,),
                                      SizedBox(
                                        width: 180,
                                        height: 34,
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
                                            border: OutlineInputBorder(
                                              // borderRadius: BorderRadius.circular(10),
                                            ),
                                            isDense: true,
                                          ),

                                        ),
                                      ),SizedBox(width: 10,),
                                      SizedBox(
                                        width: 180,
                                        height: 34,
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
                                              suffixIcon: Icon(Icons.search),
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
                                            (item['first_name']?.toString()?.toLowerCase() ?? '').contains(pattern.toLowerCase()) ||
                                                (item['emp_code']?.toString()?.toLowerCase() ?? '').contains(pattern.toLowerCase()))
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


                                      Padding(
                                        padding: const EdgeInsets.all(20.0),
                                        child: MaterialButton(
                                          color: Colors.green.shade500,
                                          height: 40,
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
                                          child: const Text("Calculate", style: TextStyle(color: Colors.white)),
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.refresh),
                                        onPressed: () {
                                          Navigator.push(context, MaterialPageRoute(builder: (context)=>SalaryCalculation()));
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.arrow_back),
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                      ),
                                      SizedBox(width: 50,),
                                      if (generatedButton || searchController.text.isNotEmpty)
                                        Container(
                                          //width: 200,
                                          padding: EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [Colors.grey.shade50, Colors.grey.shade50,],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(15.0),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.grey.withOpacity(0.5),
                                                spreadRadius: 2,
                                                blurRadius: 10,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child:
                                            Column(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                if (fromDate != null && toDate != null && searchController.text.isEmpty)
                                                  Text(
                                                    "Total Salary: ₹${calculateTotalWorkingSalary(filteredData).toStringAsFixed(2)}",
                                                    style: const TextStyle(fontSize: 16, color: Colors.black),
                                                  )
                                                else
                                                  Column(
                                                    children: [
                                                      Text(
                                                        "Total Days: ${calculateTotalDays(filteredData)}",
                                                        style: const TextStyle(fontSize: 13, color: Colors.black, fontWeight: FontWeight.bold),
                                                      ),
                                                      const SizedBox(height: 10),
                                                      Text(
                                                        "Req Time: ${calculateReqWorkTime(filteredData)}",
                                                        style: const TextStyle(fontSize: 13, color: Colors.black, fontWeight: FontWeight.bold),
                                                      ),
                                                      SizedBox(height: 10),
                                                      Text(
                                                        "Work Time: ${calculateTotalWorkTime(filteredData)}",
                                                        style: const TextStyle(fontSize: 13, color: Colors.black),
                                                      ),
                                                      if (calculateTotalWorkTimeInHours(filteredData) > 5)
                                                        Column(
                                                          children: [
                                                            const SizedBox(height: 10),
                                                            Text(
                                                              "Total Late: $toLate",
                                                              style: const TextStyle(fontSize: 13, color: Colors.red),
                                                            ),
                                                            const SizedBox(height: 10),
                                                            Text(
                                                              "Extra Production: ₹${calculateTotalExtraProduction(filteredData)}",
                                                              style: const TextStyle(fontSize: 13, color: Colors.black),
                                                            ),
                                                            const SizedBox(height: 10),
                                                            Row(
                                                              children: [
                                                                const Text(
                                                                  "Total Salary: ",
                                                                  style: TextStyle(fontSize: 13, color: Colors.black),
                                                                ),
                                                                Text(
                                                                  "₹${calculateTotalWorkingSalary(filteredData).toStringAsFixed(2)}",
                                                                  style: const TextStyle(fontSize: 16, color: Colors.black),
                                                                ),
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                    ],
                                                  ),
                                              ],
                                            ),

                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
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
                            const Align(
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
                                columnSpacing:65.0,
                                rowsPerPage:25,
                                columns:   const [
                                  DataColumn(label: Center(child: Text("S.No",style: TextStyle(fontWeight: FontWeight.bold),))),
                                  DataColumn(label: Center(child: Text("In Date",style: TextStyle(fontWeight: FontWeight.bold),))),
                                  DataColumn(label: Center(child: Text("Emp Code",style: TextStyle(fontWeight: FontWeight.bold),))),
                                  DataColumn(label: Center(child: Text("    Name",style: TextStyle(fontWeight: FontWeight.bold),))),
                                  DataColumn(label: Center(child: Text("Shift",style: TextStyle(fontWeight: FontWeight.bold),))),
                                  DataColumn(label: Center(child: Text("Work Time",style: TextStyle(fontWeight: FontWeight.bold),))),
                                  DataColumn(label: Center(child: Text("Daily Salary",style: TextStyle(fontWeight: FontWeight.bold),))),
                                  DataColumn(label: Center(child: Text("Extra Production",style: TextStyle(fontWeight: FontWeight.bold),))),
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



    return DataRow(
      selected: selectedRows[index],
      // onSelectChanged: (bool? selected) {
      //   selectedRows[index] = selected ?? false;
      //   notifyListeners();
      //   if (selected == true) {
      //     onRowSelected(row);
      //
      //   }
      // },
      cells: [
        DataCell((Center(child: Text("${index + 1}")))),
        DataCell(Center(child: Text(
          row["inDate"] != null
              ? DateFormat('yyyy-MM-dd').format(
            DateTime.parse("${row["inDate"]}").toLocal(),
          )
              : "",
        ),)),

        DataCell(Center(child: Text("${row["emp_code"]}"))),
        DataCell(Center(child: Text("${row["first_name"]}"))),
        DataCell(Center(child: Text("${row["shiftType"]}"))),
        DataCell(Center(child: Text(formatDuration(row["act_time"])))),
        DataCell(Center(child: Text("₹${row["salary"]}"))),
        DataCell(Center(child: Text((row["calculated_extraproduction"] ?? 0).toString().replaceAll(RegExp(r'(\.0+|(?<=\.\d)0+)$'), '')))),
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
          formattedDuration += ' ';
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


