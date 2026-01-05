import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;

class FirebasePdfService {
  final FirebaseStorage storage;
  final FirebaseFirestore firestore;

  FirebasePdfService({
    FirebaseStorage? storage,
    FirebaseFirestore? firestore,
  })  : storage = storage ?? FirebaseStorage.instance,
        firestore = firestore ?? FirebaseFirestore.instance;

  /// Uploads a local PDF file to Firebase Storage and returns the download URL.
  ///
  /// If [userId] is provided, file is stored under: users/{userId}/signed_pdfs/
  /// Also writes a Firestore document to: users/{userId}/signed_pdfs (if userId != null)
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

    final ref = storage.ref().child("$basePath/$fileName");

    final uploadTask = ref.putFile(
      file,
      SettableMetadata(
        contentType: "application/pdf",
        customMetadata: {
          "createdAt": DateTime.now().toIso8601String(),
          if (userId != null) "userId": userId,
        },
      ),
    );

    final snap = await uploadTask;
    final url = await snap.ref.getDownloadURL();

    // Optional: store in Firestore
    if (userId != null) {
      await firestore
          .collection("users")
          .doc(userId)
          .collection("signed_pdfs")
          .add({
        "fileName": fileName,
        "storagePath": snap.ref.fullPath,
        "url": url,
        "createdAt": FieldValue.serverTimestamp(),
        if (extraMeta != null) ...extraMeta,
      });
    }

    return url;
  }
}
