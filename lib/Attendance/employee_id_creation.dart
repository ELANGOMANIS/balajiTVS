
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../home.dart';
import '../../main.dart';
import '../employee/empview.dart';




class EmpIDCreation extends StatefulWidget {
  const EmpIDCreation({Key? key}) : super(key: key);

  @override
  State<EmpIDCreation> createState() => _EmpIDCreationState();
}
class _EmpIDCreationState extends State<EmpIDCreation> {
  DateTime date = DateTime.now();
  final _formKey = GlobalKey<FormState>();
  List<String> supplierSuggestions = [];
  String selectedSupplier = "";
  bool isDateRangeValid=true;
  int currentPage = 1;
  int rowsPerPage = 10;
  String? errorMessage="";
  TextEditingController empMobile = TextEditingController();
  String? empposition;
  String? salary;
  List<Map<String, dynamic>> filteredData = [];
  bool showInitialData = true;
  String? selectedCustomer="";

  Future<void> fetchData({String? searchText}) async {
    try {
      final url = Uri.parse('http://localhost:3309/employee_get_report/');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final List<dynamic> itemGroups = responseData;

        setState(() {
          data = itemGroups.cast<Map<String, dynamic>>();

          // If searchText is provided, filter the data
          if (searchText != null && searchText.isNotEmpty) {
            filteredData = data.where((item) {
              String empName = item['empName']?.toString()?.toLowerCase() ?? '';
              String empID = item['empID']?.toString()?.toLowerCase() ?? '';
              return empName.contains(searchText.toLowerCase()) || empID.contains(searchText.toLowerCase());
            }).toList();
          } else {
            // If no searchText, use the entire data
            filteredData = List<Map<String, dynamic>>.from(data);
          }

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


  /* Future<void> fetchData() async {
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
  }*/



  void filterData(String searchText) {
    print("Search Text: $searchText");
    setState(() {
      if (searchText.isEmpty) {
        // If the search text is empty, show all data without filtering by supplier name
        filteredData = List<Map<String, dynamic>>.from(data);
      } else {
        filteredData = data.where((item) {
          String supName = item['empName']?.toString()?.toLowerCase() ?? '';
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



  String capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text.substring(0, 1).toUpperCase() + text.substring(1);
  }
//generate code

  String? getNameFromJsonData(Map<String, dynamic> jsonItem) {
    // Use the key "name" to access the value of the "name" column.
    return jsonItem['empID'];
  }
  List<Map<String, dynamic>> data = [];
  String? quotationNo;

  Future<void> quotfetch() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:3309/empID'));
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        for(var item in jsonData){
          quotationNo = getNameFromJsonData(item);
          print('empID: $quotationNo');
        }
        setState(() {
          data = jsonData.cast<Map<String, dynamic>>();
          quotationNumber = generateId(); // Call generateId here

        });
      } else {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Error'),
              content: Text('Failed to fetch data'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } catch (error) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('An error occurred: $error'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  bool isEmployeeNameExists(String name) {
    return data.any((item) => item['empName'].toString().toLowerCase() == name.toLowerCase());
  }

  bool isEmployeeMobileExists(String name) {
    return data.any((item) => item['empMobile'].toString().toLowerCase() == name.toLowerCase());
  }

  String quotationNumber ="";
  String generateId() {
    if (quotationNo != null) {
      String iddd = quotationNo!.substring(1);
      int idInt = int.parse(iddd) + 1;
      String id = 'E${idInt.toString().padLeft(3, '0')}';
      print('empID------------------------------------------------llllllllll: $quotationNo');
      return id;
    }
    return "";
  }
  @override
  void initState() {
    super.initState();
    quotfetch();
    fetchData();
    filteredData = List<Map<String, dynamic>>.from(data);
  }


  bool generatedButton = false;
  DateTime? fromDate;
  DateTime? toDate;
  DateTime currentDate = DateTime.now();
  TextEditingController searchController = TextEditingController();

  List<String> itemGroupValues = [];
  List<String> invoiceNumber = [];
  bool isNameDuplicate = false;
  TextEditingController empName =TextEditingController();
  TextEditingController empID =TextEditingController();
  TextEditingController depName =TextEditingController();
  Map<String, dynamic> dataToInsert = {};

  Future<void> insertDataSup(Map<String, dynamic> dataToInsert) async {
    const String apiUrl = 'http://localhost:3309/employee'; // Replace with your server details
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({'dataToInsert': dataToInsert}),
      );
      if (response.statusCode == 200) {
        print('TableData inserted successfully');
      } else {
        print('Failed to Table insert data');
        throw Exception('Failed to Table insert data');
      }
    } catch (e) {
      print('Error: $e');
      throw Exception('Error: $e');
    }
  }
  Future<void> supDataToDatabase() async {
    if (isNameDuplicate) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Error"),
            content: Text("Employee Name already exists."),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text("OK"),
              ),
            ],
          );
        },
      );
      return;
    }
    List<Future<void>> insertFutures = [];
    Map<String, dynamic> dataToInsert = {
      //'date':currentDate,
      'empName': empName.text,
      'empID': empID.text,
      "fatherName":"",
      "fatherMobile":"",
      "Status":"",
      "empAddress":"",
      "empMobile":empMobile.text,
      "gender":"",
      "dob":"",
      "age":"",
      "bloodgroup":"",
      "maritalStatus":"",
      "spouseName":"",
      "spouseMobile":"",
      "empPhoto":"",
      "education":"",
      "aadhar":"",
      "doj":"",
      "endingDate":"",
      "empPosition":empposition.toString(),
      "deptName":depName.text,
      "shift":"",
      "salary":salary.toString(),
      "acNumber":"",
      "acHoldername":"",
      "branch":"",
      "ifsc":"",
      "pan":"",
      "bank":""

    };
    insertFutures.add(insertDataSup(dataToInsert));
    await Future.wait(insertFutures);
  }


  Future<void> deleteItem(BuildContext context, int id) async {
    try {
      final response = await http.delete(
        Uri.parse('http://localhost:3309/employeeviewdelete/$id'),
      );
      if (response.statusCode == 200) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => Home(),
          ),
        );
      } else {
        throw Exception('Error deleting Item Group: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete Item Group: $e');
    }
  }

