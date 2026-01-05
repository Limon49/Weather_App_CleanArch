import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class LocalPdfInfo {
  final String filePath;
  final String fileName;
  final DateTime createdAt;
  final int fileSizeBytes;
  final bool isLocal;

  LocalPdfInfo({
    required this.filePath,
    required this.fileName,
    required this.createdAt,
    required this.fileSizeBytes,
    this.isLocal = true,
  });
}

class LocalPdfService {
  static const String _localPdfsFolder = 'local_pdfs';

  Future<Directory> _getLocalPdfsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final localPdfsDir = Directory('${appDir.path}/$_localPdfsFolder');
    if (!await localPdfsDir.exists()) {
      await localPdfsDir.create(recursive: true);
    }
    return localPdfsDir;
  }

  Future<String> savePdf({
    required String sourcePath,
    String? customFileName,
  }) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw Exception("Source file does not exist: $sourcePath");
    }

    final localPdfsDir = await _getLocalPdfsDirectory();
    final fileName = customFileName ?? 
        "${p.basenameWithoutExtension(sourcePath)}_${DateTime.now().millisecondsSinceEpoch}.pdf";
    final destPath = '${localPdfsDir.path}/$fileName';
    
    await sourceFile.copy(destPath);
    return destPath;
  }

  Future<List<LocalPdfInfo>> listLocalPdfs() async {
    try {
      final localPdfsDir = await _getLocalPdfsDirectory();
      if (!await localPdfsDir.exists()) {
        return [];
      }

      final files = localPdfsDir.listSync()
          .whereType<File>()
          .where((file) => file.path.toLowerCase().endsWith('.pdf'))
          .toList();

      final pdfInfos = <LocalPdfInfo>[];
      
      for (final file in files) {
        final stat = await file.stat();
        pdfInfos.add(LocalPdfInfo(
          filePath: file.path,
          fileName: p.basename(file.path),
          createdAt: stat.modified,
          fileSizeBytes: stat.size,
        ));
      }
      pdfInfos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return pdfInfos;
    } catch (e) {
      throw Exception("Failed to list local PDFs: $e");
    }
  }

  Future<void> deletePdf(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw Exception("Failed to delete local PDF: $e");
    }
  }

  Future<LocalPdfInfo?> getPdfInfo(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return null;
      }
      
      final stat = await file.stat();
      return LocalPdfInfo(
        filePath: file.path,
        fileName: p.basename(file.path),
        createdAt: stat.modified,
        fileSizeBytes: stat.size,
      );
    } catch (e) {
      return null;
    }
  }
}

