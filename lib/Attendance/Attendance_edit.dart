import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

import '../../home.dart';


class AttendanceAlter extends StatefulWidget {
  const AttendanceAlter({Key? key}) : super(key: key);
  @override
  State<AttendanceAlter> createState() => _AttendanceAlterState();
}
class _AttendanceAlterState extends State<AttendanceAlter> {





  TextEditingController Date=TextEditingController();
  TextEditingController empCode=TextEditingController();
  TextEditingController firstName=TextEditingController();
  TextEditingController chackIn=TextEditingController();
  TextEditingController lunchOut=TextEditingController();
  TextEditingController lunchIn=TextEditingController();
  TextEditingController checkOut=TextEditingController();
  TextEditingController actTime=TextEditingController();
  TextEditingController shiftType=TextEditingController();
  TextEditingController reqTime=TextEditingController();
  TextEditingController remark=TextEditingController();
  TextEditingController late=TextEditingController();
  TextEditingController lunchLate=TextEditingController();
  TextEditingController earlyCheckOut=TextEditingController();

  String? errorMessage="";
  String selectedInvoiceNo='';

  int calculateLate(String shiftType, String checkIn) {
    if (shiftType == 'Morning') {
      DateTime checkInTime = DateFormat('HH:mm:ss').parse(checkIn);
      DateTime shiftStartTime = DateFormat('HH:mm:ss').parse('08:00:00');

      if (checkInTime.isBefore(shiftStartTime)) {
        return 0;
      } else {
        return (checkInTime.difference(shiftStartTime).inMinutes);
      }
    } else if (shiftType == 'General' || shiftType == 'Night') {
      DateTime checkInTime = DateFormat('HH:mm:ss').parse(checkIn);
      DateTime shiftStartTime =
      (shiftType == 'General') ? DateFormat('HH:mm:ss').parse('09:00:00') : DateFormat('HH:mm:ss').parse('20:00:00');

      if (checkInTime.isBefore(shiftStartTime)) {
        return 0;
      } else {
        return (checkInTime.difference(shiftStartTime).inMinutes);
      }
    }

    return 0;
  }

  int calculateEarlyCheckOut(String shiftType, String checkOut) {
    if (shiftType == 'Morning') {
      DateTime checkOutTime = DateFormat('HH:mm:ss').parse(checkOut);
      DateTime shiftEndTime = DateFormat('HH:mm:ss').parse('20:00:00');

      if (checkOutTime.isAfter(shiftEndTime)) {
        return 0;
      } else {
        return (shiftEndTime.difference(checkOutTime).inMinutes);
      }
    } else if (shiftType == 'General' || shiftType == 'Night') {
      DateTime checkOutTime = DateFormat('HH:mm:ss').parse(checkOut);
      DateTime shiftEndTime =
      (shiftType == 'General') ? DateFormat('HH:mm:ss').parse('18:00:00') : DateFormat('HH:mm:ss').parse('08:00:00');

      if (checkOutTime.isAfter(shiftEndTime)) {
        return 0;
      } else {
        return (shiftEndTime.difference(checkOutTime).inMinutes);
      }
    }

    return 0;
  }

  int calculateLunchLate(String lunchOut, String lunchIn) {
    DateTime lunchOutTime = DateFormat('HH:mm:ss').parse(lunchOut);
    DateTime lunchInTime = DateFormat('HH:mm:ss').parse(lunchIn);
    int lunchLate = 0;
    if (lunchOutTime.isBefore(lunchInTime)) {
      Duration lunchDuration = lunchInTime.difference(lunchOutTime);
      if (lunchDuration.inMinutes > 30) {
        lunchLate = lunchDuration.inMinutes - 30;
      }
    }
    return lunchLate;
  }

