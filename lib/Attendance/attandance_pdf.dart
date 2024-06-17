

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AttendancePdf extends StatefulWidget {
  int sn = 0;
  int totalPresentDays;
  int totalAbsentDays;
  final List<Map<String, dynamic>> customerData;


  AttendancePdf({
    required this.customerData,
    required this.totalPresentDays,
    required this.totalAbsentDays,
  });

  @override
  State<AttendancePdf> createState() => _AttendancePdfState();
}

class _AttendancePdfState extends State<AttendancePdf> {

  int calculateTotalPresentDays(List<Map<String, dynamic>> filteredData) {
    Set<DateTime> presentDates = Set();

    for (var item in filteredData) {
      String dateStr = item['inDate']?.toString() ?? '';
      DateTime? itemDate = DateTime.tryParse(dateStr);

      if (itemDate != null) {
        presentDates.add(itemDate);
      }
    }

    return presentDates.length;
  }
/*
  String calculateRemarkForPDF(Map<String, dynamic> data) {
    bool isTimePresent(String? time) => time != null && time.trim() != "0" && time.trim() != "00:00:00";

    // Check if all fields are absent
    if (!isTimePresent(data["check_in"]) && !isTimePresent(data["lunch_out"]) &&
        !isTimePresent(data["lunch_in"]) && !isTimePresent(data["check_out"])) {
      return 'A'; // Absent
    }

    // Specific check for only check_out present
    if (!isTimePresent(data["check_in"]) && !isTimePresent(data["lunch_out"]) &&
        !isTimePresent(data["lunch_in"]) && isTimePresent(data["check_out"])) {
      return 'A'; // Only check_out is present, mark as Absent
    }

    bool checkInPresent = isTimePresent(data["check_in"]);
    bool checkOutPresent = isTimePresent(data["check_out"]);
    bool lunchOutPresent = isTimePresent(data["lunch_out"]);
    bool lunchInPresent = isTimePresent(data["lunch_in"]);

    if (checkInPresent && checkOutPresent && !lunchOutPresent && !lunchInPresent) {
      return 'P'; // Present
    } else if ((checkInPresent && !checkOutPresent && lunchOutPresent && !lunchInPresent) ||
        (checkInPresent && !checkOutPresent && lunchOutPresent && lunchInPresent)) {
      return 'HD'; // Half Day
    } else if (checkInPresent && checkOutPresent && lunchOutPresent && lunchInPresent) {
      return 'P'; // Present
    }

    // Default case
    return 'A'; // Assume Absent if none of the above conditions are met
  }
*/
  String calculateRemarkForPDF(Map<String, dynamic> data) {
    bool isTimePresent(String? time) => time != null && time.trim() != "0" && time.trim() != "00:00:00";

    DateTime dummyDateForLunchOut;
    bool lunchOutIsCheckOut = false; // Flag to determine if lunch_out is considered check_out

    // Check if all fields are absent
    if (!isTimePresent(data["check_in"]) && !isTimePresent(data["lunch_out"]) &&
        !isTimePresent(data["lunch_in"]) && !isTimePresent(data["check_out"])) {
      return 'A'; // Absent
    }

    // Specific check for only check_out present
    if (!isTimePresent(data["check_in"]) && !isTimePresent(data["lunch_out"]) &&
        !isTimePresent(data["lunch_in"]) && isTimePresent(data["check_out"])) {
      return 'A'; // Only check_out is present, mark as Absent
    }

    // Determine if lunch_out within a specific time range should be considered as check_out
    if (isTimePresent(data["lunch_out"])) {
      dummyDateForLunchOut = DateTime.parse("2000-01-01 ${data["lunch_out"]}");
      lunchOutIsCheckOut = dummyDateForLunchOut.hour >= 16 && dummyDateForLunchOut.hour < 23;
    }

    bool checkInPresent = isTimePresent(data["check_in"]);
    bool lunchOutPresent = isTimePresent(data["lunch_out"]);
    bool lunchInPresent = isTimePresent(data["lunch_in"]);
    // Adjust checkOutPresent considering the lunchOutIsCheckOut flag
    bool checkOutPresent = isTimePresent(data["check_out"]) || lunchOutIsCheckOut;

    if (checkInPresent && checkOutPresent && !lunchInPresent) {
      return 'P'; // Present, considering lunch_out as check_out if within the specified time
    } else if (checkInPresent && !checkOutPresent && lunchOutPresent && !lunchInPresent) {
      return 'HD'; // Half Day
    } else if (checkInPresent && !checkOutPresent && lunchOutPresent && lunchInPresent) {
      return 'HD'; // Half Day
    } else if (checkInPresent && checkOutPresent && lunchOutPresent && lunchInPresent) {
      return 'P'; // Present
    }

    // Default case
    return 'A'; // Assume Absent if none of the above conditions are met
  }

