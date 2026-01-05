import 'dart:io';
import 'dart:ui';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../domain/document_field.dart';

class PdfService {
  Future<String> generateFinalPdf({
    required String originalPdfPath,
    required List<DocumentField> fields,
  }) async {
    final inputBytes = await File(originalPdfPath).readAsBytes();
    final doc = PdfDocument(inputBytes: inputBytes);
    final page = doc.pages[0];
    final pageSize = page.getClientSize();

    for (final field in fields) {
      final json = field.toJson(pageW: pageSize.width, pageH: pageSize.height);
      final rect = Rect.fromLTWH(
        (json["x"] as num).toDouble(),
        (json["y"] as num).toDouble(),
        (json["width"] as num).toDouble(),
        (json["height"] as num).toDouble(),
      );

      switch (field.type) {
        case FieldType.text:
          _drawText(page, field.textValue ?? "", rect);
          break;
        case FieldType.date:
          if (field.dateValue != null) {
            _drawDate(page, field.dateValue!, rect);
          }
          break;
        case FieldType.checkbox:
          _drawCheckbox(page, field.boolValue ?? false, rect);
          break;
        case FieldType.signature:
          if (field.signaturePngBytes != null) {
            _drawSignature(page, field.signaturePngBytes!, rect);
          }
          break;
      }
    }

    final outBytes = await doc.save();
    doc.dispose();

    final dir = await getApplicationDocumentsDirectory();
    final outFile = File(
      "${dir.path}/final_${DateTime.now().millisecondsSinceEpoch}.pdf",
    );
    await outFile.writeAsBytes(outBytes, flush: true);
    return outFile.path;
  }

  void _drawText(PdfPage page, String text, Rect bounds) {
    final font = PdfStandardFont(PdfFontFamily.helvetica, 12);
    page.graphics.drawString(text.trim(), font, bounds: bounds);
  }

  void _drawDate(PdfPage page, DateTime date, Rect bounds) {
    final dateText =
        "${date.year.toString().padLeft(4, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.day.toString().padLeft(2, '0')}";
    final font = PdfStandardFont(PdfFontFamily.helvetica, 12);
    page.graphics.drawString(dateText, font, bounds: bounds);
  }

  void _drawCheckbox(PdfPage page, bool checked, Rect bounds) {
    final pen = PdfPen(PdfColor(0, 0, 0), width: 1);
    page.graphics.drawRectangle(pen: pen, bounds: bounds);

    if (checked) {
      final left = bounds.left;
      final top = bounds.top;
      final width = bounds.width;
      final height = bounds.height;

      page.graphics.drawLine(
        pen,
        Offset(left + width * 0.2, top + height * 0.55),
        Offset(left + width * 0.45, top + height * 0.8),
      );
      page.graphics.drawLine(
        pen,
        Offset(left + width * 0.45, top + height * 0.8),
        Offset(left + width * 0.85, top + height * 0.25),
      );
    }
  }

  void _drawSignature(PdfPage page, List<int> bytes, Rect bounds) {
    final bitmap = PdfBitmap(Uint8List.fromList(bytes));
    page.graphics.drawImage(bitmap, bounds);
  }
}
