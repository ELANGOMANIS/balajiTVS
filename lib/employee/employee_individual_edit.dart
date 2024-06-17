// import 'dart:convert';
//
// import 'package:http/http.dart'as http;
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:image_picker/image_picker.dart';
// import '../../main.dart';
// import '../../purchase/purchase_order.dart';
//
// class EmployeeEdiT extends StatefulWidget {
//   String empID;
//   String empName;
//   String empMobile;
//   String deptName;
//   String salary;
//   String empAddress;
//   String shift;
//   String maritalStatus;
//   String dob;
//   String age;
//   String bloodgroup;
//   String gender;
//   // String fatherName;
//   // String fatherMobile;
//   // String spouseName;
//   // String spouseMobile;
//   String education;
//   String doj;
//   String empPhoto;
//   String end;
//   String empPosition;
//   String acNumber;
//   String acHoldername;
//   String bank;
//   String branch;
//   String pan;
//   String ifsc;
//   String aadhar;
//   EmployeeEdiT({Key? key,
//      required this.empPhoto,
//      required this.empID,
//      required this.empName,
//      required this.empMobile,
//      required this.deptName,
//      required this.salary,
//      required this.empAddress,
//      required this.shift,
//      required this.maritalStatus,
//      required this.dob,
//      required this.age,
//      required this.bloodgroup,
//      required this.gender,
//      // required this.fatherName,
//      // required this.fatherMobile,
//      // required this.spouseName,
//      // required this.spouseMobile,
//      required this.education,
//      required this.doj,
//      required this.end,
//      required this.empPosition,
//      required this.acNumber,
//      required this.acHoldername,
//      required this.bank,
//      required this.branch,
//      required this.pan,
//      required this.ifsc,
//      required this.aadhar,
//    }) : super(key: key);
//   @override
//   State<EmployeeEdiT> createState() => _EmployeeEdiTState();
// }
// class _EmployeeEdiTState extends State<EmployeeEdiT> {
//   String? maritalStatus;
//   String? sName;
//   String? fName;
//   bool dropdownValid6 = true;
//
//
//   final _formKey = GlobalKey<FormState>();
//   DateTime dOB = DateTime.now();
//   DateTime dOJ = DateTime.now();
//   DateTime eod = DateTime.now();
//   int agevalue = 0;
//   RegExp nameRegExp = RegExp(r'^[a-zA-Z\s]+$');
//
//
//   TextEditingController dateOfBirth = TextEditingController();
//   TextEditingController empID = TextEditingController();
//   TextEditingController empName = TextEditingController();
//   TextEditingController empAddress = TextEditingController();
//   TextEditingController empMobile = TextEditingController();
//   TextEditingController spouseMobile = TextEditingController();
//   TextEditingController fatherMobile = TextEditingController();
//   TextEditingController spouseName = TextEditingController();
//   TextEditingController fatherName = TextEditingController();
//   TextEditingController empPhoto = TextEditingController();
//   TextEditingController education = TextEditingController();
//   TextEditingController depName = TextEditingController();
//   TextEditingController empPosition = TextEditingController();
//   TextEditingController acHoldername = TextEditingController();
//   TextEditingController acNumber = TextEditingController();
//   TextEditingController ifsc = TextEditingController();
//   TextEditingController pan = TextEditingController();
//   TextEditingController bank = TextEditingController();
//   TextEditingController branch = TextEditingController();
//   TextEditingController age = TextEditingController();
//   TextEditingController aadhar = TextEditingController();
//   TextEditingController doj = TextEditingController();
//
//   String capitalizeFirstLetter(String text) {
//     if (text.isEmpty) return text;
//     return text.substring(0, 1).toUpperCase() + text.substring(1);
//   }
//   Future<void> insertData(Map<String, dynamic> dataToInsert) async {
//     final String apiUrl = 'http://localhost:3309/employee'; // Replace with your server details
//     try {
//       final response = await http.post(
//         Uri.parse(apiUrl),
//         headers: <String, String>{
//           'Content-Type': 'application/json; charset=UTF-8',
//         },
//         body: jsonEncode({'dataToInsert': dataToInsert}),
//       );
//       if (response.statusCode == 200) {
//         print('Data inserted successfully');
//       } else {
//         print('Failed to insert data');
//         throw Exception('Failed to insert data');
//       }
//     } catch (e) {
//       print('Error: $e');
//       throw Exception('Error: $e');
//     }
//   }
//   Map<String, dynamic> dataToInsert = {};
//
//   Future<void> updateEmployee(String empID, String empName, String empMobile, String empAddress) async {
//     final response = await http.put(
//       Uri.parse('http://localhost:3309/employee/$empID'),
//       headers: <String, String>{
//         'Content-Type': 'application/json; charset=UTF-8',
//       },
//       body: jsonEncode(<String, String>{
//         'empName': empName,
//         'empMobile': empMobile,
//         'empAddress': empAddress,
//       }),
//     );
//
//     if (response.statusCode == 200) {
//       print('Employee updated successfully');
//     } else {
//       throw Exception('Failed to update employee');
//     }
//   }
//   void initState() {
//     empID = TextEditingController(
//       text: widget.empID,
//     );
//     empName = TextEditingController(
//       text: widget.empName,
//     );
//     empMobile = TextEditingController(
//       text: widget.empMobile,
//     );
//     empAddress = TextEditingController(
//       text: widget.empAddress,
//     );
//     empPosition = TextEditingController(
//       text: widget.empPosition,
//     );
//     empPhoto = TextEditingController(
//       text: widget.empPhoto,
//     );
//     age = TextEditingController(
//       text: widget.age,
//     );
//     acHoldername = TextEditingController(
//       text: widget.acHoldername,
//     );
//     bank = TextEditingController(
//       text: widget.bank,
//     );
//     ifsc = TextEditingController(
//       text: widget.ifsc,
//     );
//     pan = TextEditingController(
//       text: widget.pan,
//     );
//     aadhar = TextEditingController(
//       text: widget.aadhar,
//     );
//     acNumber = TextEditingController(
//       text: widget.acNumber,
//     );
//     bank = TextEditingController(
//       text: widget.bank,
//     );
//     branch = TextEditingController(
//       text: widget.branch,
//     );
//     depName = TextEditingController(
//       text: widget.deptName,
//     );
//     education = TextEditingController(
//       text: widget.education,
//     );
//     age = TextEditingController(
//       text: widget.age,
//     );
//     gender = widget.gender;
//     bloodGroup = widget.bloodgroup;
//     shifttype = widget.shift;
//     salary = widget.salary;
//     maritalstatus = widget.maritalStatus;
//     empposition = widget.empPosition;
//     _imageUrl = widget.empPhoto;
//     // TODO: implement initState
//     super.initState();
//   }
//   String employeePosition = "";
//   bool gendererrormsg = true;
//   bool bloodGrouperrormsg = true;
//   bool salaryerrormsg = true;
//   bool maritalstatuserrormsg = true;
//   bool shifttypegrouperrormsg = true;
//   bool emppositionerrormsg = true;
//   String gender = "Gender";
//   String bloodGroup = "Blood Group";
//   String shifttype = "Shift Type";
//   String salary = "Salary Type";
//   String maritalstatus = "Marital Status";
//   String empposition = "Employee Position";
//
//
//
//   String? _imageUrl = '';
//
//   Future<void> _pickImage(ImageSource source) async {
//     final pickedFile = await ImagePicker().getImage(source: source);
//
//     if (pickedFile != null) {
//       setState(() {
//         _imageUrl = pickedFile.path;
//       });
//     }
//   }  @override
//   Widget build(BuildContext context) {
//     return MyScaffold(
//         route: "employee_edit",
//         body: Form(
//           key: _formKey,
//           child: SingleChildScrollView(
//             child: Center(
//               child: Column(
//                   children: [
//                     Padding(
//                       padding: const EdgeInsets.all(2.0),
//                       child: Container(
//                         width: double.infinity, // Set the width to full page width
//                         padding: EdgeInsets.all(8.0),
//                         decoration: BoxDecoration(
//                           color: Colors.grey.shade50,
//                           border: Border.all(color: Colors.grey), // Add a border for the box
//                           borderRadius: BorderRadius.circular(10.0), // Add border radius for rounded corners
//                         ),
//                         child: Padding(
//                           padding: const EdgeInsets.all(8.0),
//                           child: Row(
//                             children: [
//                               Row(
//                                 children: [
//                                   Icon(Icons.account_balance_sharp),SizedBox(width: 10,),
//                                   Text("Employee Edit",style: TextStyle(fontSize: 25,fontWeight: FontWeight.bold),),
//                                   Padding(
//                                     padding: const EdgeInsets.only(left:700.0),
//                                     child: Row(
//                                       mainAxisAlignment: MainAxisAlignment.end,
//                                       children: [
//                                         // SizedBox(
//                                         //   child: Align(
//                                         //       alignment: Alignment.topRight,
//                                         //       child:
//                                         //       Text(
//                                         //           DateFormat('dd-MM-yyyy').format(selectedDate),
//                                         //           style:TextStyle(fontWeight: FontWeight.bold))),
//                                         // ),
//                                       ],
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//                     SizedBox(height: 2,),
//                     Padding(
//                       padding: const EdgeInsets.all(2.0),
//                       child: Container(
//                           width: double.infinity, // Set the width to full page width
//                           padding: EdgeInsets.all(8.0),
//                           decoration: BoxDecoration(
//                             color: Colors.blue.shade50,
//                             border: Border.all(color: Colors.grey), // Add a border for the box
//                             borderRadius: BorderRadius.circular(10.0), // Add border radius for rounded corners
//                           ),
//                           child:Column(
//                             children: [
//                               Row(
//                                 mainAxisAlignment: MainAxisAlignment.start,
//                                 children: [
//                                   Text("Personal Details", style: TextStyle(
//                                     fontSize: 17,
//                                     fontWeight: FontWeight.bold,
//                                   ),),
//                                 ],
//                               ),
//                               // SizedBox(height: 10,),
//                               InkWell(
//                                 onTap: () {
//                                   showModalBottomSheet(context: context, builder: (ctx){
//                                     return Padding(
//                                       padding: const EdgeInsets.only(bottom: 20),
//                                       child: Column(
//                                         mainAxisSize: MainAxisSize.min,
//                                         children: [
//
//                                           ListTile(
//                                               leading: const Icon(Icons.storage),
//                                               title: const Text("From Gallery"),
//                                               onTap: () async {
//                                                 _pickImage(ImageSource.gallery);
//                                               })
//                                         ],
//                                       ),
//                                     );
//                                   });
//                                 },
//                                 child:  _imageUrl!.isNotEmpty
//                                     ? ClipOval(
//                                   child: Image.network(
//                                     _imageUrl!,
//                                     width: 100,
//                                     height: 100,
//                                     fit: BoxFit.cover,
//                                   ),
//                                 )
//                                     : CircleAvatar(
//                                   radius: 50,
//                                   backgroundImage: AssetImage("assets/employee.png"),
//                                   child: Icon(Icons.download, size: 15,color: Colors.brown,),
//                                 ),
//
//                               ),
//                               SizedBox(height: 30,),
//
//                               Wrap(
//                                   children: [
//                                     ///Employee ID
//                                     SizedBox(
//                                       width: 200, height: 70,
//                                       child: TextFormField(
//                                         readOnly: true,
//                                         controller: empID,
//                                         style: TextStyle(fontSize: 13),
//                                         validator: (value) {
//                                           if (value!.isEmpty) {
//                                             return '* Enter Employee ID';
//                                           }
//                                           return null;
//                                         },
//                                         inputFormatters: [
//                                           //UpperCaseTextFormatter(),
//                                         ],
//                                         decoration: InputDecoration(
//                                           labelText: "Employee ID",
//                                           filled: true,
//                                           fillColor: Colors.white,
//                                           border: OutlineInputBorder(
//                                             borderRadius: BorderRadius.circular(10),
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                     SizedBox(width: 85,),
//                                     ///Employee Name
//                                     SizedBox(
//                                       width: 200, height: 70,
//                                       child: TextFormField(
//                                         controller: empName,
//                                         onChanged: (value) {
//                                           empName.text = value;
//                                           String capitalizedValue = capitalizeFirstLetter(
//                                               value);
//                                           empName.value =
//                                               empName.value.copyWith(
//                                                 text: capitalizedValue,
//                                                 selection: TextSelection.collapsed(
//                                                     offset: capitalizedValue
//                                                         .length),
//                                               );
//                                         },
//                                         style: TextStyle(fontSize: 13),
//                                         validator: (value) {
//                                           if (value!.isEmpty) {
//                                             return '* Enter Employee Name';
//                                           }
//                                           return null;
//                                         },
//                                         decoration: InputDecoration(
//                                           labelText: "Employee Name",
//                                           filled: true,
//                                           fillColor: Colors.white,
//                                           border: OutlineInputBorder(
//                                             borderRadius: BorderRadius.circular(10),
//
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                     SizedBox(width: 85,),
//
//                                     ///Address
//                                     SizedBox(
//                                       width: 200, height: 70,
//                                       child: TextFormField(
//                                        controller: empAddress,
//                                         onChanged: (value) {
//                                           empAddress.text=value;
//                                           String capitalizedValue = capitalizeFirstLetter(value);
//                                           empAddress.value = empAddress.value.copyWith(
//                                             text: capitalizedValue,
//                                             selection: TextSelection.collapsed(
//                                                 offset: capitalizedValue.length),);
//                                         },
//                                         style: TextStyle(fontSize: 13),
//                                         decoration: InputDecoration(
//                                           filled: true,
//                                           fillColor: Colors.white,
//                                           labelText: "Address",
//                                           border: OutlineInputBorder(
//                                             borderRadius: BorderRadius.circular(10),
//
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                     SizedBox(width: 85,),
//
//
//                                     ///Mobile Number
//                                     SizedBox(
//                                       width: 200, height: 70,
//                                       child: TextFormField(
//                                         controller:empMobile,
//                                         style: TextStyle(fontSize: 13),
//                                         decoration: InputDecoration(
//                                           prefixText: "+91",
//                                           labelText: "Mobile Number",
//                                           filled:true,
//                                           fillColor: Colors.white,
//                                           border: OutlineInputBorder(
//                                             borderRadius: BorderRadius.circular(10),
//                                           ),
//                                         ),
//                                         keyboardType: TextInputType.number,
//                                         inputFormatters: <TextInputFormatter>[
//                                           FilteringTextInputFormatter.digitsOnly,
//                                           LengthLimitingTextInputFormatter(10)
//                                         ],
//                                       ),
//                                     ),
//
//
//                                   ]),
//
//                               Wrap(
//                                 children: [
//                                   SizedBox(
//                                     width: 200,
//                                     height: 70,
//                                     child: TextFormField(
//
//                                       style: TextStyle(fontSize: 13),
//                                       readOnly: true,
//                                       validator: (value) {
//                                         if (value!.isEmpty) {
//                                           return '* Enter Date Of Birth';
//                                         }
//                                         return null;
//                                       },
//                                       onTap: () {
//                                         showDatePicker(
//                                           context: context,
//                                           initialDate: dOB,
//                                           firstDate: DateTime(1900),
//                                           // Set the range of selectable dates
//                                           lastDate: DateTime(2100),
//                                         ).then((date) {
//                                           if (date != null) {
//                                             setState(() {
//                                               dOB = date;
//                                               calculateAge(); // Update the selected date
//                                             });
//                                           }
//                                         });
//                                       },
//                                       controller: TextEditingController(
//                                           text: dOB.toString().split(
//                                               ' ')[0]),
//                                       // Set the initial value of the field to the selected date
//                                       decoration: InputDecoration(
//                                         filled:true,
//                                         fillColor: Colors.white,
//                                         labelText: "DOB",
//                                         border: OutlineInputBorder(
//                                           borderRadius: BorderRadius.circular(10),
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                   SizedBox(width: 85,),
//
//                                   SizedBox(
//                                     width: 200, height: 70,
//                                     child: TextFormField(
//                                     //   controller:age,
//                                       style: TextStyle(fontSize: 13),
//                                       keyboardType: TextInputType.number,
//                                       inputFormatters: <TextInputFormatter>[
//                                         FilteringTextInputFormatter.digitsOnly,
//                                         LengthLimitingTextInputFormatter(2),
//                                       ],
//                                       decoration: InputDecoration(
//                                         filled:true,
//                                         fillColor: Colors.white,
//                                         labelText: "Age",
//                                         border: OutlineInputBorder(
//                                           borderRadius: BorderRadius.circular(10),
//                                         ),
//                                       ),
//                                       controller: TextEditingController(
//                                           text: agevalue.toString()),
//                                     ),
//                                   ),
//                                   SizedBox(width: 85,),
//
//                                   SizedBox(
//                                     width: 200, height: 35,
//                                     child: DropdownButtonHideUnderline(
//                                       child: DropdownButtonFormField<String>(
//                                         decoration: InputDecoration(
//                                             filled: true,
//                                             fillColor: Colors.white
//                                         ),
//                                         value: bloodGroup,
//                                         items: <String>[
//                                           "Blood Group",
//                                           "A+",
//                                           "A-",
//                                           "A1+",
//                                           "A1-",
//                                           "A2+",
//                                           "A2-",
//                                           "A1B+",
//                                           "A1B-",
//                                           "A2B+",
//                                           "A2B-",
//                                           "AB+",
//                                           "AB-",
//                                           "B+",
//                                           "B-",
//                                           "O+",
//                                           "O-",
//                                           "BBG",
//                                           "INRA"
//                                         ]
//                                             .map<DropdownMenuItem<String>>((
//                                             String value) {
//                                           return DropdownMenuItem<String>(
//                                             value: value,
//                                             child: Text(
//                                               value,
//                                               style: TextStyle(fontSize: 15),
//                                             ),
//                                           );
//                                         }).toList(),
//                                         // Step 5.
//                                         onChanged: (String? newValue) {
//                                           setState(() {
//                                             bloodGroup = newValue!;
//
//                                           });
//                                         },
//                                       ),
//                                     ),
//                                   ),
//                                   SizedBox(width: 85,),
//
//                                   ///Gender
//                                   SizedBox(
//                                     width: 200, height: 35,
//                                     child: DropdownButtonHideUnderline(
//                                       child: DropdownButtonFormField<String>(
//                                         value: gender,
//                                         decoration: InputDecoration(
//                                           fillColor: Colors.white,
//                                           filled: true,
//                                         ),
//                                         items: <String>[
//                                           'Gender',
//                                           'Male',
//                                           'Female',
//                                         ]
//                                             .map<DropdownMenuItem<String>>((
//                                             String value) {
//                                           return DropdownMenuItem<String>(
//                                             value: value,
//                                             child: Text(
//                                               value,
//                                               style: TextStyle(fontSize: 15),
//                                             ),
//                                           );
//                                         }).toList(),
//                                         // Step 5.
//                                         onChanged: (String? newValue) {
//                                           setState(() {
//                                             gender = newValue!;
//                                           });
//                                         },
//                                       ),
//                                     ),
//                                   ),
//                                   ///Date Of Birth
//                                 ],
//                               ),
//                               Wrap(
//                                 children: [
//
//                                 ],
//                               ),
//                               Wrap(
//                                 children: [
//                                   SizedBox(
//                                     width: 200, height: 35,
//                                     child: DropdownButtonHideUnderline(
//                                       child: DropdownButtonFormField<String>(
//                                         decoration: InputDecoration(
//                                             filled: true,
//                                             fillColor: Colors.white
//                                         ),
//                                         value: maritalstatus,
//                                         items: <String>[
//                                           'Marital Status',
//                                           'Married',
//                                           'Unmarried',
//                                         ]
//                                             .map<DropdownMenuItem<String>>((
//                                             String value) {
//                                           return DropdownMenuItem<String>(
//                                             value: value,
//                                             child: Text(
//                                               value,
//                                               style: TextStyle(fontSize: 15),
//                                             ),
//                                           );
//                                         }).toList(),
//                                         // Step 5.
//                                         onChanged: (String? newValue) {
//                                           setState(() {
//                                             maritalstatus = newValue!;
//
//                                           });
//                                         },
//                                       ),
//                                     ),
//                                   ),
//                                   // if (!maritalstatuserrormsg)
//                                   //   Padding(
//                                   //     padding: const EdgeInsets.all(3.0),
//                                   //     child: Text(
//                                   //       '* select a Marital Status',
//                                   //       style: TextStyle(
//                                   //         color: Colors.red,
//                                   //         fontSize: 13,
//                                   //       ),
//                                   //     ),
//                                   //   ),
//                                   if (maritalstatus == 'Married')
//                                     SizedBox(width: 85,),
//                                   if (maritalstatus == 'Married')
//                                   ///Spouse Name
//                                     SizedBox(
//                                       width: 200, height: 70,
//                                       child: TextFormField(
//                                         controller: spouseName,
//                                         onChanged: (value) {
//                                           String capitalizedValue = capitalizeFirstLetter(value);
//                                           spouseName.value = spouseName.value.copyWith(
//                                             text: capitalizedValue,
//                                             selection: TextSelection.collapsed(offset: capitalizedValue.length),
//                                           );
//                                         },
//                                         style: TextStyle(fontSize: 13),
//                                         validator: (value) {
//                                           if (value!.isEmpty) {
//                                             return "* Enter Spouse's Name";
//                                           }
//                                           return null;
//                                         },
//                                         inputFormatters: [
//                                           FilteringTextInputFormatter.deny(RegExp(r'[0-9]')) // Deny numeric characters
//                                         ],
//                                         decoration: InputDecoration(
//                                           labelText: "Spouse's Name",
//                                           filled: true,
//                                           fillColor: Colors.white,
//                                           border: OutlineInputBorder(
//                                             borderRadius: BorderRadius
//                                                 .circular(10),
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                   if (maritalstatus == 'Married')
//                                     SizedBox(width: 85,),
//                                   ///Spouse Mobile Number
//
//                                   if (maritalstatus == 'Married')
//                                     SizedBox(
//                                       width: 200, height: 70,
//                                       child: TextFormField(
//                                         controller: spouseMobile,
//                                         style: TextStyle(fontSize: 13),
//                                         validator: (value) {
//                                           if (value!.isEmpty) {
//                                             return "* Enter Mobile Number";
//                                           } else if (value.length < 10) {
//                                             return "* Mobile Number should be 10\ndigits";
//                                           } else {
//                                             return null;
//                                           }
//                                         },
//                                         decoration: InputDecoration(
//                                           prefixText: "+91",
//                                           labelText: "Spouse Mobile Number",
//                                           filled: true,
//                                           fillColor: Colors.white,
//                                           border: OutlineInputBorder(
//                                             borderRadius: BorderRadius
//                                                 .circular(10),
//                                           ),
//                                         ),
//                                         keyboardType: TextInputType.number,
//                                         inputFormatters: <TextInputFormatter>[
//                                           FilteringTextInputFormatter
//                                               .digitsOnly,
//                                           LengthLimitingTextInputFormatter(10)
//                                         ],
//                                       ),
//                                     ),
//                                   if(maritalstatus == 'Unmarried'|| maritalstatus =="Marital Status")
//                                     SizedBox(width: 85,),
//
//                                   if(maritalstatus == 'Unmarried'|| maritalstatus =="Marital Status")
//                                   ///Father Name
//                                     SizedBox(
//                                       width: 200, height: 70,
//                                       child: TextFormField(
//                                         controller: fatherName,
//                                         onChanged: (value) {
//                                           String capitalizedValue = capitalizeFirstLetter(value);
//                                           fatherName.value = fatherName.value.copyWith(
//                                             text: capitalizedValue,
//                                             selection: TextSelection.collapsed(offset: capitalizedValue.length),
//                                           );
//                                         },
//                                         style: TextStyle(fontSize: 13),
//                                         // validator: (value) {
//                                         //   if (value!.isEmpty) {
//                                         //     return '* Enter Father Name';
//                                         //   }
//                                         //   return null;
//                                         // },
//                                         inputFormatters: [
//                                           FilteringTextInputFormatter.deny(RegExp(r'[0-9]')) // Deny numeric characters
//                                         ],
//                                         decoration: InputDecoration(
//                                           filled: true,
//                                           fillColor: Colors.white,
//                                           labelText: "Father's Name",
//                                           border: OutlineInputBorder(
//                                             borderRadius: BorderRadius
//                                                 .circular(10),
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                   if(maritalstatus == 'Unmarried'|| maritalstatus =="Marital Status")
//                                     SizedBox(width: 85,),
//
//
//                                   if(maritalstatus == 'Unmarried'|| maritalstatus =="Marital Status")
//                                   ///Father Mobile
//                                     SizedBox(
//                                       width: 200, height: 70,
//                                       child: TextFormField(
//                                         controller: fatherMobile,
//                                         style: TextStyle(fontSize: 13),
//                                         // validator: (value) {
//                                         //   if (value!.isEmpty) {
//                                         //     return "* Enter Mobile Number";
//                                         //   } else if (value.length < 10) {
//                                         //     return "* Mobile Number should be 10\ndigits";
//                                         //   } else {
//                                         //     return null;
//                                         //   }
//                                         // },
//                                         decoration: InputDecoration(
//                                           prefixText: "+91",
//                                           labelText: "Father Mobile Number",
//                                           filled: true,
//                                           fillColor: Colors.white,
//                                           border: OutlineInputBorder(
//                                             borderRadius: BorderRadius
//                                                 .circular(10),
//                                           ),
//                                         ),
//                                         keyboardType: TextInputType.number,
//                                         inputFormatters: <TextInputFormatter>[
//                                           FilteringTextInputFormatter
//                                               .digitsOnly,
//                                           LengthLimitingTextInputFormatter(10)
//                                         ],
//                                       ),
//                                     ),
//                                   SizedBox(width: 85,),
//
//                                   ///dummy space for alignment
//                                   SizedBox(
//                                     width: 200, height: 70,
//                                   ),
//
//                                 ],
//                               ),
//                             ],
//                           )
//                       ),
//                     ),
//
//                     Padding(
//                       padding: const EdgeInsets.all(2.0),
//                       child:   Container(
//                         width: double.infinity, // Set the width to full page width
//                         padding: EdgeInsets.all(8.0),
//                         decoration: BoxDecoration(
//                           color: Colors.blue.shade50,
//                           border: Border.all(color: Colors.grey), // Add a border for the box
//                           borderRadius: BorderRadius.circular(10.0), // Add border radius for rounded corners
//                         ),
//                         child:Column(
//                           children: [
//                             SizedBox(height: 20,),
//                             Padding(
//                               padding: const EdgeInsets.only(left:0.0),
//
//                               child: Row(
//                                 children: [
//                                   Text("Job Details", style: TextStyle(
//
//                                       fontWeight: FontWeight.bold,
//
//                                       fontSize: 17
//
//                                   ),),
//                                 ],
//                               ),
//
//                             ),
//
//                             SizedBox(height: 20,),
//
//                             Wrap(
//
//                               children: [
//
//                                 SizedBox(
//
//                                   width: 200, height: 70,
//
//                                   child: TextFormField(
//
//                                     controller: education,
//
//                                     onChanged: (value) {
//
//                                       String capitalizedValue = capitalizeFirstLetter(
//
//                                           value);
//
//                                       education.value = education.value.copyWith(
//
//                                         text: capitalizedValue,
//
//                                         selection: TextSelection.collapsed(
//
//                                             offset: capitalizedValue.length),
//
//                                       );
//
//                                     },
//
//                                     style: TextStyle(fontSize: 13),
//
//                                     validator: (value) {
//
//                                       if (value!.isEmpty) {
//
//                                         return '* Enter Edu. Qualification';
//
//                                       }
//
//                                       return null;
//
//                                     },
//
//                                     inputFormatters: [
//
//                                       FilteringTextInputFormatter.deny(RegExp(r'[0-9]')) // Deny numeric characters
//
//                                     ],
//
//                                     decoration: InputDecoration(
//                                         filled: true,
//                                         fillColor: Colors.white,
//                                         labelText: "Edu.Qualification",
//                                         border: OutlineInputBorder(
//
//                                           borderRadius: BorderRadius.circular(
//
//                                             10,),
//
//                                         )
//
//                                     ),
//
//                                   ),
//
//                                 ),
//                                 SizedBox(width: 85,),
//
//
//                                 ///Date of Join
//
//                                 SizedBox(
//
//                                   width: 200,
//
//                                   height: 70,
//
//                                   child: TextFormField(
//
//                                     style: TextStyle(fontSize: 13),
//
//                                     readOnly: true,
//
//                                     validator: (value) {
//
//                                       if (value!.isEmpty) {
//
//                                         return '* Enter Date of Join';
//
//                                       }
//
//                                       return null;
//
//                                     },
//
//                                     onTap: () {
//
//                                       showDatePicker(
//
//                                         context: context,
//
//                                         initialDate: dOJ,
//
//                                         firstDate: DateTime(2000),
//
//                                         lastDate: DateTime(2100),
//
//                                       ).then((date) {
//
//                                         if (date != null) {
//                                           setState(() {
//                                             dOJ = date;
//                                           });
//                                         }
//                                       });
//                                     },
//                                     controller: TextEditingController(
//
//                                         text: dOJ.toString().split(' ')[0]),
//
//                                     decoration: InputDecoration(
//
//                                       labelText: "Date of Join",
//                                       filled: true,
//                                       fillColor: Colors.white,
//
//                                       border: OutlineInputBorder(
//
//                                         borderRadius: BorderRadius.circular(10),
//
//                                       ),
//
//                                     ),
//
//                                   ),
//
//                                 ),
//                                 SizedBox(width: 85,),
//                                 ///end of date
//
//                                 SizedBox(
//
//                                   width: 200,
//
//                                   height: 70,
//
//                                   child: TextFormField(
//
//                                     style: TextStyle(fontSize: 13),
//
//                                     readOnly: true,
//
//                                     // Set the field as read-only
//
//                                     validator: (value) {
//
//                                       if (value!.isEmpty) {
//
//                                         return '* Enter Ending Date';
//
//                                       }
//
//                                       return null;
//
//                                     },
//
//                                     onTap: () {
//
//                                       showDatePicker(
//
//                                         context: context,
//
//                                         initialDate: eod,
//
//                                         firstDate: DateTime(2000),
//
//                                         // Set the range of selectable dates
//
//                                         lastDate: DateTime(2100),
//
//                                       ).then((date) {
//
//                                         if (date != null) {
//
//                                           setState(() {
//
//                                             eod =
//
//                                                 date; // Update the selected date
//
//                                           });
//
//                                         }
//
//                                       });
//
//                                     },
//
//                                     controller: TextEditingController(
//
//                                         text: eod.toString().split(' ')[0]),
//
//                                     // Set the initial value of the field to the selected date
//
//                                     decoration: InputDecoration(
//                                       filled: true,
//                                       fillColor: Colors.white,
//
//                                       labelText: "Ending Date",
//
//                                       border: OutlineInputBorder(
//
//                                         borderRadius: BorderRadius.circular(10),
//
//                                       ),
//
//                                     ),
//
//                                   ),
//
//                                 ),
//                                 SizedBox(width: 85,),
//
//
//                                 ///Department Name
//
//                                 SizedBox(
//
//                                   width: 200, height: 70,
//
//                                   child: TextFormField(
//
//                                       controller: depName,
//
//                                       onChanged: (value) {
//
//                                         String capitalizedValue = capitalizeFirstLetter(
//
//                                             value);
//
//                                         depName.value =
//
//                                             depName.value.copyWith(
//
//                                               text: capitalizedValue,
//
//                                               selection: TextSelection.collapsed(
//
//                                                   offset: capitalizedValue.length),
//
//                                             );
//                                       },
//
//                                       style: TextStyle(fontSize: 13),
//
//                                       validator: (value) {
//
//                                         if (value!.isEmpty) {
//
//                                           return '* Enter Department Name';
//
//                                         }
//
//                                         return null;
//
//                                       },
//
//                                       decoration: InputDecoration(
//                                         filled: true,
//                                         fillColor: Colors.white,
//                                         labelText: "Department Name",
//                                         border: OutlineInputBorder(
//                                           borderRadius: BorderRadius.circular(
//
//                                               8.0),
//
//                                         ),
//
//                                       )
//
//                                   ),
//
//                                 ),
//                                 SizedBox(width: 85,),
//
//
//                               ],
//
//                             ),
//
//                             Wrap(
//                               children: [
//                                 SizedBox(
//                                   width: 200, height: 35,
//                                   child:DropdownButtonHideUnderline(
//                                     child: DropdownButtonFormField<String>(
//                                       decoration: InputDecoration(
//                                           filled: true,
//                                           fillColor: Colors.white
//                                       ),
//                                       value: empposition,
//
//                                       items: <String>[
//
//                                         'Employee Position',
//
//                                         'Operator',
//
//                                         'Assistant'
//
//                                       ]
//
//                                           .map<DropdownMenuItem<String>>((
//
//                                           String value) {
//
//                                         return DropdownMenuItem<String>(
//
//                                           value: value,
//
//                                           child: Text(
//
//                                             value,
//
//                                             style: TextStyle(fontSize: 15),
//
//                                           ),
//
//                                         );
//
//                                       }).toList(),
//
//                                       // Step 5.
//
//                                       onChanged: (String? newValue) {
//
//                                         setState(() {
//
//                                           empposition = newValue!;
//
//                                         });
//
//                                       },
//
//                                     ),
//
//                                   ),
//
//                                 ),
//                                 SizedBox(width: 85,),
//
//                                 ///Salary Type
//                                 SizedBox(
//
//                                   width: 200, height: 35,
//
//                                   child: DropdownButtonHideUnderline(
//
//                                     child: DropdownButtonFormField<String>(
//                                       decoration: InputDecoration(
//                                           filled: true,
//                                           fillColor: Colors.white
//                                       ),
//                                       // Step 3.
//
//                                       value: salary,
//
//                                       // Step 4.
//
//                                       items: <String>[
//
//                                         'Salary Type',
//
//                                         'Daily',
//
//                                         'Weekly',
//
//                                         'Monthly'
//
//                                       ].map<DropdownMenuItem<String>>((
//
//                                           String value) {
//
//                                         return DropdownMenuItem<String>(
//
//                                           value: value,
//
//                                           child: Text(
//
//                                             value,
//
//                                             style: TextStyle(fontSize: 15),
//
//                                           ),
//
//                                         );
//
//                                       }).toList(),
//
//                                       onChanged: (String? newValue) {
//
//                                         setState(() {
//
//                                           salary = newValue!;
//
//                                         });
//
//                                       },
//
//                                     ),
//
//                                   ),
//
//                                 ),
//                                 SizedBox(width: 85,),
//
//                                 ///Shift Type
//                                 SizedBox(
//
//                                   width: 200, height: 35,
//
//                                   child: DropdownButtonHideUnderline(
//
//                                     child: DropdownButtonFormField<String>(
//                                       decoration: InputDecoration(
//                                         filled: true,
//                                         fillColor: Colors.white,
//                                       ),
//                                       // Step 3.
//
//                                       value: shifttype,
//
//                                       // Step 4.
//
//                                       items: <String>[
//
//                                         'Shift Type',
//
//                                         'Morning',
//
//                                         'Afternoon',
//
//                                         'Night'
//
//                                       ].map<DropdownMenuItem<String>>((
//
//                                           String value) {
//
//                                         return DropdownMenuItem<String>(
//
//                                           value: value,
//
//                                           child: Text(
//
//                                             value,
//
//                                             style: TextStyle(fontSize: 15),
//
//                                           ),
//
//                                         );
//
//                                       }).toList(),
//
//                                       onChanged: (String? newValue) {
//
//                                         setState(() {
//
//                                           shifttype = newValue!;
//
//                                         });
//
//                                       },
//
//                                     ),
//
//                                   ),
//
//                                 ),
//                                 SizedBox(width: 85,),
//
//                                 ///dummy space for alignment
//                                 SizedBox(
//                                   width: 200, height: 70,
//                                 ),
//                               ],
//                             ),
//                             SizedBox(height: 20,)
//                           ],
//                         ),
//                       ),
//                     ),
//                     Padding(
//                       padding: const EdgeInsets.all(2.0),
//                       child:   Container(
//
//                         width: double.infinity, // Set the width to full page width
//
//                         padding: EdgeInsets.all(8.0),
//
//                         decoration: BoxDecoration(
//
//                           color: Colors.blue.shade50,
//
//                           border: Border.all(color: Colors.grey), // Add a border for the box
//
//                           borderRadius: BorderRadius.circular(10.0), // Add border radius for rounded corners
//
//                         ),
//
//                         child:Column(
//
//                           children: [
//
//                             SizedBox(height: 20,),
//
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.start,
//                               children: [
//                                 SizedBox(width: 5,),
//                                 Text("Bank Details", style: TextStyle(
//                                     fontWeight: FontWeight.bold,
//                                     fontSize: 17
//                                 ),),
//                               ],
//                             ),
//
//                             SizedBox(height: 20,),
//
//                             Wrap(
//
//                               children: [
//                                 SizedBox(
//
//                                   width: 200, height: 70,
//
//                                   child: TextFormField(
//
//                                       controller: acNumber,
//
//                                       style: (TextStyle(fontSize: 13)),
//
//                                       validator: (value) {
//
//                                         if (value!.isEmpty) {
//
//                                           return '* Enter Account Number';
//
//                                         }
//
//                                         return null;
//
//                                       },
//
//                                       keyboardType: TextInputType.number,
//
//                                       inputFormatters: <TextInputFormatter>[
//
//                                         LengthLimitingTextInputFormatter(16),
//
//                                         FilteringTextInputFormatter.digitsOnly,
//
//                                       ],
//
//                                       decoration: InputDecoration(
//                                         labelText: "Account Number",
//                                         filled: true,
//                                         fillColor: Colors.white,
//                                         border: OutlineInputBorder(
//                                           borderRadius: BorderRadius.circular(
//
//                                               8.0),
//
//                                         ),
//
//                                       )
//
//                                   ),
//
//                                 ),
//                                 SizedBox(width: 85,),
//
//
//                                 SizedBox(
//
//                                   width: 200, height: 70,
//
//                                   child: TextFormField(
//
//                                     controller: acHoldername,
//
//                                     onChanged: (value) {
//
//                                       String capitalizedValue = capitalizeFirstLetter(
//
//                                           value);
//
//                                       acHoldername.value =
//
//                                           acHoldername.value.copyWith(
//
//                                             text: capitalizedValue,
//
//                                             selection: TextSelection.collapsed(
//
//                                                 offset: capitalizedValue.length),
//
//                                           );
//
//                                     },
//
//                                     inputFormatters: [
//
//                                       FilteringTextInputFormatter.deny(RegExp(r'[0-9]')) // Deny numeric characters
//
//                                     ],
//
//                                     style: TextStyle(fontSize: 13),
//
//                                     validator: (value) {
//
//                                       if (value!.isEmpty) {
//
//                                         return '* Enter Account holder Name';
//
//                                       } else if (!nameRegExp.hasMatch(value)) {
//
//                                         return '* Enter Alphabets only';
//
//                                       }
//
//                                       return null;
//
//                                     },
//
//                                     decoration: InputDecoration(
//                                         filled: true,
//                                         fillColor: Colors.white,
//                                         labelText: "Account Holder Name",
//                                         border: OutlineInputBorder(
//
//                                           borderRadius: BorderRadius.circular(
//
//                                             10,),
//
//                                         )
//
//                                     ),
//
//                                   ),
//
//                                 ),
//                                 SizedBox(width: 85,),
//
//
//                                 ///Bank Name
//                                 SizedBox(
//                                   width: 200, height: 70,
//                                   child: TextFormField(
//                                       controller: bank,
//                                       onChanged: (value) {
//                                         String capitalizedValue = capitalizeFirstLetter(value);
//                                         bank.value = bank.value.copyWith(
//                                           text: capitalizedValue,
//                                           selection: TextSelection.collapsed(
//                                               offset: capitalizedValue.length),);},
//                                       inputFormatters: [
//                                         FilteringTextInputFormatter.deny(RegExp(r'[0-9]')) // Deny numeric characters
//                                       ],
//
//                                       style: TextStyle(fontSize: 13),
//
//                                       validator: (value) {
//
//                                         if (value!.isEmpty) {
//
//                                           return '* Enter Bank Name';
//
//                                         }
//
//                                         return null;
//
//                                       },
//
//                                       decoration: InputDecoration(
//
//                                         labelText: "Bank",
//                                         filled: true,
//                                         fillColor: Colors.white,
//
//                                         border: OutlineInputBorder(
//
//                                           borderRadius: BorderRadius.circular(
//
//                                               8.0),
//
//                                         ),
//
//                                       )
//
//                                   ),
//
//                                 ),
//                                 SizedBox(width: 85,),
//
//                                 SizedBox(
//
//                                   width: 200, height: 70,
//
//                                   child: TextFormField(
//
//                                     controller: branch,
//
//                                     onChanged: (value) {
//                                       String capitalizedValue = capitalizeFirstLetter(value);
//                                       branch.value = branch.value.copyWith(
//
//                                             text: capitalizedValue,
//
//                                             selection: TextSelection.collapsed(
//
//                                                 offset: capitalizedValue.length),
//
//                                           );
//
//                                     },
//
//                                     style: TextStyle(fontSize: 13),
//
//                                     validator: (value) {
//
//                                       if (value!.isEmpty) {
//
//                                         return '* Enter Branch Name';
//
//                                       }
//
//                                       return null;
//
//                                     },
//
//                                     inputFormatters: [
//
//                                       FilteringTextInputFormatter.deny(RegExp(r'[0-9]')) // Deny numeric characters
//
//                                     ],
//
//                                     decoration: InputDecoration(
//
//                                         labelText: "Branch",
//                                         filled: true,
//                                         fillColor: Colors.white,
//
//                                         border: OutlineInputBorder(
//
//                                           borderRadius: BorderRadius.circular(
//
//                                             10,),
//
//                                         )
//
//                                     ),
//
//                                   ),
//
//                                 ),
//                                 ///Account Number
//
//
//
//                                 ///Account holder Name
//                               ],
//
//                             ),
//
//                             Wrap(
//
//                               children: [
//                                 SizedBox(
//
//                                   width: 200, height: 70,
//
//                                   child: TextFormField(
//
//                                       controller: ifsc,
//
//                                       style: TextStyle(fontSize: 13),
//
//                                       // validator: (value) {
//                                       //
//                                       //   if (value!.isEmpty) {
//                                       //
//                                       //     return '* Enter your IFSC Code';
//                                       //
//                                       //   }
//                                       //
//                                       //   if (value.length != 11) {
//                                       //     return '* Enter a valid IFSC Code';
//                                       //   }
//                                       //   // Check if the first four characters are alphabetic
//                                       //
//                                       //   if (!RegExp(r'^[a-zA-Z]{4}').hasMatch(
//                                       //
//                                       //       value)) {
//                                       //
//                                       //     return '* Enter a valid IFSC Code';
//                                       //
//                                       //   }
//                                       //
//                                       //   // Check if the fifth character is 0
//                                       //
//                                       //   if (value[4] != '0') {
//                                       //
//                                       //     return '* Enter a valid IFSC Code';
//                                       //
//                                       //   }
//                                       //
//                                       //   // Check if the last six characters are alphanumeric
//                                       //
//                                       //   if (!RegExp(r'^[a-zA-Z0-9]{6}$')
//                                       //
//                                       //       .hasMatch(value.substring(5))) {
//                                       //
//                                       //     return '* Enter a valid IFSC Code';
//                                       //
//                                       //   }
//                                       //
//                                       //   return null; // Return null if the IFSC code is valid
//                                       //
//                                       // },
//
//                                       inputFormatters: [
//
//                                         UpperCaseTextFormatter()
//
//                                       ],
//
//                                       decoration: InputDecoration(
//
//                                         labelText: "IFSC Code",
//                                         filled: true,
//                                         fillColor: Colors.white,
//
//                                         border: OutlineInputBorder(
//
//                                           borderRadius: BorderRadius.circular(
//
//                                               8.0),
//
//                                         ),
//
//                                       )
//
//                                   ),
//
//                                 ),
//                                 SizedBox(width: 85,),
//
//
//                                 SizedBox(
//
//                                   width: 200, height: 70,
//
//                                   child: TextFormField(
//
//                                       controller: pan,
//
//                                       style: TextStyle(fontSize: 13),
//
//                                       // validator: (value) {
//                                       //
//                                       //   if (value!.isEmpty) {
//                                       //
//                                       //     return '* Enter PAN card Number';
//                                       //
//                                       //   }
//                                       //
//                                       //   String formattedValue = value
//                                       //
//                                       //       .replaceAll(RegExp(r'\s+'), '')
//                                       //
//                                       //       .toUpperCase();
//                                       //
//                                       //
//                                       //
//                                       //   // PAN card validation patterns
//                                       //
//                                       //   List<RegExp> panPatterns = [
//                                       //
//                                       //     RegExp(r'^[A-Z]{5}\d{4}[A-Z]$'),
//                                       //
//                                       //     // Individuals, Companies, HUFs
//                                       //
//                                       //     RegExp(r'^[A-Z]{4}\d{4}[A-Z]$'),
//                                       //
//                                       //     // Firms
//                                       //
//                                       //     RegExp(r'^T[A-Z]{4}\d{4}[A-Z]$'),
//                                       //
//                                       //     // Trusts
//                                       //
//                                       //     RegExp(r'^[A-Z]{4}\d{4}[A-Z]$'),
//                                       //
//                                       //     // AOPs
//                                       //
//                                       //     RegExp(r'^P[A-Z]{4}\d{4}[A-Z]$'),
//                                       //
//                                       //     // Local Authorities
//                                       //
//                                       //     RegExp(r'^G[A-Z]{4}\d{4}[A-Z]$'),
//                                       //
//                                       //
//                                       //
//                                       //     // Government Agencies
//                                       //
//                                       //   ];
//                                       //
//                                       //
//                                       //
//                                       //   for (RegExp pattern in panPatterns) {
//                                       //
//                                       //     if (pattern.hasMatch(
//                                       //
//                                       //         formattedValue)) {
//                                       //
//                                       //       return null; // Return null if the PAN card number is valid
//                                       //
//                                       //     }
//                                       //
//                                       //   }
//                                       //
//                                       //   return '* Enter a valid PAN card Number';
//                                       //
//                                       // },
//
//                                       inputFormatters: [
//
//                                         UpperCaseTextFormatter()
//
//                                       ],
//
//                                       decoration: InputDecoration(
//
//                                         labelText: "PAN Card Number",
//                                         filled: true,
//                                         fillColor: Colors.white,
//                                         border: OutlineInputBorder(
//                                           borderRadius: BorderRadius.circular(
//                                               8.0),
//                                         ),
//                                       )
//                                   ),
//                                 ),
//                                 SizedBox(width: 85,),
//
//
//                                 SizedBox(
//                                   width: 200, height: 70,
//                                   child: TextFormField(
//                                       controller: aadhar,
//                                       style: TextStyle(fontSize: 13),
//                                       // validator: (value){
//                                       //   if (value!.isEmpty) {
//                                       //     return '* Enter a enter Aadhaar';
//                                       //   }
//                                       //   if (value.length != 12) {
//                                       //     return '* Aadhaar should be 12 digits';
//                                       //   }
//                                       //   if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
//                                       //     return '* Aadhaar can only contain digits';
//                                       //   }
//                                       //   return null;
//                                       // },
//                                       inputFormatters: [
//                                         UpperCaseTextFormatter(),
//                                         LengthLimitingTextInputFormatter(12),
//                                       ],
//                                       decoration: InputDecoration(
//                                         labelText: "Aadhar Number",
//                                         filled: true,
//                                         fillColor: Colors.white,
//                                         border: OutlineInputBorder(
//                                           borderRadius: BorderRadius.circular(
//                                               8.0),
//                                         ),
//                                       )
//                                   ),
//                                 ),
//                                 SizedBox(width: 85,),
//
//                                 SizedBox(width: 200, height: 70,),
//                               ],
//
//                             ),
//
//                           ],
//
//                         ),
//
//                       ),
//                     ),
//
//
//                     Padding(
//                       padding: const EdgeInsets.all(30.0),
//                       child:
//                       Wrap(
//                         children: [
//                           MaterialButton(
//                             color: Colors.green.shade600,
//                             onPressed: () {
//                               if (_formKey.currentState!.validate()) {
//                                 updateEmployee(widget.empID, empName.text, empMobile.text, empAddress.text);
//                               }
//                             }, child: Text("Submit", style: TextStyle(
//                               color: Colors.white),),),
//                           SizedBox(width: 10,),
//                           MaterialButton(
//                             color: Colors.blue.shade600,
//                             onPressed:(){
//                             },
//                             child: Text("Reset", style: TextStyle(color: Colors
//                                 .white),),),
//                           SizedBox(width: 10,),
//                           MaterialButton(
//                             color: Colors.red.shade600,
//                             onPressed: () {
//                               // Navigator.push(context, MaterialPageRoute(builder: (context)=>EmployeeEntry()));
//                             }, child: Text("Cancel", style: TextStyle(
//                               color: Colors.white),),)
//                         ],
//                       ),
//                     ),
//                   ]),
//             ),
//
//           ),
//         ));
//   }
//   ///age calculation
//   void calculateAge() {
//     final today = DateTime.now();
//     final ageCalculation = today.year - dOB.year;
//     if (today.month < dOB.month ||
//         (today.month == dOB.month && today.day < dOB.day)) {
//       agevalue = ageCalculation - 1;
//     } else {
//       agevalue = ageCalculation;
//     }
//     setState(() {
//       agevalue = agevalue;
//     });
//   }
// }
//
//
//