  void calculateLateTime() {
    String shiftTypeValue = shiftType.text;
    String checkInValue = chackIn.text;
    String checkOutValue = checkOut.text;
    String lunchOutValue = lunchOut.text;
    String lunchInValue = lunchIn.text;

    // Calculate late, earlyCheckOut, and lunchLate
    int lateValue = calculateLate(shiftTypeValue, checkInValue);
    int earlyCheckOutValue = calculateEarlyCheckOut(shiftTypeValue, checkOutValue);
    int lunchLateValue = calculateLunchLate(lunchOutValue, lunchInValue);

    // Update the respective TextEditingControllers
    late.text = lateValue.toString();
    earlyCheckOut.text = earlyCheckOutValue.toString();
    lunchLate.text = lunchLateValue.toString();
  }



  void calculateActTime() {
    TextSelection savedSelection = actTime.selection;
    if (shiftType.text.toLowerCase().trim().contains('night')) {
      if (chackIn.text.isNotEmpty &&
          lunchOut.text.isNotEmpty &&
          lunchIn.text.isNotEmpty &&
          checkOut.text.isNotEmpty) {
        int chckInTime = convertToMinutes(chackIn.text);
        int lunchOutTime = convertToMinutes("23:59:59");
        int lunchInTime = convertToMinutes("00:00:00");
        int checkOutTime = convertToMinutes(checkOut.text);

        int firstHalf = lunchOutTime - chckInTime;
        int secondHalf = checkOutTime - lunchInTime;

        int totalActTime = firstHalf + secondHalf;

        setState(() {
          actTime.text = totalActTime.toString();
        });
      }
    } else {
      if (chackIn.text.isNotEmpty &&
          lunchOut.text.isNotEmpty &&
          lunchIn.text.isNotEmpty &&
          checkOut.text.isNotEmpty) {
        int chckInTime = convertToMinutes(chackIn.text);
        int lunchOutTime = convertToMinutes(lunchOut.text);
        int lunchInTime = convertToMinutes(lunchIn.text);
        int checkOutTime = convertToMinutes(checkOut.text);

        int firstHalf = lunchOutTime - chckInTime;
        int secondHalf = checkOutTime - lunchInTime;

        int totalActTime = firstHalf + secondHalf;

        setState(() {
          actTime.text = totalActTime.toString();
        });
      }
    }
    actTime.selection = savedSelection;
  }



  int convertToMinutes(String time) {
    List<String> parts = time.split(':');
    int hours = int.parse(parts[0]);
    int minutes = int.parse(parts[1]);
    int seconds = int.parse(parts[2]);
    return hours * 60 + minutes + seconds ~/ 60;
  }

