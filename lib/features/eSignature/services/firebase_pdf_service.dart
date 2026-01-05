import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;

class FirebasePdfService {
  final FirebaseStorage storage;

  FirebasePdfService({
    FirebaseStorage? storage,
  }) : storage = storage ?? FirebaseStorage.instance;

  Future<String> uploadFinalPdf({
    required String localPdfPath,
    required String fileNamePrefix,
    String? userId,
    Map<String, dynamic>? extraMeta,
  }) async {
    final file = File(localPdfPath);
    if (!await file.exists()) {
      throw Exception("File does not exist: $localPdfPath");
    }

    final originalName = p.basename(localPdfPath);
    final safeName = originalName.endsWith(".pdf") ? originalName : "$originalName.pdf";
    final ts = DateTime.now().toIso8601String().replaceAll(":", "-");
    final fileName = "${fileNamePrefix}_${ts}_$safeName";

    final basePath = userId == null
        ? "signed_pdfs"
        : "users/$userId/signed_pdfs";

    try {
      final ref = storage.ref().child("$basePath/$fileName");

      final uploadTask = ref.putFile(
        file,
        SettableMetadata(
          contentType: "application/pdf",
          customMetadata: {
            "createdAt": DateTime.now().toIso8601String(),
            if (userId != null) "userId": userId,
            if (extraMeta != null) ...extraMeta.map((key, value) => MapEntry(key, value.toString())),
          },
        ),
      );

      uploadTask.snapshotEvents.listen((taskSnapshot) {
        final progress = (taskSnapshot.bytesTransferred / taskSnapshot.totalBytes) * 100;
        print("Upload progress: ${progress.toStringAsFixed(1)}%");
      });

      final snap = await uploadTask;
      
      if (snap.state == TaskState.success) {
        final url = await snap.ref.getDownloadURL();
        print(" PDF uploaded to Storage successfully!");
        print("Storage path: ${snap.ref.fullPath}");
        print(" Download URL: $url");
        return url;
      } else {
        throw Exception("Upload failed with state: ${snap.state}");
      }
    } on FirebaseException catch (e) {
      String errorMessage = "Upload failed: ";
      switch (e.code) {
        case 'object-not-found':
          errorMessage += "Storage bucket not found. Please enable Firebase Storage in your Firebase Console.";
          break;
        case 'unauthorized':
          errorMessage += "Permission denied. Please check your Storage security rules.";
          break;
        case 'canceled':
          errorMessage += "Upload was canceled.";
          break;
        case 'unknown':
          errorMessage += "Unknown error occurred: ${e.message}";
          break;
        default:
          errorMessage += "${e.code}: ${e.message ?? 'Unknown error'}";
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception("Failed to upload PDF: ${e.toString()}");
    }
  }

  Future<void> deletePdf(String storagePath) async {
    try {
      await storage.ref(storagePath).delete();
      print(" File deleted from Storage: $storagePath");
    } catch (e) {
      print(" Error deleting from Storage: $e");
      rethrow;
    }
  }

  // /// Deletes a PDF file from Storage using its download URL
  // Future<void> deletePdfByUrl(String url) async {
  //   try {
  //     final ref = storage.refFromURL(url);
  //     await ref.delete();
  //     print("✅ File deleted from Storage using URL");
  //   } catch (e) {
  //     print("❌ Error deleting from Storage: $e");
  //     rethrow;
  //   }
  // }

  // Future<File> downloadPdf(String url, String localPath) async {
  //   try {
  //     final ref = storage.refFromURL(url);
  //     final file = File(localPath);
  //     await ref.writeToFile(file);
  //     print("✅ PDF downloaded to: $localPath");
  //     return file;
  //   } catch (e) {
  //     print("❌ Error downloading PDF: $e");
  //     rethrow;
  //   }
  // }

  Future<List<Reference>> listUserPdfs(String userId) async {
    try {
      final listResult = await storage.ref("users/$userId/signed_pdfs").listAll();
      return listResult.items;
    } catch (e) {
      print(" Error listing files: $e");
      rethrow;
    }
  }
}