  int calculateTotalAbsentDays(DateTime fromDate, DateTime toDate, List<Map<String, dynamic>> filteredData) {
    Set<DateTime> presentDates = Set();

    for (var item in filteredData) {
      String dateStr = item['inDate']?.toString() ?? '';
      DateTime? itemDate = DateTime.tryParse(dateStr);

      if (itemDate != null) {
        presentDates.add(itemDate);
      }
    }

    // Calculate total days within the specified range
    int totalDaysInRange = toDate.difference(fromDate).inDays + 1;

    // Calculate total absent days by subtracting present days from total days in range
    int totalAbsentDays = totalDaysInRange - presentDates.length;

    return totalAbsentDays;
  }
  double calculateTotalWorkingSalary(List<Map<String, dynamic>> filteredData) {
    double totalSalary = 0;
    for (var row in filteredData) {
      totalSalary += double.parse(row['working_salary'] ?? '0');
    }
    return totalSalary;
  }

  double getTotalWorkingSalary() {
    return calculateTotalWorkingSalary(widget.customerData);
  }

  final pw.TextStyle defaultTextStyle = pw.TextStyle(fontSize: 8);

  String formatTime(String timeString) {
    if (timeString != null && timeString != "00:00:00") {
      List<String> timeParts = timeString.split(':');

      if (timeParts.length == 3) {
        DateTime dateTime = DateTime(1970, 1, 1, int.parse(timeParts[0]), int.parse(timeParts[1]), int.parse(timeParts[2]));
        return DateFormat('h:mm a').format(dateTime);
      }
    }
    return "0";
  }

  String formatTimeOrZero(String timeString) {
    if (timeString != null && timeString != "00:00:00" && timeString != "0") {
      List<String> timeParts = timeString.split(':');

      if (timeParts.length == 3) {
        DateTime dateTime = DateTime(1970, 1, 1, int.parse(timeParts[0]), int.parse(timeParts[1]), int.parse(timeParts[2]));
        return DateFormat('h:mm a').format(dateTime);
      }
    }
    return "0";
  }
  String formatDuration(String durationInMinutes) {
    try {
      if (durationInMinutes != null) {
        int minutes = int.tryParse(durationInMinutes) ?? 0;
        Duration duration = Duration(minutes: minutes);

        int hours = duration.inHours;
        int remainingMinutes = duration.inMinutes.remainder(60);

        String formattedDuration = '';

        if (hours > 0) {
          formattedDuration += '$hours h';
        }

        if (remainingMinutes > 0) {
          if (hours > 0) {
            formattedDuration += ' ';
          }
          formattedDuration += '$remainingMinutes m';
        }

        return formattedDuration.trim();
      }
    } catch (e) {
      // Handle the exception, e.g., log the error or return a default value
      print('Error formatting duration: $e');
    }

    return ""; // Return a default value if there's an error
  }
  bool isBetweenLunchOutTime(String lunchOutTime, String shiftType) {
    if (lunchOutTime == "00:00:00") {
      return false; // Handle the "00:00:00" case as needed
    }

    DateTime dummyDate = DateTime.parse("2000-01-01 $lunchOutTime");

    if (shiftType == "General") {
      return dummyDate.hour >= 16 && dummyDate.hour < 23;
    } else if (shiftType == "Morning") {
      return dummyDate.hour >= 17 && dummyDate.hour < 23;
    }

    return false; // Default case
  }

