

import 'package:pdf/widgets.dart' as pw;

Future<void> examplepdf() async {

  final pdf = pw.Document();

  // Define the layout for the original copy
  final originalPage = pw.Page(
    build: (pw.Context context) {
      return pw.Container(
        // Add your original copy content here

      );
    },
  );

  // Define the layout for the duplicate copy
  final duplicatePage = pw.Page(
    build: (pw.Context context) {
      return pw.Container(
        // Add your duplicate copy content here
        child: pw.Text('Duplicate Invoice'),
      );
    },
  );

  // Define the layout for the triplicate copy
  final triplicatePage = pw.Page(
    build: (pw.Context context) {
      return pw.Container(
        // Add your triplicate copy content here
        child: pw.Text('Triplicate Invoice'),
      );
    },
  );

  // Add the pages to the PDF document
  pdf.addPage(originalPage);


  // Save the PDF document

}

// Call the function to create the invoice PDF
