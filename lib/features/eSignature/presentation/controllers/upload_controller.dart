import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../auth/data/auth_service.dart';
import '../../data/file_service.dart';
import '../../services/docx_converter_service.dart';
import '../../services/local_pdf_service.dart';
import '../editor_page.dart';

class UploadController extends GetxController {
  final AuthService authService = Get.find<AuthService>();
  final FileService fileService = FileService();
  // final DocxConverterService docxConverter = DocxConverterService();
  final LocalPdfService localPdfService = LocalPdfService();

  final RxBool isConverting = false.obs;

  Future<void> pickAndOpenDocument() async {
    final file = await fileService.pickDocument();
    if (file == null) return;

    final filePath = file.path.toLowerCase();

    if (filePath.endsWith('.pdf')) {
      Get.to(() => EditorPage(pdfPath: file.path));
    } else if (filePath.endsWith('.docx')) {
      // await _handleDocxFile(file.path);
    } else {
      Get.snackbar(
        "Unsupported File",
        "Please select a PDF or DOCX file.",
      );
    }
  }

  // Future<void> _handleDocxFile(String docxPath) async {
  //   final shouldConvert = await Get.dialog<bool>(
  //     AlertDialog(
  //       title: const Text("DOCX File Detected"),
  //       content: const Text(
  //         "DOCX files need to be converted to PDF for editing.\n\n"
  //         "Options:\n"
  //         "• Convert now (creates a placeholder PDF)\n"
  //         "• Cancel and convert manually\n\n"
  //         "For best results, convert DOCX to PDF using:\n"
  //         "• Microsoft Word\n"
  //         "• Google Docs\n"
  //         "• Online converters",
  //       ),
  //       shape: RoundedRectangleBorder(
  //         borderRadius: BorderRadius.circular(16),
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Get.back(result: false),
  //           child: const Text("Cancel"),
  //         ),
  //         TextButton(
  //           onPressed: () => Get.back(result: true),
  //           child: const Text("Convert Now"),
  //         ),
  //       ],
  //     ),
  //   );
  //
  //   if (shouldConvert != true) return;
  //
  //   isConverting.value = true;
  //   try {
  //     final pdfPath = await docxConverter.convertDocxViaPrinting(docxPath);
  //     if (pdfPath == null) return;
  //
  //     final savedPath = await localPdfService.savePdf(
  //       sourcePath: pdfPath,
  //       customFileName: "${DateTime.now().millisecondsSinceEpoch}_converted.pdf",
  //     );
  //
  //     Get.snackbar(
  //       "Conversion Complete",
  //       "DOCX converted to PDF and saved locally. You can now edit it.",
  //       duration: const Duration(seconds: 3),
  //     );
  //     Get.to(() => EditorPage(pdfPath: savedPath));
  //   } catch (e) {
  //     Get.snackbar(
  //       "Conversion Failed",
  //       e.toString(),
  //       duration: const Duration(seconds: 4),
  //     );
  //   } finally {
  //     isConverting.value = false;
  //   }
  // }

  Future<void> signOut() async {
    await authService.signOut();
  }
}
