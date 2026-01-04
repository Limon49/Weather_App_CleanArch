import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdfx/pdfx.dart';
import 'dart:typed_data' as td;
import '../domain/document_field.dart';
import '../services/pdf_service.dart';
import 'preview_page.dart';
import 'signature_pad_page.dart';

class EditorPage extends StatefulWidget {
  final String pdfPath;
  const EditorPage({super.key, required this.pdfPath});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  late final PdfControllerPinch _pdfController;
  final RxList<DocumentField> fields = <DocumentField>[].obs;

  bool published = false; // locks move/resize if true
  Size pageSize = const Size(1, 1);
  String? selectedId;

  bool generating = false;
  final pdfService = PdfService();

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

  Future<void> _openFieldEditorSheet(DocumentField f) async {
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
          onDelete: published
              ? null
              : () {
            fields.removeWhere((x) => x.id == f.id);
            Navigator.pop(context);
            setState(() => selectedId = null);
          },
        ),
      ),
    );

    setState(() {}); // refresh overlay
  }

  Future<void> _generateFinalPdf() async {
    // validation
    for (final f in fields) {
      final ok = switch (f.type) {
        FieldType.text => (f.textValue ?? "").trim().isNotEmpty,
        FieldType.checkbox => f.boolValue != null,
        FieldType.date => f.dateValue != null,
        FieldType.signature => f.signaturePngBytes != null,
      };
      if (!ok) {
        Get.snackbar("Missing", "Please fill ${f.id}");
        return;
      }
    }

    setState(() => generating = true);
    try {
      final outPath = await pdfService.generateFinalPdf(
        originalPdfPath: widget.pdfPath,
        fields: fields.toList(),
      );
      Get.to(() => PreviewPage(pdfPath: outPath));
    } catch (e) {
      Get.snackbar("PDF generation failed", e.toString());
    } finally {
      setState(() => generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Document Editor"),
        actions: [
          IconButton(
            icon: Icon(
              Icons.delete,
              color: selectedId != null ? Colors.red : Colors.grey,
            ),
            onPressed: (published || selectedId == null)
                ? null
                : () {
              fields.removeWhere((f) => f.id == selectedId);
              setState(() => selectedId = null);
            },
          ),
          TextButton(
            onPressed: generating ? null : _generateFinalPdf,
            child: Text(
              generating ? "Generating..." : "Generate PDF",
              style: const TextStyle(color: Colors.white),
            ),
          ),
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
                  _toolBtn(
                    published ? "Unlocked" : "Lock fields",
                        () => setState(() => published = !published),
                  ),
                ],
              ),
            ),
          Expanded(
            child: LayoutBuilder(
              builder: (_, constraints) {
                pageSize = Size(constraints.maxWidth, constraints.maxHeight);

                return Stack(
                  children: [
                    PdfViewPinch(controller: _pdfController),
                    Obx(() {
                      return IgnorePointer(
                        ignoring: false,
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

    final selected = selectedId == f.id;

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: () async {
          setState(() => selectedId = f.id);
          await _openFieldEditorSheet(f);
        },

        // move (disabled if published)
        onPanUpdate: published
            ? null
            : (d) {
          final newLeft = left + d.delta.dx;
          final newTop = top + d.delta.dy;

          final nx = (newLeft / pageSize.width).clamp(0.0, 1.0 - f.nw);
          final ny = (newTop / pageSize.height).clamp(0.0, 1.0 - f.nh);

          setState(() {
            f.nx = nx;
            f.ny = ny;
          });
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
                    _fieldValueLabel(f),
                    style: const TextStyle(fontSize: 9),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // resize handle (bottom-right)
            if (!published && selected)
              Positioned(
                right: -6,
                bottom: -6,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onPanUpdate: (d) {
                    final newWpx =
                    (w + d.delta.dx).clamp(30.0, pageSize.width);
                    final newHpx =
                    (h + d.delta.dy).clamp(24.0, pageSize.height);

                    final newNw =
                    (newWpx / pageSize.width).clamp(0.02, 1.0 - f.nx);
                    final newNh =
                    (newHpx / pageSize.height).clamp(0.02, 1.0 - f.ny);

                    setState(() {
                      f.nw = newNw;
                      f.nh = newNh;
                    });
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
  }

  String _fieldValueLabel(DocumentField f) {
    switch (f.type) {
      case FieldType.text:
        final t = (f.textValue ?? "").trim();
        return t.isEmpty ? "(empty)" : t;
      case FieldType.checkbox:
        return (f.boolValue ?? false) ? "Yes" : "No";
      case FieldType.date:
        return f.dateValue == null ? "(no date)" : f.dateValue!.toIso8601String();
      case FieldType.signature:
        return f.signaturePngBytes == null ? "(no sign)" : "(signed)";
    }
  }

  void _exportJson() {
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

/// Bottom Sheet Editor
class FieldEditorSheet extends StatefulWidget {
  final DocumentField field;
  final VoidCallback? onDelete;

  const FieldEditorSheet({
    super.key,
    required this.field,
    required this.onDelete,
  });

  @override
  State<FieldEditorSheet> createState() => _FieldEditorSheetState();
}

class _FieldEditorSheetState extends State<FieldEditorSheet> {
  late final TextEditingController _textCtrl;

  @override
  void initState() {
    super.initState();
    _textCtrl = TextEditingController(text: widget.field.textValue ?? "");
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.field;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Edit: ${f.id}",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (widget.onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: widget.onDelete,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _buildEditorByType(context, f),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (f.type == FieldType.text) {
                    f.textValue = _textCtrl.text;
                  }
                  Navigator.pop(context);
                },
                child: const Text("Done"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditorByType(BuildContext context, DocumentField f) {
    switch (f.type) {
      case FieldType.text:
        return TextField(
          controller: _textCtrl,
          decoration: const InputDecoration(
            labelText: "Text",
            border: OutlineInputBorder(),
          ),
          minLines: 1,
          maxLines: 3,
        );

      case FieldType.checkbox:
        return SwitchListTile(
          title: const Text("Checked"),
          value: f.boolValue ?? false,
          onChanged: (v) => setState(() => f.boolValue = v),
        );

      case FieldType.date:
        return ListTile(
          title: const Text("Date"),
          subtitle: Text(
            f.dateValue == null ? "Pick a date" : f.dateValue!.toIso8601String(),
          ),
          trailing: const Icon(Icons.calendar_month),
          onTap: () async {
            final now = DateTime.now();
            final d = await showDatePicker(
              context: context,
              firstDate: DateTime(now.year - 5),
              lastDate: DateTime(now.year + 5),
              initialDate: f.dateValue ?? now,
            );
            if (d != null) setState(() => f.dateValue = d);
          },
        );

      case FieldType.signature:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 140,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: f.signaturePngBytes == null
                  ? const Center(child: Text("No signature yet"))
                  : Padding(
                padding: const EdgeInsets.all(8),
                child: Image.memory(
                  td.Uint8List.fromList(f.signaturePngBytes!),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: () async {
                final td.Uint8List? init = (f.signaturePngBytes == null)
                    ? null
                    : td.Uint8List.fromList(f.signaturePngBytes!);

                final td.Uint8List? bytes =
                await Navigator.of(context).push<td.Uint8List>(
                  MaterialPageRoute(
                    builder: (_) => SignaturePadPage(initial: init),
                  ),
                );

                if (bytes != null) {
                  setState(() => f.signaturePngBytes = bytes.toList());
                }
              },
              icon: const Icon(Icons.border_color),
              label: Text(
                f.signaturePngBytes == null ? "Add signature" : "Edit signature",
              ),
            ),
          ],
        );
    }
  }
}
