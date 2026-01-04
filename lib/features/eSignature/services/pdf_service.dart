import 'dart:io';
import 'dart:ui';
import 'package:path/path.dart' as p;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../domain/document_field.dart';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';


class PdfService {
  Future<String> generateFinalPdf({
    required String originalPdfPath,
    required List<DocumentField> fields,
  }) async {
    final inputBytes = await File(originalPdfPath).readAsBytes();
    final doc = PdfDocument(inputBytes: inputBytes);

    // ✅ For now: assumes all fields are for page 0
    // If you need multi-page later, add pageIndex to DocumentField.
    final page = doc.pages[0];
    final s = page.getClientSize(); // PDF points

    for (final f in fields) {
      final j = f.toJson(pageW: s.width, pageH: s.height);

      final rect = Rect.fromLTWH(
        (j["x"] as num).toDouble(),
        (j["y"] as num).toDouble(),
        (j["width"] as num).toDouble(),
        (j["height"] as num).toDouble(),
      );

      switch (f.type) {
        case FieldType.text:
          final txt = (f.textValue ?? "").trim();
          final font = PdfStandardFont(PdfFontFamily.helvetica, 12);
          page.graphics.drawString(txt, font, bounds: rect);
          break;

        case FieldType.date:
          final d = f.dateValue!;
          final txt =
              "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
          final font = PdfStandardFont(PdfFontFamily.helvetica, 12);
          page.graphics.drawString(txt, font, bounds: rect);
          break;

        case FieldType.checkbox:
          final checked = f.boolValue ?? false;
          final pen = PdfPen(PdfColor(0, 0, 0), width: 1);
          page.graphics.drawRectangle(pen: pen, bounds: rect);

          if (checked) {
            page.graphics.drawLine(
              pen,
              Offset(rect.left + rect.width * 0.2, rect.top + rect.height * 0.55),
              Offset(rect.left + rect.width * 0.45, rect.top + rect.height * 0.8),
            );
            page.graphics.drawLine(
              pen,
              Offset(rect.left + rect.width * 0.45, rect.top + rect.height * 0.8),
              Offset(rect.left + rect.width * 0.85, rect.top + rect.height * 0.25),
            );
          }
          break;

        case FieldType.signature:
          final bytes = f.signaturePngBytes!;
          final bitmap = PdfBitmap(Uint8List.fromList(bytes));
          page.graphics.drawImage(bitmap, rect);
          break;
      }
    }

    final outBytes = await doc.save();
    doc.dispose();

    final dir = await getApplicationDocumentsDirectory();
    final outFile = File("${dir.path}/final_${DateTime.now().millisecondsSinceEpoch}.pdf");
    await outFile.writeAsBytes(outBytes, flush: true);
    return outFile.path;
  }
}

