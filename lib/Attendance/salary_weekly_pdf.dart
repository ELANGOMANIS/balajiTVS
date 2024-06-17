import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class SalaryWeeklyPdf extends StatefulWidget {
  final DateTime? fromDate;
  final DateTime? toDate;
  final List<Map<String, dynamic>> customerData;

  const SalaryWeeklyPdf({
    Key? key,
    required this.fromDate,
    required this.toDate,
    required this.customerData,
  }) : super(key: key);

  @override
  State<SalaryWeeklyPdf> createState() => _SalaryWeeklyPdfState();
}

class _SalaryWeeklyPdfState extends State<SalaryWeeklyPdf> {
  final pw.TextStyle defaultTextStyle = pw.TextStyle(fontSize: 8);

  String formatTime(String timeString) {
    if (timeString != null) {
      DateTime dateTime = DateTime.parse("2023-01-01 $timeString");
      return DateFormat('h:mm a').format(dateTime);
    }
    return "";
  }
  double calculateSalary(Map<String, dynamic> data) {

    double totalSalary = double.parse(data['total_salary'].toString());
    double perDaySalary = double.parse(data['perDaySalary'].toString());
    double totalLate = double.parse(data['total_late'].toString());
    String shiftType = data['shift_type'].toString();

    double salary = totalSalary;

    if (shiftType == 'Morning') {
      if (totalLate < 5.75 * 60) {
        salary = totalSalary;
      } else if (totalLate >= 5.75 * 60 && totalLate < 11.5 * 60) {
        salary = totalSalary - (perDaySalary / 2);
      } else if (totalLate >= 11.5 * 60 && totalLate < 17.25 * 60) {
        salary = totalSalary - perDaySalary;
      } else if (totalLate >= 17.25 * 60 && totalLate < 23 * 60) {
        salary = totalSalary - (2.5 * perDaySalary);
      } else if (totalLate >= 23 * 60 && totalLate < 28.75 * 60) {
        salary = totalSalary - (3 * perDaySalary);
      } else if (totalLate >= 28.75 * 60 && totalLate < 34.5 * 60) {
        salary = totalSalary - (3.5 * perDaySalary);
      } else if (totalLate >= 34.5 * 60 && totalLate < 40.25 * 60) {
        salary = totalSalary - (4 * perDaySalary);
      } else if (totalLate >= 40.25 * 60 && totalLate < 46 * 60) {
        salary = totalSalary - (4.5 * perDaySalary);
      } else if (totalLate >= 46 * 60 && totalLate < 51.75 * 60) {
        salary = totalSalary - (5 * perDaySalary);
      } else if (totalLate >= 51.75 * 60 && totalLate < 57.5 * 60) {
        salary = totalSalary - (5.5 * perDaySalary);
      }
    }
    else if (shiftType == 'General') {
      if (totalLate < 4.25 * 60) {
        salary = totalSalary;
      } else if (totalLate >= 4.25 * 60 && totalLate < 8.5 * 60) {
        salary = totalSalary - (perDaySalary / 2);
      } else if (totalLate >= 8.5 * 60 && totalLate < 12.75 * 60) {
        salary = totalSalary - perDaySalary;
      } else if (totalLate >= 12.75 * 60 && totalLate < 17 * 60) {
        salary = totalSalary - (2.5 * perDaySalary);
      } else if (totalLate >= 17 * 60 && totalLate < 21.25 * 60) {
        salary = totalSalary - (3 * perDaySalary);
      } else if (totalLate >= 21.25 * 60 && totalLate < 25.5 * 60) {
        salary = totalSalary - (3.5 * perDaySalary);
      } else if (totalLate >= 25.5 * 60 && totalLate < 29.75 * 60) {
        salary = totalSalary - (4 * perDaySalary);
      } else if (totalLate >= 29.75 * 60 && totalLate < 34 * 60) {
        salary = totalSalary - (4.5 * perDaySalary);
      } else if (totalLate >= 34 * 60 && totalLate < 38.25 * 60) {
        salary = totalSalary - (5 * perDaySalary);
      } else if (totalLate >= 38.25 * 60 && totalLate < 42.5 * 60) {
        salary = totalSalary - (5.5 * perDaySalary);
      }
    }
    else if (shiftType == 'Night') {
      if (totalLate < 6 * 60) {
        salary = totalSalary;
      } else if (totalLate >= 6 * 60 && totalLate < 12 * 60) {
        salary = totalSalary - (perDaySalary / 2);
      } else if (totalLate >= 12 * 60 && totalLate < 18 * 60) {
        salary = totalSalary - perDaySalary;
      } else if (totalLate >= 18 * 60 && totalLate < 24 * 60) {
        salary = totalSalary - (2.5 * perDaySalary);
      } else if (totalLate >= 24 * 60 && totalLate < 30 * 60) {
        salary = totalSalary - (3 * perDaySalary);
      } else if (totalLate >= 30 * 60 && totalLate < 36 * 60) {
        salary = totalSalary - (3.5 * perDaySalary);
      } else if (totalLate >= 36 * 60 && totalLate < 42 * 60) {
        salary = totalSalary - (4 * perDaySalary);
      } else if (totalLate >= 42 * 60 && totalLate < 48 * 60) {
        salary = totalSalary - (4.5 * perDaySalary);
      } else if (totalLate >= 48 * 60 && totalLate < 54 * 60) {
        salary = totalSalary - (5 * perDaySalary);
      } else if (totalLate >= 54 * 60 && totalLate < 60 * 60) {
        salary = totalSalary - (5.5 * perDaySalary);
      }
    }

    if (salary < 0) {
      salary = 0; // Ensure salary does not go below 0
    }

    return salary;
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

  pw.Widget _buildFooter(pw.Context context, int currentPage, int totalPages) {
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('dd-MM-yyyy').format(now);
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
          pw.Padding(
            padding: const pw.EdgeInsets.only(
              right: 20,
            ),
            child: pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: pw.TextStyle(fontSize: 6),
            ),
          )
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
    int serialNumber = 1;

    final List<Map<String, dynamic>> customerData = widget.customerData;
    int recordsPerPage= 10;

    for (var i = 0; i < copies; i++) {
      for (var j = 0; j < customerData.length; j += recordsPerPage) {
        recordsPerPage = (j == 0) ? 11 : 11;
        final List<Map<String, dynamic>> pageData = customerData.skip(j).take(recordsPerPage).toList();
        pdf.addPage(
          pw.Page(
            pageFormat: format,
            build: (context) {
              final double pageHeight = j == 0 ? format.availableHeight + 300 : format.availableHeight + 440;
              return pw.Column(
                children: [
                  if (j == 0)
                    pw.Container(
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(
                              top: 0,
                            ),
                            child: pw.Container(
                              height: 70,
                              width: 70,
                              child: pw.Image(image),
                            ),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.only(right: 10),
                            child: pw.Column(children: [
                              pw.Text(
                                "VINAYAGA CONES",
                                style: pw.TextStyle(
                                  font: ttf,
                                  fontSize: 20,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.SizedBox(height: 5),
                              pw.Text(
                                "(Manufactures of : QUALITY PAPER CONES)",
                                style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                              ),
                              pw.SizedBox(height: 5),
                              pw.Container(
                                constraints: const pw.BoxConstraints(
                                  maxWidth: 300,
                                ),
                                child: pw.Text(
                                  "5/624-I5,SOWDESWARI \n" "NAGAR,VEPPADAI,ELANTHAKUTTAI(PO)TIRUCHENGODE(T.K)\n" "NAMAKKAL-638008 ",
                                  style: const pw.TextStyle(fontSize: 7),
                                  textAlign: pw.TextAlign.center,
                                ),
                              )
                            ]),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(top: 0),
                            child: pw.Container(
                              height: 70,
                              width: 70,
                              child: pw.Container(
                                child: pw.Image(image1),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  pw.Container(
                      height: pageHeight * 0.5,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(width: 1, color: PdfColors.black),
                      ),
                      child: pw.Column(children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.only(top: 5),
                          child: pw.Text(
                            'Salary Payment',
                            style: pw.TextStyle(fontSize: 14, font: font, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.only(top: 5, left: 16, right: 16, bottom: 10),
                          child: pw.Expanded(
                            child: pw.Table(
                              border: pw.TableBorder.all(),
                              children: [
                                pw.TableRow(
                                  children: [
                                    pw.Container(
                                      padding: pw.EdgeInsets.all(8.0),
                                      child: pw.Text('      S.No',
                                          style: defaultTextStyle.merge(pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font, fontSize: 8))),
                                    ),
                                    pw.Container(
                                      padding: pw.EdgeInsets.all(8.0),
                                      child: pw.Text('from', style: defaultTextStyle.merge(pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font, fontSize: 8))),
                                    ),
                                    pw.Container(
                                      padding: pw.EdgeInsets.all(8.0),
                                      child: pw.Text('to date', style: defaultTextStyle.merge(pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font, fontSize: 8))),
                                    ),
                                    pw.Container(
                                      padding: pw.EdgeInsets.all(8.0),
                                      child: pw.Center(
                                        child: pw.Text(
                                          'employee',
                                          style: pw.TextStyle(fontSize: 8, font: font, fontWeight: pw.FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    pw.Container(
                                      padding: pw.EdgeInsets.all(8.0),
                                      child: pw.Center(
                                        child: pw.Text(
                                          'shift',
                                          style: pw.TextStyle(fontSize: 8, font: font, fontWeight: pw.FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    pw.Container(
                                      padding: pw.EdgeInsets.all(8.0),
                                      child: pw.Center(
                                        child: pw.Text(
                                          'no of days',
                                          style: pw.TextStyle(fontSize: 8, font: font, fontWeight: pw.FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    pw.Container(
                                      padding: pw.EdgeInsets.all(8.0),
                                      child: pw.Center(
                                        child: pw.Text(
                                          'req time',
                                          style: pw.TextStyle(fontSize: 8, font: font, fontWeight: pw.FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    pw.Container(
                                      padding: pw.EdgeInsets.all(8.0),
                                      child: pw.Center(
                                        child: pw.Text(
                                          'act time',
                                          style: pw.TextStyle(fontSize: 8, font: font, fontWeight: pw.FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    pw.Container(
                                      padding: pw.EdgeInsets.all(8.0),
                                      child: pw.Center(
                                        child: pw.Text(
                                          'late time',
                                          style: pw.TextStyle(fontSize: 8, font: font, fontWeight: pw.FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    pw.Container(
                                      padding: pw.EdgeInsets.all(8.0),
                                      child: pw.Center(
                                        child: pw.Text(
                                          'per day salary',
                                          style: pw.TextStyle(fontSize: 8, font: font, fontWeight: pw.FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    pw.Container(
                                      padding: pw.EdgeInsets.all(8.0),
                                      child: pw.Center(
                                        child: pw.Text(
                                          'salary',
                                          style: pw.TextStyle(fontSize: 8, font: font, fontWeight: pw.FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    pw.Container(
                                      padding: pw.EdgeInsets.all(8.0),
                                      child: pw.Center(
                                        child: pw.Text(
                                          'extra production',
                                          style: pw.TextStyle(fontSize: 8, font: font, fontWeight: pw.FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    pw.Container(
                                      padding: pw.EdgeInsets.all(8.0),
                                      child: pw.Center(
                                        child: pw.Text(
                                          'Total Salary',
                                          style: pw.TextStyle(fontSize: 8, font: font, fontWeight: pw.FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                ...pageData.asMap().entries.map((entry) {
                                  int sn = entry.key + 1;
                                  var data = entry.value;
                                  double calculatedSalary = calculateSalary(data);
                                  double calculatedExtraProduction = double.parse(data['calculated_extraproduction'].toString());
                                  double totalSalaryWithExtraProduction = calculatedSalary + calculatedExtraProduction;

                                  return pw.TableRow(children: [
                                    pw.Container(
                                      padding: pw.EdgeInsets.all(8.0),
                                      child: pw.Center(
                                        child: pw.Text('${serialNumber++}', style: pw.TextStyle(fontSize: 8, font: font1)),
                                      ),
                                    ),
                                    pw.Container(
                                      padding: pw.EdgeInsets.all(8.0),
                                      child: pw.Center(child: pw.Text(widget.fromDate != null ? DateFormat('yyyy-MM-dd').format(widget.fromDate!) : '', style: pw.TextStyle(fontSize: 8, font: font1))),
                                    ),
                                    pw.Container(
                                      padding: pw.EdgeInsets.all(8.0),
                                      child: pw.Center(child: pw.Text(widget.toDate != null ? DateFormat('yyyy-MM-dd').format(widget.toDate!) : '', style: pw.TextStyle(fontSize: 8, font: font1))),
                                    ),
                                    pw.Container(
                                      padding: pw.EdgeInsets.all(8.0),
                                      child: pw.Center(
                                        child: pw.Text(data['employee'].toString(), style: pw.TextStyle(fontSize: 8, font: font1)),
                                      ),
                                    ),
                                    pw.Container(
                                      padding: pw.EdgeInsets.all(8.0),
                                      child: pw.Center(
                                        child: pw.Text(data['shift_type'].toString(), style: pw.TextStyle(fontSize: 8, font: font1)),
                                      ),
                                    ),
                                    pw.Container(
                                      padding: pw.EdgeInsets.all(8.0),
                                      child: pw.Center(
                                        child: pw.Text(data['no_of_work_days'].toString(), style: pw.TextStyle(fontSize: 8, font: font1)),
                                      ),
                                    ),
                                    pw.Container(
                                      padding: pw.EdgeInsets.all(8.0),
                                      child: pw.Center(
                                        child: pw.Text(formatDuration(data['total_req_time'].toString()), style: pw.TextStyle(fontSize: 8, font: font1)),
                                      ),
                                    ),
                                    pw.Container(
                                      padding: pw.EdgeInsets.all(8.0),
                                      child: pw.Center(
                                        child: pw.Text(formatDuration(data['total_act_time'].toString()), style: pw.TextStyle(fontSize: 8, font: font1)),
                                      ),
                                    ),
                                    pw.Container(
                                      padding: pw.EdgeInsets.all(8.0),
                                      child: pw.Center(
                                        child: pw.Text(formatDuration(data['total_late'].toString()), style: pw.TextStyle(fontSize: 8, font: font1)),
                                      ),
                                    ),
                                    pw.Container(
                                      padding: pw.EdgeInsets.all(8.0),
                                      child: pw.Center(
                                        child: pw.Text((data['perDaySalary'].toString()), style: pw.TextStyle(fontSize: 8, font: font1)),
                                      ),
                                    ),
                                    pw.Container(
                                      padding: pw.EdgeInsets.all(8.0),
                                      child: pw.Center(
                                        child: pw.Text(
                                          calculateSalary(data).toString(), // Display the calculated salary
                                          style: pw.TextStyle(fontSize: 8),
                                        ),
                                      ),
                                    ),
                                    pw.Container(
                                      padding: pw.EdgeInsets.all(8.0),
                                      child: pw.Center(
                                        child: pw.Text((data['calculated_extraproduction'].toString()), style: pw.TextStyle(fontSize: 8, font: font1)),
                                      ),
                                    ),
                                    pw.Container(
                                      padding: pw.EdgeInsets.all(8.0),
                                      child: pw.Center(
                                        child: pw.Text(totalSalaryWithExtraProduction.toString(), style: pw.TextStyle(fontSize: 8, font: font1)),
                                      ),
                                    ),
                                  ]);
                                }).toList(),
                              ],
                            ),
                          ),
                        ),
                      ])),
                  pw.SizedBox(height: 5),
                  pw.Align(
                    alignment: pw.Alignment.bottomCenter,
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
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
    }
    return pdf.save();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Salary PDF"),
        centerTitle: true,
      ),
      body: PdfPreview(
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
