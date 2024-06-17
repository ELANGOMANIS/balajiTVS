
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:intl/intl.dart';
import 'package:vinayaga_project/main.dart';
import 'package:http/http.dart' as http;
import '../../home.dart';
import 'Attendance/attandance_pdf.dart';


class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);
  @override
  State<Home> createState() => _HomeState();

}
class _HomeState extends State<Home> {

  String? errorMessage;

  ScrollController _scrollController = ScrollController();


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
        searchText = searchText.toLowerCase(); // Convert search text to lowercase once

        filteredData = data.where((item) {
          String supName = item['first_name']?.toString()?.toLowerCase() ?? '';
          String shiftType = item['shiftType']?.toString()?.toLowerCase() ?? '';

          String searchTextLowerCase = searchText.toLowerCase();

          return supName.contains(searchTextLowerCase) ||
              shiftType.contains(searchTextLowerCase);
        }).toList();
        if (filteredData.isNotEmpty) {
          Map<String, dynamic> order = filteredData.first;
          emp_code.text = order['emp_code']?.toString() ?? '';
        } else {
          emp_code.clear();
        }
      }

      // Move the sorting after applying the search filter
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
  void applyDateFilter() {
    setState(() {
      if (!isDateRangeValid) {
        return;
      }

      // Calculate present and missing dates
      Set<DateTime> presentDates = Set();
      List<DateTime> missingDates = [];
      for (var item in data) {
        String dateStr = item['inDate']?.toString() ?? '';
        DateTime? itemDate = DateTime.tryParse(dateStr);

        if (itemDate != null &&
            itemDate.isAfter(fromDate!.subtract(Duration(days: 1))) &&
            itemDate.isBefore(toDate!.add(Duration(days: 1)))) {
          presentDates.add(itemDate);
        }
      }

      // Find missing dates
      for (DateTime date = fromDate!; date.isBefore(toDate!); date = date.add(Duration(days: 1))) {
        if (!presentDates.contains(date)) {
          missingDates.add(date);
        }
      }

      // Filter data based on search query
      String searchTextLowerCase = searchController.text.toLowerCase();
      filteredData = data.where((item) {
        String id = item['first_name']?.toString()?.toLowerCase() ?? '';
        String shiftType = item['shiftType']?.toString()?.toLowerCase() ?? '';
        return (id.contains(searchTextLowerCase) || shiftType.contains(searchTextLowerCase)) &&
            (presentDates.contains(DateTime.parse(item['inDate'])));
      }).toList();

      applySorting();

      // Calculate total present and absent days
      int totalPresentDays = presentDates.length;
      int totalAbsentDays = missingDates.length;

      // Format missing dates as date strings without time component
      List<String> formattedMissingDates =
      missingDates.map((date) => DateFormat('yyyy-MM-dd').format(date)).toList();

      print('Total Present Days: $totalPresentDays');
      print('Total Absent Days: $totalAbsentDays');
      print('Missing Dates: $formattedMissingDates');
    });
  }
  Map<String, dynamic> calculateTotalAbsentDays(DateTime fromDate, DateTime toDate, List<Map<String, dynamic>> filteredData) {
    Set<DateTime> presentDates = Set();

    // Add present dates to the set
    for (var item in filteredData) {
      String dateStr = item['inDate']?.toString() ?? '';
      DateTime? itemDate = DateTime.tryParse(dateStr);

      if (itemDate != null) {
        presentDates.add(itemDate);
      }
    }

    // Calculate total days within the specified range
    int totalDaysInRange = toDate.difference(fromDate).inDays + 1;

    // Find missing dates
    List<DateTime> missingDates = [];
    for (DateTime date = fromDate; date.isBefore(toDate.add(Duration(days: 1))); date = date.add(Duration(days: 1))) {
      if (!presentDates.contains(date)) {
        missingDates.add(date);
      }
    }

    // Calculate total absent days
    int totalAbsentDays = missingDates.length;

    return {
      'totalAbsentDays': totalAbsentDays,
      'missingDates': missingDates,
    };
  }
