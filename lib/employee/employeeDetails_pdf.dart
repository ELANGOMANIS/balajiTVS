
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;

class EmployeeReportPdf extends StatefulWidget {

  String? empID;
  String? empName;
  String? empAddress;
  String? pincode;
  String? empMobile;
  String? dob;
  String? age;
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
  String? aadhar;

  EmployeeReportPdf({
    required this.empID,
    required this.empName,
    required this. empAddress,required this. pincode,
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
    //required this.customerData,

  });

  @override
  State<EmployeeReportPdf> createState() => _EmployeeReportPdfState();
}
int serialNumber=1;
class _EmployeeReportPdfState extends State<EmployeeReportPdf> {
  pw.Widget _buildFooter(pw.Context context, int currentPage, int totalPages) {
    // ... (rest of your code)
    // Get the current date and time
    DateTime now = DateTime.now();

    // Format the date
    String formattedDate = DateFormat('dd-MM-yyyy').format(now);

    // Format the time in AM/PM
    String formattedTime = DateFormat('hh.mm a').format(now);


    return pw.Container(

      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.start,
        children: [
          pw.Text(
            '$formattedDate   $formattedTime',
            style: pw.TextStyle(fontSize:4 ),
          ),
          pw.SizedBox(width: 405),
          pw.Padding(padding: const pw.EdgeInsets.only(right: 0,),
            child:  pw.Text(
              'Page $currentPage of $totalPages',
              style: pw.TextStyle(fontSize: 4),
            ),)
        ],
      ),
    );
  }
  int serialNumber=1;
  Future<Map<String, dynamic>> fetchCompanyData() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:3309/fetch_company_details?id=1'));

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic dataCompany = json.decode(response.body);
        if (dataCompany != null && dataCompany is Map<String, dynamic>) {
          print('Company Name: ${dataCompany['companyName']}');
          print('Address: ${dataCompany['address']}');
          print('Contact: ${dataCompany['contact']}');
          return dataCompany;
        } else {
          throw Exception('Unexpected response format');
        }
      } else {
        throw Exception('Error loading company data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load company data: $e');
    }
  }

  Future<Uint8List> _generatePdfWithCopies(PdfPageFormat format, int copies) async {
    final pdf = pw.Document(version: PdfVersion.pdf_1_5, compress: true);
    /// final image = await imageFromAssetBundle("assets/pillaiyar.png");
    //   final image1 = await imageFromAssetBundle("assets/sarswathi.png");
    final fontData = await rootBundle.load('assets/fonts/Algerian_Regular.ttf');
    final ttf = pw.Font.ttf(fontData.buffer.asByteData());


    //  final List<Map<String, dynamic>> customerData = widget.customerData;
    final int recordsPerPage = 4;
    final companyData = await fetchCompanyData(); // Fetch company data

    pw.Widget createHeader(String companyName, String address, String contact) {
      return pw.Container(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Padding(
                  padding: pw.EdgeInsets.only(right: 10),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        "${companyData['companyName']}",
                        style: pw.TextStyle(
                          font: ttf,
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
    //
    // for (var i = 0; i < copies; i++) {
    //   for (var j = 0; j < customerData.length; j += recordsPerPage)
    //   {
    //     final List<Map<String, dynamic>> pageData =
    //     customerData.skip(j).take(recordsPerPage).toList();
    pdf.addPage(
      pw.Page(
        pageFormat: format,
        build: (pw.Context context) {
          return pw.Column(
            children: [
              //    if (j == 0)
              createHeader(
                companyData['companyName'],
                companyData['address'],
                companyData['contact'],),
              pw.SizedBox(height: 1),
              pw.Divider(),
              pw.Text(
                'Employee Report',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              pw.Container(
                child:pw.Column(
                  children:[
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("Personal  Details",style: pw.TextStyle(fontWeight: pw.FontWeight.bold,fontSize: 10)),
                        pw.SizedBox(height:10),
                        pw.Row(
                            children:[
                              pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.start,

                                children: [

                                  pw.Padding(
                                    padding: pw.EdgeInsets.all(3.0),
                                    child: pw.Column(
                                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                                      children: [
                                        pw.Text(
                                          "Employee ID",
                                          style: pw.TextStyle(
                                            fontSize: 10,
                                            fontWeight: pw.FontWeight.bold,
                                          ),
                                        ),
                                        pw.SizedBox(height: 7),
                                        pw.Text(
                                          "Employee Name",
                                          style: pw.TextStyle(
                                            fontSize: 10,
                                            fontWeight: pw.FontWeight.bold,
                                          ),
                                        ),
                                        pw.SizedBox(height: 7),
                                        pw.Text(
                                          "Gender",
                                          style: pw.TextStyle(
                                            fontSize: 10,
                                            fontWeight: pw.FontWeight.bold,
                                          ),
                                        ),
                                        pw.SizedBox(height: 7),
                                        pw.Text(
                                          "Pincode",
                                          style: pw.TextStyle(
                                            fontSize: 10,
                                            fontWeight: pw.FontWeight.bold,
                                          ),
                                        ),
                                        pw.SizedBox(height: 7),
                                        pw.Text(
                                          "Contact",
                                          style: pw.TextStyle(
                                            fontSize: 10,
                                            fontWeight: pw.FontWeight.bold,
                                          ),
                                        ),
                                        pw.SizedBox(height: 7),
                                        pw.Text(
                                          "Address",
                                          style: pw.TextStyle(
                                            fontSize: 10,
                                            fontWeight: pw.FontWeight.bold,
                                          ),
                                        ),
                                        pw.SizedBox(height: 7),

                                      ],
                                    ),
                                  ),
                                  pw.Padding(
                                    padding: pw.EdgeInsets.only(bottom:3,left:60,right:3,top:3),
                                    child: pw.Column(
                                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                                      children: [
                                        pw.Text(":", style: pw.TextStyle(fontSize: 10,)),
                                        pw.SizedBox(height: 7),
                                        pw.Text(":", style: pw.TextStyle(fontSize: 10,)),
                                        pw.SizedBox(height: 7),
                                        pw.Text(":", style: pw.TextStyle(fontSize: 10,)),
                                        pw.SizedBox(height: 7),
                                        pw.Text(":", style: pw.TextStyle(fontSize: 10,)),
                                        pw.SizedBox(height: 7),
                                        pw.Text(":", style: pw.TextStyle(fontSize: 10,)),
                                        pw.SizedBox(height: 7),
                                        pw.Text(":", style: pw.TextStyle(fontSize: 10,)),
                                        pw.SizedBox(height: 7),

                                      ],
                                    ),
                                  ),
                                  pw.Padding(
                                    padding: pw.EdgeInsets.all(4.0),
                                    child: pw.Column(
                                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                                      children: [
                                        pw.Text(widget.empID.toString(), style: pw.TextStyle(fontSize: 10,)),
                                        pw.SizedBox(height: 7),
                                        pw.Text(widget.empName.toString(), style: pw.TextStyle(fontSize: 10,)),
                                        pw.SizedBox(height:7),
                                        pw.Text(widget.pincode.toString() != "" ? widget.pincode.toString() : "-", style: pw.TextStyle(fontSize: 10)),
                                        pw.SizedBox(height: 7),
                                        pw.Text(widget.gender.toString(), style: pw.TextStyle(fontSize: 10,)),
                                        pw.SizedBox(height: 7),
                                        pw.Text(widget.empMobile.toString(), style: pw.TextStyle(fontSize: 10,)),
                                        pw.SizedBox(height: 7),
                                        pw.Container(
                                          constraints: pw.BoxConstraints(
                                            minWidth: 100, // minimum width
                                            maxWidth: 100, // maximum width
                                            minHeight: 20, // minimum height
                                            maxHeight: 50, // maximum height
                                          ),
                                          child: pw.Text(
                                              widget.empAddress.toString() != "" ? widget.empAddress.toString() : "-",
                                              style: pw.TextStyle(fontSize: 10)
                                          ),
                                        ),
                                        pw.SizedBox(height: 5),

                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              pw.SizedBox(width: 85),
                              pw.Padding(
                                padding:pw.EdgeInsets.only(bottom:10),
                                child:
                                pw.Row(
                                  mainAxisAlignment: pw.MainAxisAlignment.start,

                                  children: [

                                    pw.Padding(
                                      padding: pw.EdgeInsets.all(3.0),
                                      child: pw.Column(
                                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                                        children: [

                                          pw.Text(
                                            "Date of Join",
                                            style: pw.TextStyle(
                                              fontSize: 10,
                                              fontWeight: pw.FontWeight.bold,
                                            ),
                                          ),
                                          pw.SizedBox(height: 7),
                                          pw.Text(
                                            "Aadhar No",
                                            style: pw.TextStyle(
                                              fontSize: 10,
                                              fontWeight: pw.FontWeight.bold,
                                            ),
                                          ),
                                          pw.SizedBox(height: 7),
                                          pw.Text(
                                            "Employee Position",
                                            style: pw.TextStyle(
                                              fontSize: 10,
                                              fontWeight: pw.FontWeight.bold,
                                            ),
                                          ),
                                          pw.SizedBox(height: 7),
                                          pw.Text(
                                            "Salary Type",

                                            style: pw.TextStyle(
                                              fontSize: 10,
                                              fontWeight: pw.FontWeight.bold,
                                            ),
                                          ),
                                          pw.SizedBox(height: 7),
                                          pw.Text(
                                            "Salary per Day",
                                            style: pw.TextStyle(
                                              fontSize: 10,
                                              fontWeight: pw.FontWeight.bold,
                                            ),
                                          ),
                                          pw.SizedBox(height: 7),
                                          pw.Text(
                                            "",
                                            style: pw.TextStyle(
                                              fontSize: 10,
                                              fontWeight: pw.FontWeight.bold,
                                            ),
                                          ),
                                          pw.SizedBox(height: 7),

                                        ],
                                      ),
                                    ),
                                    pw.SizedBox(width:15),
                                    pw.Padding(
                                      padding: pw.EdgeInsets.all(3.0),
                                      child: pw.Column(
                                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                                        children: [
                                          pw.Text(":", style: pw.TextStyle(fontSize: 10,)),
                                          pw.SizedBox(height: 7),
                                          pw.Text(":", style: pw.TextStyle(fontSize: 10,)),
                                          pw.SizedBox(height: 7),
                                          pw.Text(":", style: pw.TextStyle(fontSize: 10,)),
                                          pw.SizedBox(height: 7),
                                          pw.Text(":", style: pw.TextStyle(fontSize: 10,)),
                                          pw.SizedBox(height: 7),
                                          pw.Text(":", style: pw.TextStyle(fontSize: 10,)),
                                          pw.SizedBox(height: 7),
                                          pw.Text("", style: pw.TextStyle(fontSize: 10,)),
                                          pw.SizedBox(height: 7),
                                        ],
                                      ),
                                    ),
                                    pw.Padding(
                                      padding: pw.EdgeInsets.all(4.0),
                                      child: pw.Column(
                                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                                        children: [
                                          pw.Text(
                                            widget.doj != null ? DateFormat('dd-MM-yyyy').format(DateTime.parse(widget.doj!)) : "-",
                                            style: pw.TextStyle(fontSize: 10),
                                          ),
                                          pw.SizedBox(height: 7),
                                          pw.Text(widget.aadhar.toString() != "" ? widget.aadhar.toString() : "-", style: pw.TextStyle(fontSize: 10)),
                                          pw.SizedBox(height: 7),
                                          pw.Text(widget.empPosition.toString() != "" ? widget.empPosition.toString() : "-", style: pw.TextStyle(fontSize: 10)),
                                          pw.SizedBox(height: 7),
                                          pw.Text(widget.salary.toString() != "" ? widget.salary.toString() : "-", style: pw.TextStyle(fontSize: 10)),
                                          pw.SizedBox(height: 7),
                                          pw.Text(widget.daySalary.toString() != "" ? widget.daySalary.toString() : "-", style: pw.TextStyle(fontSize: 10)),
                                          pw.SizedBox(height: 7),
                                          pw.Text("" , style: pw.TextStyle(fontSize: 10)),
                                          pw.SizedBox(height: 7),

                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),


                            ]
                        ),



                      ],
                    ),
                    pw.Divider(),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("Other Details",style: pw.TextStyle(fontWeight: pw.FontWeight.bold,fontSize: 10)),
                        pw.SizedBox(height:10),
                        pw.Row(
                            children:[
                              pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.start,

                                children: [

                                  pw.Padding(
                                    padding: pw.EdgeInsets.all(3.0),
                                    child: pw.Column(
                                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                                      children: [
                                        pw.Text(
                                          "DOB",
                                          style: pw.TextStyle(
                                            fontSize: 10,
                                            fontWeight: pw.FontWeight.bold,
                                          ),
                                        ),
                                        pw.SizedBox(height: 7),
                                        pw.Text(
                                          "Age",
                                          style: pw.TextStyle(
                                            fontSize: 10,
                                            fontWeight: pw.FontWeight.bold,
                                          ),
                                        ),
                                        pw.SizedBox(height: 7),
                                        pw.Text(
                                          "Blood Group",
                                          style: pw.TextStyle(
                                            fontSize: 10,
                                            fontWeight: pw.FontWeight.bold,
                                          ),
                                        ),
                                        pw.SizedBox(height: 7),
                                        pw.Text(
                                          "Qualification",
                                          style: pw.TextStyle(
                                            fontSize: 10,
                                            fontWeight: pw.FontWeight.bold,
                                          ),
                                        ),
                                        pw.SizedBox(height: 7),
                                        pw.Text(
                                          "Marital Status",
                                          style: pw.TextStyle(
                                            fontSize: 10,
                                            fontWeight: pw.FontWeight.bold,
                                          ),
                                        ),
                                        pw.SizedBox(height: 7),
                                        pw.Text(
                                          "Spouse Name/Father Name",
                                          style: pw.TextStyle(
                                            fontSize: 10,
                                            fontWeight: pw.FontWeight.bold,
                                          ),
                                        ),
                                        pw.SizedBox(height: 7),
                                        pw.Text(
                                          "Spouse Name/Father MobileNo",
                                          style: pw.TextStyle(
                                            fontSize: 10,
                                            fontWeight: pw.FontWeight.bold,
                                          ),

                                        ),
                                        pw.SizedBox(height: 7),
                                        pw.Text(
                                          "Department Name",
                                          style: pw.TextStyle(
                                            fontSize: 10,
                                            fontWeight: pw.FontWeight.bold,
                                          ),
                                        ),

                                      ],
                                    ),
                                  ),
                                  pw.Padding(
                                    padding: pw.EdgeInsets.only(top:10,left:10,right:3,bottom:10),
                                    child: pw.Column(
                                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                                      children: [
                                        pw.Text(":", style: pw.TextStyle(fontSize: 10,)),
                                        pw.SizedBox(height: 7),
                                        pw.Text(":", style: pw.TextStyle(fontSize: 10,)),
                                        pw.SizedBox(height: 7),
                                        pw.Text(":", style: pw.TextStyle(fontSize: 10,)),
                                        pw.SizedBox(height: 7),
                                        pw.Text(":", style: pw.TextStyle(fontSize: 10,)),
                                        pw.SizedBox(height: 7),
                                        pw.Text(":", style: pw.TextStyle(fontSize: 10,)),
                                        pw.SizedBox(height: 7),
                                        pw.Text(":", style: pw.TextStyle(fontSize: 10,)),
                                        pw.SizedBox(height: 7),
                                        pw.Text(":", style: pw.TextStyle(fontSize: 10,)),
                                        pw.SizedBox(height: 7),
                                        pw.Text(":", style: pw.TextStyle(fontSize: 10,)),
                                      ],
                                    ),
                                  ),
                                  pw.Padding(
                                    padding: pw.EdgeInsets.only(bottom:8,left:3,right:3,top:10),
                                    child: pw.Column(
                                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                                      children: [
                                        pw.Text(widget.dob.toString() ?? "-", style: pw.TextStyle(fontSize: 10,)),
                                        pw.SizedBox(height: 7),
                                        pw.Text(widget.age.toString(), style: pw.TextStyle(fontSize: 10,)),
                                        pw.SizedBox(height: 7),
                                        pw.Text(widget.bloodgroup.toString() != "Blood Group" ? widget.bloodgroup.toString() : "-", style: pw.TextStyle(fontSize: 10)),
                                        pw.SizedBox(height: 7),
                                        pw.Text(widget.education.toString() != "" ? widget.education.toString() : "-", style: pw.TextStyle(fontSize: 10)),
                                        pw.SizedBox(height: 7),
                                        pw.Text(widget.maritalStatus.toString() != "Marital Status" ? widget.maritalStatus.toString() : "-", style: pw.TextStyle(fontSize: 10)),
                                        pw.SizedBox(height: 7),
                                        pw.Text(widget.gaurdian.toString() != "" ? widget.gaurdian.toString() : "-", style: pw.TextStyle(fontSize: 10)),
                                        pw.SizedBox(height: 7),
                                        pw.Text(widget.gaurdianmobile.toString() != "" ? widget.gaurdianmobile.toString() : "-", style: pw.TextStyle(fontSize: 10)),
                                        pw.SizedBox(height: 7),
                                        pw.Text(widget.deptName.toString() != "" ? widget.deptName.toString() : "-", style: pw.TextStyle(fontSize: 10)),


                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              pw.SizedBox(width: 85),
                              pw.Padding(
                                padding:pw.EdgeInsets.only(bottom:0),
                                child:
                                pw.Row(
                                  mainAxisAlignment: pw.MainAxisAlignment.start,

                                  children: [

                                    pw.Padding(
                                      padding: pw.EdgeInsets.only(top:10,left:3,right:3,bottom:3),
                                      child: pw.Column(
                                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                                        children: [

                                          pw.Text(
                                            "Account No",
                                            style: pw.TextStyle(
                                              fontSize: 10,
                                              fontWeight: pw.FontWeight.bold,
                                            ),
                                          ),
                                          pw.SizedBox(height: 7),
                                          pw.Text(
                                            "Holder Name",

                                            style: pw.TextStyle(
                                              fontSize: 10,
                                              fontWeight: pw.FontWeight.bold,
                                            ),
                                          ),
                                          pw.SizedBox(height: 7),
                                          pw.Text(
                                            "Bank",
                                            style: pw.TextStyle(
                                              fontSize: 10,
                                              fontWeight: pw.FontWeight.bold,
                                            ),
                                          ),
                                          pw.SizedBox(height: 7),
                                          pw.Text(
                                            "Branch",
                                            style: pw.TextStyle(
                                              fontSize: 10,
                                              fontWeight: pw.FontWeight.bold,
                                            ),
                                          ),
                                          pw.SizedBox(height: 7),
                                          pw.Text(
                                            "IFSC Code",
                                            style: pw.TextStyle(
                                              fontSize: 10,
                                              fontWeight: pw.FontWeight.bold,
                                            ),
                                          ),
                                          pw.SizedBox(height: 7),
                                          pw.Text(
                                            "Pancard No",
                                            style: pw.TextStyle(
                                              fontSize: 10,
                                              fontWeight: pw.FontWeight.bold,
                                            ),
                                          ),
                                          pw.SizedBox(height: 7),
                                          pw.Text(
                                            "",
                                            style: pw.TextStyle(
                                              fontSize: 10,
                                              fontWeight: pw.FontWeight.bold,
                                            ),
                                          ),
                                          pw.SizedBox(height: 7),
                                          pw.Text(
                                            "",
                                            style: pw.TextStyle(
                                              fontSize: 10,
                                            ),
                                          ),

                                        ],
                                      ),
                                    ),
                                    pw.Padding(
                                      padding: pw.EdgeInsets.only(top:10,left:35,right:3,bottom:3),
                                      child: pw.Column(
                                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                                        children: [
                                          pw.Text(":", style: pw.TextStyle(fontSize: 10,)),
                                          pw.SizedBox(height: 7),
                                          pw.Text(":", style: pw.TextStyle(fontSize: 10,)),
                                          pw.SizedBox(height: 7),
                                          pw.Text(":", style: pw.TextStyle(fontSize: 10,)),
                                          pw.SizedBox(height: 7),
                                          pw.Text(":", style: pw.TextStyle(fontSize: 10,)),
                                          pw.SizedBox(height: 7),
                                          pw.Text(":", style: pw.TextStyle(fontSize: 10,)),
                                          pw.SizedBox(height: 7),
                                          pw.Text(":", style: pw.TextStyle(fontSize: 10,)),
                                          pw.SizedBox(height: 7),
                                          pw.Text("", style: pw.TextStyle(fontSize: 10,)),
                                          pw.SizedBox(height: 7),
                                          pw.Text("", style: pw.TextStyle(fontSize: 10,),),
                                        ],
                                      ),
                                    ),
                                    pw.Padding(
                                      padding: pw.EdgeInsets.only(top:10,left:3,right:3,bottom:3),
                                      child: pw.Column(
                                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                                        children: [
                                          pw.Text(widget.acNumber.toString() != "" ? widget.acNumber.toString() : "-", style: pw.TextStyle(fontSize: 10)),
                                          pw.SizedBox(height: 7),
                                          pw.Text(widget.acHoldername.toString() != "" ? widget.acHoldername.toString() : "-", style: pw.TextStyle(fontSize: 10)),
                                          pw.SizedBox(height: 7),
                                          pw.Text(widget.bank.toString() != "" ? widget.bank.toString() : "-", style: pw.TextStyle(fontSize: 10)),
                                          pw.SizedBox(height: 7),
                                          pw.Text(widget.branch.toString() != "" ? widget.branch.toString() : "-", style: pw.TextStyle(fontSize: 10)),
                                          pw.SizedBox(height: 7),
                                          pw.Text(widget.ifsc.toString() != "" ? widget.ifsc.toString() : "-", style: pw.TextStyle(fontSize: 10)),
                                          pw.SizedBox(height: 7),
                                          pw.Text(widget.pan.toString() != "" ? widget.pan.toString() : "-", style: pw.TextStyle(fontSize: 10)),
                                          pw.SizedBox(height: 7),
                                          pw.Text("", style: pw.TextStyle(fontSize: 10,)),
                                          pw.SizedBox(height: 7),
                                          pw.Text("", style: pw.TextStyle(fontSize: 10,)),

                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),


                            ]
                        ),



                      ],
                    ),
                    pw.Divider(),
                  ],

                ),),


              pw.Align(
                alignment: pw.Alignment.bottomCenter,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.SizedBox(height: 10),
                    //  _buildFooter(context, j ~/ recordsPerPage + 1, (customerData.length / recordsPerPage).ceil()),
                  ],
                ),
              )


            ],
          );
        },
      ),
    );
    //   }
    //   //return pdf.save() ?? Uint8List(0);
    //
    // }
    return pdf.save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Employee Report PDF"), centerTitle: true,),
      body: PdfPreview(
        build: (format) => _generatePdfWithCopies(format, 1), // Generate 1 copy
        onPrinted: (context) {},
      ),
    );
  }
}

















