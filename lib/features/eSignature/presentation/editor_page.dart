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
        actions: [
          Obx(() {
            final selectedId = controller.selectedId.value;
            return IconButton(
              icon: Icon(
                Icons.delete,
                color: selectedId != null ? Colors.red : Colors.grey,
              ),
              onPressed: (controller.published.value || selectedId == null)
                  ? null
                  : () => controller.deleteField(selectedId),
            );
          }),
          Obx(() => TextButton(
            onPressed: controller.generating.value ? null : controller.generateFinalPdf,
            child: Text(
              controller.generating.value ? "Generating..." : "Generate PDF",
              style: const TextStyle(color: Colors.purple),
            ),
          )),
        ],
      ),
      body: Column(
        children: [
          Obx(() => controller.published.value
              ? const SizedBox.shrink()
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _toolBtn("Signature", () => controller.addField(FieldType.signature)),
                      _toolBtn("Text", () => controller.addField(FieldType.text)),
                      _toolBtn("Checkbox", () => controller.addField(FieldType.checkbox)),
                      _toolBtn("Date", () => controller.addField(FieldType.date)),
                      _toolBtn("Export JSON", controller.exportJson),
                      _toolBtn("Import JSON", controller.showImportJsonDialog),
                      Obx(() => _toolBtn(
                        controller.published.value ? "Unlocked" : "Lock fields",
                        controller.togglePublished,
                      )),
                    ],
                  ),
                )),
          Expanded(
            child: LayoutBuilder(
              builder: (_, constraints) {
                controller.updatePageSize(Size(constraints.maxWidth, constraints.maxHeight));

                return Stack(
                  children: [
                    PdfViewPinch(controller: controller.pdfController),
                    Obx(() {
                      return IgnorePointer(
                        ignoring: false,
                        child: Stack(
                          children: controller.fields.map((f) => _buildFieldWidget(f, context)).toList(),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolBtn(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: ElevatedButton(onPressed: onTap, child: Text(label)),
    );
  }

  Widget _buildFieldWidget(DocumentField f, BuildContext context) {
    return Obx(() {
      final pageSize = controller.pageSize.value;
      final left = f.nx * pageSize.width;
      final top = f.ny * pageSize.height;
      final w = max(30.0, f.nw * pageSize.width);
      final h = max(24.0, f.nh * pageSize.height);

      final selectedId = controller.selectedId.value;
      final selected = selectedId == f.id;

      return Positioned(
        left: left,
        top: top,
        child: GestureDetector(
          onTap: () async {
            controller.selectField(f.id);
            await _openFieldEditorSheet(f, context);
          },
          onPanUpdate: controller.published.value
              ? null
              : (d) {
                  controller.moveField(f, d.delta.dx, d.delta.dy);
                },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: w,
                height: h,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(width: selected ? 2 : 1),
                  color: Colors.white.withOpacity(0.80),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      f.type.name.toUpperCase(),
                      style: const TextStyle(fontSize: 10),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      controller.getFieldValueLabel(f),
                      style: const TextStyle(fontSize: 9),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (!controller.published.value && selected)
                Positioned(
                  right: -6,
                  bottom: -6,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onPanUpdate: (d) {
                      controller.resizeField(f, d.delta.dx, d.delta.dy);
                    },
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.open_in_full, size: 12),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  Future<void> _openFieldEditorSheet(DocumentField f, BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
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