/*
  int calculateTotalAbsentDays(DateTime fromDate, DateTime toDate, List<Map<String, dynamic>> filteredData) {
    Set<DateTime> presentDates = Set();

    // Add present dates to the set
    for (var item in filteredData) {
      String dateStr = item['inDate']?.toString() ?? '';
      DateTime? itemDate = DateTime.tryParse(dateStr);

      if (itemDate != null) {
        presentDates.add(itemDate);
      }
    }

    // Calculate total days within the specified range
    int totalDaysInRange = toDate.difference(fromDate).inDays + 1;

    // Calculate total absent days by subtracting present days from total days in range
    int totalAbsentDays = totalDaysInRange - presentDates.length;

    return totalAbsentDays;
  }
*/

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

    int totalPresentDays = fromDate != null && toDate != null
        ? filteredData.length
        : 0;
    int totalAbsentDays = fromDate != null && toDate != null
        ? calculateTotalAbsentDays(fromDate!, toDate!, filteredData)['totalAbsentDays']
        : 0;

    List<DateTime> missingDates = fromDate != null && toDate != null
        ? calculateTotalAbsentDays(fromDate!, toDate!, filteredData)['missingDates']
        : [];
    searchController.addListener(() {
      filterData(searchController.text);
    });

    // if (data.isEmpty) {
    //   return const CircularProgressIndicator(); // Show a loading indicator while data is fetched.
    // }
    return MyScaffold(
      route: "attendance_report",backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Form(
          child: Center(
            child: Column(
              children: [

                Padding(
                  padding: const EdgeInsets.all(3.0),
                  child: SingleChildScrollView(
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                       // color: Colors.blue.shade100,
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
                                  child: Wrap(
                                    //mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Row(
                                        children: [
                                          Text("Today's Attendance",style: TextStyle(fontSize:17,fontWeight: FontWeight.bold),),
                                        ],
                                      ),

                                      Row(
                                        children: [
                                          Text("Shift",style: TextStyle(fontSize:15),),
                                          SizedBox(width: 10,),
                                          Text("1",style: TextStyle(fontSize:15),),
                                          Checkbox(value: true, onChanged: (value){}),
                                          Text("2",style: TextStyle(fontSize:15),),
                                          Checkbox(value: true, onChanged: (value){}),
                                          Text("3",style: TextStyle(fontSize:15),),
                                          Checkbox(value: true, onChanged: (value){}),
                                        ],
                                      ),
                                      


                                    ],
                                  ),
                                )),
                            const SizedBox(height: 20,),
                            PaginatedDataTable(
                              columnSpacing:52.5,
                              rowsPerPage:25,
                              columns:   const [
                                DataColumn(label: Center(child: Text("S.No",style: TextStyle(fontWeight: FontWeight.bold),))),
                                DataColumn(label: Center(child: Text("In Date",style: TextStyle(fontWeight: FontWeight.bold),))),
                                DataColumn(label: Center(child: Text("Emp Code",style: TextStyle(fontWeight: FontWeight.bold),))),
                                DataColumn(label: Center(child: Text("Name",style: TextStyle(fontWeight: FontWeight.bold),))),
                                DataColumn(label: Center(child: Text("Shift",style: TextStyle(fontWeight: FontWeight.bold),))),
                                DataColumn(label: Center(child: Text("Check-in",style: TextStyle(fontWeight: FontWeight.bold),))),
                               // DataColumn(label: Center(child: Text("Lunch-out",style: TextStyle(fontWeight: FontWeight.bold),))),
                               // DataColumn(label: Center(child: Text("Lunch-in",style: TextStyle(fontWeight: FontWeight.bold),))),
                                DataColumn(label: Center(child: Text("Check-out",style: TextStyle(fontWeight: FontWeight.bold),))),
                                DataColumn(label: Center(child: Text("Total Hrs",style: TextStyle(fontWeight: FontWeight.bold),))),
                                DataColumn(label: Center(child: Text("Remark",style: TextStyle(fontWeight: FontWeight.bold),))),

                              ],
                              source: _YourDataTableSource(filteredData,context,generatedButton),
                            ),
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
                            Navigator.push(context, MaterialPageRoute(builder: (context)=>AttendancePdf(
                              customerData : filteredData,
                              totalPresentDays : totalPresentDays,
                              totalAbsentDays : totalAbsentDays,

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
                          child: const Text("CANCEL",style: TextStyle(color: Colors.white),),),
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

  _YourDataTableSource(this.data,this.context, this.generatedButton);

  @override
  DataRow? getRow(int index) {
    if (index >= data.length) {
      return null;
    }

    final row = data[index];

    return DataRow(
      cells: [
        DataCell(Center(child: Text("${index + 1}"))),
        DataCell(Center(
          child: Text(
            row["inDate"] != null
                ? DateFormat('yyyy-MM-dd').format(
              DateTime.parse("${row["inDate"]}").toLocal(),
            )
                : "",
          ),
        )),
        DataCell(Center(child: Text("${row["emp_code"]}"))),
        DataCell(Center(child: Text("${row["first_name"]}"))),
        DataCell(Center(child: Text("${row["shiftType"]}"))),
        DataCell(Center(child: Text(formatTime(row["check_in"])))),
       /* DataCell(
          Center(
            child: Text(
              formatTimeOrZero(
                (isBetweenLunchOutTime(row["lunch_out"], row["shiftType"]))
                    ? "00:00:00" // Assuming "General" shift has lunchOutTime of "00:00:00"
                    : row["lunch_out"],
              ),
            ),
          ),
        ),
        DataCell(
          Center(
            child: Text(
              formatTimeOrZero(
                (isBetweenLunchInTime(row["lunch_in"], row["shiftType"]))
                    ? "00:00:00" // Assuming "General" shift has lunchOutTime of "00:00:00"
                    : row["lunch_in"],
              ),
            ),
          ),
        ),*/
        DataCell(
          Center(
            child: Text(
              formatTime(
                (isBetweenLunchOutTime(row["lunch_out"], row["shiftType"]) || isBetweenLunchInTime(row["lunch_in"], row["shiftType"]))
                    ? (isBetweenLunchOutTime(row["lunch_out"], row["shiftType"]) ? row["lunch_out"] : row["lunch_in"])
                    : row["check_out"],
              ),
            ),
          ),
        ),
        DataCell(Center(child: Text(formatDuration(row["act_time"])))),
        DataCell(Center(
          child: Text(
            calculateRemark(row),
            style: TextStyle(
              fontSize: 15,
              color: calculateRemark(row) == "A" ? Colors.red : (calculateRemark(row) == "P" ? Colors.green.shade500 : Colors.orange), // Adjust color for HD as needed
              fontWeight: FontWeight.bold,
            ),
          ),
        )),
      ],
    );
  }
  bool isBetweenLunchOutTime(String lunchOutTime, String shiftType) {
    if (lunchOutTime == "00:00:00") {
      return false; // Handle the "00:00:00" case as needed
    }

    DateTime dummyDate = DateTime.parse("2000-01-01 $lunchOutTime");

    if (shiftType == "General") {
      return dummyDate.hour >= 16 && dummyDate.hour < 23;
    } else if (shiftType == "Morning") {
      return dummyDate.hour >= 17 && dummyDate.hour < 23;
    }

    return false; // Default case
  }
  bool isBetweenLunchInTime(String lunchInTime, String shiftType) {
    if (lunchInTime == "00:00:00") {
      return false; // Handle the "00:00:00" case as needed
    }

    DateTime dummyDate = DateTime.parse("2000-01-01 $lunchInTime");

    if (shiftType == "General") {
      return dummyDate.hour >= 16 && dummyDate.hour < 23;
    } else if (shiftType == "Morning") {
      return dummyDate.hour >= 17 && dummyDate.hour < 23;
    }

    return false; // Default case
  }
  String calculateRemark(Map<String, dynamic> row) {
    // Helper function to check if a time value is considered present
    bool isTimePresent(String? time) => time != null && time.trim() != "0" && time.trim() != "00:00:00";

    // Check if all time values are '0' or equivalent
    if (!isTimePresent(row["check_in"]) && !isTimePresent(row["lunch_out"]) &&
        !isTimePresent(row["lunch_in"]) && !isTimePresent(row["check_out"])) {
      return 'A'; // All fields are '0', marked as Absent
    }

    // Determine the presence of each time stamp
    bool checkInPresent = isTimePresent(row["check_in"]);
    bool checkOutPresent = isTimePresent(row["check_out"]);
    bool lunchOutPresent = isTimePresent(row["lunch_out"]);
    bool lunchInPresent = isTimePresent(row["lunch_in"]);

    // If only check_out is present and all other fields are '0' or not present
    if (!checkInPresent && checkOutPresent && !lunchOutPresent && !lunchInPresent) {
      return 'A'; // Mark as Absent since only check_out is present
    }

    // Check if lunch_out should be considered as check_out
    bool lunchOutIsCheckOut = isBetweenLunchOutTime(row["lunch_out"], row["shiftType"]);

    // Conditions for remark calculations
    if (checkInPresent && checkOutPresent && !lunchInPresent) {
      return 'P'; // Present, considering lunch_out as check_out if within the specified time
    } else if (checkInPresent && !checkOutPresent && lunchOutPresent && !lunchInPresent) {
      if (!lunchOutIsCheckOut) {
        return 'HD'; // Half Day
      } else {
        return 'P'; // Present
      }
    } else if (checkInPresent && !checkOutPresent && lunchOutPresent && lunchInPresent) {
      return 'HD'; // Half Day
    } else if (checkInPresent && checkOutPresent && lunchOutPresent && lunchInPresent) {
      return 'P'; // Present
    }

    // Default case if none of the above conditions are met
    return 'A'; // Mark as Absent by default
  }

/*
  bool isBetweenLunchOutTime(String lunchOutTime) {
    if (lunchOutTime == "00:00:00") {
      return false; // Handle the "00:00:00" case as needed
    }

    DateTime dummyDate = DateTime.parse("2000-01-01 $lunchOutTime");
    return dummyDate.hour >= 16 && dummyDate.hour < 23;
  }
*/
  String formatTime(String timeString) {
    if (timeString != null && timeString != "00:00:00") {
      List<String> timeParts = timeString.split(':');

      if (timeParts.length == 3) {
        DateTime dateTime = DateTime(1970, 1, 1, int.parse(timeParts[0]), int.parse(timeParts[1]), int.parse(timeParts[2]));
        return DateFormat('h:mm a').format(dateTime);
      }
    }
    return "0";
  }

  String formatTimeOrZero(String timeString) {
    if (timeString != null && timeString != "00:00:00" && timeString != "0") {
      List<String> timeParts = timeString.split(':');

      if (timeParts.length == 3) {
        DateTime dateTime = DateTime(1970, 1, 1, int.parse(timeParts[0]), int.parse(timeParts[1]), int.parse(timeParts[2]));
        return DateFormat('h:mm a').format(dateTime);
      }
    }
    return "0";
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


  @override
  int get rowCount => data.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
}


