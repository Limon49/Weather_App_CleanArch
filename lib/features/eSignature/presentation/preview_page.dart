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
        title: const Text("Final PDF Preview"),
        actions: [
          Obx(() => controller.isUploaded.value
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Icon(Icons.check_circle, color: Colors.green),
                )
              : const SizedBox.shrink()),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PdfViewPinch(controller: pdfController),
          ),
          if (userId != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Obx(() => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: controller.isUploading.value || controller.isUploaded.value
                        ? null
                        : controller.saveToFirebase,
                    icon: controller.isUploading.value
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: controller.isUploaded.value ? Colors.green : null,
                      foregroundColor: controller.isUploaded.value ? Colors.white : null,
                    ),
                  ),
                )),
              ),
            ),
        ],
      ),
    );
  }
}
