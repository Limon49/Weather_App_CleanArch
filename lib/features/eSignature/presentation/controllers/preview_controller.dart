import 'package:get/get.dart';
import '../../services/firebase_pdf_service.dart';
import '../../services/local_pdf_service.dart';
import 'pdf_list_controller.dart';
import 'navigation_controller.dart';

class PreviewController extends GetxController {
  final String pdfPath;
  final String originalPdfPath;
  final int fieldCount;
  final String? userId;

  final FirebasePdfService _firebasePdfService = FirebasePdfService();
  final LocalPdfService _localPdfService = LocalPdfService();

  final RxBool isUploading = false.obs;
  final RxBool isUploaded = false.obs;
  final RxBool isSavingLocally = false.obs;
  final RxBool isSavedLocally = false.obs;
  final Rx<String?> downloadUrl = Rx<String?>(null);
  final Rx<String?> localPdfPath = Rx<String?>(null);

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

      downloadUrl.value = url;
      isUploaded.value = true;
      Get.snackbar(
        "Success",
        "PDF saved to Firebase Storage!",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.primaryContainer,
        colorText: Get.theme.colorScheme.onPrimaryContainer,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      Get.snackbar(
        "Upload Failed",
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.errorContainer,
        colorText: Get.theme.colorScheme.onErrorContainer,
        duration: const Duration(seconds: 4),
      );
    } finally {
      isUploading.value = false;
    }
  }

  Future<void> saveLocally() async {
    if (isSavingLocally.value || isSavedLocally.value) return;

    isSavingLocally.value = true;
    try {
      final savedPath = await _localPdfService.savePdf(
        sourcePath: pdfPath,
        customFileName: "signed_document_${DateTime.now().millisecondsSinceEpoch}.pdf",
      );

      localPdfPath.value = savedPath;
      isSavedLocally.value = true;
      
      Get.snackbar(
        "Success",
        "PDF saved locally! Navigating to PDF list...",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.primaryContainer,
        colorText: Get.theme.colorScheme.onPrimaryContainer,
        duration: const Duration(seconds: 2),
      );

      await Future.delayed(const Duration(milliseconds: 500));
      
      Get.until((route) => route.isFirst);
      
      try {
        final pdfListController = Get.find<PdfListController>();
        await pdfListController.refreshPdfs();
      } catch (e) {
        final pdfListController = Get.put(PdfListController());
        await pdfListController.refreshPdfs();
      }
      
      try {
        final navController = Get.find<NavigationController>();
        navController.setTab(0);
      } catch (e) {
        final navController = Get.put(NavigationController());
        navController.setTab(0);
      }
    } catch (e) {
      Get.snackbar(
        "Save Failed",
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.errorContainer,
        colorText: Get.theme.colorScheme.onErrorContainer,
        duration: const Duration(seconds: 4),
      );
    } finally {
      isSavingLocally.value = false;
    }
  }
}