  pw.Widget _buildFooter(
      pw.Context context,
      int currentPage, int totalPages) {
    // ... (rest of your code)
    // Get the current date and time
    DateTime now = DateTime.now();

    // Format the date
    String formattedDate = DateFormat('dd-MM-yyyy').format(now);

    // Format the time in AM/PM
    String formattedTime = DateFormat('hh.mm a').format(now);


    return pw.Container(
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            '$formattedDate   $formattedTime',
            style: pw.TextStyle(fontSize: 6),
          ),
          pw.SizedBox(width: 635),
          pw.Padding(padding: const pw.EdgeInsets.only(right: 15,),
            child:  pw.Text(
              'Page $currentPage of $totalPages',
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

    for (var i = 0; i < copies; i++) {
      for (var j = 0; j < customerData.length; j += recordsPerPage) {
        recordsPerPage = (j == 0) ? 10 : 12;
        final List<Map<String, dynamic>> pageData =
        customerData.skip(j).take(recordsPerPage).toList();
        pdf.addPage(
          pw.Page(
            pageFormat: format,
            build: (context) {
              final double pageHeight = j == 0 ? format.availableHeight + 290: format.availableHeight +440;
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
                    child:pw.Column(

                        children: [
                          pw.Padding(padding:pw.EdgeInsets.only(top:5),
                            child:pw.Text(
                              'Attendance Report',
                              style: pw.TextStyle(fontSize: 14,font:font, fontWeight: pw.FontWeight.bold),
                            ),),


                          pw.Padding(
                            padding: pw.EdgeInsets.only(top:5,left: 16,right:16,bottom:10),
                            child:pw.Expanded(
                              child: pw.Table(
                                border: pw.TableBorder.all(),
                                children: [
                                  pw.TableRow(
                                    children: [
                                      pw.Container(
                                        padding: pw.EdgeInsets.all(8.0),
                                        child: pw.Text('      S.No', style: defaultTextStyle.merge(pw.TextStyle(fontWeight: pw.FontWeight.bold,fontSize: 8,font:font,))),
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
                                            child: pw.Text('check-in',
                                                style: pw.TextStyle(fontSize: 8,font:font,
                                                    fontWeight: pw.FontWeight.bold)),)
                                      ),  pw.Container(
                                          padding: pw.EdgeInsets.all(8.0),
                                          child: pw.Center(
                                            child: pw.Text('lunch_out',
                                                style: pw.TextStyle(fontSize: 8,font:font,
                                                    fontWeight: pw.FontWeight.bold)),)
                                      ), pw.Container(
                                          padding: pw.EdgeInsets.all(8.0),
                                          child: pw.Center(
                                            child: pw.Text('lunch_in',
                                                style: pw.TextStyle(fontSize: 8,font:font,
                                                    fontWeight: pw.FontWeight.bold)),)
                                      ), pw.Container(
                                          padding: pw.EdgeInsets.all(8.0),
                                          child: pw.Center(
                                            child: pw.Text('check_out',
                                                style: pw.TextStyle(fontSize: 8,font:font,
                                                    fontWeight: pw.FontWeight.bold)),)
                                      ),
                                      pw.Container(
                                          padding: pw.EdgeInsets.all(8.0),
                                          child: pw.Center(
                                            child: pw.Text('Total Hrs',
                                                style: pw.TextStyle(fontSize: 8,font:font,
                                                    fontWeight: pw.FontWeight.bold)),)
                                      ),

                                      pw.Container(
                                          padding: pw.EdgeInsets.all(8.0),
                                          child: pw.Center(
                                            child: pw.Text('',
                                                style: pw.TextStyle(fontSize: 8,font:font,
                                                    fontWeight: pw.FontWeight.bold)),)
                                      ),
                                      // Add more Text widgets for additional columns if needed
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
                                          pw.Text('${serialNumber++}',style: pw.TextStyle(fontSize: 8,font:font1)),
                                        ),
                                      ),
                                      pw.Container(
                                        padding: pw.EdgeInsets.all(8.0),
                                        child: pw.Center(
                                          child: pw.Text(data["inDate"] != null
                                              ? DateFormat('yyyy-MM-dd').format(
                                            DateTime.parse("${data["inDate"]}").toLocal(),)
                                              : "",
                                              style: pw.TextStyle(fontSize: 8,font:font1)),),
                                      ),
                                      pw.Container(
                                          padding: pw.EdgeInsets.all(8.0),
                                          child: pw.Center(
                                            child: pw.Text(data['emp_code'].toString(),
                                                style: pw.TextStyle(fontSize: 8,font:font1)),)
                                      ),
                                      pw.Container(
                                        padding: pw.EdgeInsets.all(8.0),
                                        child: pw.Center(
                                          child: pw.Text(data['first_name'].toString(),
                                              style: pw.TextStyle(fontSize: 8,font:font1)),),
                                      ),
                                      pw.Container(
                                        padding: pw.EdgeInsets.all(8.0),
                                        child: pw.Center(
                                          child: pw.Text(data['shiftType'].toString(),
                                              style: pw.TextStyle(fontSize: 8,font:font1)),),
                                      ),
                                      pw.Container(
                                        padding: pw.EdgeInsets.all(8.0),
                                        child: pw.Center(
                                          child: pw.Text(
                                            formatTime(data['check_in']),
                                            style: pw.TextStyle(fontSize: 8,font:font1),
                                          ),
                                        ),
                                      ),
                                      pw.Container(
                                        padding: pw.EdgeInsets.all(8.0),
                                        child: pw.Center(
                                          child: pw.Text(
                                            formatTimeOrZero(
                                              (data['shiftType'] == "General" && isBetweenLunchOutTime(data['lunch_out'], data['shiftType']))
                                                  ? "00:00:00"
                                                  : data['lunch_out'],
                                            ),
                                            style: pw.TextStyle(fontSize: 8, font: font1),
                                          ),
                                        ),
                                      ),
                                      pw.Container(
                                        padding: pw.EdgeInsets.all(8.0),
                                        child: pw.Center(
                                          child: pw.Text(
                                            formatTimeOrZero(data['lunch_in']),
                                            style: pw.TextStyle(fontSize: 8,font:font1),
                                          ),
                                        ),
                                      ),
                                      pw.Container(
                                        padding: pw.EdgeInsets.all(8.0),
                                        child: pw.Center(
                                          child: pw.Text(
                                            formatTime(
                                              (data['shiftType'] == "General" && isBetweenLunchOutTime(data['lunch_out'], data['shiftType']))
                                                  ? data['lunch_out']
                                                  : data['check_out'],
                                            ),
                                            style: pw.TextStyle(fontSize: 8, font: font1),
                                          ),
                                        ),
                                      ),
                                      pw.Container(
                                        padding: pw.EdgeInsets.all(8.0),
                                        child: pw.Center(
                                          child: pw.Text(
                                            formatDuration(data['act_time']),
                                            style: pw.TextStyle(fontSize: 8,font:font1),
                                          ),
                                        ),
                                      ),
                                      pw.Container(
                                        padding: pw.EdgeInsets.all(8.0),
                                        child: pw.Center(
                                          child: pw.Text(
                                            calculateRemarkForPDF(data),
                                            style: pw.TextStyle(fontSize: 8, font: font1),
                                          ),
                                        ),
                                      ),

                                    ]);
                                  }
                                  ).toList(),
                                ],
                              ),
                            ),    ),
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
                                //  borderRadius: pw.BorderRadius.circular(10.0), // Add border radius for rounded corners
                              ),
                              child:pw.Padding(
                                padding: const pw.EdgeInsets.only(left: 8.0), // Adjust the padding as needed
                                child:
                                pw.Column(
                                  children: [
                                    pw.Padding(
                                      padding: const pw.EdgeInsets.only(left: 8.0),
                                      child: pw.Text(
                                        "Present: ${widget.totalPresentDays} Days",
                                        style: pw.TextStyle(
                                          fontSize: 9,
                                          color: PdfColors.green,
                                        ),
                                      ),
                                    ),
                                    pw.Padding(
                                      padding: const pw.EdgeInsets.only(left: 8.0),
                                      child: pw.Text(
                                        "Absent: ${widget.totalAbsentDays} Days",
                                        style: pw.TextStyle(
                                          fontSize: 9,
                                          color: PdfColors.red,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          )
                        ]
                    ),

                  ),
                  pw.SizedBox(height:5),

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
      //return pdf.save() ?? Uint8List(0);
    }
    return pdf.save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Attendance PDF"), centerTitle: true,),
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

















