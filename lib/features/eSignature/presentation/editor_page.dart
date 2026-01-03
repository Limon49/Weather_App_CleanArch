import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdfx/pdfx.dart';
import '../domain/document_field.dart';
import 'sign_page.dart';
import 'dart:convert';

class EditorPage extends StatefulWidget {
  final String pdfPath;
  const EditorPage({super.key, required this.pdfPath});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  late final PdfControllerPinch _pdfController;
  final RxList<DocumentField> fields = <DocumentField>[].obs;

  bool published = false;
  Size pageSize = const Size(1, 1);

  @override
  void initState() {
    super.initState();
    _pdfController = PdfControllerPinch(
      document: PdfDocument.openFile(widget.pdfPath),
    );
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  void addField(FieldType type) {
    final id = "${type.name}_${fields.length + 1}";
    fields.add(
      DocumentField(
        id: id,
        type: type,
        nx: 0.2,
        ny: 0.2,
        nw: 0.25,
        nh: type == FieldType.signature ? 0.10 : 0.08,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Document Editor"),
        actions: [
          TextButton(
            onPressed: published
                ? null
                : () {
              setState(() => published = true);
              Get.to(
                    () => SignPage(
                  pdfPath: widget.pdfPath,
                  fields: fields.toList(),
                ),
              );
            },
            child: Text(
              published ? "Published" : "Publish",
              style: const TextStyle(color: Colors.white),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          if (!published)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _toolBtn("Signature", () => addField(FieldType.signature)),
                  _toolBtn("Text", () => addField(FieldType.text)),
                  _toolBtn("Checkbox", () => addField(FieldType.checkbox)),
                  _toolBtn("Date", () => addField(FieldType.date)),
                  _toolBtn("Export JSON", _exportJson),
                  _toolBtn("Import JSON", _importJson),
                ],
              ),
            ),
          Expanded(
            child: LayoutBuilder(
              builder: (_, constraints) {
                // This is the key fix: use the widget size as the coordinate space.
                // It stays stable across devices and zoom doesn't break your saved coordinates.
                pageSize = Size(constraints.maxWidth, constraints.maxHeight);

                return Stack(
                  children: [
                    PdfViewPinch(
                      controller: _pdfController,
                    ),

                    // Overlay fields
                    Obx(() {
                      return IgnorePointer(
                        ignoring: published,
                        child: Stack(
                          children: fields.map(_buildFieldWidget).toList(),
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

  Widget _buildFieldWidget(DocumentField f) {
    final left = f.nx * pageSize.width;
    final top = f.ny * pageSize.height;
    final w = max(30.0, f.nw * pageSize.width);
    final h = max(24.0, f.nh * pageSize.height);

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onPanUpdate: (d) {
          final newLeft = left + d.delta.dx;
          final newTop = top + d.delta.dy;

          final nx = newLeft / pageSize.width;
          final ny = newTop / pageSize.height;

          setState(() {
            f.nx = nx.clamp(0.0, 1.0 - f.nw);
            f.ny = ny.clamp(0.0, 1.0 - f.nh);
          });
        },
        child: Container(
          width: w,
          height: h,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(),
            color: Colors.white.withOpacity(0.75),
          ),
          child: Text(
            f.type.name.toUpperCase(),
            style: const TextStyle(fontSize: 10),
          ),
        ),
      ),
    );
  }

  void _exportJson() {
    // Export schema must be { fields: [ {id,type,x,y,width,height} ] }
    // We export with current viewport size (stable for preview/editing).
    final map = {
      "fields": fields
          .map((f) => f.toJson(pageW: pageSize.width, pageH: pageSize.height))
          .toList(),
    };

    final pretty = const JsonEncoder.withIndent("  ").convert(map);

    Get.defaultDialog(
      title: "Export JSON",
      content: SizedBox(
        width: 340,
        child: SingleChildScrollView(child: SelectableText(pretty)),
      ),
    );
  }

  void _importJson() {
    final ctrl = TextEditingController();

    Get.defaultDialog(
      title: "Paste JSON",
      content: SizedBox(
        width: 340,
        child: TextField(controller: ctrl, maxLines: 12),
      ),
      textConfirm: "Import",
      textCancel: "Cancel",
      onConfirm: () {
        try {
          final text = ctrl.text.trim();
          if (text.isEmpty) return;

          final decoded = jsonDecode(text);
          if (decoded is! Map<String, dynamic>) {
            throw Exception("JSON root must be an object { ... }");
          }

          final rawFields = decoded["fields"];
          if (rawFields is! List) {
            throw Exception('"fields" must be a list');
          }

          final newFields = rawFields.map((e) {
            if (e is! Map<String, dynamic>) {
              throw Exception("Each field must be an object");
            }
            return DocumentField.fromJson(
              e,
              pageW: pageSize.width,
              pageH: pageSize.height,
            );
          }).toList();

          fields.assignAll(newFields);
          Get.back();
        } catch (e) {
          Get.snackbar("Invalid JSON", e.toString());
        }
      },
    );
  }
}

