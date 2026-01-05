import 'dart:io';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../services/firebase_pdf_service.dart';
import '../../services/local_pdf_service.dart';

class PdfListItem {
  final String? firebaseUrl;
  final Reference? firebaseRef;
  final LocalPdfInfo? localPdf;
  final String fileName;
  final DateTime createdAt;
  final int fileSizeBytes;
  final bool isLocal;

  PdfListItem({
    this.firebaseUrl,
    this.firebaseRef,
    this.localPdf,
    required this.fileName,
    required this.createdAt,
    required this.fileSizeBytes,
    required this.isLocal,
  });

  String get filePath => isLocal ? localPdf!.filePath : '';
  String get url => isLocal ? localPdf!.filePath : (firebaseUrl ?? '');
}

class PdfListController extends GetxController {
  final FirebasePdfService _firebasePdfService = FirebasePdfService();
  final LocalPdfService _localPdfService = LocalPdfService();

  final RxList<PdfListItem> pdfFiles = <PdfListItem>[].obs;
  final RxBool isLoading = false.obs;
  final Rx<String?> errorMessage = Rx<String?>(null);
  final RxList<String> likedPdfs = <String>[].obs;
  final RxString selectedTab = 'recent'.obs;

  String get userId => FirebaseAuth.instance.currentUser!.uid;

  @override
  void onInit() {
    super.onInit();
    if (!Get.isRegistered<Map<String, dynamic>>(tag: 'liked_pdfs')) {
      Get.put<Map<String, dynamic>>(
        {'urls': <String>[]},
        tag: 'liked_pdfs',
        permanent: true,
      );
    }
    loadPdfs();
    loadLikedPdfs();
  }

  Future<void> loadPdfs() async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      final allPdfs = <PdfListItem>[];

      try {
        final firebaseFiles = await _firebasePdfService.listUserPdfs(userId);
        for (final ref in firebaseFiles) {
          try {
            final url = await ref.getDownloadURL();
            final metadata = await ref.getMetadata();
            allPdfs.add(PdfListItem(
              firebaseUrl: url,
              firebaseRef: ref,
              fileName: ref.name,
              createdAt: metadata.timeCreated ?? DateTime.now(),
              fileSizeBytes: metadata.size ?? 0,
              isLocal: false,
            ));
          } catch (e) {
            print("Skipping Firebase PDF: $e");
          }
        }
      } catch (e) {
        print("Error loading Firebase PDFs: $e");
      }

      try {
        final localPdfs = await _localPdfService.listLocalPdfs();
        for (final localPdf in localPdfs) {
          allPdfs.add(PdfListItem(
            localPdf: localPdf,
            fileName: localPdf.fileName,
            createdAt: localPdf.createdAt,
            fileSizeBytes: localPdf.fileSizeBytes,
            isLocal: true,
          ));
        }
      } catch (e) {
        print("Error loading local PDFs: $e");
      }

      allPdfs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      pdfFiles.assignAll(allPdfs);
    } catch (e) {
      errorMessage.value = e.toString();
      Get.snackbar("Error", "Failed to load PDFs: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshPdfs() async {
    await loadPdfs();
  }

  Future<String> getDownloadUrl(PdfListItem item) async {
    if (item.isLocal) {
      return item.localPdf!.filePath;
    } else {
      return item.firebaseUrl ?? await item.firebaseRef!.getDownloadURL();
    }
  }

  Future<void> deletePdf(PdfListItem item) async {
    try {
      if (item.isLocal) {
        await _localPdfService.deletePdf(item.localPdf!.filePath);
      } else {
        await item.firebaseRef!.delete();
      }
      Get.snackbar("Success", "PDF deleted successfully");
      await loadPdfs();
    } catch (e) {
      Get.snackbar("Error", "Failed to delete PDF: $e");
    }
  }

  void toggleLike(PdfListItem item) async {
    final identifier = item.isLocal ? item.localPdf!.filePath : (item.firebaseUrl ?? '');
    if (likedPdfs.contains(identifier)) {
      likedPdfs.remove(identifier);
    } else {
      likedPdfs.add(identifier);
    }
    saveLikedPdfs();
  }

  bool isLiked(PdfListItem item) {
    final identifier = item.isLocal ? item.localPdf!.filePath : (item.firebaseUrl ?? '');
    return likedPdfs.contains(identifier);
  }

  void loadLikedPdfs() {
    try {
      final stored = Get.find<Map<String, dynamic>>(tag: 'liked_pdfs');
      if (stored != null && stored['urls'] != null) {
        likedPdfs.assignAll(List<String>.from(stored['urls']));
      }
    } catch (e) {
      likedPdfs.clear();
    }
  }

  void saveLikedPdfs() {
    Get.put<Map<String, dynamic>>(
      {'urls': likedPdfs.toList()},
      tag: 'liked_pdfs',
      permanent: true,
    );
  }

  List<PdfListItem> get recentPdfs => pdfFiles.toList();

  List<PdfListItem> get likedPdfsList {
    return pdfFiles.where((item) => isLiked(item)).toList();
  }

  void setTab(String tab) {
    selectedTab.value = tab;
  }
}
