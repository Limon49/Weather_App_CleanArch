import 'package:get/get.dart';
import '../../services/firebase_pdf_service.dart';

class PreviewController extends GetxController {
  final String pdfPath;
  final String originalPdfPath;
  final int fieldCount;
  final String? userId;

  final FirebasePdfService _firebasePdfService = FirebasePdfService();
  
  final RxBool isUploading = false.obs;
  final RxBool isUploaded = false.obs;
  final Rx<String?> downloadUrl = Rx<String?>(null);

  PreviewController({
    required this.pdfPath,
    required this.originalPdfPath,
    required this.fieldCount,
    this.userId,
  });

  Future<void> saveToFirebase() async {
    if (isUploading.value || isUploaded.value || userId == null) return;

    isUploading.value = true;

    try {
      final url = await _firebasePdfService.uploadFinalPdf(
        localPdfPath: pdfPath,
        fileNamePrefix: "signed_document",
        userId: userId!,
        extraMeta: {
          "originalPdfPath": originalPdfPath,
          "fieldCount": fieldCount,
        },
      );

      isUploaded.value = true;
      downloadUrl.value = url;
      isUploading.value = false;

      Get.snackbar(
        "Success",
        "PDF saved to Firebase!",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.primaryContainer,
        colorText: Get.theme.colorScheme.onPrimaryContainer,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      isUploading.value = false;
      Get.snackbar(
        "Upload Failed",
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.errorContainer,
        colorText: Get.theme.colorScheme.onErrorContainer,
        duration: const Duration(seconds: 4),
      );
    }
  }
}

