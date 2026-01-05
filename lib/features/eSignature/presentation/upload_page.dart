import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controllers/upload_controller.dart';

class UploadPage extends GetView<UploadController> {
  const UploadPage({super.key});

  @override
  UploadController get controller => Get.put(UploadController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Upload Document"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: controller.signOut,
          ),
        ],
      ),
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.upload_file),
          label: const Text("Pick PDF/DOCX"),
          onPressed: controller.pickAndOpenDocument,
        ),
      ),
    );
  }
}