  void showDeleteConfirmationDialog(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this item?'),
          actions: [
            TextButton(
              onPressed: () {
                onDelete(id);
                Navigator.push(context, MaterialPageRoute(builder: (context)=> EmpIDCreation()));
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

  void onDelete(int id) {
    deleteItem(context, id);
  }

  @override
  Widget build(BuildContext context) {
    searchController.addListener(() {
      filterData(searchController.text);
    });
    empID.text= generateId();
    DateTime currentDate = DateTime.now();
    return MyScaffold(
      route: "empID_creation",backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Center(
            child: Column(
              children: [
                SizedBox(height: 5,),
                SizedBox(
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Container(
                      width: double.infinity, // Set the width to full page width
                      padding: EdgeInsets.all(16.0), // Add padding for spacing
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey), // Add a border for the box
                        borderRadius: BorderRadius.circular(10.0), // Add border radius for rounded corners
                      ),
                      child: Wrap(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(bottom:5),
                                          child: const Icon(Icons.edit, size:30),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text("Employee ID Creation",style: TextStyle(fontSize:20,fontWeight: FontWeight.bold),),
                                        ),
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(top:10.0),
                                      child: Padding(
                                        padding: const EdgeInsets.only(right:10.0),
                                        child: Text(
                                            DateFormat('dd-MM-yyyy').format(currentDate),
                                            style:TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ]
                              ),
                            ),

                          ]
                      ),
                    ),
                  ),
                ),
                SizedBox(

                  //height: 400,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: Container(
                          width: double.infinity, // Set the width to full page width
                          padding: EdgeInsets.all(16.0), // Add padding for spacing
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            border: Border.all(color: Colors.grey), // Add a border for the box
                            borderRadius: BorderRadius.circular(10.0), // Add border radius for rounded corners
                          ),
                          child:Padding(
                            padding: const EdgeInsets.only(left:10),
                            child: Column(
                              children: [
                                Wrap(
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.only(bottom: 13),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(left: 10,bottom: 10),
                                              child: Text("Enter the Details",style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 17,
                                              ),),
                                            ),
                                            Text(
                                              errorMessage ?? '',
                                              style: TextStyle(color: Colors.red),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(left:10.0),
                                        child: Wrap(
                                          children: [
                                            SizedBox(
                                              width: 220,height: 75,
                                              child: TextFormField(
                                                controller:empID,
                                                style: TextStyle(fontSize: 13),
                                                onChanged: (value) {
                                                  setState(() {
                                                    empID.text= generateId();
                                                  });
                                                  String capitalizedValue = capitalizeFirstLetter(value);
                                                  empID.value = empID.value.copyWith(
                                                    text: capitalizedValue,
                                                    selection: TextSelection.collapsed(offset: capitalizedValue.length),
                                                  );
                                                },
                                                decoration: InputDecoration(
                                                    labelText: "Employee ID",
                                                    filled: true,
                                                    fillColor: Colors.white,
                                                    border: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(10,),
                                                    )
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 32,),
                                            SizedBox(
                                              width: 220,
                                              height: 75,
                                              child: TextFormField(
                                                controller: empName,
                                                style: TextStyle(fontSize: 13),
                                                onChanged: (value) {
                                                  String trimmedValue = value.trim();
                                                  String formattedValue = trimmedValue.replaceAll(RegExp(r'\s+'), ' ');

                                                  if (isEmployeeNameExists(formattedValue)) {
                                                    setState(() {
                                                      errorMessage = '* Employee Name already exists';
                                                    });
                                                    return;
                                                  }
                                                  String capitalizedValue = capitalizeFirstLetter(formattedValue);
                                                  empName.value = empName.value.copyWith(
                                                    text: capitalizedValue,
                                                    selection: TextSelection.collapsed(offset: capitalizedValue.length),
                                                  );
                                                  setState(() {
                                                    errorMessage = null; // Reset error message when user types
                                                  });
                                                },
                                                decoration: InputDecoration(
                                                  labelText: "Employee Name",
                                                  filled: true,
                                                  fillColor: Colors.white,
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(8.0),
                                                  ),
                                                ),
                                                // Remove the autofocus property
                                              ),
                                            ),
                                            SizedBox(width: 32,),
                                            SizedBox(
                                              width: 220,
                                              height: 75,
                                              child: TextFormField(
                                                onChanged: (value) {
                                                  setState(() {
                                                    // Clear the error message when the mobile number changes
                                                    errorMessage = '';
                                                  });

                                                  if (isEmployeeMobileExists(empMobile.text)) {
                                                    setState(() {
                                                      errorMessage = '* Employee Mobile already exists';
                                                    });
                                                    return;
                                                  }
                                                },
                                                controller: empMobile,
                                                style: TextStyle(fontSize: 13),
                                                decoration: InputDecoration(
                                                  prefixText: "+91",
                                                  labelText: "Mobile Number",
                                                  filled: true,
                                                  fillColor: Colors.white,
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                ),
                                                keyboardType: TextInputType.number,
                                                inputFormatters: <TextInputFormatter>[
                                                  FilteringTextInputFormatter.digitsOnly,
                                                  LengthLimitingTextInputFormatter(10)
                                                ],
                                              ),
                                            ),

                                            /*SizedBox(
                                              width: 220, height: 75,
                                              child: TextFormField(
                                                onChanged: (value){
                                                  if (isEmployeeMobileExists(empMobile.text)) {
                                                    setState(() {
                                                      errorMessage = '* Employee Mobile already exists';
                                                    });
                                                    return;
                                                  }
                                                },
                                                controller: empMobile,
                                                style: TextStyle(fontSize: 13),

                                                decoration: InputDecoration(
                                                  prefixText: "+91",
                                                  labelText: "Mobile Number",
                                                  filled:true,
                                                  fillColor: Colors.white,
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                ),
                                                keyboardType: TextInputType.number,
                                                inputFormatters: <TextInputFormatter>[
                                                  FilteringTextInputFormatter.digitsOnly,
                                                  LengthLimitingTextInputFormatter(10)
                                                ],
                                              ),
                                            ),*/
                                            SizedBox(width: 32,),

                                            Padding(
                                              padding: const EdgeInsets.only(bottom: 35.0),
                                              child: SizedBox(
                                                width: 220,
                                                child: DropdownButtonHideUnderline(
                                                  child: DropdownButtonFormField<String>(
                                                    decoration: const InputDecoration(
                                                      filled: true,
                                                      fillColor: Colors.white,
                                                      contentPadding: EdgeInsets.symmetric(
                                                        vertical: 10.0,
                                                        horizontal: 16.0,
                                                      ),
                                                      disabledBorder: OutlineInputBorder(
                                                          borderSide: BorderSide(
                                                              width: 1, color: Colors.white)),
                                                    ),
                                                    hint: const Text("Employee Position",style: TextStyle(fontSize:13,color:Colors.black),),
                                                    isExpanded: true,
                                                    value: empposition,

                                                    items: <String>[  "Operator", "Assistant",]
                                                        .map<DropdownMenuItem<String>>((String value) {
                                                      return DropdownMenuItem<String>(
                                                        value: value,
                                                        child: Text(
                                                          value,
                                                          style: const TextStyle(fontSize: 15),
                                                        ),
                                                      );
                                                    }).toList(),
                                                    onChanged: (String? newValue) {
                                                      setState(() {
                                                        empposition = newValue!;
                                                      });},),),),
                                            ),

                                          ],
                                        ),
                                      ),
                                    ]
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(right: 290.0),
                                  child: Wrap(
                                    children: [
                                      SizedBox(
                                        width: 220, height: 70,
                                        child: TextFormField(
                                            controller: depName,
                                            onChanged: (value) {
                                              String capitalizedValue = capitalizeFirstLetter(
                                                  value);
                                              depName.value =
                                                  depName.value.copyWith(
                                                    text: capitalizedValue,
                                                    selection: TextSelection.collapsed(
                                                        offset: capitalizedValue.length),
                                                  );
                                            },
                                            style: TextStyle(fontSize: 13),
                                            decoration: InputDecoration(
                                              filled: true,
                                              fillColor: Colors.white,
                                              labelText: "Designation",
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(
                                                    8.0),
                                              ),
                                            )
                                        ),
                                      ),
                                      SizedBox(width: 32,),

                                      SizedBox(
                                        width: 220,
                                        height:34,
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButtonFormField<String>(
                                            decoration: const InputDecoration(
                                              filled: true,
                                              fillColor: Colors.white,
                                              contentPadding: EdgeInsets.symmetric(
                                                vertical: 10.0,
                                                horizontal: 16.0,
                                              ),
                                              disabledBorder: OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      width: 1, color: Colors.white)),
                                            ),
                                            hint: const Text("Salary Type",style: TextStyle(fontSize:13,color: Colors.black),),
                                            isExpanded: true,
                                            value: salary,
                                            items: <String>["Weekly","Monthly"
                                            ]
                                                .map<DropdownMenuItem<String>>((String value) {
                                              return DropdownMenuItem<String>(
                                                value: value,
                                                child: Text(
                                                  value,
                                                  style: const TextStyle(fontSize: 15),
                                                ),
                                              );
                                            }).toList(),
                                            onChanged: (String? newValue) {
                                              setState(() {
                                                salary = newValue!;
                                              });},),),),
                                      SizedBox(width: 32,),
                                      SizedBox(
                                        width: 220,
                                        child: Text(""
                                        ),
                                      ),
                                      SizedBox(width: 32,),
                                      SizedBox(
                                        width: 220,
                                        child: Text(""
                                        ),
                                      ),
                                      SizedBox(width: 105,),

                                    ],),
                                )
                              ],
                            ),

                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(40.0),
                  child:
                  Wrap(
                    children: [
                      MaterialButton(
                        color: Colors.green.shade600,
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            if (isEmployeeNameExists(empName.text)) {
                              setState(() {
                                errorMessage = '* Employee Name already Storded';
                              });
                              return;
                            }
                            if (isEmployeeMobileExists(empMobile.text)) {
                              setState(() {
                                errorMessage = '* Employee Mobile already Storded';
                              });
                              return;
                            }
                            if (empName.text.isEmpty) {
                              setState(() {
                                errorMessage = '* Enter a Employee Name';
                              });
                            }
                            else if (empMobile.text.isEmpty) {
                              setState(() {
                                errorMessage = '* Enter a Mobile Number';
                              });
                            }
                            else if (empMobile.text.length != 10) {
                              setState(() {
                                errorMessage = '* Mobile number should be 10 digits';
                              });
                            }
                            else if(empposition==null){
                              setState(() {
                                errorMessage ="* Select a Employee Position";
                              });
                            }
                            else if (depName.text.isEmpty) {
                              setState(() {
                                errorMessage = '* Enter a Designation';
                              });
                            }
                            else if(salary==null){
                              setState(() {
                                errorMessage ="* Select a Salary Type";
                              });
                            }
                            else {
                              List<Map<String, dynamic>> rowsDataToInsert = [];
                              rowsDataToInsert.add(dataToInsert);
                              supDataToDatabase();
                              try {
                                empID.clear();
                                empName.clear();
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text("Empolyee"),
                                      content: Text("Created Successfully."),
                                      actions: <Widget>[
                                        TextButton(
                                          onPressed: () {
                                            Navigator.push(context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        EmpIDCreation()));
                                          },
                                          child: Text("OK"),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              }
                              catch (e) {
                                print('Error inserting data: $e');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        "Failed to save data. Please try again."),
                                  ),
                                );
                              }
                            }
                          }
                        },
                        child: const Text("SAVE", style: TextStyle(color: Colors.white)),

                      ),
                      const SizedBox(width: 20,),
                      MaterialButton(
                        color: Colors.blue.shade600,
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Confirmation'),
                                content: const Text('Do you want to Reset?'),
                                actions: <Widget>[
                                  TextButton(
                                    child: const Text('Yes'),
                                    onPressed: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (context)=> EmpIDCreation()));
                                    },
                                  ),
                                  TextButton(
                                    child: const Text('No'),
                                    onPressed: () {
                                      Navigator.pop(context); // Close the alert box
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: const Text("RESET",style: TextStyle(color: Colors.white),),),
                      const SizedBox(width: 20,),
                      MaterialButton(
                        color: Colors.red.shade600,
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
                                          MaterialPageRoute(builder: (context) =>Home()));// Close the alert box
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
                        child: Text("CANCEL",style: TextStyle(color: Colors.white),),)
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Padding(
                          padding:  EdgeInsets.all(8.0),
                          child: SingleChildScrollView(
                            child: Container(
                                width: double.infinity,
                                child: Padding(
                                  padding: EdgeInsets.all(8.0),

                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.all(8.0),
                                                child:SizedBox(
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
                                                        String empName = item['empName']?.toString()?.toLowerCase() ?? '';
                                                        String empID = item['empID']?.toString()?.toLowerCase() ?? '';
                                                        return empName.contains(pattern.toLowerCase()) || empID.contains(pattern.toLowerCase());
                                                      })
                                                          .map<String>((item) =>
                                                      '${item['empName']} (${item['empID']})') // Modify this line to match your data structure
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
                                                        selectedCustomer = selectedEmpName;
                                                        // Use selectedEmpID as needed
                                                        searchController.text = selectedEmpName;
                                                      });
                                                      print('Selected Customer: $selectedCustomer, ID: $selectedEmpID');
                                                    },
                                                  ),
                                                ),

                                                /*SizedBox(
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
                                                        labelText: "Employee Name",
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
                                                          .where((item) =>
                                                          (item['empName']?.toString()?.toLowerCase() ?? '')
                                                              .startsWith(pattern.toLowerCase()))
                                                          .map<String>((item) =>
                                                      '${item['empName']} (${item['empID']})') // Modify this line to match your data structure
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
                                                        selectedCustomer = selectedEmpName;
                                                        // Use selectedEmpID as needed
                                                        searchController.text = selectedEmpName;
                                                      });
                                                      print('Selected Customer: $selectedCustomer, ID: $selectedEmpID');
                                                    },
                                                  ),
                                                ),*/
                                              ),

                                              /*SizedBox(
                                          width: 220,
                                          height: 50,
                                          child: TextFormField(
                                            onChanged: (value){
                                              String capitalizedValue = capitalizeFirstLetter(value);
                                              searchController.value = searchController.value.copyWith(
                                                text: capitalizedValue,
                                                selection: TextSelection.collapsed(offset: capitalizedValue.length),);
                                            },
                                            focusNode: _searchFocus,
                                            controller: searchController,
                                            style: const TextStyle(fontSize: 13),
                                            //onChanged: filterData,
                                            decoration: InputDecoration(
                                              labelText: "Employee Name",
                                              suffixIcon: Icon(Icons.search),
                                              fillColor: Colors.white,
                                              filled: true,
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                            ),
                                          ),
                                        ),*/
                                              if (supplierSuggestions.isNotEmpty)
                                                Container(
                                                  padding: EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius: BorderRadius.circular(10),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.grey.withOpacity(0.5),
                                                        spreadRadius: 2,
                                                        blurRadius: 4,
                                                        offset: Offset(0, 3),
                                                      ),
                                                    ],
                                                  ),
                                                  child: ListView.builder(
                                                    shrinkWrap: true,
                                                    itemCount: supplierSuggestions.length,
                                                    itemBuilder: (context, index) {
                                                      return ListTile(
                                                        title: Text(supplierSuggestions[index]),
                                                        onTap: () {
                                                          setState(() {
                                                            selectedSupplier = supplierSuggestions[index];
                                                            searchController.text = selectedSupplier;
                                                            filterData(selectedSupplier);
                                                          });
                                                        },
                                                      );
                                                    },
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      PaginatedDataTable(
                                        columnSpacing:50.0,
                                        //  header: const Text("Report Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                        rowsPerPage:10,
                                        columns:   const [
                                          DataColumn(label: Center(child: Text("S.No",style: TextStyle(fontWeight: FontWeight.bold),))),
                                          // DataColumn(label: Center(child: Text("   Date",style: TextStyle(fontWeight: FontWeight.bold),))),
                                          DataColumn(label: Center(child: Text("Employee ID",style: TextStyle(fontWeight: FontWeight.bold),))),
                                          DataColumn(label: Center(child: Text("Employee Name",style: TextStyle(fontWeight: FontWeight.bold),))),
                                          DataColumn(label: Center(child: Text("Employee Mobile",style: TextStyle(fontWeight: FontWeight.bold),))),
                                          DataColumn(label: Center(child: Text("Employee Position",style: TextStyle(fontWeight: FontWeight.bold),))),
                                          DataColumn(label: Center(child: Text("Designation",style: TextStyle(fontWeight: FontWeight.bold),))),
                                          DataColumn(label: Center(child: Text("Salary Type",style: TextStyle(fontWeight: FontWeight.bold),))),
                                          DataColumn(label: Center(child: Text("     Action",style: TextStyle(fontWeight: FontWeight.bold),))),
                                        ],
                                        source: _YourDataTableSource( filteredData, context,generatedButton,  onDelete, showDeleteConfirmationDialog),

                                      ),
                                    ],
                                  ),
                                )
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
  final Function(int) onDelete;
  final Function(BuildContext, int) showDeleteConfirmationDialog;
  final bool generatedButton;

  _YourDataTableSource(
      this.data, this.context, this.generatedButton, this.onDelete, this.showDeleteConfirmationDialog);
  @override
  DataRow? getRow(int index) {
    if (index >= data.length) {
      return null;
    }
    final row = data[index];
    final id = row["id"];
    return DataRow(
      cells: [
        DataCell(Center(child: Text("${index + 1}"))),
        //DataCell(Center(
        //   child:   Text(
        //     row["date"] != null
        //         ? DateFormat('dd-MM-yyyy').format(
        //       DateTime.parse("${row["date"]}"),
        //     ) : "",
        //   ),
        // )),
        DataCell(Center(child: Text("${row["empID"]}"))),
        DataCell(Center(child: Text("${row["empName"]}"))),
        DataCell(Center(child: Container(
            constraints: BoxConstraints(maxWidth:150),child: Text("${row["empMobile"]}")))),
        DataCell(Center(child: Container(
            constraints: BoxConstraints(maxWidth:150),child: Text("${row["empPosition"]}")))),
        DataCell(Center(child: Container(
            constraints: BoxConstraints(maxWidth:150),child: Text("${row["deptName"]}")))),
        DataCell(Center(child: Container(
            constraints: BoxConstraints(maxWidth:150),child: Text("${row["salary"]}")))),
        DataCell(Center(child:Container(
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(icon: Icon(Icons.edit ,color:Colors. blue,),onPressed: (){
                  Navigator.push(context, MaterialPageRoute(builder: (context)=>employeeView(
                    customerData:data,
                    id: row["id"],
                    //date:row["date"],
                    empolyeeName:row["empName"],
                    empID:row["empID"],
                    //empolyeeMobile:row["empMobile"].toString(),
                    positoion:row["empPosition"],
                    department:row["deptName"],
                    salary:row["salary"],
                  )));
                },),

                /*IconButton(
                  icon: Icon(Icons.delete),
                  color: Colors.red,
                  onPressed: () {
                    showDeleteConfirmationDialog(context, id);
                  },
                ),*/
              ],
            ),
          ),
        ),)),
      ],
    );
  }

  @override
  int get rowCount => data.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
}


