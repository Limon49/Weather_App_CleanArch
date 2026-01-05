import 'dart:io';
import 'dart:ui';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path/path.dart' as p;

// class DocxConverterService {
//   /// Converts DOCX file to PDF
//   /// Note: This is a simplified conversion. For full DOCX support,
//   /// you may need to use platform channels or cloud services.
//   Future<String?> convertDocxToPdf(String docxPath) async {
//     try {
//       // Read the DOCX file
//       final docxFile = File(docxPath);
//       if (!await docxFile.exists()) {
//         throw Exception("DOCX file does not exist");
//       }
//
//       // For now, we'll create a simple PDF with a message
//       // Full DOCX parsing requires additional packages like 'docx' or platform-specific code
//       final pdfDoc = PdfDocument();
//       final page = pdfDoc.pages.add();
//       final graphics = page.graphics;
//
//       // Add a note that this is a converted document
//       final font = PdfStandardFont(PdfFontFamily.helvetica, 16);
//       final brush = PdfSolidBrush(PdfColor(0, 0, 0));
//
//       graphics.drawString(
//         "Document converted from DOCX",
//         font,
//         brush: brush,
//         bounds: const Rect.fromLTWH(50, 50, 500, 50),
//       );
//
//       graphics.drawString(
//         "Note: Full DOCX content conversion requires additional setup.",
//         PdfStandardFont(PdfFontFamily.helvetica, 12),
//         brush: brush,
//         bounds: const Rect.fromLTWH(50, 100, 500, 50),
//       );
//
//       graphics.drawString(
//         "For best results, please convert DOCX to PDF using:",
//         PdfStandardFont(PdfFontFamily.helvetica, 12),
//         brush: brush,
//         bounds: const Rect.fromLTWH(50, 150, 500, 50),
//       );
//
//       graphics.drawString(
//         "• Microsoft Word (Save As PDF)\n• Google Docs (Download as PDF)\n• Online converters",
//         PdfStandardFont(PdfFontFamily.helvetica, 11),
//         brush: brush,
//         bounds: const Rect.fromLTWH(50, 200, 500, 200),
//       );
//
//       // Save PDF
//       final dir = await getApplicationDocumentsDirectory();
//       final fileName = p.basenameWithoutExtension(docxPath);
//       final pdfPath = "${dir.path}/${fileName}_converted_${DateTime.now().millisecondsSinceEpoch}.pdf";
//
//       final pdfBytes = await pdfDoc.save();
//       await File(pdfPath).writeAsBytes(pdfBytes);
//       pdfDoc.dispose();
//
//       return pdfPath;
//     } catch (e) {
//       throw Exception("Failed to convert DOCX: $e");
//     }
//   }
//
//   /// Alternative: Use printing package to share/print DOCX as PDF
//   Future<String?> convertDocxViaPrinting(String docxPath) async {
//     try {
//       // This method uses the printing package to create a PDF
//       // Note: This requires the document to be readable by the printing package
//       final docxFile = File(docxPath);
//       final bytes = await docxFile.readAsBytes();
//
//       // Create a simple PDF document
//       final pdfDoc = PdfDocument();
//       final page = pdfDoc.pages.add();
//       final graphics = page.graphics;
//
//       final font = PdfStandardFont(PdfFontFamily.helvetica, 14);
//       final brush = PdfSolidBrush(PdfColor(0, 0, 0));
//
//       graphics.drawString(
//         "DOCX File: ${p.basename(docxPath)}",
//         font,
//         brush: brush,
//         bounds: const Rect.fromLTWH(50, 50, 500, 30),
//       );
//
//       graphics.drawString(
//         "This DOCX file needs to be converted to PDF.",
//         PdfStandardFont(PdfFontFamily.helvetica, 12),
//         brush: brush,
//         bounds: const Rect.fromLTWH(50, 100, 500, 30),
//       );
//
//       graphics.drawString(
//         "Please use an online converter or Microsoft Word to convert this file to PDF first.",
//         PdfStandardFont(PdfFontFamily.helvetica, 11),
//         brush: brush,
//         bounds: const Rect.fromLTWH(50, 150, 500, 100),
//       );
//
//       // Save PDF
//       final dir = await getApplicationDocumentsDirectory();
//       final fileName = p.basenameWithoutExtension(docxPath);
//       final pdfPath = "${dir.path}/${fileName}_converted_${DateTime.now().millisecondsSinceEpoch}.pdf";
//
//       final pdfBytes = await pdfDoc.save();
//       await File(pdfPath).writeAsBytes(pdfBytes);
//       pdfDoc.dispose();
//
//       return pdfPath;
//     } catch (e) {
//       throw Exception("Failed to convert DOCX: $e");
//     }
//   }
// }

