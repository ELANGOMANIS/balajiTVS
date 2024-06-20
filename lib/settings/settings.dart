
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:intl/intl.dart';
import 'package:vinayaga_project/main.dart';
import 'package:http/http.dart' as http;
import '../../home.dart';


class Settings extends StatefulWidget {
  const Settings({Key? key}) : super(key: key);
  @override
  State<Settings> createState() => _SettingsState();

}
class _SettingsState extends State<Settings> {
  List shifts = [];
  List time2 = [];
  bool isLoading = true;
  bool showLunchOutRows = false; // Initially hide the Lunch Out rows
  bool isAddingShift = false; // Control the visibility of the add shift form
  int? selectedRowIndex;

  String? selectedShiftType ;
  String newShiftType = '';
  String newStartTime = '';
  String newEndTime = '';


  final _formKey = GlobalKey<FormState>();
  final TextEditingController _shiftTypeController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchShifts();
    selectedShiftType = 'shift1'; // Initially select 'shift1'
    timeFetch(selectedShiftType!);
  }
  Future<void> _selectTime(BuildContext context, TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        final localizations = MaterialLocalizations.of(context);
        controller.text = localizations.formatTimeOfDay(picked, alwaysUse24HourFormat: true) + ':00';
      });
    }
  }

  void _showAddShiftDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Shift Details', style: TextStyle(fontSize: 12)),
          contentPadding: EdgeInsets.all(8.0),
          content: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 200,
                    child: TextFormField(
                      style: TextStyle(fontSize: 12),
                      decoration: InputDecoration(labelText: 'Shift Type', labelStyle: TextStyle(fontSize: 12)),
                      controller: _shiftTypeController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter shift type';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(height: 10),
                  SizedBox(
                    width: 200,
                    child: TextFormField(
                      style: TextStyle(fontSize: 12),
                      decoration: InputDecoration(labelText: 'Start Time (HH:MM:SS)', labelStyle: TextStyle(fontSize: 12)),
                      controller: _startTimeController,
                      readOnly: true,
                      onTap: () => _selectTime(context, _startTimeController),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select start time';
                        }
                        // Validate time format
                        if (!RegExp(r'^\d{2}:\d{2}:\d{2}$').hasMatch(value)) {
                          return 'Please enter time in HH:MM:SS format';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(height: 10),
                  SizedBox(
                    width: 200,
                    child: TextFormField(
                      style: TextStyle(fontSize: 12),
                      decoration: InputDecoration(labelText: 'End Time (HH:MM:SS)', labelStyle: TextStyle(fontSize: 12)),
                      controller: _endTimeController,
                      readOnly: true,
                      onTap: () => _selectTime(context, _endTimeController),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select end time';
                        }
                        // Validate time format
                        if (!RegExp(r'^\d{2}:\d{2}:\d{2}$').hasMatch(value)) {
                          return 'Please enter time in HH:MM:SS format';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            isAddingShift = false;
                          });
                          Navigator.of(context).pop();
                        },
                        icon: Icon(Icons.close_outlined, color: Colors.red),
                      ),
                      SizedBox(width: 5),
                      IconButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            addShift();
                            fetchShifts();
                            timeFetch(selectedShiftType!);
                            Navigator.of(context).pop();
                          }
                        },
                        icon: Icon(Icons.check_circle_outline, color: Colors.green),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
