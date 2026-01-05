import 'package:get/get.dart';
import '../../../auth/data/auth_service.dart';
import '../../data/file_service.dart';
import '../editor_page.dart';

class UploadController extends GetxController {
  final AuthService authService = Get.find<AuthService>();
  final FileService fileService = FileService();

  Future<void> pickAndOpenDocument() async {
    final file = await fileService.pickDocument();
    if (file == null) return;

    if (!file.path.toLowerCase().endsWith('.pdf')) {
      Get.snackbar(
        "DOCX not supported yet",
        "Convert DOCX to PDF first (for now).",
      );
      return;
    }

    Get.to(() => EditorPage(pdfPath: file.path));
  }

  Future<void> signOut() async {
    await authService.signOut();
  }
}

