import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../auth/data/auth_service.dart';
import '../data/file_service.dart';
import 'editor_page.dart';

class UploadPage extends StatelessWidget {
  const UploadPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthService>();
    final fileService = FileService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Upload Document"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => auth.signOut(),
          ),
        ],
      ),
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.upload_file),
          label: const Text("Pick PDF/DOCX"),
          onPressed: () async {
            final file = await fileService.pickDocument();
            if (file == null) return;

            if (!file.path.toLowerCase().endsWith('.pdf')) {
              Get.snackbar("DOCX not supported yet",
                  "Convert DOCX to PDF first (for now).");
              return;
            }
            Get.to(() => EditorPage(pdfPath: file.path));
          },
        ),
      ),
    );
  }
}