  void updateAttendance(String empCode, String inDate) async {

    Map<String, dynamic> requestData = {
      'emp_code': empCode,
      'inDate': inDate,
      'first_name': firstName.text,
      'shiftType': shiftType.text,
      'check_in': chackIn.text,
      'lunch_out': lunchOut.text,
      'lunch_in': lunchIn.text,
      'check_out': checkOut.text,
      'late_lunch': lunchLate.text,
      'latecheck_in': late.text,
      'earlycheck_out': earlyCheckOut.text,
      'req_time': reqTime.text,
      'act_time': actTime.text,
      'remark': remark.text,

    };

    var response = await http.post(Uri.parse('http://localhost:3309/updateAttendance'),
        body: jsonEncode(requestData),
        headers: {'Content-Type': 'application/json'});

    if (response.statusCode == 200) {
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Update Attendance"),
            content: const Text(
                "Update Successfully"),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.push(context,
                      MaterialPageRoute(
                          builder: (context) =>
                              AttendanceAlter()));
                },
                child: Text("OK"),
              ),
            ],
          );
        },
      );
    } else {
      print('Failed to update attendance. Status code: ${response.statusCode}');
    }
  }

  Future<void> fetchData() async {
    try {
      final url = Uri.parse('http://localhost:3309/get_attendance_alter/');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final List<dynamic> itemGroups = responseData;

        setState(() {
          data = itemGroups.cast<Map<String, dynamic>>();
        });

        print('Data: $data');
      } else {
        print('Error: ${response.statusCode}');
      }
    } catch (error) {
      print('Error: $error');
    }
  }
  List<Map<String, dynamic>> filteredData = [];
  List<Map<String, dynamic>> data = [];
  void filterData(String searchText, String selectedDate) {
    setState(() {
      if (searchText.isEmpty) {
        filteredData = data;
        setState(() {
          Date.clear();
          firstName.clear();
          chackIn.clear();
          checkOut.clear();
          lunchIn.clear();
          lunchOut.clear();
          actTime.clear();
          reqTime.clear();
          shiftType.clear();
          remark.clear();
          late.clear();
          lunchLate.clear();
          earlyCheckOut.clear();
        });
      } else {
        List<Map<String, dynamic>> filteredRows = data.where((item) {
          String id = item['emp_code']?.toString() ?? '';
          String date = item['inDate']?.toString() ?? '';
          return id.contains(searchText) && date == selectedDate;
        }).toList();

        filteredData = data.where((item) {
          String id = item['emp_code']?.toString() ?? '';
          String date = item['inDate']?.toString() ?? '';
          return id.contains(searchText) && date == selectedDate;
        }).toList();
        filteredData = filteredRows;
        if (filteredData.isNotEmpty) {
          Map<String, dynamic> order = filteredData.first;
          firstName.text = order['first_name']?.toString() ?? '';
          chackIn.text = order['check_in']?.toString() ?? '';
          lunchOut.text = order['lunch_out']?.toString() ?? '';
          lunchIn.text = order['lunch_in']?.toString() ?? '';
          checkOut.text = order['check_out']?.toString() ?? '';
          shiftType.text = order['shiftType']?.toString() ?? '';
          reqTime.text = order['req_time']?.toString() ?? '';
          remark.text = order['remark']?.toString() ?? '';
          actTime.text = order['act_time']?.toString() ?? '';
          late.text = order['latecheck_in']?.toString() ?? '';
          lunchLate.text = order['late_lunch']?.toString() ?? '';
          earlyCheckOut.text = order['earlycheck_out']?.toString() ?? '';
        } else {
          setState(() {
          });
        }
      }
    });
  }


  @override
  void initState() {
    super.initState();
    //_showPasswordDialog();//add Row
    fetchData();
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }
  @override
  Widget build(BuildContext context) {
    empCode.addListener(() {
      filterData(empCode.text, Date.text);
    });

    return MyScaffold(
      route: "",
      body: Form(
        key: GlobalKey<FormState>(),
        child: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      border: Border.all(color: Colors.grey), // Add a border for the box
                      borderRadius: BorderRadius.circular(10.0), // Add border radius for rounded corners
                    ),
                    child:Wrap(
                        children: [
                          Row(
                            children: [
                              Row(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Icon(Icons.edit_attributes),
                                  ),
                                  Text("Attendance Edit", style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18
                                  ),),

                                ],
                              ),
                              const SizedBox(width: 710,),
                              Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: SizedBox(
                                      width: 200,height: 50,
                                      child: TypeAheadFormField<String>(
                                        textFieldConfiguration: TextFieldConfiguration(
                                          controller: empCode,
                                          style: const TextStyle(fontSize: 13),
                                          onChanged: (value) {
                                            setState(() {
                                              errorMessage = null; // Reset error message when the user types
                                            });
                                          },
                                          decoration: InputDecoration(
                                            fillColor: Colors.white,
                                            filled: true,
                                            labelText: "Employee code",
                                            labelStyle: TextStyle(fontSize: 13),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                        suggestionsCallback: (pattern) async {
                                          List<String> suggestions;
                                          if (pattern.isNotEmpty) {
                                            suggestions = data
                                                .where((item) =>
                                                (item['emp_code']?.toString()?.toLowerCase() ?? '')
                                                    .startsWith(pattern.toLowerCase()))
                                                .map((item) => item['emp_code'].toString())
                                                .toSet() // Remove duplicates using a Set
                                                .toList();
                                          } else {
                                            suggestions = [];
                                          }
                                          return suggestions;
                                        },
                                        itemBuilder: (context, suggestion) {
                                          return ListTile(
                                            title: Text(suggestion),
                                          );
                                        },
                                        onSuggestionSelected: (suggestion) {
                                          setState(() {
                                            selectedInvoiceNo = suggestion;
                                            empCode.text = suggestion;
                                          });
                                          print('Selected Invoice Number: $selectedInvoiceNo');
                                        },
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 20),                                 child: SizedBox(
                                    width: 190,
                                    height: 70,
                                    child: TextFormField(
                                      style: const TextStyle(fontSize: 13),
                                      readOnly: true, // Set the field as read-only
                                      onTap: () async {
                                        calculateActTime();
                                        DateTime? pickDate = await showDatePicker(
                                          context: context,
                                          initialDate: DateTime.now(),
                                          firstDate: DateTime(
                                              1900),
                                          lastDate: DateTime.now(),
                                        );
                                        if (pickDate == null) {
                                          return;
                                        }
                                        {
                                          setState(() {
                                            Date.text =
                                                DateFormat(
                                                    'yyyy-MM-dd')
                                                    .format(
                                                    pickDate);
                                            errorMessage=null;

                                          });
                                          filterData(empCode.text, Date.text);
                                        }
                                      },
                                      controller: Date, // Set the initial value of the field to the selected date
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: Colors.white,
                                        labelText: "Date",
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ),
                                  ),
                                ],
                              ),


                            ],
                          ),
                        ]
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    height: 200,
                    width: double.infinity, // Set the width to full page width
                    padding:const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      border: Border.all(color: Colors.grey), // Add a border for the box
                      borderRadius: BorderRadius.circular(10.0), // Add border radius for rounded corners
                    ),
                    child:Wrap(
                        children: [
                          Text(
                            errorMessage ?? '',
                            style: TextStyle(color: Colors.red),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 150),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 200,height: 70,
                                  child: TextFormField(
                                    controller: firstName,
                                    style: TextStyle(fontSize: 13),
                                    onChanged: (value){
                                      setState(() {
                                        errorMessage=null;
                                      });
                                    },
                                    decoration: InputDecoration(
                                      fillColor: Colors.white,
                                      filled: true,

                                      labelText: "Employee Name",

                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),const SizedBox(width: 80,),
                                SizedBox(
                                  width: 200,height: 70,
                                  child: TextFormField(
                                    controller: shiftType,
                                    style: TextStyle(fontSize: 13),
                                    onChanged: (value){
                                      setState(() {
                                        errorMessage=null;
                                      });
                                    },
                                    decoration: InputDecoration(
                                      fillColor: Colors.white,
                                      filled: true,

                                      labelText: "Shift Type",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),const SizedBox(width: 80,),
                                SizedBox(
                                  width: 200,height: 70,
                                  child: TextFormField(
                                    controller: chackIn,
                                    onChanged: (value) {
                                      calculateActTime();
                                      calculateLateTime();
                                      setState(() {
                                        errorMessage=null;
                                      });
                                    },
                                    style: const TextStyle(fontSize: 13),

                                    decoration: InputDecoration(
                                      fillColor: Colors.white,
                                      filled: true,

                                      labelText: "Check In",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),const SizedBox(width: 80,),
                                SizedBox(
                                  width: 200,height: 70,
                                  child: TextFormField(
                                    controller: lunchOut,
                                    onChanged: (value) {
                                      calculateActTime();
                                      calculateLateTime();
                                    },
                                    style: TextStyle(fontSize: 13),

                                    decoration: InputDecoration(
                                      fillColor: Colors.white,
                                      filled: true,

                                      labelText: "Lunch Out",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),

                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 150),
                            child: Row(
                              children: [

                                SizedBox(
                                  width: 200,height: 70,
                                  child: TextFormField(
                                    controller: lunchIn,
                                    style: TextStyle(fontSize: 13),
                                    onChanged: (value) {
                                      calculateActTime();
                                      calculateLateTime();
                                    },
                                    decoration: InputDecoration(
                                      fillColor: Colors.white,
                                      filled: true,

                                      labelText: "Lunch In",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),const SizedBox(width: 80,),
                                SizedBox(
                                  width: 200,height: 70,
                                  child: TextFormField(
                                    controller: checkOut,
                                    style: TextStyle(fontSize: 13),
                                    onChanged: (value) {
                                      calculateActTime();
                                      calculateLateTime();
                                    },
                                    decoration: InputDecoration(
                                      fillColor: Colors.white,
                                      filled: true,

                                      labelText: "Check Out",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),const SizedBox(width: 80,),
                                SizedBox(
                                  width: 200,height: 70,
                                  child: TextFormField(
                                    controller: late,
                                    style: TextStyle(fontSize: 13),
                                    onChanged: (value) {
                                      calculateActTime();
                                    },
                                    decoration: InputDecoration(
                                      fillColor: Colors.white,
                                      filled: true,

                                      labelText: "Late Checkin",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),const SizedBox(width: 80,),
                                SizedBox(
                                  width: 200,height: 70,
                                  child: TextFormField(
                                    controller: lunchLate,
                                    style: TextStyle(fontSize: 13),
                                    onChanged: (value) {
                                      calculateActTime();
                                    },
                                    decoration: InputDecoration(
                                      fillColor: Colors.white,
                                      filled: true,

                                      labelText: "Lunch Late",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 150),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 200,height: 70,
                                  child: TextFormField(
                                    controller: earlyCheckOut,
                                    style:const TextStyle(fontSize: 13),
                                    inputFormatters: [
                                      UpperCaseTextFormatter(),
                                    ],
                                    decoration: InputDecoration(

                                      fillColor: Colors.white,
                                      filled: true,
                                      labelText: "Early CheckOut",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),const SizedBox(width: 80,),
                                SizedBox(
                                  width: 200,height: 70,
                                  child: TextFormField(
                                    controller: reqTime,
                                    style: TextStyle(fontSize: 13),
                                    decoration: InputDecoration(
                                      fillColor: Colors.white,
                                      filled: true,

                                      labelText: "Req Time",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),const SizedBox(width: 80,),
                                SizedBox(
                                  width: 200,height: 70,
                                  child: TextFormField(
                                    controller: actTime,
                                    style: TextStyle(fontSize: 13),
                                    decoration: InputDecoration(
                                      fillColor: Colors.white,
                                      filled: true,
                                      labelText: "Actual Time",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),const SizedBox(width: 80,),
                                SizedBox(
                                  width: 200,height: 70,
                                  child: TextFormField(
                                    controller: remark,
                                    style:const TextStyle(fontSize: 13),
                                    inputFormatters: [
                                      UpperCaseTextFormatter(),
                                    ],
                                    decoration: InputDecoration(

                                      fillColor: Colors.white,
                                      filled: true,
                                      labelText: "Remark",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        ]),

                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: MaterialButton(
                        color: Colors.green.shade600,
                        onPressed: (){
                          if (empCode.text.isEmpty) {
                            setState(() {
                              errorMessage = '* Enter a employee code';
                            });
                          }
                          else if (firstName.text.isEmpty) {
                            setState(() {
                              errorMessage = '* Enter a employee Name';
                            });

                          }
                          else if (shiftType.text.isEmpty) {
                            setState(() {
                              errorMessage = '* select a shift type';
                            });

                          }
                          else {
                            updateAttendance(empCode.text, Date.text);
                          }
                        },
                        child: const Text("SAVE",style: TextStyle(color: Colors.white),),),

                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: MaterialButton(
                        color: Colors.green.shade600,
                        onPressed: (){
                          // Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (context)=> const Home()));

                        },
                        child: const Text("BACK",style: TextStyle(color: Colors.white),),),

                    ),

                  ],
                ),
              ],
            )


        ),
      ),
    );
  }
}
class MyScaffold extends StatelessWidget {
  final String route;
  final Widget body;

  MyScaffold({required this.route, required this.body});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //  // title: Text(route),
      // ),
      body: body,
    );
  }
}
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}