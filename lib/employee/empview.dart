import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:vinayaga_project/main.dart';
import 'package:http/http.dart' as http;
import '../Attendance/employee_id_creation.dart';

class employeeView extends StatefulWidget {
  int id;
  String? empolyeeName;
  String? empID;
 // String? empolyeeMobile;
  String? positoion;
  String? salary;
  String? department;

  employeeView({Key? key,
    required this.id,
    //required this.date,
    required this.empolyeeName,
    required this.empID,
   // required this.empolyeeMobile,
    required this.positoion,
    required this.salary,
    required this.department,
    required List<Map<String, dynamic>> customerData}) : super(key: key);

  @override
  State<employeeView> createState() => _employeeViewState();
}
DateTime selectedDate = DateTime.now();
DateTime warrantyDate = DateTime.now();
String? errorMessage="";
String? empposition;
String? salary;

class _employeeViewState extends State<employeeView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController empID = TextEditingController();
  TextEditingController empName = TextEditingController();
  TextEditingController employeemobile = TextEditingController();
  TextEditingController employeeposition = TextEditingController();
  TextEditingController employeesalay = TextEditingController();
  TextEditingController employeedept = TextEditingController();
  TextEditingController warrantydatecontroller = TextEditingController();
  TextEditingController purchasedatecontroller = TextEditingController();
  TextEditingController currentdatecontroller = TextEditingController();

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != controller.text) {
      setState(() {
        controller.text = DateFormat("yyyy-MM-dd").format(picked);
      });
    }
  }


  @override
  void initState() {
    super.initState();
    empID = TextEditingController();
    empName = TextEditingController();
    employeemobile = TextEditingController();
    employeeposition = TextEditingController();
    employeesalay=TextEditingController();
    employeedept=TextEditingController();
    currentdatecontroller=TextEditingController();
    empID.text = widget.empID ?? '';
    empName.text = widget.empolyeeName ?? '';
   // employeemobile.text = widget.empolyeeMobile.toString();
    employeeposition.text = widget.positoion.toString();
    employeedept.text = widget.department ?? '';
    employeesalay.text = widget.salary.toString();
    fetchEmployeeDetails(widget.empID ?? '');
  }

  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  void fetchEmployeeDetails(String empID) async {
    if (empID.isEmpty) {
      return;
    }
    final response = await http.get(Uri.parse('http://localhost:3309/employee/$empID'));
    print("Response status code: ${response.statusCode}");
    print("Response body: ${response.body}");

    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);
      print("Data received: $data");

      setState(() {
        empposition = data["empPosition"] ?? "";
        salary = data["salary"] ?? "";
      });

    } else {
      print("Error fetching employee details. Employee ID not found or server error.");
    }
  }


  String currentDateString = DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now());

  Future<void> updateEmployeeDetails(
      String id,
      String empID,
      String empolyeeName,
      String empolyeeMobile,
      String positoion,
      String salary,
      String department,
      String modifyDate, // Add modifyDate parameter
      ) async {
    try {
      final response = await http.put(
        Uri.parse('http://localhost:3309/employeeview_update/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': id,
          'empID': empID,
          'empName': empolyeeName,
          'empMobile': empolyeeMobile,
          'deptName': department,
          'salary': salary,
          'empPosition': positoion,
          'modifyDate': modifyDate,
        }),
      );
      if (response.statusCode == 200) {
        print('Data updated successfully');
      } else {
        print('Error updating data: ${response.statusCode}, ${response.body}');
      }
    }catch (error) {
      print('Error fetching data: $error');
    }
  }


  String capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text.substring(0, 1).toUpperCase() + text.substring(1);
  }
  @override
  Widget build(BuildContext context) {
    DateTime currentDate = DateTime.now();
    String currentdatecontroller = DateFormat("yyyy-MM-dd HH:mm:ss").format(currentDate);
    // DateTime purchaseDate = DateTime.now();
    // String purchasedatecontroller = DateFormat("yyyy-MM-dd").format(purchaseDate);
    // DateTime warrantyDate = DateTime.now();
    // String warrantydatecontroller = DateFormat("yyyy-MM-dd").format(warrantyDate);

    return  MyScaffold(
      route: '',backgroundColor: Colors.white,
      body: Form(key: _formKey,child:
      Column(
        children: [
          SizedBox(height: 2,),
          SizedBox(
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: Container(
                height: 80,
                width: double.infinity, // Set the width to full page width
                padding: EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border.all(color: Colors.grey), // Add a border for the box
                  borderRadius: BorderRadius.circular(10.0), // Add border radius for rounded corners
                ),
                child: Wrap(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top:15.0),
                          child: Row(
                            children: [
                              Icon(Icons.account_balance_sharp),SizedBox(width: 10,),
                              Text("Employee Report",style: TextStyle(fontSize: 25,fontWeight: FontWeight.bold),),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top:20.0),
                          child: Text(
                              DateFormat('dd-MM-yyyy').format(currentDate),
                              style:TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(
            child:  Padding(
              padding: const EdgeInsets.only(right: 4.0,left:4),
              child: Container(
                width: double.infinity, // Set the width to full page width
                padding: EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  border: Border.all(color: Colors.grey), // Add a border for the box
                  borderRadius: BorderRadius.circular(10.0), // Add border radius for rounded corners
                ),
                child: Wrap(
                  children: [
                    Row(
                      children: [
                        Text("Employee Details",style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          errorMessage ?? '',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                    SizedBox(height: 50,),
                    Wrap(
                      spacing: 68.0, // Set the horizontal spacing between the children
                      runSpacing: 20.0,
                      children: [
                        SizedBox(
                          width: 200, height: 70,
                          child: TextFormField(
                            readOnly: true,
                            onChanged: (value) {
                              fetchEmployeeDetails(value);
                              String capitalizedValue = capitalizeFirstLetter(value);
                              empID.value = empID.value.copyWith(
                                text: capitalizedValue,
                                selection: TextSelection.collapsed(offset: capitalizedValue.length),
                              );
                              setState(() {
                                errorMessage = null; // Reset error message when user types
                              });
                            },
                            initialValue: widget.empID,
                            style: TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              labelText: "Employee ID",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            //const Text("Machine Model"),
                            SizedBox(
                              width: 200, height: 70,
                              child: TextFormField(
                                readOnly: true,
                                onChanged: (value) {
                                  String capitalizedValue = capitalizeFirstLetter(value);
                                  empName.value = empName.value.copyWith(
                                    text: capitalizedValue,
                                    selection: TextSelection.collapsed(offset: capitalizedValue.length),
                                  );
                                  setState(() {
                                    errorMessage = null; // Reset error message when user types
                                  });
                                },
                                initialValue: widget.empolyeeName,
                                style: TextStyle(fontSize: 13),
                                decoration: InputDecoration(
                                  labelText: "Employee Name",
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        // SizedBox(width: 8,),
                       /* SizedBox(
                          width: 200, height: 70,
                          child: TextFormField(
                            onChanged: (value) {
                              String capitalizedValue = capitalizeFirstLetter(value);
                              employeemobile.value = employeemobile.value.copyWith(
                                text: capitalizedValue,
                                selection: TextSelection.collapsed(offset: capitalizedValue.length),
                              );
                              setState(() {
                                errorMessage = null; // Reset error message when user types
                              });
                            },
                            initialValue: widget.empolyeeMobile,
                            //controller: machineS_No,
                            style: TextStyle(fontSize: 13),
                            keyboardType: TextInputType.text,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(10),
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              prefixText: "+91",
                              labelText: "Employee Mobile",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),*/
                        // SizedBox(width: 8,),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 200,
                              height: 35,
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
                                        borderSide: BorderSide(width: 1, color: Colors.white)),
                                  ),
                                  hint: const Text("Employee Position", style: TextStyle(fontSize: 13),),
                                  isExpanded: true,
                                  value: empposition, // Use the position variable here

                                  items: <String>["Operator", "Assistant"]
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
                                      empposition = newValue!; // Update the position variable
                                    });
                                  },
                                ),
                              ),
                            ),

                          ],
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 68.0, // Set the horizontal spacing between the children
                      runSpacing: 20.0,
                      children: [
                        SizedBox(
                          width: 200,height: 70,
                          child: TextFormField(
                            onChanged: (value) {
                              String capitalizedValue = capitalizeFirstLetter(value);
                              employeedept.value = employeedept.value.copyWith(
                                text: capitalizedValue,
                                selection: TextSelection.collapsed(offset: capitalizedValue.length),
                              );
                              setState(() {
                                errorMessage = null; // Reset error message when user types
                              });
                            },
                            initialValue: widget.department.toString(),
                            style: TextStyle(fontSize: 13),
                            keyboardType: TextInputType.text,
                            decoration: InputDecoration(
                              labelText: "Department Name",
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 200,
                              height: 35,
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
                                        borderSide: BorderSide(width: 1, color: Colors.white)),
                                  ),
                                  hint: const Text("Salary Type", style: TextStyle(fontSize: 13),),
                                  isExpanded: true,
                                  value: salary, // Use the position variable here
                                  items: <String>["Weekly","Monthly"]
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
                                      salary = newValue!; // Update the position variable
                                    });
                                  },
                                ),
                              ),
                            ),

                          ],
                        ),

                        /* Column(
                          children: [
                            SizedBox(
                              width: 200,
                              height: 35,
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
                                        width: 1,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  hint: const Text("Salary Type", style: TextStyle(fontSize: 12)),
                                  isExpanded: true,
                                  value: salary, // Set the initial value to the selected salary
                                  items: <String>["Weekly","Monthly"]
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
                                      salary = newValue!; // Update the selected salary value
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),*/
                      ],
                    ),
                  ],
                ),

              ),


            ),
          ),
          Wrap(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: MaterialButton(
                  color: Colors.green.shade600,
                  onPressed: () {

                    if (empName.text.isEmpty) {
                      setState(() {
                        errorMessage = '* Enter a Employee Name';
                      });
                    }
                    else if (employeemobile.text.isEmpty) {
                      setState(() {
                        errorMessage = '* Enter a Employee Mobile';
                      });
                    }
                    else if (employeemobile.text.length != 10) {
                      setState(() {
                        errorMessage = '* Mobile number should be 10 digits';
                      });
                    }
                    else if (employeeposition.text.isEmpty) {
                      setState(() {
                        errorMessage = '* Select a Employee Position';
                      });
                    }
                    else if (employeedept.text.isEmpty) {
                      setState(() {
                        errorMessage = '* Enter a Employee Department';
                      });
                    }
                    else if (employeesalay.text.isEmpty) {
                      setState(() {
                        errorMessage = '* Select a Employee salary Type';
                      });
                    }
                    else{
                      updateEmployeeDetails(
                        widget.id.toString(),
                        empID.text,
                        empName.text,
                        employeemobile.text,
                        employeeposition.text,
                        employeesalay.text,
                        employeedept.text,
                        DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now()),
                      );
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Employee'),
                            content: Text('Update Successfully'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context)=> EmpIDCreation())) ;// Close the alert box
                                },
                                child: Text('OK'),
                              ),
                            ],
                          );
                        },
                      );
                    }
                  },
                  child: const Text("SAVE", style: TextStyle(color: Colors.white)),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(8.0),
                child: MaterialButton(
                  color: Colors.red.shade600,
                  onPressed: (){
                    Navigator.pop(context);
                  },child: const Text("BACK",style: TextStyle(color: Colors.white),),),
              ),
            ],
          ),
        ],

      ),

      ),

    );
  }
}