import 'dart:convert';

import 'package:http/http.dart'as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../main.dart';

class EmployeeEdiT extends StatefulWidget {
  // String empID;
  // String empName;
  // String empMobile;
  // String deptName;
  // String salary;
  // String empAddress;
  // String shift;
  // String maritalStatus;
  // String dob;
  // String age;
  // String bloodgroup;
  // String gender;
  // // String fatherName;
  // // String fatherMobile;
  // // String spouseName;
  // // String spouseMobile;
  // String education;
  // String doj;
  // String empPhoto;
  // String end;
  // String empPosition;
  // String acNumber;
  // String acHoldername;
  // String bank;
  // String branch;
  // String pan;
  // String ifsc;
  // String aadhar;
  EmployeeEdiT({Key? key,
    // required this.empPhoto,
    // required this.empID,
    // required this.empName,
    // required this.empMobile,
    // required this.deptName,
    // required this.salary,
    // required this.empAddress,
    // required this.shift,
    // required this.maritalStatus,
    // required this.dob,
    // required this.age,
    // required this.bloodgroup,
    // required this.gender,
    // // required this.fatherName,
    // // required this.fatherMobile,
    // // required this.spouseName,
    // // required this.spouseMobile,
    // required this.education,
    // required this.doj,
    // required this.end,
    // required this.empPosition,
    // required this.acNumber,
    // required this.acHoldername,
    // required this.bank,
    // required this.branch,
    // required this.pan,
    // required this.ifsc,
    // required this.aadhar,
  }) : super(key: key);
  @override
  State<EmployeeEdiT> createState() => _EmployeeEdiTState();
}
class _EmployeeEdiTState extends State<EmployeeEdiT> {
  String? maritalStatus;
  String? sName;
  String? fName;
  bool dropdownValid6 = true;


