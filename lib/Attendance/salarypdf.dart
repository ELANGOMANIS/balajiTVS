

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class SalaryPdf extends StatefulWidget {
  int sn = 0;
  final List<Map<String, dynamic>> customerData;


  SalaryPdf({
    required this.customerData,
  });

  @override
  State<SalaryPdf> createState() => _SalaryPdfState();
}

class _SalaryPdfState extends State<SalaryPdf> {

  final pw.TextStyle defaultTextStyle = pw.TextStyle(fontSize: 8);

  String formatTime(String timeString) {
    if (timeString != null) {
      DateTime dateTime = DateTime.parse("2023-01-01 $timeString");
      return DateFormat('h:mm a').format(dateTime);
    }
    return "";
  }

  String formatTimeOrZero(String timeString) {
    if (timeString != null && timeString != "0") {
      DateTime dateTime = DateTime.parse("2023-01-01 $timeString");
      return DateFormat('h:mm a').format(dateTime);
    }
    return "0";
  }
  int calculateTotalDays(List<Map<String, dynamic>> filteredData) {
    return filteredData.length;
  }
  String formatDuration(String durationInMinutes) {
    if (durationInMinutes != null) {
      int minutes = int.parse(durationInMinutes);
      Duration duration = Duration(minutes: minutes);
      int hours = duration.inHours;
      int remainingMinutes = duration.inMinutes.remainder(60);
      return '$hours h $remainingMinutes m';
    }
    return "";
  }
  double calculateTotalExtraProduction(List<Map<String, dynamic>> filteredData) {
    double totalExtraProduction = 0;
    for (var row in filteredData) {
      totalExtraProduction += double.parse(row['calculated_extraproduction'] ?? '0');
    }
    return totalExtraProduction;
  }
  double calculateTotalWorkTime(List<Map<String, dynamic>> customerData) {
    double totalWorkTime = 0;
    for (var row in customerData) {
      totalWorkTime += double.parse(row['act_time'] ?? '0');
    }
    return totalWorkTime;
  }

  double calculateTotalReqWorkTime(List<Map<String, dynamic>> customerData) {
    double reqWorkTime = 0;
    for (var row in customerData) {
      reqWorkTime += double.parse(row['req_time'] ?? '0');
    }
    return reqWorkTime;
  }

  double calculateTotalLate(List<Map<String, dynamic>> customerData) {
    double totalLate = 0;
    for (var row in customerData) {
      double reqTime = double.parse(row['req_time'] ?? '0');
      double workTime = double.parse(row['act_time'] ?? '0');
      totalLate += reqTime - workTime;
    }

    // If the totalLate is negative, set it to zero
    totalLate = totalLate < 0 ? 0 : totalLate;

    return totalLate;
  }
  double calculateTotalWorkSalary(List<Map<String, dynamic>> filteredData) {
    double totalWorkSalary = 0;
    for (var row in filteredData) {
      totalWorkSalary += double.parse(row['salary'] ?? '0');
    }
    return totalWorkSalary;
  }

