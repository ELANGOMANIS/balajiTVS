import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'employee_report.dart';


class EmployeeDetails extends StatefulWidget {
  String? empID;
  String? empName;
  String? empAddress;String? pincode;
  int? empMobile;
  String? dob;
  int age;
  String? bloodgroup;
  String? gender;
  String? maritalStatus;
  String? gaurdian;
  String? gaurdianmobile;
  String? education;
  String? doj;
  String? end;
  String? deptName;
  String? empPosition;
  String? shift;
  String? salary;
  int daySalary;
  String? acNumber;
  String? acHoldername;
  String? bank;
  String? branch;
  String? ifsc;
  String? pan;
  int aadhar;

  EmployeeDetails({Key? key,
    required this.empID,
    required this.empName,
    required this. empAddress,
    required this. pincode,
    required this. empMobile,
    required this. dob,
    required this. age,
    required this. bloodgroup,
    required this. gender,
    required this. maritalStatus,
    required this.gaurdian,
    required this.gaurdianmobile,
    required this.education,
    required this.doj,
    required this.end,
    required this.deptName,
    required this.empPosition,
    required this.shift,
    required this.salary,
    required this.daySalary,
    required this.acNumber,
    required this.acHoldername,
    required this.bank,
    required this.branch,
    required this.ifsc,
    required this.pan,
    required this.aadhar
  }) : super(key: key);

  @override
  State<EmployeeDetails> createState() => _EmployeeDetailsState();
}

class _EmployeeDetailsState extends State<EmployeeDetails> {
  final doj = DateFormat('dd-MM-yyyy');
  late final DateTime end;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(3.0),
                    child: Container(
                      width: 800,
                      padding: EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color:Colors.grey[50],
                        border: Border.all(color: Colors.grey), // Add a border for the box
                        borderRadius: BorderRadius.circular(10.0), // Add border radius for rounded corners
                      ),

