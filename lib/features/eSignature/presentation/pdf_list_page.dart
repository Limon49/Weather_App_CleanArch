import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'controllers/pdf_list_controller.dart';
import 'editor_page.dart';

class PdfListPage extends GetView<PdfListController> {
  const PdfListPage({super.key});

  @override
  PdfListController get controller => Get.put(PdfListController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Get.theme.colorScheme.primary,
              Get.theme.colorScheme.primaryContainer,
              Get.theme.colorScheme.secondaryContainer,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "My PDFs",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        onPressed: controller.refreshPdfs,
                        tooltip: "Refresh",
                      ),
                    ),
                  ],
                ),
              ),
              Obx(() => Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTabButton(
                        'Recent',
                        'recent',
                        controller.selectedTab.value == 'recent',
                        Icons.access_time,
                      ),
                    ),
                    Expanded(
                      child: _buildTabButton(
                        'Liked',
                        'liked',
                        controller.selectedTab.value == 'liked',
                        Icons.favorite,
                      ),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 16),
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value && controller.pdfFiles.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }

                  final errorMsg = controller.errorMessage.value;
                  if (errorMsg != null && controller.pdfFiles.isEmpty) {
                    return _buildErrorState(errorMsg);
                  }

                  if (controller.selectedTab.value == 'recent') {
                    return _buildRecentList();
                  } else {
                    return _buildLikedList();
                  }
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, String value, bool isSelected, IconData icon) {
    return InkWell(
      onTap: () => controller.setTab(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Get.theme.colorScheme.primary : Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Get.theme.colorScheme.primary : Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String errorMsg) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              errorMsg,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: controller.loadPdfs,
              style: ElevatedButton.styleFrom(
                backgroundColor: Get.theme.colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentList() {
    return Obx(() {
      if (controller.recentPdfs.isEmpty) {
        return _buildEmptyState(
          icon: Icons.description_outlined,
          title: "No PDFs yet",
          subtitle: "Upload a PDF to get started",
        );
      }

      return RefreshIndicator(
        onRefresh: controller.refreshPdfs,
        child: ListView.builder(
          itemCount: controller.recentPdfs.length,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemBuilder: (context, index) {
            final item = controller.recentPdfs[index];
            return _buildPdfCard(item);
          },
        ),
      );
    });
  }

  Widget _buildLikedList() {
    return Obx(() {
      final likedPdfs = controller.likedPdfsList;

      if (likedPdfs.isEmpty) {
        return _buildEmptyState(
          icon: Icons.favorite_border,
          title: "No liked PDFs",
          subtitle: "Like PDFs to see them here",
        );
      }

      return ListView.builder(
        itemCount: likedPdfs.length,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemBuilder: (context, index) {
          final item = likedPdfs[index];
          return _buildPdfCard(item);
        },
      );
    });
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPdfCard(PdfListItem item) {
    final isLiked = controller.isLiked(item);
    final isLocal = item.isLocal;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Get.theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              Icon(
                Icons.picture_as_pdf,
                color: Get.theme.colorScheme.primary,
                size: 28,
              ),
              if (isLocal)
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.phone_android,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
        title: Text(
          item.fileName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isLocal ? Icons.phone_android : Icons.cloud,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isLocal ? "Local" : "Cloud",
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _formatFileSize(item.fileSizeBytes),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
        trailing: Builder(
          builder: (popupContext) => PopupMenuButton(
            icon: Icon(Icons.more_vert, color: Colors.grey[700]),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'open',
                child: const Row(
                  children: [
                    Icon(Icons.open_in_new, size: 20),
                    SizedBox(width: 8),
                    Text("Open"),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'edit',
                enabled: isLocal,
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20, color: isLocal ? null : Colors.grey),
                    const SizedBox(width: 8),
                    Text("Edit", style: TextStyle(color: isLocal ? null : Colors.grey)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'like',
                child: Row(
                  children: [
                    Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      size: 20,
                      color: isLiked ? Colors.red : null,
                    ),
                    const SizedBox(width: 8),
                    Text(isLiked ? "Unlike" : "Like"),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text("Delete", style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) async {
              switch (value) {
                case 'open':
                  await _openPdf(item);
                  break;
                case 'edit':
                  if (isLocal) {
                    Get.to(() => EditorPage(pdfPath: item.localPdf!.filePath));
                  }
                  break;
                case 'like':
                  controller.toggleLike(item);
                  break;
                case 'delete':
                  _showDeleteDialog(popupContext, item);
                  break;
              }
            },
          ),
        ),
        onTap: () => _openPdf(item),
      ),
    );
  }

  Future<void> _openPdf(PdfListItem item) async {
    if (item.isLocal) {
      Get.to(() => EditorPage(pdfPath: item.localPdf!.filePath));
    } else {
      final url = item.firebaseUrl ?? '';
      if (url.isNotEmpty && await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return "$bytes B";
    if (bytes < 1024 * 1024) return "${(bytes / 1024).toStringAsFixed(1)} KB";
    return "${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB";
  }

  void _showDeleteDialog(BuildContext context, PdfListItem item) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text("Delete PDF"),
        content: Text("Are you sure you want to delete ${item.fileName}?"),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              controller.deletePdf(item);
              Get.back();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}