  final _formKey = GlobalKey<FormState>();
  DateTime dOB = DateTime.now();
  DateTime dOJ = DateTime.now();
  DateTime eod = DateTime.now();
  int agevalue = 0;
  RegExp nameRegExp = RegExp(r'^[a-zA-Z\s]+$');


  TextEditingController dateOfBirth = TextEditingController();
  TextEditingController empID = TextEditingController();
  TextEditingController empName = TextEditingController();
  TextEditingController empAddress = TextEditingController();
  TextEditingController empMobile = TextEditingController();
  TextEditingController spouseMobile = TextEditingController();
  TextEditingController fatherMobile = TextEditingController();
  TextEditingController spouseName = TextEditingController();
  TextEditingController fatherName = TextEditingController();
  TextEditingController empPhoto = TextEditingController();
  TextEditingController education = TextEditingController();
  TextEditingController depName = TextEditingController();
  TextEditingController empPosition = TextEditingController();
  TextEditingController acHoldername = TextEditingController();
  TextEditingController acNumber = TextEditingController();
  TextEditingController ifsc = TextEditingController();
  TextEditingController pan = TextEditingController();
  TextEditingController bank = TextEditingController();
  TextEditingController branch = TextEditingController();
  TextEditingController age = TextEditingController();
  TextEditingController aadhar = TextEditingController();
  TextEditingController doj = TextEditingController();

