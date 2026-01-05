import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:get/get.dart';
import 'controllers/preview_controller.dart';

class PreviewPage extends GetView<PreviewController> {
  final String pdfPath;
  final String originalPdfPath;
  final int fieldCount;
  final String? userId;

  const PreviewPage({
    super.key,
    required this.pdfPath,
    required this.originalPdfPath,
    required this.fieldCount,
    this.userId,
  });

  @override
  PreviewController get controller => Get.put(PreviewController(
        pdfPath: pdfPath,
        originalPdfPath: originalPdfPath,
        fieldCount: fieldCount,
        userId: userId,
      ));

  @override
  Widget build(BuildContext context) {
    final pdfController = PdfControllerPinch(
      document: PdfDocument.openFile(pdfPath),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("PDF Preview"),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
              ),
              child: PdfViewPinch(controller: pdfController),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Obx(() => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: controller.isSavingLocally.value ||
                              controller.isSavedLocally.value
                          ? null
                          : controller.saveLocally,
                      icon: controller.isSavingLocally.value
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : controller.isSavedLocally.value
                              ? const Icon(Icons.check_circle)
                              : const Icon(Icons.save),
                      label: Text(
                        controller.isSavingLocally.value
                            ? "Saving..."
                            : controller.isSavedLocally.value
                                ? "Saved Locally"
                                : "Save Locally",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: controller.isSavedLocally.value
                            ? Colors.green
                            : Get.theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  if (userId != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: controller.isUploading.value ||
                                controller.isUploaded.value
                            ? null
                            : controller.saveToFirebase,
                        icon: controller.isUploading.value
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : controller.isUploaded.value
                                ? const Icon(Icons.check_circle)
                                : const Icon(Icons.cloud_upload),
                        label: Text(
                          controller.isUploading.value
                              ? "Uploading..."
                              : controller.isUploaded.value
                                  ? "Saved to Firebase"
                                  : "Save to Firebase",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: controller.isUploaded.value
                              ? Colors.green
                              : Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ],
              )),
            ),
          ),
        ],
      ),
    );
  }
}
