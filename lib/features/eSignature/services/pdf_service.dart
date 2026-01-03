import 'dart:io';
import 'dart:ui';
import 'package:path/path.dart' as p;
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../domain/document_field.dart';

class PdfService {
  Future<String> generateFinalPdf({
    required String originalPdfPath,
    required List<DocumentField> fields,
  }) async {
    final bytes = await File(originalPdfPath).readAsBytes();
    final document = PdfDocument(inputBytes: bytes);

    // ✅ IMPORTANT:
    // Your editor currently stores normalized values relative to the editor viewport.
    // For correct stamping, we map them onto PDF page size (in points).
    // (This assumes page 1 only; extend by adding field.pageIndex later.)
    final page = document.pages[0];
    final size = page.getClientSize(); // PDF page width/height in points

    for (final f in fields) {
      final x = f.nx * size.width;
      final y = f.ny * size.height;
      final w = f.nw * size.width;
      final h = f.nh * size.height;

      switch (f.type) {
        case FieldType.text:
          page.graphics.drawString(
            f.textValue ?? "",
            PdfStandardFont(PdfFontFamily.helvetica, 12),
            bounds: Rect.fromLTWH(x, y, w, h),
          );
          break;

        case FieldType.checkbox:
          final symbol = (f.boolValue ?? false) ? "☑" : "☐";
          page.graphics.drawString(
            symbol,
            PdfStandardFont(PdfFontFamily.helvetica, 14),
            bounds: Rect.fromLTWH(x, y, w, h),
          );
          break;

        case FieldType.date:
          final dateText = f.dateValue == null
              ? ""
              : f.dateValue!.toIso8601String().split("T").first;
          page.graphics.drawString(
            dateText,
            PdfStandardFont(PdfFontFamily.helvetica, 12),
            bounds: Rect.fromLTWH(x, y, w, h),
          );
          break;

        case FieldType.signature:
        // For now, text placeholder. Next step: stamp PNG bytes.
          page.graphics.drawString(
            "SIGNED",
            PdfStandardFont(PdfFontFamily.helvetica, 12),
            bounds: Rect.fromLTWH(x, y, w, h),
          );
          break;
      }
    }

    final outBytes = document.saveSync();
    document.dispose();

    final outFile = File(
      p.join(
        Directory.systemTemp.path,
        "signed_${DateTime.now().millisecondsSinceEpoch}.pdf",
      ),
    );
    await outFile.writeAsBytes(outBytes);
    return outFile.path;
  }
}
