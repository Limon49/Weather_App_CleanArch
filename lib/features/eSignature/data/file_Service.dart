import 'dart:io';
import 'package:file_picker/file_picker.dart';

class FileService {
  Future<File?> pickDocument() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx'],
    );
    if (res == null || res.files.single.path == null) return null;
    return File(res.files.single.path!);
  }
}