// Function to add a new shift
  Future<void> addShift() async {
    final newShift = {
      'shiftType': _shiftTypeController.text,
      'startTime': _startTimeController.text,
      'endTime': _endTimeController.text,
      'checkin_start': '00:00:00',
      'checkin_end': '00:00:00',
      'checkout_start': '00:00:00',
      'checkout_end': '00:00:00',
    };

    final response = await http.post(
      Uri.parse('http://localhost:3309/shift_insert_tvs'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(newShift),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text(responseData['message']),
        ),
      );
      Navigator.push(context, MaterialPageRoute(builder: (context) => const Settings()));
      // Clear text fields after successful addition
      _shiftTypeController.clear();
      _startTimeController.clear();
      _endTimeController.clear();
    } else {
      throw Exception('Failed to add shift');
    }
  }


  fetchShifts() async {
    final response = await http.get(Uri.parse('http://localhost:3309/shift_tvs'));
    if (response.statusCode == 200) {
      setState(() {
        shifts = json.decode(response.body);
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }
  Future<void> deleteShift(int id) async {
    final response = await http.delete(
      Uri.parse('http://localhost:3309/shift_tvs_delete/$id'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        shifts.removeWhere((shift) => shift['id'] == id);
      });
    } else if (response.statusCode == 404) {
      throw Exception('Shift not found');
    } else {
      throw Exception('Failed to delete shift');
    }
  }

  Future<void> timeFetch(String shiftType) async {
    setState(() {
      isLoading = true;
    });

    final response = await http.get(Uri.parse('http://localhost:3309/timing?shiftType=$shiftType'));

    if (response.statusCode == 200) {
      setState(() {
        time2 = json.decode(response.body);
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }
  int? editingIndex;

  Future<void> updateShift(int id, Map<String, String> shift) async {
    final response = await http.put(
      Uri.parse('http://localhost:3309/shift_update_tvs$id'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(shift),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Shift updated'),
        ),
      );
    } else {
      throw Exception('Failed to update shift');
    }
  }

  // void timeFetch(String shiftType) async {
  //   // Assuming this function fetches the time data from the server
  //   // And sets it in the time2 variable
  //   // After fetching, store the initial values
  //   setState(() {
  //     // Replace with the actual fetched data
  //     initialTimeData = {
  //       'shiftType': selectedShiftType,
  //       'checkin_start': time2.isNotEmpty ? time2[0]['checkin_start'] : '',
  //       'checkin_end': time2.isNotEmpty ? time2[0]['checkin_end'] : '',
  //       'checkout_start': time2.isNotEmpty ? time2[0]['checkout_start'] : '',
  //       'checkout_end': time2.isNotEmpty ? time2[0]['checkout_end'] : '',
  //       'lunchout_start': time2.isNotEmpty ? time2[0]['lunchout_start'] : '',
  //       'lunchout_end': time2.isNotEmpty ? time2[0]['lunchout_end'] : '',
  //       'lunchin_start': time2.isNotEmpty ? time2[0]['lunchin_start'] : '',
  //       'lunchin_end': time2.isNotEmpty ? time2[0]['lunchin_end'] : '',
  //     };
  //   });
  // }
  Map<String, dynamic> initialTimeData = {};

  Future<void> updateTime(int id, Map<String, dynamic> updatedData) async {
    final url = Uri.parse('http://localhost:3309/time_update_tvs/$id');
    final response = await http.put(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(updatedData),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Time updated'),
        ),
      );
    } else {
      throw Exception('Failed to update shift');
    }
  }
  void incrementTime(Map<String, dynamic> shift, String field) {
    final time = TimeOfDay(
      hour: int.parse(shift[field]!.split(':')[0]),
      minute: int.parse(shift[field]!.split(':')[1]),
    );
    final newTime = time.replacing(
        minute: (time.minute + 1) % 60,
        hour: (time.minute == 59 ? (time.hour + 1) % 24 : time.hour));
    shift[field] = '${newTime.hour.toString().padLeft(2, '0')}:${newTime.minute.toString().padLeft(2, '0')}:00';
    setState(() {});
  }

  void incrementTime2(Map<String, dynamic> time2, String field) {
    final time = TimeOfDay(
      hour: int.parse(time2[field]!.split(':')[0]),
      minute: int.parse(time2[field]!.split(':')[1]),
    );
    final newTime = time.replacing(
        minute: (time.minute + 1) % 60,
        hour: (time.minute == 59 ? (time.hour + 1) % 24 : time.hour));
    time2[field] = '${newTime.hour.toString().padLeft(2, '0')}:${newTime.minute.toString().padLeft(2, '0')}:00';
    setState(() {});
  }

  void decrementTime(Map<String, dynamic> shift, String field) {
    final time = TimeOfDay(
      hour: int.parse(shift[field]!.split(':')[0]),
      minute: int.parse(shift[field]!.split(':')[1]),
    );
    final newTime = time.replacing(
        minute: (time.minute - 1 + 60) % 60,
        hour: (time.minute == 0 ? (time.hour - 1 + 24) % 24 : time.hour));
    shift[field] = '${newTime.hour.toString().padLeft(2, '0')}:${newTime.minute.toString().padLeft(2, '0')}:00';
    setState(() {});
  }
  void decrementTime2(Map<String, dynamic> time2, String field) {
    final time = TimeOfDay(
      hour: int.parse(time2[field]!.split(':')[0]),
      minute: int.parse(time2[field]!.split(':')[1]),
    );
    final newTime = time.replacing(
        minute: (time.minute - 1 + 60) % 60,
        hour: (time.minute == 0 ? (time.hour - 1 + 24) % 24 : time.hour));
    time2[field] = '${newTime.hour.toString().padLeft(2, '0')}:${newTime.minute.toString().padLeft(2, '0')}:00';
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MyScaffold(
      route: 'settings',
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
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
                  Navigator.push(context, MaterialPageRoute(builder: (context)=>Settings()));
                },
              ),

              SizedBox(width: 20,),
              Text("Settings", style: TextStyle(fontSize: 18)),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(3.0),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                      ),
                      child: const Column(
                        children: [
                          Text(
                            "Shift Management",
                            style: TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: MaterialButton(
                          color: Colors.blue.shade900,
                          onPressed: () {
                            setState(() {
                              _showAddShiftDialog(context);
                            });
                          },
                          child: Text("Add Shift +", style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ),

                    isLoading
                        ? Center(child: CircularProgressIndicator())
                        : Align(
                      alignment: Alignment.topLeft,
                      child: Card(

                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: [
                              DataColumn(label: Text('S.No')),
                              DataColumn(label: Text('Shift Type')),
                              DataColumn(label: Text('Start Time')),
                              DataColumn(label: Text('End Time')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: List.generate(shifts.length, (index) {
                              var shift = shifts[index];
                              var time = time2.isNotEmpty && index < time2.length ? time2[index] : null;
                              bool isEditing = editingIndex == index;
                              bool isSelected = selectedRowIndex == index;
                              return DataRow(
                                selected: isSelected,
                                color: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
                                  if (states.contains(MaterialState.selected)) {
                                    return Colors.grey.withOpacity(0.5);
                                  }
                                  return null; // Use default value.
                                }),
                                onSelectChanged: (selected) {
                                  setState(() {
                                    selectedRowIndex = selected! ? index : null;
                                  });
                                },
                                cells: [
                                  DataCell(Text((index + 1).toString())),
                                  DataCell(Text(shift['shiftType'])),
                                  DataCell(
                                    isEditing
                                        ? Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.arrow_drop_up),
                                          onPressed: () => incrementTime(shift, 'startTime'),
                                        ),
                                        Expanded(
                                          child: TextField(
                                            controller: TextEditingController(text: shift['startTime']),
                                            onChanged: (value) {
                                              shift['startTime'] = value;
                                            },
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.arrow_drop_down),
                                          onPressed: () => decrementTime(shift, 'startTime'),
                                        ),
                                      ],
                                    )
                                        : Text(shift['startTime']),
                                  ),
                                  DataCell(
                                    isEditing
                                        ? Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.arrow_drop_up),
                                          onPressed: () => incrementTime(shift, 'endTime'),
                                        ),
                                        Expanded(
                                          child: TextField(
                                            controller: TextEditingController(text: shift['endTime']),
                                            onChanged: (value) {
                                              shift['endTime'] = value;
                                            },
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.arrow_drop_down),
                                          onPressed: () => decrementTime(shift, 'endTime'),
                                        ),
                                      ],
                                    )
                                        : Text(shift['endTime']),
                                  ),
                                  DataCell(
                                    isSelected
                                        ? Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(isEditing ? Icons.check : Icons.edit),
                                          onPressed: () {
                                            setState(() {
                                              if (isEditing) {
                          // Save changes
                                                updateShift(shift['id'], {
                                                  'shiftType': shift['shiftType'],
                                                  'startTime': shift['startTime'],
                                                  'endTime': shift['endTime'],
                                                });
                                                editingIndex = null;
                                              } else {
                                                editingIndex = index;
                                              }
                                            });
                                          },
                                        ),

                                        IconButton(
                                          icon: Icon(Icons.delete),
                                          onPressed: () {
                                            deleteShift(shift['id']);
                                          },
                                        ),
                                      ],
                                    )
                                        : Container(),
                                  ),
                                ],
                              );
                            }),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(3.0),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                      ),
                      child: const Column(
                        children: [
                          Text(
                            "Time Management",
                            style: TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 10),
                    isLoading
                        ? Center(child: CircularProgressIndicator())
                        : Align(
                      alignment: Alignment.topLeft,
                  child: Card(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                DropdownButton<String>(
                                  hint: const Text("Shift Type"),
                                  value: selectedShiftType,
                                  items: shifts.map<DropdownMenuItem<String>>((shift) {
                                    return DropdownMenuItem<String>(
                                      value: shift['shiftType'],
                                      child: Text(shift['shiftType']),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        selectedShiftType = value;
                                      });
                                      timeFetch(value);
                                    }
                                  },
                                ),
                                SizedBox(width: 10),
                                MaterialButton(
                                  color: Colors.blue.shade900,
                                  onPressed: () {
                                    // Prepare updated data
                                    final updatedData = {
                                      'shiftType': selectedShiftType,
                                      'checkin_start': time2.isNotEmpty ? time2[0]['checkin_start'] : '',
                                      'checkin_end': time2.isNotEmpty ? time2[0]['checkin_end'] : '',
                                      'checkout_start': time2.isNotEmpty ? time2[0]['checkout_start'] : '',
                                      'checkout_end': time2.isNotEmpty ? time2[0]['checkout_end'] : '',
                                      'lunchout_start': time2.isNotEmpty ? time2[0]['lunchout_start'] : '',
                                      'lunchout_end': time2.isNotEmpty ? time2[0]['lunchout_end'] : '',
                                      'lunchin_start': time2.isNotEmpty ? time2[0]['lunchin_start'] : '',
                                      'lunchin_end': time2.isNotEmpty ? time2[0]['lunchin_end'] : '',
                                    };

                                    // Check if updated data is different from initial data
                                    if (mapEquals(updatedData, initialTimeData)) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          backgroundColor: Colors.blue,
                                          content: Text('Already updated'),
                                        ),
                                      );
                                    } else {
                                      // Update time data
                                      updateTime(time2.isNotEmpty ? time2[0]['id'] : 0, updatedData);

                                      // Update initialTimeData with new values
                                      initialTimeData = Map.from(updatedData);
                                    }
                                  },
                                  child: Text("Save", style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                            Row(
                              children: [
                                Text("Check In", style: TextStyle(fontSize: 14)),
                                SizedBox(width: 10),
                                Text("Start:    ", style: TextStyle(fontSize: 14)),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.arrow_drop_up),
                                      onPressed: () => incrementTime2(time2[0], 'checkin_start'),
                                    ),
                                    SizedBox(
                                      width: 80,
                                      child: time2.isNotEmpty
                                          ? TextField(
                                        style: TextStyle(fontSize: 12),
                                        controller: TextEditingController(text: time2[0]['checkin_start']),
                                        onChanged: (value) {
                                          time2[0]['checkin_start'] = value;
                                        },
                                      )
                                          : SizedBox.shrink(),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.arrow_drop_down),
                                      onPressed: () => decrementTime2(time2[0], 'checkin_start'),
                                    ),
                                  ],
                                ),
                                Text("End", style: TextStyle(fontSize: 14)),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.arrow_drop_up),
                                      onPressed: () => incrementTime2(time2[0], 'checkin_end'),
                                    ),
                                    SizedBox(
                                      width: 80,
                                      child: time2.isNotEmpty
                                          ? TextField(
                                        style: TextStyle(fontSize: 12),
                                        controller: TextEditingController(text: time2[0]['checkin_end']),
                                        onChanged: (value) {
                                          time2[0]['checkin_end'] = value;
                                        },
                                      )
                                          : SizedBox.shrink(),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.arrow_drop_down),
                                      onPressed: () => incrementTime2(time2[0], 'checkin_end'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                            Row(
                              children: [
                                Text("Check Out", style: TextStyle(fontSize: 14)),
                                SizedBox(width: 10),
                                Text("Start: ", style: TextStyle(fontSize: 14)),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.arrow_drop_up),
                                      onPressed: () => incrementTime2(time2[0], 'checkout_start'),
                                    ),
                                    SizedBox(
                                      width: 80,
                                      child: time2.isNotEmpty
                                          ? TextField(
                                        style: TextStyle(fontSize: 12),
                                        controller: TextEditingController(text: time2[0]['checkout_start']),
                                        onChanged: (value) {
                                          time2[0]['checkout_start'] = value;
                                        },
                                      )
                                          : SizedBox.shrink(),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.arrow_drop_down),
                                      onPressed: () => incrementTime2(time2[0], 'checkout_start'),
                                    ),
                                  ],
                                ),
                                Text("End", style: TextStyle(fontSize: 14)),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.arrow_drop_up),
                                      onPressed: () => incrementTime2(time2[0], 'checkout_end'),
                                    ),
                                    SizedBox(
                                      width: 80,
                                      child: time2.isNotEmpty
                                          ? TextField(
                                        style: TextStyle(fontSize: 12),
                                        controller: TextEditingController(text: time2[0]['checkout_end']),
                                        onChanged: (value) {
                                          time2[0]['checkout_end'] = value;
                                        },
                                      )
                                          : SizedBox.shrink(),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.arrow_drop_down),
                                      onPressed: () => incrementTime2(time2[0], 'checkout_end'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                            if (showLunchOutRows)
                              Column(
                                children: [
                                  Row(
                                    children: [
                                      Text("Lunch Out", style: TextStyle(fontSize: 14)),
                                      SizedBox(width: 10),
                                      Text("Start:  ", style: TextStyle(fontSize: 14)),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: Icon(Icons.arrow_drop_up),
                                            onPressed: () => incrementTime2(time2[0], 'lunchout_start'),
                                          ),
                                          SizedBox(
                                            width: 80,
                                            child: time2.isNotEmpty
                                                ? TextField(
                                              style: TextStyle(fontSize: 12),
                                              controller: TextEditingController(text: time2[0]['lunchout_start']),
                                              onChanged: (value) {
                                                time2[0]['lunchout_start'] = value;
                                              },
                                            )
                                                : SizedBox.shrink(),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.arrow_drop_down),
                                            onPressed: () => incrementTime2(time2[0], 'lunchout_start'),
                                          ),
                                        ],
                                      ),
                                      Text("End", style: TextStyle(fontSize: 14)),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: Icon(Icons.arrow_drop_up),
                                            onPressed: () => incrementTime2(time2[0], 'lunchout_end'),
                                          ),
                                          SizedBox(
                                            width: 80,
                                            child: time2.isNotEmpty
                                                ?
                                            TextField(
                                              style: TextStyle(fontSize: 12),
                                              controller: TextEditingController(text: time2[0]['lunchout_end']),
                                              onChanged: (value) {
                                                time2[0]['lunchout_end'] = value;
                                              },
                                            )
                                                : SizedBox.shrink(),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.arrow_drop_down),
                                            onPressed: () => incrementTime2(time2[0], 'lunchout_end'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 20),
                                  Row(
                                    children: [
                                      Text("Lunch In", style: TextStyle(fontSize: 14)),
                                      SizedBox(width: 10),
                                      Text("Start:     ", style: TextStyle(fontSize: 14)),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: Icon(Icons.arrow_drop_up),
                                            onPressed: () => incrementTime2(time2[0], 'lunchin_start'),
                                          ),
                                          SizedBox(
                                            width: 80,
                                            child: time2.isNotEmpty
                                                ? TextField(
                                              style: TextStyle(fontSize: 12),
                                              controller: TextEditingController(text: time2[0]['lunchin_start']),
                                              onChanged: (value) {
                                                time2[0]['lunchin_start'] = value;
                                              },
                                            )
                                                : SizedBox.shrink(),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.arrow_drop_down),
                                            onPressed: () => incrementTime2(time2[0], 'lunchin_start'),
                                          ),
                                        ],
                                      ),
                                      Text("End", style: TextStyle(fontSize: 14)),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: Icon(Icons.arrow_drop_up),
                                            onPressed: () => incrementTime2(time2[0], 'lunchin_end'),
                                          ),
                                          SizedBox(
                                            width: 80,
                                            child: time2.isNotEmpty
                                                ? TextField(
                                              style: TextStyle(fontSize: 12),
                                              controller: TextEditingController(text: time2[0]['lunchin_end']),
                                              onChanged: (value) {
                                                time2[0]['lunchin_end'] = value;
                                              },
                                            )
                                                : SizedBox.shrink(),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.arrow_drop_down),
                                            onPressed: () => incrementTime2(time2[0], 'lunchin_end'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            // Rest of your code for input fields and increment/decrement buttons
                            // ...
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
          )
        ],
      ),
    );
  }
}


