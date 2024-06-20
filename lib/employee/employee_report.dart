import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:intl/intl.dart';
import 'package:vinayaga_project/main.dart';
import 'package:http/http.dart' as http;
import '../home.dart';
import 'employeeDetails_pdf.dart';
import 'employeeDetails_report.dart';
import 'employee_report_pdf.dart';

class EmployeeReport extends StatefulWidget {
  const EmployeeReport({Key? key}) : super(key: key);
  @override
  State<EmployeeReport> createState() => _EmployeeReportState();
}
class _EmployeeReportState extends State<EmployeeReport> {
  List<String> supplierSuggestions = [];
  String selectedSupplier = "";
  bool isDateRangeValid=true;
  int currentPage = 1;
  int rowsPerPage = 10;
  String? selectedCustomer="";
  final ScrollController _scrollController = ScrollController();





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
  String text="";
  List<String> itemGroupValues = [];
  List<String> invoiceNumber = [];
  Future<void> fetchData() async {
    try {
      final url = Uri.parse('http://localhost:3309/employee_get_report/');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final List<dynamic> itemGroups = responseData;

        setState(() {
          data = itemGroups.cast<Map<String, dynamic>>();

          filteredData = List<Map<String, dynamic>>.from(data);

          filteredData.sort((a, b) {
            DateTime? dateA = DateTime.tryParse(a['date'] ?? '');
            DateTime? dateB = DateTime.tryParse(b['date'] ?? '');
            if (dateA == null || dateB == null) {
              return 0;

            }
            return dateB.compareTo(dateA);
          });
        });
        print('Data: $data');
      } else {
        print('Error: ${response.statusCode}');
      }
    } catch (error) {
      print('Error: $error');
    }
  }

  List<Map<String, dynamic>> data = [];
  List<Map<String, dynamic>> filteredData = [];

  void filterData(String searchText) {
    print("Search Text: $searchText");
    setState(() {
      if (searchText.isEmpty) {
        // If the search text is empty, show all data without filtering by supplier name
        filteredData = List<Map<String, dynamic>>.from(data);
      } else {
        filteredData = data.where((item) {
          String supName = item['emp_code']?.toString()?.toLowerCase() ?? '';
          String searchTextLowerCase = searchText.toLowerCase();

          return supName.contains(searchTextLowerCase);
        }).toList();
      }

      // Sort filteredData in descending order based on the "date" field
      filteredData.sort((a, b) {
        DateTime? dateA = DateTime.tryParse(a['date'] ?? '');
        DateTime? dateB = DateTime.tryParse(b['date'] ?? '');

        if (dateA == null || dateB == null) {
          return 0;
        }

        return dateB.compareTo(dateA);
      });
    });
    print("Filtered Data Length: ${filteredData.length}");
  }

  Future<void> updateEmployeeStatus(String empCode, String status) async {
    try {
      final Uri url = Uri.parse('http://localhost:3309/update_status');
      final response = await http.post(url, headers: {
        'Content-Type': 'application/json',
      }, body: jsonEncode({
        'empCode': empCode,
        'status': status,
      }));
      if (response.statusCode == 200) {
        print('Employee status updated successfully');
      } else {
        print('Error updating employee status: ${response.statusCode}');
      }
    } catch (error) {
      print('Error updating employee status: $error');
    }
  }


  Future<void> deleteItem(BuildContext context, int id) async {
    try {
      final response = await http.delete(
        Uri.parse('http://localhost:3309/Employee_delete/$id'),
      );
      if (response.statusCode == 200) {
      } else {
        throw Exception('Error deleting Item Group: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete Item Group: $e');
    }
  }
  void onDelete(int id) {
    deleteItem(context, id);
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

  @override
  Widget build(BuildContext context) {

    final formattedDate = fromDate != null ? DateFormat("dd-MM-yyyy").format(fromDate!) : "";
    final formattedDate2 = toDate != null ? DateFormat("dd-MM-yyyy").format(toDate!) : "";

    searchController.addListener(() {
      filterData(searchController.text);
    });

    return MyScaffold(
      route: "employee_report",backgroundColor: Colors.white,
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
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Column(
                          children: [
                            Wrap(
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
                                        Navigator.push(context, MaterialPageRoute(builder: (context)=>EmployeeReport()));
                                      },
                                    ),

                                    Icon(Icons.report,),
                                    SizedBox(width:10,),
                                    Text(
                                      'Employee Report',
                                      style: TextStyle(
                                        fontSize:20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 10,),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: 220,
                                          height: 70,
                                          child: TypeAheadFormField<String>(
                                            textFieldConfiguration: TextFieldConfiguration(
                                              controller: searchController,
                                              onChanged: (value) {
                                                String capitalizedValue = capitalizeFirstLetter(value);
                                                searchController.value = searchController.value.copyWith(
                                                  text: capitalizedValue,
                                                  selection: TextSelection.collapsed(offset: capitalizedValue.length),
                                                );
                                              },
                                              style: const TextStyle(fontSize: 13),
                                              decoration: InputDecoration(
                                                suffixIcon: Icon(Icons.search),
                                                fillColor: Colors.white,
                                                filled: true,
                                                labelText: "Employee Name or ID", // Update label
                                                labelStyle: TextStyle(fontSize: 13, color: Colors.black),
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                              ),
                                            ),
                                            suggestionsCallback: (pattern) async {
                                              if (pattern.isEmpty) {
                                                return [];
                                              }
                                              List<String> suggestions = data
                                                  .where((item) {
                                                String empName = item['first_name']?.toString()?.toLowerCase() ?? '';
                                                String empID = item['emp_code']?.toString()?.toLowerCase() ?? '';
                                                return empName.contains(pattern.toLowerCase()) || empID.contains(pattern.toLowerCase());
                                              })
                                                  .map<String>((item) =>
                                              '${item['first_name']} (${item['emp_code']})') // Modify this line to match your data structure
                                                  .toSet() // Remove duplicates using a Set
                                                  .toList();

                                              return suggestions;
                                            },
                                            itemBuilder: (context, suggestion) {
                                              return ListTile(
                                                title: Text(suggestion),
                                              );
                                            },
                                            onSuggestionSelected: (suggestion) {
                                              String selectedEmpName = suggestion.split(' ')[0];
                                              String selectedEmpID = suggestion.split('(')[1].split(')')[0];
                                              setState(() {
                                                selectedCustomer = selectedEmpID;
                                                // Use selectedEmpID as needed
                                                searchController.text = selectedEmpID;

                                              });
                                              print('Selected Customer: $selectedCustomer, ID: $selectedEmpID');
                                            },
                                          ),
                                        ),
                                      ],
                                    ),

                                      IconButton(
                                        icon: Icon(Icons.refresh),
                                        onPressed: () {
                                          Navigator.push(context, MaterialPageRoute(builder: (context)=>EmployeeReport()));
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.arrow_back),
                                        onPressed: () {
                                          // Navigator.push(context, MaterialPageRoute(builder: (context)=>SalaryCalculation()));
                                          Navigator.pop(context);
                                        },
                                      ),
                                  ],
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
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            const Align(
                                alignment:Alignment.topLeft,
                                child: Padding(
                                  padding: EdgeInsets.only(left: 5),
                                  child: Text("Report Details",style: TextStyle(fontSize:17,fontWeight: FontWeight.bold),),
                                )),
                            const SizedBox(height: 20,),
                            Scrollbar(
                              thumbVisibility: true,
                              controller: _scrollController,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                controller: _scrollController,
                                child: SizedBox(
                                  width:1200,
                                  child: PaginatedDataTable(
                                    columnSpacing:90.0,
                                    rowsPerPage:25,
                                    columns:   const [
                                      DataColumn(label: Center(child: Text("    S.No",style: TextStyle(fontWeight: FontWeight.bold),))),
                                      DataColumn(label: Center(child: Text("  Emp ID",style: TextStyle(fontWeight: FontWeight.bold),))),
                                      DataColumn(label: Center(child: Text("   Employee Name",style: TextStyle(fontWeight: FontWeight.bold),))),
                                      DataColumn(label: Center(child: Text("      Mobile",style: TextStyle(fontWeight: FontWeight.bold),))),
                                      DataColumn(label: Center(child: Text("    Position",style: TextStyle(fontWeight: FontWeight.bold),))),
                                      DataColumn(label: Center(child: Text("    Salary",style: TextStyle(fontWeight: FontWeight.bold),))),
                                      //DataColumn(label: Center(child: Text("    Status",style: TextStyle(fontWeight: FontWeight.bold),))),
                                      DataColumn(label: Center(child: Text("    Action",style: TextStyle(fontWeight: FontWeight.bold),))),
                                    ],
                                    source: _YourDataTableSource(filteredData,context,generatedButton,onDelete),
                                  ),
                                ),
                              ),
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
                            Navigator.push(context, MaterialPageRoute(builder: (context)=>EmployeeReportPDF(
                              customerData : filteredData,
                            )));
                          },child: const Text("PRINT",style: TextStyle(color: Colors.white),),),
                      ),
                      SizedBox(height: 20,),
                      Padding(
                        padding: const EdgeInsets.only(left: 15.0,right: 15.0),
                        child: MaterialButton(
                          shape:  RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                          color: Colors.red,
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
  final Function(int) onDelete;
  final BuildContext context;
  final bool generatedButton;
  _YourDataTableSource(this.data,this.context, this.generatedButton,this.onDelete);
  Future<void> updateEmployeeStatus(String emp_code, String Status) async {
    try {
      final Uri url = Uri.parse('http://localhost:3309/update_status');
      final response = await http.post(url, headers: {
        'Content-Type': 'application/json',
      }, body: jsonEncode({
        'emp_code': emp_code,
        'Status': Status,
      }));
      if (response.statusCode == 200) {
        print('Employee status updated successfully');
      } else {
        print('Error updating employee status: ${response.statusCode}');
      }
    } catch (error) {
      print('Error updating employee status: $error');
    }
  }

  Future<void> employeedeactivate(String emp_code, String Status) async {
    try {
      final Uri url = Uri.parse('http://localhost:3309/update_status2');
      final response = await http.post(url, headers: {
        'Content-Type': 'application/json',
      }, body: jsonEncode({
        'emp_code': emp_code,
        'Status': Status,
      }));
      if (response.statusCode == 200) {
        print('Employee status updated successfully');
      } else {
        print('Error updating employee status: ${response.statusCode}');
      }
    } catch (error) {
      print('Error updating employee status: $error');
    }
  }

  @override
  DataRow? getRow(int index) {
    if (index >= data.length) {
      return null;
    }

    final row = data[index];
    final id=row["id"];

    return DataRow(
      cells: [
        DataCell(Center(child: Text("${index + 1}"))),
        DataCell(Center(child: Text("${row["emp_code"]}"))),
        DataCell(Center(child: Text("${row["first_name"]}"))),
        DataCell(Center(child: Text("${row["empMobile"]}"))),
        DataCell(Center(child: Text("${row["empPosition"]}"))),
        DataCell(Center(child: Text("${row["salary"]}"))),
        // DataCell(Center(child:
        // Row(children: [
        //   Visibility(visible:(row["Status"]=="Active") ,
        //     child: IconButton(
        //         onPressed: () {
        //           showDialog(
        //               context: context,
        //               builder: (ctx) =>
        //               // Dialog box for register meeting and add guest
        //               AlertDialog(
        //                 backgroundColor:
        //                 Colors.grey[
        //                 800],
        //                 title: const Text(
        //                     'Deactivate',
        //                     style: TextStyle(
        //                         color: Colors
        //                             .white)),
        //                 content: const Text(
        //                     "Do you want to Deactivate this Employee?",
        //                     style: TextStyle(
        //                         color: Colors
        //                             .white)),
        //                 actions: [
        //                   TextButton(
        //                     onPressed:
        //                         () async {
        //                       await employeedeactivate(row["emp_code"], "Deactivate");
        //                       Navigator.push(context, MaterialPageRoute(builder: (context)=>EmployeeReport()));
        //                       ScaffoldMessenger.of(
        //                           context)
        //                           .showSnackBar(const SnackBar(
        //                           content:
        //                           Text("You have Successfully Deactivate this Employee")));
        //                     },
        //                     child: const Text(
        //                         'Yes',
        //                         style: TextStyle(
        //                             color:
        //                             Colors.white)),
        //                   ),
        //                   TextButton(
        //                       onPressed:
        //                           () async {
        //                         Navigator.pop(
        //                             context);
        //                       },
        //                       child: const Text(
        //                           'No',
        //                           style: TextStyle(
        //                               color:
        //                               Colors.white)))
        //                 ],
        //               ));
        //         },
        //         icon: const Icon(
        //           Icons.check_circle_outline,
        //           color: Colors.green,
        //         ))
        //   ),
        //   Visibility(visible:(row["Status"]=="Deactivate"),
        //     child:  IconButton(
        //         onPressed: () {
        //           showDialog(
        //               context: context,
        //               builder: (ctx) =>
        //               // Dialog box for register meeting and add guest
        //               AlertDialog(
        //                 backgroundColor:
        //                 Colors.grey[
        //                 800],
        //                 title: const Text(
        //                     'Activate',
        //                     style: TextStyle(
        //                         color: Colors
        //                             .white)),
        //                 content: const Text(
        //                     "Do you want to Activate this Employee?",
        //                     style: TextStyle(
        //                         color: Colors
        //                             .white)),
        //                 actions: [
        //                   TextButton(
        //                     onPressed:
        //                         () async {
        //                           await employeedeactivate(row["emp_code"], "Active");
        //                      Navigator.push(context, MaterialPageRoute(builder: (context)=>EmployeeReport()));
        //                       ScaffoldMessenger.of(
        //                           context)
        //                           .showSnackBar(const SnackBar(
        //                           content:
        //                           Text("You have Successfully Deactivate this Employee")));
        //                     },
        //                     child: const Text(
        //                         'Yes',
        //                         style: TextStyle(
        //                             color:
        //                             Colors.white)),
        //                   ),
        //                   TextButton(
        //                       onPressed:
        //                           () {
        //                         Navigator.pop(
        //                             context);
        //                       },
        //                       child: const Text(
        //                           'No',
        //                           style: TextStyle(
        //                               color:
        //                               Colors.white)))
        //                 ],
        //               ));
        //         },
        //         icon: const Icon(
        //           Icons.remove,
        //           color: Colors.red,
        //         ))
        //
        //     /*IconButton(
        //       onPressed: () async {
        //         await employeedeactivate(row["emp_code"], "Deactivate");
        //       },
        //       icon: Icon(Icons.remove),
        //       color: Colors.green.shade600,
        //     ),*/
        //   ),
        //
        // ],)
        // )
        // ),
        DataCell(Container(
          child: Row(children: [
            // IconButton(
            //   onPressed: (){
            //     String fathername=row["fatherName"];
            //     String fatherMobile=row["fatherMobile"];
            //     Navigator.push(context, MaterialPageRoute(builder: (context)=>EmployeeDetails(
            //       // empPhoto:row["empPhoto"],
            //       empID:row["emp_code"].toString(),
            //       empName:row["first_name"].toString(),
            //       empAddress :row["empAddress"].toString(),
            //       pincode: (row["pincode"] ?? "-").toString(),
            //       empMobile:row["empMobile"].toString(),
            //       dob:row["dob"],
            //       age:row["age"].toString(),
            //       bloodgroup:row["bloodgroup"].toString(),
            //       gender:row["gender"].toString(),
            //       maritalStatus:row["maritalStatus"].toString(),
            //       gaurdian: fathername.isEmpty? row["spouseName"]??"":fathername,
            //       gaurdianmobile:fatherMobile.isEmpty?row["spouseMobile"]??"":fatherMobile,
            //       education:row["education"].toString(),
            //       doj:row["doj"],
            //       end:row["endingDate"],
            //       deptName:row["deptName"].toString(),
            //       empPosition:row["empPosition"].toString(),
            //       salary:row["salaryType"].toString(),
            //       daySalary:row["salary"].toString(),
            //       shift:row["shift"].toString(),
            //       acNumber:row["acNumber"].toString(),
            //       acHoldername:row["acHoldername"].toString(),
            //       bank:row["bank"].toString(),
            //       branch:row["branch"].toString(),
            //       ifsc:row["ifsc"].toString(),
            //       pan:row["pan"].toString(),
            //       aadhar:row["aadhar"].toString(),
            //     )
            //     ));
            //   },icon:const Icon(Icons.remove_red_eye_outlined),
            //   color: Colors.blue.shade600,
            // ),

            IconButton(
              onPressed: (){

                String fathername=row["fatherName"] ?? "";
                String fatherMobile=row["fatherMobile"]?? "";
                Navigator.push(context, MaterialPageRoute(builder: (context)=> EmployeeReportPdf(
                  empID:row["emp_code"],
                  empName:row["first_name"],
                  empAddress :row["empAddress"],
                  pincode :row["pincode"],
                  empMobile:row["empMobile"],
                  dob:row["dob"],
                  age:row["age"],
                  bloodgroup:row["bloodgroup"],
                  gender:row["gender"],
                  maritalStatus:row["maritalStatus"],
                  gaurdian: fathername.isEmpty? row["spouseName"]??"":fathername,
                  gaurdianmobile:fatherMobile.isEmpty?row["spouseMobile"]??"":fatherMobile,
                  education:row["education"],
                  doj:row["doj"],
                  end:row["endingDate"],
                  deptName:row["deptName"],
                  empPosition:row["empPosition"],
                  salary:row["salaryType"],
                  shift:row["shift"],
                  daySalary:row["salary"],
                  acNumber:row["acNumber"],
                  acHoldername:row["acHoldername"],
                  bank:row["bank"],
                  branch:row["branch"],
                  ifsc:row["ifsc"],
                  pan:row["pan"],
                  aadhar:row["aadhar"],
                )
                ));
              },icon: Icon(Icons.print,),
              color: Colors.blue.shade600,
            ),

            // IconButton(
            //   icon: Icon(Icons.delete, color: Colors.red),
            //   onPressed: () {
            //     showDeleteConfirmationDialog(context, id);
            //   },
            // ),


          ],),

        )),
      ],
    );

  }
  void showDeleteConfirmationDialog(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this Employee?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context)=>const EmployeeReport()));
                onDelete(id); // Call the onDelete function
              },
              child: Text('Yes'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('No'),
            ),
          ],
        );
      },
    );
  }


  @override
  int get rowCount => data.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
}

