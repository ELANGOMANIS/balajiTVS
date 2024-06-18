
import 'dart:convert';
import 'package:flutter/cupertino.dart';
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

  String? selectedShiftType ;
  String newShiftType = '';
  String newStartTime = '';
  String newEndTime = '';
  @override
  void initState() {
    super.initState();
    fetchShifts();
    selectedShiftType = 'shift1'; // Initially select 'shift1'
    timeFetch(selectedShiftType!);
  }

  Future<void> addShift() async {
    final newShift = {
      'shiftType': newShiftType,
      'startTime': newStartTime,
      'endTime': newEndTime,
    };

    final response = await http.post(
      Uri.parse('http://localhost:3309/shift_insert_tvs'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(newShift),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Shift added'),
        ),
      );
      setState(() {
        shifts.add(json.decode(response.body));
        isAddingShift = false;
      });
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
  Future<void> updateTime(int id, Map<String, dynamic> updatedData) async {
    final url = Uri.parse('http://localhost:3309/time_update_tvs/$id');
    final response = await http.put(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(updatedData), // Use jsonEncode to convert the map to JSON string
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
          Text("Settings", style: TextStyle(fontSize: 18)),
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
                              isAddingShift = true;
                            });
                          },
                          child: Text("Add Shift +", style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ),
                    if (isAddingShift)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 200,

                              child: TextField(
                                style: TextStyle(fontSize: 12),

                                decoration: InputDecoration(labelText: 'Shift Type'),
                                onChanged: (value) {
                                  setState(() {
                                    newShiftType = value;
                                  });
                                },
                              ),
                            ),
                            SizedBox(height: 10),
                            SizedBox(
                              width: 200,
                              child: TextField(
                                style: TextStyle(fontSize: 12),

                                decoration: InputDecoration(labelText: 'Start Time (HH:MM:SS)'),
                                onChanged: (value) {
                                  setState(() {
                                    newStartTime = value;
                                  });
                                },
                              ),
                            ),
                            SizedBox(height: 10),
                            SizedBox(
                              width: 200,

                              child: TextField(
                                style: TextStyle(fontSize: 12),
                                decoration: InputDecoration(labelText: 'End Time (HH:MM:SS)',),
                                onChanged: (value) {
                                  setState(() {
                                    newEndTime = value;
                                  });
                                },
                              ),
                            ),
                            SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                MaterialButton(
                                  color: Colors.green,
                                  onPressed: () {
                                    addShift();
                                  },
                                  child: Text('Save', style: TextStyle(color: Colors.white)),
                                ),
                                SizedBox(width: 10),
                                MaterialButton(
                                  color: Colors.red,
                                  onPressed: () {
                                    setState(() {
                                      isAddingShift = false;
                                    });
                                  },
                                  child: Text('Cancel', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),

                          ],
                        ),
                      ),
                    isLoading
                        ? Center(child: CircularProgressIndicator())
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            DataTable(
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
                                return DataRow(cells: [
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
                                  ),
                                ]);
                              }),
                            ),
                          ],
                                                  ),
                        ),
                    SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(3.0),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                      ),
                      child: Column(
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
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Column(
                          children: [
                            Align(
                              alignment: Alignment.topLeft,
                              child: DropdownButton<String>(
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
                            ),
                            /*Align(
                              alignment: Alignment.topLeft,
                              child: Row(
                                children: [
                                  Text("Lunch Time", style: TextStyle(fontSize: 14)),

                                  Switch(
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // Reduces tap target size
                                    activeColor: Colors.blue, // Color when switch is ON
                                    inactiveThumbColor: Colors.grey, // Color of the switch knob when OFF
                                    inactiveTrackColor: Colors.grey.withOpacity(0.5),
                                    value: showLunchOutRows,
                                    onChanged: (value) {
                                      setState(() {
                                        showLunchOutRows = value;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),*/
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

                            SizedBox(height: 20),
                            Align(
                              alignment: Alignment.topLeft,
                              child: MaterialButton(
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

                                  // Update time data
                                  updateTime(time2.isNotEmpty ? time2[0]['id'] : 0, updatedData); // Replace with actual ID
                                },
                                child: Text("Save", style: TextStyle(color: Colors.white)),
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
          )
        ],
      ),
    );
  }
}