  double calculateTotalWorkingSalary(List<Map<String, dynamic>> filteredData) {
    double totalLate = calculateTotalLate(filteredData);
    double totalSalary = calculateTotalWorkSalary(filteredData);
    double totalWorkSalary = 0 ;
    print("totalSalary$totalSalary");

    for (var row in filteredData) {
      double salary = double.parse(row['salary'] ?? '0');
      String shiftType = row['shiftType'] ?? '';
      if (shiftType == 'Morning') {
        if (totalLate < 5.75 * 60) {
          totalWorkSalary =  totalSalary;
        } else if (totalLate >= 5.75 * 60 && totalLate < 11.5 * 60) {
          totalWorkSalary = totalSalary - (salary - (salary / 2));
        }
        else if (totalLate >= 11.5 * 60 && totalLate < 17.25 * 60) {
          totalWorkSalary = totalSalary - (salary);
        } else if (totalLate >= 17.25 && totalLate < 23 * 60) {
          totalWorkSalary = totalSalary - ((2.5 * salary)-salary);
        } else if (totalLate >= 23 * 60 && totalLate < 28.75 * 60) {
          totalWorkSalary = totalSalary - ((3 * salary)-salary);
        }
      }
      else if (shiftType == 'General') {
        if (totalLate < 4.25 * 60) {
          totalWorkSalary =  totalSalary;
        } else if (totalLate >= 4.25 && totalLate < 8.50 * 60) {
          totalWorkSalary = totalSalary - (salary - (salary / 2));
        }
        else if (totalLate >= 8.50 * 60 && totalLate < 12.75 * 60) {
          totalWorkSalary = totalSalary - (salary);
        } else if (totalLate >= 12.75 * 60 && totalLate < 17 * 60) {
          totalWorkSalary = totalSalary - ((2.5 * salary)-salary);
        } else if (totalLate >= 17 * 60 && totalLate < 21.25 * 60) {
          totalWorkSalary = totalSalary - ((3 * salary)-salary);
        }
      }
      else if (shiftType == 'Night') {
        if (totalLate < 6 * 60) {
          totalWorkSalary =  totalSalary;
        } else if (totalLate >= 6 && totalLate < 12 * 60) {
          totalWorkSalary = totalSalary - (salary - (salary / 2));
        }
        else if (totalLate >= 12 * 60 && totalLate < 24 * 60) {
          totalWorkSalary = totalSalary - (salary);
        } else if (totalLate >= 24 * 60 && totalLate < 30 * 60) {
          totalWorkSalary = totalSalary - ((2.5 * salary)-salary);
        } else if (totalLate >= 30 * 60 && totalLate < 36 * 60) {
          totalWorkSalary = totalSalary - ((3 * salary)-salary);
        }
      }
      totalWorkSalary += calculateTotalExtraProduction(filteredData);
    }
    return totalWorkSalary;
  }


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
            style: pw.TextStyle(fontSize: 6),
          ),
          pw.SizedBox(width: 635),
          pw.Padding(padding: const pw.EdgeInsets.only(right: 20,),
            child:  pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: pw.TextStyle(fontSize: 6),
            ),)
        ],
      ),
    );
  }

  Future<Uint8List> _generatePdfWithCopies(PdfPageFormat format, int copies) async {
    final pdf = pw.Document(version: PdfVersion.pdf_1_5, compress: true);
    final image = await imageFromAssetBundle("assets/pillaiyar.png");
    final image1 = await imageFromAssetBundle("assets/sarswathi.png");
    final fontData = await rootBundle.load('assets/fonts/Algerian_Regular.ttf');
    final ttf = pw.Font.ttf(fontData.buffer.asByteData());
    var font = await PdfGoogleFonts.crimsonTextBold();
    var font1 = await PdfGoogleFonts.crimsonTextSemiBold();
    int serialNumber=1;


    final List<Map<String, dynamic>> customerData = widget.customerData;
    int recordsPerPage ;
    double totalWorkTime = calculateTotalWorkTime(widget.customerData);
    double totalReqWorkTime = calculateTotalReqWorkTime(widget.customerData);
    double totalLate = calculateTotalLate(widget.customerData);
    double totalSalary = calculateTotalWorkingSalary(widget.customerData);
    double totalExtraProduction = calculateTotalExtraProduction(widget.customerData);

    for (var i = 0; i < copies; i++) {
      for (var j = 0; j < customerData.length; j += recordsPerPage) {
        recordsPerPage = (j == 0) ? 12  : 15;
        final List<Map<String, dynamic>> pageData =
        customerData.skip(j).take(recordsPerPage).toList();
        pdf.addPage(
          pw.Page(
            pageFormat: format,
            build: (context) {
              final double pageHeight = j == 0 ? format.availableHeight + 300: format.availableHeight +440;
              return pw.Column(
                children: [
                  if (j == 0)
                    pw.Container(
                      child:
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.only(top: 0,),
                            child:
                            pw.Container(
                                height: 70,
                                width: 70,
                                child: pw.Image(image)

                            ),),

                          pw.Padding(padding:pw.EdgeInsets.only(right: 10),
                            child:    pw.Column(children: [
                              pw.Text("VINAYAGA CONES",
                                  style: pw.TextStyle(
                                    font: ttf,
                                    fontSize: 20,

                                    fontWeight: pw.FontWeight.bold,)),
                              pw.SizedBox(height: 5),
                              pw.Text("(Manufactures of : QUALITY PAPER CONES)",
                                  style: pw.TextStyle(
                                      fontSize: 8, fontWeight: pw.FontWeight.bold)),
                              pw.SizedBox(height: 5),
                              pw.Container(
                                  constraints: const pw.BoxConstraints(
                                    maxWidth: 300,
                                  ),
                                  child: pw.Text(
                                      "5/624-I5,SOWDESWARI \n"
                                          "NAGAR,VEPPADAI,ELANTHAKUTTAI(PO)TIRUCHENGODE(T.K)\n"
                                          "NAMAKKAL-638008 ",
                                      style: const pw.TextStyle(fontSize: 7),
                                      textAlign: pw.TextAlign.center))
                            ]), ),

                          pw.Padding(
                              padding: const pw.EdgeInsets.only(top:0),
                              child: pw.Container(
                                height: 70,
                                width: 70,
                                child: pw.Container(
                                  child: pw.Image(image1,
                                  ),
                                ),
                              )),
                        ],
                      ),),
                  pw.Container(
                      height: pageHeight * 0.5,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(width: 1, color: PdfColors.black),
                      ),
                      child: pw.Column(
                          children: [
                            pw.Padding(padding:pw.EdgeInsets.only(top:5),
                              child:pw.Text(
                                'Salary Payment',
                                style: pw.TextStyle(fontSize: 14,font:font, fontWeight: pw.FontWeight.bold),
                              ),),
                            pw.Padding(
                              padding: pw.EdgeInsets.only(top:5,left: 16,right:16,bottom:10),
                              child: pw.Expanded(
                                child: pw.Table(
                                  border: pw.TableBorder.all(),
                                  children: [
                                    pw.TableRow(
                                      children: [
                                        pw.Container(
                                          padding: pw.EdgeInsets.all(8.0),
                                          child: pw.Text('      S.No', style: defaultTextStyle.merge(pw.TextStyle(fontWeight: pw.FontWeight.bold,font:font , fontSize: 8))),
                                        ),
                                        pw.Container(
                                          padding: pw.EdgeInsets.all(8.0),
                                          child: pw.Center(child: pw.Text('Date',
                                              style: pw.TextStyle(fontSize: 8,font:font,
                                                  fontWeight: pw.FontWeight.bold)),
                                          ),),
                                        pw.Container(
                                            padding: pw.EdgeInsets.all(8.0),
                                            child: pw.Center(
                                              child: pw.Text('Emp code',
                                                  style: pw.TextStyle(fontSize: 8,font:font,
                                                      fontWeight: pw.FontWeight.bold)),)
                                        ),
                                        pw.Container(
                                            padding: pw.EdgeInsets.all(8.0),
                                            child: pw.Center(
                                              child: pw.Text('Name',
                                                  style: pw.TextStyle(fontSize: 8,font:font,
                                                      fontWeight: pw.FontWeight.bold)),)
                                        ),
                                        pw.Container(
                                            padding: pw.EdgeInsets.all(8.0),
                                            child: pw.Center(
                                              child: pw.Text('shift',
                                                  style: pw.TextStyle(fontSize: 8,font:font,
                                                      fontWeight: pw.FontWeight.bold)),)
                                        ),
                                        pw.Container(
                                            padding: pw.EdgeInsets.all(8.0),
                                            child: pw.Center(
                                              child: pw.Text('work time',
                                                  style: pw.TextStyle(fontSize: 8,font:font,
                                                      fontWeight: pw.FontWeight.bold)),)
                                        ),
                                        pw.Container(
                                            padding: pw.EdgeInsets.all(8.0),
                                            child: pw.Center(
                                              child: pw.Text('Salary',
                                                  style: pw.TextStyle(fontSize: 8,font:font,
                                                      fontWeight: pw.FontWeight.bold)),)
                                        ),
                                        pw.Container(
                                            padding: pw.EdgeInsets.all(8.0),
                                            child: pw.Center(
                                              child: pw.Text('Extra Production',
                                                  style: pw.TextStyle(fontSize: 8,font:font,
                                                      fontWeight: pw.FontWeight.bold)),)
                                        ),
                                      ],
                                    ),


                                    ...pageData.asMap().entries.map((entry) {
                                      int sn = entry.key + 1; // Calculate the S.No based on the entry index (starting from 1)
                                      var data = entry.value;
                                      return pw.TableRow(children: [
                                        pw.Container(
                                          padding: pw.EdgeInsets.all(8.0),
                                          child: pw.Center(
                                            child:
                                            pw.Text('${serialNumber++}',style: pw.TextStyle(fontSize: 8,font:font1,)),
                                          ),
                                        ),
                                        pw.Container(
                                          padding: pw.EdgeInsets.all(8.0),
                                          child: pw.Center(
                                            child: pw.Text(data["inDate"] != null
                                                ? DateFormat('yyyy-MM-dd').format(
                                              DateTime.parse("${data["inDate"]}").toLocal(),)
                                                : "",
                                                style: pw.TextStyle(fontSize:8, font:font1,)),),
                                        ),
                                        pw.Container(
                                            padding: pw.EdgeInsets.all(8.0),
                                            child: pw.Center(
                                              child: pw.Text(data['emp_code'].toString(),
                                                  style: pw.TextStyle(fontSize: 8,font:font1,)),)
                                        ),
                                        pw.Container(
                                          padding: pw.EdgeInsets.all(8.0),
                                          child: pw.Center(
                                            child: pw.Text(data['first_name'].toString(),
                                                style: pw.TextStyle(fontSize: 8,font:font1,)),),
                                        ),
                                        pw.Container(
                                          padding: pw.EdgeInsets.all(8.0),
                                          child: pw.Center(
                                            child: pw.Text(data['shiftType'].toString(),
                                                style: pw.TextStyle(fontSize: 8,font:font1,)),),
                                        ),
                                        pw.Container(
                                          padding: pw.EdgeInsets.all(8.0),
                                          child: pw.Center(
                                            child: pw.Text(formatDuration(data['act_time']),
                                                style: pw.TextStyle(fontSize: 8,font:font1,)),),
                                        ),
                                        pw.Container(
                                          padding: pw.EdgeInsets.all(8.0),
                                          child: pw.Center(
                                            child: pw.Text(data['salary'].toString(),
                                                style: pw.TextStyle(fontSize: 8,font:font1,)),),
                                        ),
                                        pw.Container(
                                          padding: pw.EdgeInsets.all(8.0),
                                          child: pw.Center(
                                            child: pw.Text((data["calculated_extraproduction"] ?? 0).toString().replaceAll(RegExp(r'(\.0+|(?<=\.\d)0+)$'), ''),style: pw.TextStyle(fontSize: 8,font:font1,) ),),
                                        ),
                                      ]);
                                    }
                                    ).toList(),
                                  ],
                                ),
                              ),
                            ),
                            pw.SizedBox(height:10),
                            pw.Padding(
                              padding: pw.EdgeInsets.only(right:16),child:
                            pw.Align(
                              alignment: pw.Alignment.topRight,
                              child:pw.Container(
                                width: 110,
                                decoration: pw.BoxDecoration(
                                  color:PdfColors.white,
                                  border: pw.Border.all(color:PdfColors.black), // Add a border for the box
                                  borderRadius: pw.BorderRadius.circular(10.0), // Add border radius for rounded corners
                                ),
                                child:pw.Padding(
                                  padding: pw.EdgeInsets.only(left: 13,top:8,right: 8,bottom: 8),
                                  child:
                                  pw.Column(
                                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Text(
                                        'Total Days: ${calculateTotalDays(widget.customerData)}',
                                        style: pw.TextStyle(fontSize: 8,font:font1, color: PdfColor.fromInt(0xFF000000), fontWeight: pw.FontWeight.bold),
                                      ),
                                      pw.SizedBox(height: 5),
                                      pw.Text(
                                        'Req Time: ${formatDuration(totalReqWorkTime.toStringAsFixed(0))}',
                                        style:  pw.TextStyle(fontSize: 8,font:font1,),
                                      ),
                                      pw.SizedBox(height: 5),
                                      pw.Text(
                                        'Act Time: ${formatDuration(totalWorkTime.toStringAsFixed(0))}',
                                        style:  pw.TextStyle(fontSize: 8,font:font1,),
                                      ),
                                      pw.SizedBox(height: 5),
                                      pw.Text(
                                        'Late: ${formatDuration(totalLate.toStringAsFixed(0))}',
                                        style: const pw.TextStyle(fontSize: 8, color: PdfColor.fromInt(0xFFff0000)),
                                      ),
                                      pw.SizedBox(height: 5),
                                      if (totalWorkTime > 5)  // Display only if work time is greater than 5 hours
                                        pw.Text(
                                          'Extra Production: ${(totalExtraProduction.toStringAsFixed(0))}',
                                          style: pw.TextStyle(fontSize: 8,font:font1,),
                                        ),
                                      pw.SizedBox(height: 5),
                                      if (totalWorkTime > 5)  // Display only if work time is greater than 5 hours
                                        pw.Row(
                                          children: [
                                            pw.Text(
                                              'Salary: ',
                                              style: pw.TextStyle(fontSize: 9,font:font,),
                                            ),
                                            pw.Text(
                                              totalSalary.toStringAsFixed(2),
                                              style: pw.TextStyle(fontSize: 9,font:font,),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),),),),


                          ]
                      )
                  ),
                  pw.SizedBox(height:5),

                  pw.Align(
                    alignment: pw.Alignment.bottomCenter,
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        //pw.SizedBox(height: 20),
                        _buildFooter(context, j ~/ recordsPerPage + 1, (customerData.length / recordsPerPage).ceil()),
                      ],
                    ),
                  )
                ],
              );
            },
          ),
        );
      }
      //return pdf.save() ?? Uint8List(0);
    }
    return pdf.save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Salary PDF"), centerTitle: true,),
      body:
      PdfPreview(
        build: (format) => _generatePdfWithCopies(
          PdfPageFormat.a4.copyWith(
            width: PdfPageFormat.a4.height,
            height: PdfPageFormat.a4.width,
          ),
          1,
        ),
        onPrinted: (context) {},
      ),



    );
  }
}

















