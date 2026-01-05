import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdfx/pdfx.dart';
import '../domain/document_field.dart';
import 'field_editor_sheet.dart';
import 'controllers/editor_controller.dart';

class EditorPage extends GetView<EditorController> {
  final String pdfPath;

  const EditorPage({super.key, required this.pdfPath});

  @override
  EditorController get controller => Get.put(EditorController(pdfPath: pdfPath));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Document Editor"),
        elevation: 0,
        actions: [
          Obx(() {
            final selectedId = controller.selectedId.value;
            return IconButton(
            icon: Icon(
                Icons.delete_outline,
                color: selectedId != null && !controller.published.value
                    ? Colors.red
                    : Colors.grey,
              ),
              onPressed: (controller.published.value || selectedId == null)
                  ? null
                  : () => controller.deleteField(selectedId),
              tooltip: "Delete Field",
            );
          }),
          Obx(() => Container(
            margin: const EdgeInsets.only(right: 8),
            child: ElevatedButton.icon(
              icon: controller.generating.value
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.picture_as_pdf, size: 18),
              label: Text(
                controller.generating.value ? "Generating..." : "Generate",
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              onPressed: controller.generating.value
                ? null
                  : controller.generateFinalPdf,
              style: ElevatedButton.styleFrom(
                backgroundColor: Get.theme.colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          )),
        ],
      ),
      body: Column(
        children: [
          Obx(() => controller.published.value
              ? Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.orange.withOpacity(0.1),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock, color: Colors.orange[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        "Fields are locked",
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              : Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                        _buildToolButton(
                          icon: Icons.edit,
                          label: "Signature",
                          onTap: () => controller.addField(FieldType.signature),
                        ),
                        _buildToolButton(
                          icon: Icons.text_fields,
                          label: "Text",
                          onTap: () => controller.addField(FieldType.text),
                        ),
                        _buildToolButton(
                          icon: Icons.check_box,
                          label: "Checkbox",
                          onTap: () => controller.addField(FieldType.checkbox),
                        ),
                        _buildToolButton(
                          icon: Icons.calendar_today,
                          label: "Date",
                          onTap: () => controller.addField(FieldType.date),
                        ),
                        _buildToolButton(
                          icon: Icons.download,
                          label: "Export",
                          onTap: controller.exportJson,
                        ),
                        _buildToolButton(
                          icon: Icons.upload,
                          label: "Import",
                          onTap: controller.showImportJsonDialog,
                        ),
                        Obx(() => _buildToolButton(
                          icon: controller.published.value
                              ? Icons.lock_open
                              : Icons.lock,
                          label: controller.published.value ? "Unlock" : "Lock",
                          onTap: controller.togglePublished,
                        )),
                ],
              ),
            ),
                )),
          Expanded(
            child: Container(
              color: Colors.grey[200],
            child: LayoutBuilder(
              builder: (_, constraints) {
                  controller.updatePageSize(
                    Size(constraints.maxWidth, constraints.maxHeight),
                  );

                return Stack(
                  children: [
                      PdfViewPinch(controller: controller.pdfController),
                      Obx(() => RepaintBoundary(
                        child: IgnorePointer(
                        ignoring: false,
                        child: Stack(
                            children: controller.fields
                                .map((f) => _buildFieldWidget(f, context))
                                .toList(),
                          ),
                        ),
                      )),
                  ],
                );
              },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 18),
        label: Text(label),
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Get.theme.colorScheme.primaryContainer,
          foregroundColor: Get.theme.colorScheme.onPrimaryContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
    );
  }

  Widget _buildFieldWidget(DocumentField f, BuildContext context) {
    return Obx(() {
      final pageSize = controller.pageSize.value;
      final selectedId = controller.selectedId.value;
    final selected = selectedId == f.id;
      final isPublished = controller.published.value;
      final isMoving = controller.isFieldMoving(f.id);

      return _FieldWidget(
        key: ValueKey('${f.id}_${f.nx}_${f.ny}_${f.nw}_${f.nh}'),
        field: f,
        pageSize: pageSize,
        selected: selected,
        isPublished: isPublished,
        isMoving: isMoving,
        controller: controller,
        onTap: () async {
          controller.selectField(f.id);
          await _openFieldEditorSheet(f, context);
        },
      );
    });
  }

  Future<void> _openFieldEditorSheet(DocumentField f, BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: FieldEditorSheet(
          field: f,
          onDelete: controller.published.value
              ? null
              : () {
                  controller.deleteField(f.id);
                  Navigator.pop(context);
                },
        ),
      ),
    );
  }
}

class _FieldWidget extends StatelessWidget {
  final DocumentField field;
  final Size pageSize;
  final bool selected;
  final bool isPublished;
  final bool isMoving;
  final EditorController controller;
  final VoidCallback onTap;

  const _FieldWidget({
    super.key,
    required this.field,
    required this.pageSize,
    required this.selected,
    required this.isPublished,
    required this.isMoving,
    required this.controller,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final left = field.nx * pageSize.width;
    final top = field.ny * pageSize.height;
    final w = max(30.0, field.nw * pageSize.width);
    final h = max(24.0, field.nh * pageSize.height);

    return Positioned(
      left: left,
      top: top,
      child: RepaintBoundary(
      child: GestureDetector(
          onTap: onTap,
          onPanStart: isPublished
              ? null
              : (_) {
                  controller.selectField(field.id);
                },
          onPanUpdate: isPublished
            ? null
            : (d) {
                  controller.moveField(field, d.delta.dx, d.delta.dy);
                },
          onPanEnd: isPublished
              ? null
              : (_) {
                  controller.fields.refresh();
                },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: w,
                height: h,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(
                    width: selected ? 3 : 2,
                    color: selected
                        ? Get.theme.colorScheme.primary
                        : Colors.grey[400]!,
                  ),
                  color: selected
                      ? Get.theme.colorScheme.primaryContainer.withOpacity(0.3)
                      : Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: Get.theme.colorScheme.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      field.type.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: selected
                            ? Get.theme.colorScheme.primary
                            : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      controller.getFieldValueLabel(field),
                      style: TextStyle(
                        fontSize: 9,
                        color: selected
                            ? Get.theme.colorScheme.onPrimaryContainer
                            : Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (!isPublished && selected)
                Positioned(
                  right: -6,
                  bottom: -6,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onPanUpdate: (d) {
                      controller.resizeField(field, d.delta.dx, d.delta.dy);
                    },
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Get.theme.colorScheme.primary,
                        border: Border.all(color: Colors.white, width: 2),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.open_in_full,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
