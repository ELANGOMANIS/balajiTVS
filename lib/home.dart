
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
  int totalEmployees = 0;
  int present = 0;
  int absent = 0;

  @override
  void initState() {
    super.initState();
    fetchAttendanceSummary();

  }
  Future<void> fetchAttendanceSummary() async {
    final response = await http.get(Uri.parse('http://localhost:3309/attendance-summary'));
    print("response ${response.statusCode}");
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        totalEmployees = data['totalEmployees'];
        present = data['present'];
        absent = data['absent'];
      });
    } else {
      // Handle the error
      throw Exception('Failed to load attendance summary');
    }
  }
  @override
  Widget build(BuildContext context) {
    return MyScaffold(
      route: "attendance_report",backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            TotalEmployeesHeader(totalEmployees: totalEmployees), // Example total students
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Wrap(

                children: [
                  AttendanceCard(
                    color: Colors.green,
                    icon: Icons.check_circle_outline,
                    title: 'Present',
                    count: present,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => PresentEmployeesPage(),));
                    }, // Example count
                  ),
                  SizedBox(height: 16),
                  AttendanceCard(
                    color: Colors.red,
                    icon: Icons.cancel_outlined,
                    title: 'Absent',
                    count: absent, onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => AbsentEmployeesPage(),));

                  }, // Example count
                  ),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TotalEmployeesHeader extends StatelessWidget {
  final int totalEmployees;

  TotalEmployeesHeader({required this.totalEmployees});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueAccent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group,
            color: Colors.white,
            size: 40,
          ),
          SizedBox(width: 16),
          Text(
            'Total Employees: $totalEmployees',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
class AttendanceCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final int count;
  final VoidCallback onTap;

  AttendanceCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.count,
    required this.onTap,
  });

  void _navigateToPage(BuildContext context, String routeName) {
    Navigator.pushNamed(context, routeName);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '$count Employees',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
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



class PresentEmployeesPage extends StatefulWidget {
  @override
  _PresentEmployeesPageState createState() => _PresentEmployeesPageState();
}

class _PresentEmployeesPageState extends State<PresentEmployeesPage> {
  List<dynamic> presentEmployees = [];

  @override
  void initState() {
    super.initState();
    fetchPresentEmployees();
  }

  Future<void> fetchPresentEmployees() async {
    final response = await http.get(Uri.parse('http://localhost:3309/present-employees'));
    if (response.statusCode == 200) {
      setState(() {
        presentEmployees = json.decode(response.body);
      });
    } else {
      throw Exception('Failed to load present employees');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     // route: "",backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Present Employees'),
      ),
      body: ListView.builder(
        itemCount: presentEmployees.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: Text((index + 1).toString()),
            title: Text(presentEmployees[index]['first_name']),
            subtitle: Text('Emp Code: ${presentEmployees[index]['emp_code']} | Mobile: ${presentEmployees[index]['empMobile']}'),
          );
        },
      ),
    );
  }
}

class AbsentEmployeesPage extends StatefulWidget {
  @override
  _AbsentEmployeesPageState createState() => _AbsentEmployeesPageState();
}

class _AbsentEmployeesPageState extends State<AbsentEmployeesPage> {
  List<dynamic> absentEmployees = [];

  @override
  void initState() {
    super.initState();
    fetchAbsentEmployees();
  }

  Future<void> fetchAbsentEmployees() async {
    final response = await http.get(Uri.parse('http://localhost:3309/absent-employees'));
    if (response.statusCode == 200) {
      setState(() {
        absentEmployees = json.decode(response.body);
      });
    } else {
      throw Exception('Failed to load absent employees');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     // route: '',backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Absent Employees'),
      ),

      body: ListView.builder(
        itemCount: absentEmployees.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: Text((index + 1).toString()),
            title: Text(absentEmployees[index]['first_name']),
            subtitle: Text('Emp Code: ${absentEmployees[index]['emp_code']} | Mobile: ${absentEmployees[index]['empMobile']}'),
          );
        },
      ),
    );
  }
}

class Utils {
  static Future<List<String>> getSuggestions() async {
    List<String> _shiftTypes = [];

    try {
      final response = await http.get(Uri.http('localhost:3309', '/get_shift_type'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        data.forEach((item) {
          _shiftTypes.add(item['shiftType']);
        });
      } else {
        throw Exception('Failed to fetch suggestions');
      }
    } catch (error) {
      print('Error fetching suggestions: $error');
      throw Exception('Failed to fetch suggestions');
    }

    return _shiftTypes;
  }

}