                      child: Wrap(
                          children: [
                            Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(children: [
                                    Icon(
                                      Icons.person, // Replace with the icon you want to use
                                      // Replace with the desired icon color
                                    ),
                                    SizedBox(width:2),
                                    const Text("Employee Reports", style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 22
                                    ),),
                                  ],),
                                ]),
                          ]
                      ),
                    ),

                  ),
                  SizedBox(height: 10,),
                  Container(
                    width:800,
                    padding: EdgeInsets.all(0.0),
                    decoration:BoxDecoration(
                      color: Colors.blue.shade50,
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Container(
                                  child:  Text("Personal Details",style: TextStyle(fontSize: 15,color: Colors.black,fontWeight: FontWeight.bold),),
                                ),
                              ),

                            ],
                          ),
                          Wrap(
                              children:[
                                Row(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Row(
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text("Employee ID" ,style:TextStyle(fontWeight: FontWeight.bold)),
                                              SizedBox(height: 7,),
                                              Text("Employee Name",style:TextStyle(fontWeight: FontWeight.bold)),
                                              SizedBox(height: 7,),
                                              Text("Address",style:TextStyle(fontWeight: FontWeight.bold)),
                                              SizedBox(height: 7,),
                                              Text("Pincode",style:TextStyle(fontWeight: FontWeight.bold)),
                                              SizedBox(height: 7,),
                                              Text("Contact",style:TextStyle(fontWeight: FontWeight.bold)),
                                              SizedBox(height: 7,),
                                              Text("Genter",style:TextStyle(fontWeight: FontWeight.bold)),
                                              SizedBox(height: 7,),


                                            ],
                                          ),
                                          SizedBox(width:95),
                                          Column(
                                            children: [
                                              Text(":"),
                                              SizedBox(height: 7,),
                                              Text(":"),
                                              SizedBox(height: 7,),
                                              Text(":"),
                                              SizedBox(height: 7,),
                                              Text(":"),
                                              SizedBox(height: 7,),
                                              Text(":"),
                                              SizedBox(height: 7,),
                                              Text(":"),
                                              SizedBox(height: 7,),

                                            ],
                                          ),
                                          SizedBox(width:10),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(widget.empID.toString()),
                                              SizedBox(height: 7,),
                                              Text(widget.empName.toString()),
                                              SizedBox(height: 7,),
                                              Text(widget.empAddress.toString() != "" ? widget.empAddress.toString() : "-"),
                                              SizedBox(height: 7,),
                                              Text(widget.pincode.toString() != "" ? widget.pincode.toString() : "-"),
                                              SizedBox(height: 7,),
                                              Text(widget.empMobile.toString()),
                                              SizedBox(height: 7,),
                                              Text(widget.gender.toString(), ),
                                              SizedBox(height: 5,),
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 25,),
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Row(
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text("Date of Join",style:TextStyle(fontWeight: FontWeight.bold)),
                                              SizedBox(height: 7,),
                                              Text("Aadhar No",style:TextStyle(fontWeight: FontWeight.bold)),
                                              SizedBox(height: 7,),
                                              Text("Employee Position",style:TextStyle(fontWeight: FontWeight.bold)),
                                              SizedBox(height: 7,),
                                              Text("SalaryType",style:TextStyle(fontWeight: FontWeight.bold)),
                                              SizedBox(height: 7,),
                                              Text("Salary Per Date",style:TextStyle(fontWeight: FontWeight.bold)),
                                              SizedBox(height: 7,),
                                              Text("",style:TextStyle(fontWeight: FontWeight.bold)),
                                              SizedBox(height: 7,),

                                            ],
                                          ),
                                          SizedBox(width: 35,),
                                          Column(
                                            children: [
                                              Text(":"),
                                              SizedBox(height: 7,),
                                              Text(":"),
                                              SizedBox(height: 7,),
                                              Text(":"),
                                              SizedBox(height: 7,),
                                              Text(":"),
                                              SizedBox(height: 7,),
                                              Text(":"),
                                              SizedBox(height: 7,),
                                              Text("",style:TextStyle(fontWeight: FontWeight.bold)),
                                              SizedBox(height: 7,),
                                            ],
                                          ),
                                          SizedBox(width: 10,),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(widget.doj != null ? DateFormat('dd-MM-yyyy').format(DateTime.parse(widget.doj!)) : "-"),
                                              SizedBox(height: 7,),
                                              Text(widget.aadhar.toString() != "" ? widget.aadhar.toString() : "-"),
                                              SizedBox(height: 7,),
                                              Text(widget.empPosition.toString() != "" ? widget.empPosition.toString() : "-"),
                                              SizedBox(height: 7,),
                                              Text(widget.salary.toString() != "" ? widget.salary.toString() : "-"),
                                              SizedBox(height: 7,),
                                              Text(widget.daySalary.toString() != "" ? widget.daySalary.toString() : "-"),
                                              SizedBox(height: 7,),
                                              Text("",style:TextStyle(fontWeight: FontWeight.bold)),
                                              SizedBox(height: 5,),
                                            ],
                                          )
                                        ],
                                      ),
                                    )

                                  ],
                                ),


                              ]

                          ),




                        ]
                    ),


                  ),
                  SizedBox(height:10),

                  Container(
                    width: 800,
                    padding: EdgeInsets.all(0.0),
                    decoration:BoxDecoration(
                      color: Colors.blue.shade50,
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Container(
                                  child:  Text("Other Details",style: TextStyle(fontSize: 15,color: Colors.black,fontWeight: FontWeight.bold),),
                                ),
                              ),

                            ],
                          ),
                          Wrap(
                              children:[
                                Row(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Row(
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text("DOB",style:TextStyle(fontWeight: FontWeight.bold)),
                                              SizedBox(height: 7,),
                                              Text("Age",style:TextStyle(fontWeight: FontWeight.bold)),
                                              SizedBox(height: 7,),
                                              Text("Blood Group",style:TextStyle(fontWeight: FontWeight.bold)),
                                              SizedBox(height: 7,),
                                              Text("Qualification",style:TextStyle(fontWeight: FontWeight.bold)),
                                              SizedBox(height: 7,),
                                              Text("Marital Status",style:TextStyle(fontWeight: FontWeight.bold)),
                                              SizedBox(height: 7,),
                                              Text("Spouse Name/Father Name",style:TextStyle(fontWeight: FontWeight.bold)),
                                              SizedBox(height: 7,),
                                              Text("Spouse/Father MobileNo",style:TextStyle(fontWeight: FontWeight.bold)),
                                              SizedBox(height: 7,),
                                              Text("Department Name",style:TextStyle(fontWeight: FontWeight.bold)),

                                            ],
                                          ),
                                          SizedBox(width: 25,),
                                          Column(
                                            children: [
                                              Text(":"),
                                              SizedBox(height: 7,),
                                              Text(":"),
                                              SizedBox(height: 7,),
                                              Text(":"),
                                              SizedBox(height: 7,),
                                              Text(":"),
                                              SizedBox(height: 7,),
                                              Text(":"),
                                              SizedBox(height: 7,),
                                              Text(":"),
                                              SizedBox(height: 7,),
                                              Text(":"),
                                              SizedBox(height: 7,),
                                              Text(":"),

                                            ],
                                          ),
                                          SizedBox(width: 10,),
                                          Padding(
                                            padding: const EdgeInsets.only(top:5),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(widget.dob.toString()),
                                                SizedBox(height: 7,),
                                                Text(widget.age.toString()),
                                                SizedBox(height: 7,),
                                                Text(widget.bloodgroup.toString() != "" ? widget.bloodgroup.toString() : "-"),
                                                SizedBox(height: 7,),
                                                Text(widget.education.toString() != "" ? widget.education.toString() : "-"),
                                                SizedBox(height: 7,),
                                                Text(widget.maritalStatus.toString()),
                                                SizedBox(height: 7,),
                                                Text(widget.gaurdian.toString() != "" ? widget.gaurdian.toString() : "-"),
                                                SizedBox(height: 7,),
                                                Text(widget.gaurdianmobile.toString() != "" ? widget.gaurdianmobile.toString() : "-"),
                                                SizedBox(height: 7,),
                                                Text(widget.deptName.toString() != "" ? widget.deptName.toString() : "-"),
                                              ],
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 25,),
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Row(
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [

                                              Text("Account No",style:TextStyle(fontWeight: FontWeight.bold)),
                                              SizedBox(height: 7,),
                                              Text("Holder Name",style:TextStyle(fontWeight: FontWeight.bold)),
                                              SizedBox(height: 7,),
                                              Text("Bank",style:TextStyle(fontWeight: FontWeight.bold)),
                                              SizedBox(height: 7,),
                                              Text("Branch",style:TextStyle(fontWeight: FontWeight.bold)),
                                              SizedBox(height: 7,),
                                              Text("IFSC Code",style:TextStyle(fontWeight: FontWeight.bold)),
                                              SizedBox(height: 7,),
                                              Text("PanCard No",style:TextStyle(fontWeight: FontWeight.bold)),
                                              SizedBox(height: 7,),
                                              Text("Ending Date",style:TextStyle(fontWeight: FontWeight.bold)),
                                              SizedBox(height: 7,),
                                              Text(""),
                                            ],
                                          ),
                                          SizedBox(width: 65,),
                                          Padding(
                                            padding: const EdgeInsets.only(bottom:25),
                                            child: Column(
                                              children: [
                                                Text(":"),
                                                SizedBox(height: 7,),
                                                Text(":"),
                                                SizedBox(height: 7,),
                                                Text(":"),
                                                SizedBox(height: 7,),
                                                Text(":"),
                                                SizedBox(height: 7,),
                                                Text(":"),
                                                SizedBox(height: 7,),
                                                Text(":"),
                                                SizedBox(height: 7,),
                                                Text(":"),
                                              ],
                                            ),
                                          ),
                                          SizedBox(width: 10,),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(widget.acNumber.toString() != "" ? widget.acNumber.toString() : "-"),
                                              SizedBox(height: 7,),
                                              Text(widget.acHoldername.toString() != "" ? widget.acHoldername.toString() : "-"),
                                              SizedBox(height: 7,),
                                              Text(widget.bank.toString() != "" ? widget.bank.toString() : "-", ),
                                              SizedBox(height: 7,),
                                              Text(widget.branch.toString() != "" ? widget.branch.toString() : "-",),
                                              SizedBox(height: 7,),
                                              Text(widget.ifsc.toString() != "" ? widget.ifsc.toString() : "-", ),
                                              SizedBox(height: 7,),
                                              Text(widget.pan.toString() != "" ? widget.pan.toString() : "-"),
                                              SizedBox(height: 7,),
                                              Text(widget.end != null ? DateFormat('dd-MM-yyyy').format(DateTime.parse(widget.end!)) : "-",),
                                              SizedBox(height: 7,),
                                              Text(""),
                                            ],
                                          )
                                        ],
                                      ),
                                    )

                                  ],
                                ),
                              ]
                          ),
                        ]
                    ),
                  ),
                  SizedBox(height: 20,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      MaterialButton(
                          color: Colors.green.shade600,
                          child: Text("BACK",style:TextStyle(color: Colors.white),),
                          onPressed:(){
                            Navigator.push(context, MaterialPageRoute(builder: (context)=>EmployeeReport()));
                          }
                      )
                    ],
                  )
                ],
              ),
            )
        )
    );
  }
}