  String capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text.substring(0, 1).toUpperCase() + text.substring(1);
  }
  Future<void> insertData(Map<String, dynamic> dataToInsert) async {
    final String apiUrl = 'http://localhost:3309/employee'; // Replace with your server details
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({'dataToInsert': dataToInsert}),
      );
      if (response.statusCode == 200) {
        print('Data inserted successfully');
      } else {
        print('Failed to insert data');
        throw Exception('Failed to insert data');
      }
    } catch (e) {
      print('Error: $e');
      throw Exception('Error: $e');
    }
  }
  Map<String, dynamic> dataToInsert = {};

  Future<void> updateEmployee(String empID, String empName, String empMobile, String empAddress) async {
    final response = await http.put(
      Uri.parse('http://localhost:3309/employee/$empID'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'empName': empName,
        'empMobile': empMobile,
        'empAddress': empAddress,
      }),
    );

    if (response.statusCode == 200) {
      print('Employee updated successfully');
    } else {
      throw Exception('Failed to update employee');
    }
  }
  // void initState() {
  //   empID = TextEditingController(
  //     text: widget.empID,
  //   );
  //   empName = TextEditingController(
  //     text: widget.empName,
  //   );
  //   empMobile = TextEditingController(
  //     text: widget.empMobile,
  //   );
  //   empAddress = TextEditingController(
  //     text: widget.empAddress,
  //   );
  //   empPosition = TextEditingController(
  //     text: widget.empPosition,
  //   );
  //   empPhoto = TextEditingController(
  //     text: widget.empPhoto,
  //   );
  //   age = TextEditingController(
  //     text: widget.age,
  //   );
  //   acHoldername = TextEditingController(
  //     text: widget.acHoldername,
  //   );
  //   bank = TextEditingController(
  //     text: widget.bank,
  //   );
  //   ifsc = TextEditingController(
  //     text: widget.ifsc,
  //   );
  //   pan = TextEditingController(
  //     text: widget.pan,
  //   );
  //   aadhar = TextEditingController(
  //     text: widget.aadhar,
  //   );
  //   acNumber = TextEditingController(
  //     text: widget.acNumber,
  //   );
  //   bank = TextEditingController(
  //     text: widget.bank,
  //   );
  //   branch = TextEditingController(
  //     text: widget.branch,
  //   );
  //   depName = TextEditingController(
  //     text: widget.deptName,
  //   );
  //   education = TextEditingController(
  //     text: widget.education,
  //   );
  //   age = TextEditingController(
  //     text: widget.age,
  //   );
  //   gender = widget.gender;
  //   bloodGroup = widget.bloodgroup;
  //   shifttype = widget.shift;
  //   salary = widget.salary;
  //   maritalstatus = widget.maritalStatus;
  //   empposition = widget.empPosition;
  //   _imageUrl = widget.empPhoto;
  //   // TODO: implement initState
  //   super.initState();
  // }
  String employeePosition = "";
  bool gendererrormsg = true;
  bool bloodGrouperrormsg = true;
  bool salaryerrormsg = true;
  bool maritalstatuserrormsg = true;
  bool shifttypegrouperrormsg = true;
  bool emppositionerrormsg = true;
  String gender = "Gender";
  String bloodGroup = "Blood Group";
  String shifttype = "Shift Type";
  String salary = "Salary Type";
  String maritalstatus = "Marital Status";
  String empposition = "Employee Position";



  String? _imageUrl = '';

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().getImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _imageUrl = pickedFile.path;
      });
    }
  }  @override
  Widget build(BuildContext context) {
    return MyScaffold(
        route: "employee_edit",backgroundColor: Colors.white,
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Center(
              child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Container(
                        width: double.infinity, // Set the width to full page width
                        padding: EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          border: Border.all(color: Colors.grey), // Add a border for the box
                          borderRadius: BorderRadius.circular(10.0), // Add border radius for rounded corners
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.account_balance_sharp),SizedBox(width: 10,),
                                  Text("Employee Edit",style: TextStyle(fontSize: 25,fontWeight: FontWeight.bold),),
                                  Padding(
                                    padding: const EdgeInsets.only(left:700.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        // SizedBox(
                                        //   child: Align(
                                        //       alignment: Alignment.topRight,
                                        //       child:
                                        //       Text(
                                        //           DateFormat('dd-MM-yyyy').format(selectedDate),
                                        //           style:TextStyle(fontWeight: FontWeight.bold))),
                                        // ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 2,),
                    Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Container(
                          width: double.infinity, // Set the width to full page width
                          padding: EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            border: Border.all(color: Colors.grey), // Add a border for the box
                            borderRadius: BorderRadius.circular(10.0), // Add border radius for rounded corners
                          ),
                          child:Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text("Personal Details", style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),),
                                ],
                              ),
                              // SizedBox(height: 10,),
                              InkWell(
                                onTap: () {
                                  showModalBottomSheet(context: context, builder: (ctx){
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 20),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [

                                          ListTile(
                                              leading: const Icon(Icons.storage),
                                              title: const Text("From Gallery"),
                                              onTap: () async {
                                                _pickImage(ImageSource.gallery);
                                              })
                                        ],
                                      ),
                                    );
                                  });
                                },
                                child:  _imageUrl!.isNotEmpty
                                    ? ClipOval(
                                  child: Image.network(
                                    _imageUrl!,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                )
                                    : CircleAvatar(
                                  radius: 50,
                                  backgroundImage: AssetImage("assets/employee.png"),
                                  child: Icon(Icons.download, size: 15,color: Colors.brown,),
                                ),

                              ),
                              SizedBox(height: 30,),

                              Wrap(
                                  children: [
                                    ///Employee ID
                                    SizedBox(
                                      width: 200, height: 70,
                                      child: TextFormField(
                                        readOnly: true,
                                        controller: empID,
                                        style: TextStyle(fontSize: 13),
                                        validator: (value) {
                                          if (value!.isEmpty) {
                                            return '* Enter Employee ID';
                                          }
                                          return null;
                                        },
                                        inputFormatters: [
                                          //UpperCaseTextFormatter(),
                                        ],
                                        decoration: InputDecoration(
                                          labelText: "Employee ID",
                                          filled: true,
                                          fillColor: Colors.white,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 85,),
                                    ///Employee Name
                                    SizedBox(
                                      width: 200, height: 70,
                                      child: TextFormField(
                                        controller: empName,
                                        onChanged: (value) {
                                          empName.text = value;
                                          String capitalizedValue = capitalizeFirstLetter(
                                              value);
                                          empName.value =
                                              empName.value.copyWith(
                                                text: capitalizedValue,
                                                selection: TextSelection.collapsed(
                                                    offset: capitalizedValue
                                                        .length),
                                              );
                                        },
                                        style: TextStyle(fontSize: 13),
                                        validator: (value) {
                                          if (value!.isEmpty) {
                                            return '* Enter Employee Name';
                                          }
                                          return null;
                                        },
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
                                    SizedBox(width: 85,),

                                    ///Address
                                    SizedBox(
                                      width: 200, height: 70,
                                      child: TextFormField(
                                        controller: empAddress,
                                        onChanged: (value) {
                                          empAddress.text=value;
                                          String capitalizedValue = capitalizeFirstLetter(value);
                                          empAddress.value = empAddress.value.copyWith(
                                            text: capitalizedValue,
                                            selection: TextSelection.collapsed(
                                                offset: capitalizedValue.length),);
                                        },
                                        style: TextStyle(fontSize: 13),
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: Colors.white,
                                          labelText: "Address",
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),

                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 85,),


                                    ///Mobile Number
                                    SizedBox(
                                      width: 200, height: 70,
                                      child: TextFormField(
                                        controller:empMobile,
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
                                    ),


                                  ]),

                              Wrap(
                                children: [
                                  SizedBox(
                                    width: 200,
                                    height: 70,
                                    child: TextFormField(

                                      style: TextStyle(fontSize: 13),
                                      readOnly: true,
                                      validator: (value) {
                                        if (value!.isEmpty) {
                                          return '* Enter Date Of Birth';
                                        }
                                        return null;
                                      },
                                      onTap: () {
                                        showDatePicker(
                                          context: context,
                                          initialDate: dOB,
                                          firstDate: DateTime(1900),
                                          // Set the range of selectable dates
                                          lastDate: DateTime(2100),
                                        ).then((date) {
                                          if (date != null) {
                                            setState(() {
                                              dOB = date;
                                              calculateAge(); // Update the selected date
                                            });
                                          }
                                        });
                                      },
                                      controller: TextEditingController(
                                          text: dOB.toString().split(
                                              ' ')[0]),
                                      // Set the initial value of the field to the selected date
                                      decoration: InputDecoration(
                                        filled:true,
                                        fillColor: Colors.white,
                                        labelText: "DOB",
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 85,),

                                  SizedBox(
                                    width: 200, height: 70,
                                    child: TextFormField(
                                      //   controller:age,
                                      style: TextStyle(fontSize: 13),
                                      keyboardType: TextInputType.number,
                                      inputFormatters: <TextInputFormatter>[
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(2),
                                      ],
                                      decoration: InputDecoration(
                                        filled:true,
                                        fillColor: Colors.white,
                                        labelText: "Age",
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      controller: TextEditingController(
                                          text: agevalue.toString()),
                                    ),
                                  ),
                                  SizedBox(width: 85,),

                                  SizedBox(
                                    width: 200, height: 35,
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButtonFormField<String>(
                                        decoration: InputDecoration(
                                            filled: true,
                                            fillColor: Colors.white
                                        ),
                                        value: bloodGroup,
                                        items: <String>[
                                          "Blood Group",
                                          "A+",
                                          "A-",
                                          "A1+",
                                          "A1-",
                                          "A2+",
                                          "A2-",
                                          "A1B+",
                                          "A1B-",
                                          "A2B+",
                                          "A2B-",
                                          "AB+",
                                          "AB-",
                                          "B+",
                                          "B-",
                                          "O+",
                                          "O-",
                                          "BBG",
                                          "INRA"
                                        ]
                                            .map<DropdownMenuItem<String>>((
                                            String value) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(
                                              value,
                                              style: TextStyle(fontSize: 15),
                                            ),
                                          );
                                        }).toList(),
                                        // Step 5.
                                        onChanged: (String? newValue) {
                                          setState(() {
                                            bloodGroup = newValue!;

                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 85,),

                                  ///Gender
                                  SizedBox(
                                    width: 200, height: 35,
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButtonFormField<String>(
                                        value: gender,
                                        decoration: InputDecoration(
                                          fillColor: Colors.white,
                                          filled: true,
                                        ),
                                        items: <String>[
                                          'Gender',
                                          'Male',
                                          'Female',
                                        ]
                                            .map<DropdownMenuItem<String>>((
                                            String value) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(
                                              value,
                                              style: TextStyle(fontSize: 15),
                                            ),
                                          );
                                        }).toList(),
                                        // Step 5.
                                        onChanged: (String? newValue) {
                                          setState(() {
                                            gender = newValue!;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                  ///Date Of Birth
                                ],
                              ),
                              Wrap(
                                children: [

                                ],
                              ),
                              Wrap(
                                children: [
                                  SizedBox(
                                    width: 200, height: 35,
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButtonFormField<String>(
                                        decoration: InputDecoration(
                                            filled: true,
                                            fillColor: Colors.white
                                        ),
                                        value: maritalstatus,
                                        items: <String>[
                                          'Marital Status',
                                          'Married',
                                          'Unmarried',
                                        ]
                                            .map<DropdownMenuItem<String>>((
                                            String value) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(
                                              value,
                                              style: TextStyle(fontSize: 15),
                                            ),
                                          );
                                        }).toList(),
                                        // Step 5.
                                        onChanged: (String? newValue) {
                                          setState(() {
                                            maritalstatus = newValue!;

                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                  // if (!maritalstatuserrormsg)
                                  //   Padding(
                                  //     padding: const EdgeInsets.all(3.0),
                                  //     child: Text(
                                  //       '* select a Marital Status',
                                  //       style: TextStyle(
                                  //         color: Colors.red,
                                  //         fontSize: 13,
                                  //       ),
                                  //     ),
                                  //   ),
                                  if (maritalstatus == 'Married')
                                    SizedBox(width: 85,),
                                  if (maritalstatus == 'Married')
                                  ///Spouse Name
                                    SizedBox(
                                      width: 200, height: 70,
                                      child: TextFormField(
                                        controller: spouseName,
                                        onChanged: (value) {
                                          String capitalizedValue = capitalizeFirstLetter(value);
                                          spouseName.value = spouseName.value.copyWith(
                                            text: capitalizedValue,
                                            selection: TextSelection.collapsed(offset: capitalizedValue.length),
                                          );
                                        },
                                        style: TextStyle(fontSize: 13),
                                        validator: (value) {
                                          if (value!.isEmpty) {
                                            return "* Enter Spouse's Name";
                                          }
                                          return null;
                                        },
                                        inputFormatters: [
                                          FilteringTextInputFormatter.deny(RegExp(r'[0-9]')) // Deny numeric characters
                                        ],
                                        decoration: InputDecoration(
                                          labelText: "Spouse's Name",
                                          filled: true,
                                          fillColor: Colors.white,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius
                                                .circular(10),
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (maritalstatus == 'Married')
                                    SizedBox(width: 85,),
                                  ///Spouse Mobile Number

                                  if (maritalstatus == 'Married')
                                    SizedBox(
                                      width: 200, height: 70,
                                      child: TextFormField(
                                        controller: spouseMobile,
                                        style: TextStyle(fontSize: 13),
                                        validator: (value) {
                                          if (value!.isEmpty) {
                                            return "* Enter Mobile Number";
                                          } else if (value.length < 10) {
                                            return "* Mobile Number should be 10\ndigits";
                                          } else {
                                            return null;
                                          }
                                        },
                                        decoration: InputDecoration(
                                          prefixText: "+91",
                                          labelText: "Spouse Mobile Number",
                                          filled: true,
                                          fillColor: Colors.white,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius
                                                .circular(10),
                                          ),
                                        ),
                                        keyboardType: TextInputType.number,
                                        inputFormatters: <TextInputFormatter>[
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                          LengthLimitingTextInputFormatter(10)
                                        ],
                                      ),
                                    ),
                                  if(maritalstatus == 'Unmarried'|| maritalstatus =="Marital Status")
                                    SizedBox(width: 85,),

                                  if(maritalstatus == 'Unmarried'|| maritalstatus =="Marital Status")
                                  ///Father Name
                                    SizedBox(
                                      width: 200, height: 70,
                                      child: TextFormField(
                                        controller: fatherName,
                                        onChanged: (value) {
                                          String capitalizedValue = capitalizeFirstLetter(value);
                                          fatherName.value = fatherName.value.copyWith(
                                            text: capitalizedValue,
                                            selection: TextSelection.collapsed(offset: capitalizedValue.length),
                                          );
                                        },
                                        style: TextStyle(fontSize: 13),
                                        // validator: (value) {
                                        //   if (value!.isEmpty) {
                                        //     return '* Enter Father Name';
                                        //   }
                                        //   return null;
                                        // },
                                        inputFormatters: [
                                          FilteringTextInputFormatter.deny(RegExp(r'[0-9]')) // Deny numeric characters
                                        ],
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: Colors.white,
                                          labelText: "Father's Name",
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius
                                                .circular(10),
                                          ),
                                        ),
                                      ),
                                    ),
                                  if(maritalstatus == 'Unmarried'|| maritalstatus =="Marital Status")
                                    SizedBox(width: 85,),


                                  if(maritalstatus == 'Unmarried'|| maritalstatus =="Marital Status")
                                  ///Father Mobile
                                    SizedBox(
                                      width: 200, height: 70,
                                      child: TextFormField(
                                        controller: fatherMobile,
                                        style: TextStyle(fontSize: 13),
                                        // validator: (value) {
                                        //   if (value!.isEmpty) {
                                        //     return "* Enter Mobile Number";
                                        //   } else if (value.length < 10) {
                                        //     return "* Mobile Number should be 10\ndigits";
                                        //   } else {
                                        //     return null;
                                        //   }
                                        // },
                                        decoration: InputDecoration(
                                          prefixText: "+91",
                                          labelText: "Father Mobile Number",
                                          filled: true,
                                          fillColor: Colors.white,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius
                                                .circular(10),
                                          ),
                                        ),
                                        keyboardType: TextInputType.number,
                                        inputFormatters: <TextInputFormatter>[
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                          LengthLimitingTextInputFormatter(10)
                                        ],
                                      ),
                                    ),
                                  SizedBox(width: 85,),

                                  ///dummy space for alignment
                                  SizedBox(
                                    width: 200, height: 70,
                                  ),

                                ],
                              ),
                            ],
                          )
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(2.0),
                      child:   Container(
                        width: double.infinity, // Set the width to full page width
                        padding: EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          border: Border.all(color: Colors.grey), // Add a border for the box
                          borderRadius: BorderRadius.circular(10.0), // Add border radius for rounded corners
                        ),
                        child:Column(
                          children: [
                            SizedBox(height: 20,),
                            Padding(
                              padding: const EdgeInsets.only(left:0.0),

                              child: Row(
                                children: [
                                  Text("Job Details", style: TextStyle(

                                      fontWeight: FontWeight.bold,

                                      fontSize: 17

                                  ),),
                                ],
                              ),

                            ),

                            SizedBox(height: 20,),

                            Wrap(

                              children: [

                                SizedBox(

                                  width: 200, height: 70,

                                  child: TextFormField(

                                    controller: education,

                                    onChanged: (value) {

                                      String capitalizedValue = capitalizeFirstLetter(

                                          value);

                                      education.value = education.value.copyWith(

                                        text: capitalizedValue,

                                        selection: TextSelection.collapsed(

                                            offset: capitalizedValue.length),

                                      );

                                    },

                                    style: TextStyle(fontSize: 13),

                                    validator: (value) {

                                      if (value!.isEmpty) {

                                        return '* Enter Edu. Qualification';

                                      }

                                      return null;

                                    },

                                    inputFormatters: [

                                      FilteringTextInputFormatter.deny(RegExp(r'[0-9]')) // Deny numeric characters

                                    ],

                                    decoration: InputDecoration(
                                        filled: true,
                                        fillColor: Colors.white,
                                        labelText: "Edu.Qualification",
                                        border: OutlineInputBorder(

                                          borderRadius: BorderRadius.circular(

                                            10,),

                                        )

                                    ),

                                  ),

                                ),
                                SizedBox(width: 85,),


                                ///Date of Join

                                SizedBox(

                                  width: 200,

                                  height: 70,

                                  child: TextFormField(

                                    style: TextStyle(fontSize: 13),

                                    readOnly: true,

                                    validator: (value) {

                                      if (value!.isEmpty) {

                                        return '* Enter Date of Join';

                                      }

                                      return null;

                                    },

                                    onTap: () {

                                      showDatePicker(

                                        context: context,

                                        initialDate: dOJ,

                                        firstDate: DateTime(2000),

                                        lastDate: DateTime(2100),

                                      ).then((date) {

                                        if (date != null) {
                                          setState(() {
                                            dOJ = date;
                                          });
                                        }
                                      });
                                    },
                                    controller: TextEditingController(

                                        text: dOJ.toString().split(' ')[0]),

                                    decoration: InputDecoration(

                                      labelText: "Date of Join",
                                      filled: true,
                                      fillColor: Colors.white,

                                      border: OutlineInputBorder(

                                        borderRadius: BorderRadius.circular(10),

                                      ),

                                    ),

                                  ),

                                ),
                                SizedBox(width: 85,),
                                ///end of date

                                SizedBox(

                                  width: 200,

                                  height: 70,

                                  child: TextFormField(

                                    style: TextStyle(fontSize: 13),

                                    readOnly: true,

                                    // Set the field as read-only

                                    validator: (value) {

                                      if (value!.isEmpty) {

                                        return '* Enter Ending Date';

                                      }

                                      return null;

                                    },

                                    onTap: () {

                                      showDatePicker(

                                        context: context,

                                        initialDate: eod,

                                        firstDate: DateTime(2000),

                                        // Set the range of selectable dates

                                        lastDate: DateTime(2100),

                                      ).then((date) {

                                        if (date != null) {

                                          setState(() {

                                            eod =

                                                date; // Update the selected date

                                          });

                                        }

                                      });

                                    },

                                    controller: TextEditingController(

                                        text: eod.toString().split(' ')[0]),

                                    // Set the initial value of the field to the selected date

                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.white,

                                      labelText: "Ending Date",

                                      border: OutlineInputBorder(

                                        borderRadius: BorderRadius.circular(10),

                                      ),

                                    ),

                                  ),

                                ),
                                SizedBox(width: 85,),


                                ///Department Name

                                SizedBox(

                                  width: 200, height: 70,

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

                                      validator: (value) {

                                        if (value!.isEmpty) {

                                          return '* Enter Department Name';

                                        }

                                        return null;

                                      },

                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: Colors.white,
                                        labelText: "Department Name",
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(

                                              8.0),

                                        ),

                                      )

                                  ),

                                ),
                                SizedBox(width: 85,),


                              ],

                            ),

                            Wrap(
                              children: [
                                SizedBox(
                                  width: 200, height: 35,
                                  child:DropdownButtonHideUnderline(
                                    child: DropdownButtonFormField<String>(
                                      decoration: InputDecoration(
                                          filled: true,
                                          fillColor: Colors.white
                                      ),
                                      value: empposition,

                                      items: <String>[

                                        'Employee Position',

                                        'Operator',

                                        'Assistant'

                                      ]

                                          .map<DropdownMenuItem<String>>((

                                          String value) {

                                        return DropdownMenuItem<String>(

                                          value: value,

                                          child: Text(

                                            value,

                                            style: TextStyle(fontSize: 15),

                                          ),

                                        );

                                      }).toList(),

                                      // Step 5.

                                      onChanged: (String? newValue) {

                                        setState(() {

                                          empposition = newValue!;

                                        });

                                      },

                                    ),

                                  ),

                                ),
                                SizedBox(width: 85,),

                                ///Salary Type
                                SizedBox(

                                  width: 200, height: 35,

                                  child: DropdownButtonHideUnderline(

                                    child: DropdownButtonFormField<String>(
                                      decoration: InputDecoration(
                                          filled: true,
                                          fillColor: Colors.white
                                      ),
                                      // Step 3.

                                      value: salary,

                                      // Step 4.

                                      items: <String>[

                                        'Salary Type',

                                        'Daily',

                                        'Weekly',

                                        'Monthly'

                                      ].map<DropdownMenuItem<String>>((

                                          String value) {

                                        return DropdownMenuItem<String>(

                                          value: value,

                                          child: Text(

                                            value,

                                            style: TextStyle(fontSize: 15),

                                          ),

                                        );

                                      }).toList(),

                                      onChanged: (String? newValue) {

                                        setState(() {

                                          salary = newValue!;

                                        });

                                      },

                                    ),

                                  ),

                                ),
                                SizedBox(width: 85,),

                                ///Shift Type
                                SizedBox(

                                  width: 200, height: 35,

                                  child: DropdownButtonHideUnderline(

                                    child: DropdownButtonFormField<String>(
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: Colors.white,
                                      ),
                                      // Step 3.

                                      value: shifttype,

                                      // Step 4.

                                      items: <String>[

                                        'Shift Type',

                                        'Morning',

                                        'Afternoon',

                                        'Night'

                                      ].map<DropdownMenuItem<String>>((

                                          String value) {

                                        return DropdownMenuItem<String>(

                                          value: value,

                                          child: Text(

                                            value,

                                            style: TextStyle(fontSize: 15),

                                          ),

                                        );

                                      }).toList(),

                                      onChanged: (String? newValue) {

                                        setState(() {

                                          shifttype = newValue!;

                                        });

                                      },

                                    ),

                                  ),

                                ),
                                SizedBox(width: 85,),

                                ///dummy space for alignment
                                SizedBox(
                                  width: 200, height: 70,
                                ),
                              ],
                            ),
                            SizedBox(height: 20,)
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(2.0),
                      child:   Container(

                        width: double.infinity, // Set the width to full page width

                        padding: EdgeInsets.all(8.0),

                        decoration: BoxDecoration(

                          color: Colors.blue.shade50,

                          border: Border.all(color: Colors.grey), // Add a border for the box

                          borderRadius: BorderRadius.circular(10.0), // Add border radius for rounded corners

                        ),

                        child:Column(

                          children: [

                            SizedBox(height: 20,),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                SizedBox(width: 5,),
                                Text("Bank Details", style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17
                                ),),
                              ],
                            ),

                            SizedBox(height: 20,),

                            Wrap(

                              children: [
                                SizedBox(

                                  width: 200, height: 70,

                                  child: TextFormField(

                                      controller: acNumber,

                                      style: (TextStyle(fontSize: 13)),

                                      validator: (value) {

                                        if (value!.isEmpty) {

                                          return '* Enter Account Number';

                                        }

                                        return null;

                                      },

                                      keyboardType: TextInputType.number,

                                      inputFormatters: <TextInputFormatter>[

                                        LengthLimitingTextInputFormatter(16),

                                        FilteringTextInputFormatter.digitsOnly,

                                      ],

                                      decoration: InputDecoration(
                                        labelText: "Account Number",
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(

                                              8.0),

                                        ),

                                      )

                                  ),

                                ),
                                SizedBox(width: 85,),


                                SizedBox(

                                  width: 200, height: 70,

                                  child: TextFormField(

                                    controller: acHoldername,

                                    onChanged: (value) {

                                      String capitalizedValue = capitalizeFirstLetter(

                                          value);

                                      acHoldername.value =

                                          acHoldername.value.copyWith(

                                            text: capitalizedValue,

                                            selection: TextSelection.collapsed(

                                                offset: capitalizedValue.length),

                                          );

                                    },

                                    inputFormatters: [

                                      FilteringTextInputFormatter.deny(RegExp(r'[0-9]')) // Deny numeric characters

                                    ],

                                    style: TextStyle(fontSize: 13),

                                    validator: (value) {

                                      if (value!.isEmpty) {

                                        return '* Enter Account holder Name';

                                      } else if (!nameRegExp.hasMatch(value)) {

                                        return '* Enter Alphabets only';

                                      }

                                      return null;

                                    },

                                    decoration: InputDecoration(
                                        filled: true,
                                        fillColor: Colors.white,
                                        labelText: "Account Holder Name",
                                        border: OutlineInputBorder(

                                          borderRadius: BorderRadius.circular(

                                            10,),

                                        )

                                    ),

                                  ),

                                ),
                                SizedBox(width: 85,),


                                ///Bank Name
                                SizedBox(
                                  width: 200, height: 70,
                                  child: TextFormField(
                                      controller: bank,
                                      onChanged: (value) {
                                        String capitalizedValue = capitalizeFirstLetter(value);
                                        bank.value = bank.value.copyWith(
                                          text: capitalizedValue,
                                          selection: TextSelection.collapsed(
                                              offset: capitalizedValue.length),);},
                                      inputFormatters: [
                                        FilteringTextInputFormatter.deny(RegExp(r'[0-9]')) // Deny numeric characters
                                      ],

                                      style: TextStyle(fontSize: 13),

                                      validator: (value) {

                                        if (value!.isEmpty) {

                                          return '* Enter Bank Name';

                                        }

                                        return null;

                                      },

                                      decoration: InputDecoration(

                                        labelText: "Bank",
                                        filled: true,
                                        fillColor: Colors.white,

                                        border: OutlineInputBorder(

                                          borderRadius: BorderRadius.circular(

                                              8.0),

                                        ),

                                      )

                                  ),

                                ),
                                SizedBox(width: 85,),

                                SizedBox(

                                  width: 200, height: 70,

                                  child: TextFormField(

                                    controller: branch,

                                    onChanged: (value) {
                                      String capitalizedValue = capitalizeFirstLetter(value);
                                      branch.value = branch.value.copyWith(

                                        text: capitalizedValue,

                                        selection: TextSelection.collapsed(

                                            offset: capitalizedValue.length),

                                      );

                                    },

                                    style: TextStyle(fontSize: 13),

                                    validator: (value) {

                                      if (value!.isEmpty) {

                                        return '* Enter Branch Name';

                                      }

                                      return null;

                                    },

                                    inputFormatters: [

                                      FilteringTextInputFormatter.deny(RegExp(r'[0-9]')) // Deny numeric characters

                                    ],

                                    decoration: InputDecoration(

                                        labelText: "Branch",
                                        filled: true,
                                        fillColor: Colors.white,

                                        border: OutlineInputBorder(

                                          borderRadius: BorderRadius.circular(

                                            10,),

                                        )

                                    ),

                                  ),

                                ),
                                ///Account Number



                                ///Account holder Name
                              ],

                            ),

                            Wrap(

                              children: [
                                SizedBox(

                                  width: 200, height: 70,

                                  child: TextFormField(

                                      controller: ifsc,

                                      style: TextStyle(fontSize: 13),

                                      // validator: (value) {
                                      //
                                      //   if (value!.isEmpty) {
                                      //
                                      //     return '* Enter your IFSC Code';
                                      //
                                      //   }
                                      //
                                      //   if (value.length != 11) {
                                      //     return '* Enter a valid IFSC Code';
                                      //   }
                                      //   // Check if the first four characters are alphabetic
                                      //
                                      //   if (!RegExp(r'^[a-zA-Z]{4}').hasMatch(
                                      //
                                      //       value)) {
                                      //
                                      //     return '* Enter a valid IFSC Code';
                                      //
                                      //   }
                                      //
                                      //   // Check if the fifth character is 0
                                      //
                                      //   if (value[4] != '0') {
                                      //
                                      //     return '* Enter a valid IFSC Code';
                                      //
                                      //   }
                                      //
                                      //   // Check if the last six characters are alphanumeric
                                      //
                                      //   if (!RegExp(r'^[a-zA-Z0-9]{6}$')
                                      //
                                      //       .hasMatch(value.substring(5))) {
                                      //
                                      //     return '* Enter a valid IFSC Code';
                                      //
                                      //   }
                                      //
                                      //   return null; // Return null if the IFSC code is valid
                                      //
                                      // },

                                      inputFormatters: [


                                      ],

                                      decoration: InputDecoration(

                                        labelText: "IFSC Code",
                                        filled: true,
                                        fillColor: Colors.white,

                                        border: OutlineInputBorder(

                                          borderRadius: BorderRadius.circular(

                                              8.0),

                                        ),

                                      )

                                  ),

                                ),
                                SizedBox(width: 85,),


                                SizedBox(

                                  width: 200, height: 70,

                                  child: TextFormField(

                                      controller: pan,

                                      style: TextStyle(fontSize: 13),

                                      // validator: (value) {
                                      //
                                      //   if (value!.isEmpty) {
                                      //
                                      //     return '* Enter PAN card Number';
                                      //
                                      //   }
                                      //
                                      //   String formattedValue = value
                                      //
                                      //       .replaceAll(RegExp(r'\s+'), '')
                                      //
                                      //       .toUpperCase();
                                      //
                                      //
                                      //
                                      //   // PAN card validation patterns
                                      //
                                      //   List<RegExp> panPatterns = [
                                      //
                                      //     RegExp(r'^[A-Z]{5}\d{4}[A-Z]$'),
                                      //
                                      //     // Individuals, Companies, HUFs
                                      //
                                      //     RegExp(r'^[A-Z]{4}\d{4}[A-Z]$'),
                                      //
                                      //     // Firms
                                      //
                                      //     RegExp(r'^T[A-Z]{4}\d{4}[A-Z]$'),
                                      //
                                      //     // Trusts
                                      //
                                      //     RegExp(r'^[A-Z]{4}\d{4}[A-Z]$'),
                                      //
                                      //     // AOPs
                                      //
                                      //     RegExp(r'^P[A-Z]{4}\d{4}[A-Z]$'),
                                      //
                                      //     // Local Authorities
                                      //
                                      //     RegExp(r'^G[A-Z]{4}\d{4}[A-Z]$'),
                                      //
                                      //
                                      //
                                      //     // Government Agencies
                                      //
                                      //   ];
                                      //
                                      //
                                      //
                                      //   for (RegExp pattern in panPatterns) {
                                      //
                                      //     if (pattern.hasMatch(
                                      //
                                      //         formattedValue)) {
                                      //
                                      //       return null; // Return null if the PAN card number is valid
                                      //
                                      //     }
                                      //
                                      //   }
                                      //
                                      //   return '* Enter a valid PAN card Number';
                                      //
                                      // },


                                      decoration: InputDecoration(

                                        labelText: "PAN Card Number",
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              8.0),
                                        ),
                                      )
                                  ),
                                ),
                                SizedBox(width: 85,),


                                SizedBox(
                                  width: 200, height: 70,
                                  child: TextFormField(
                                      controller: aadhar,
                                      style: TextStyle(fontSize: 13),
                                      // validator: (value){
                                      //   if (value!.isEmpty) {
                                      //     return '* Enter a enter Aadhaar';
                                      //   }
                                      //   if (value.length != 12) {
                                      //     return '* Aadhaar should be 12 digits';
                                      //   }
                                      //   if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                                      //     return '* Aadhaar can only contain digits';
                                      //   }
                                      //   return null;
                                      // },
                                      inputFormatters: [
                                        LengthLimitingTextInputFormatter(12),
                                      ],
                                      decoration: InputDecoration(
                                        labelText: "Aadhar Number",
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              8.0),
                                        ),
                                      )
                                  ),
                                ),
                                SizedBox(width: 85,),

                                SizedBox(width: 200, height: 70,),
                              ],

                            ),

                          ],

                        ),

                      ),
                    ),


                    Padding(
                      padding: const EdgeInsets.all(30.0),
                      child:
                      Wrap(
                        children: [
                          MaterialButton(
                            color: Colors.green.shade600,
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                              //  updateEmployee(widget.empID, empName.text, empMobile.text, empAddress.text);
                              }
                            }, child: Text("Submit", style: TextStyle(
                              color: Colors.white),),),
                          SizedBox(width: 10,),
                          MaterialButton(
                            color: Colors.blue.shade600,
                            onPressed:(){
                            },
                            child: Text("Reset", style: TextStyle(color: Colors
                                .white),),),
                          SizedBox(width: 10,),
                          MaterialButton(
                            color: Colors.red.shade600,
                            onPressed: () {
                              // Navigator.push(context, MaterialPageRoute(builder: (context)=>EmployeeEntry()));
                            }, child: Text("Cancel", style: TextStyle(
                              color: Colors.white),),)
                        ],
                      ),
                    ),
                  ]),
            ),

          ),
        ));
  }
  ///age calculation
  void calculateAge() {
    final today = DateTime.now();
    final ageCalculation = today.year - dOB.year;
    if (today.month < dOB.month ||
        (today.month == dOB.month && today.day < dOB.day)) {
      agevalue = ageCalculation - 1;
    } else {
      agevalue = ageCalculation;
    }
    setState(() {
      agevalue = agevalue;
    });
  }
}



