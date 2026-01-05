import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdfx/pdfx.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/document_field.dart';
import '../../services/pdf_service.dart';
import '../preview_page.dart';

class EditorController extends GetxController {
  final String pdfPath;
  final PdfService pdfService = PdfService();
  
  late PdfControllerPinch pdfController;
  final RxList<DocumentField> fields = <DocumentField>[].obs;
  final RxBool published = false.obs;
  final Rx<Size> pageSize = const Size(1, 1).obs;
  final Rx<String?> selectedId = Rx<String?>(null);
  final RxBool generating = false.obs;
  
  String get uid => FirebaseAuth.instance.currentUser!.uid;

  EditorController({required this.pdfPath});

  @override
  void onInit() {
    super.onInit();
    pdfController = PdfControllerPinch(
      document: PdfDocument.openFile(pdfPath),
    );
  }

  @override
  void onClose() {
    pdfController.dispose();
    super.onClose();
  }

  void updatePageSize(Size size) {
    pageSize.value = size;
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

  void deleteField(String fieldId) {
    fields.removeWhere((f) => f.id == fieldId);
    selectedId.value = null;
  }

  void selectField(String? id) {
    selectedId.value = id;
  }

  void togglePublished() {
    published.value = !published.value;
  }

  void moveField(DocumentField field, double deltaX, double deltaY) {
    final left = field.nx * pageSize.value.width;
    final top = field.ny * pageSize.value.height;
    
    final newLeft = left + deltaX;
    final newTop = top + deltaY;

    field.nx = (newLeft / pageSize.value.width).clamp(0.0, 1.0 - field.nw);
    field.ny = (newTop / pageSize.value.height).clamp(0.0, 1.0 - field.nh);
  }

  void resizeField(DocumentField field, double deltaX, double deltaY) {
    final w = max(30.0, field.nw * pageSize.value.width);
    final h = max(24.0, field.nh * pageSize.value.height);

    final newWpx = (w + deltaX).clamp(30.0, pageSize.value.width);
    final newHpx = (h + deltaY).clamp(24.0, pageSize.value.height);

    field.nw = (newWpx / pageSize.value.width).clamp(0.02, 1.0 - field.nx);
    field.nh = (newHpx / pageSize.value.height).clamp(0.02, 1.0 - field.ny);
  }

  bool validateFields() {
    for (final f in fields) {
      final ok = switch (f.type) {
        FieldType.text => (f.textValue ?? "").trim().isNotEmpty,
        FieldType.checkbox => f.boolValue != null,
        FieldType.date => f.dateValue != null,
        FieldType.signature => f.signaturePngBytes != null,
      };
      if (!ok) {
        Get.snackbar("Missing", "Please fill ${f.id}");
        return false;
      }
    }
    return true;
  }

  Future<void> generateFinalPdf() async {
    if (!validateFields()) return;

    generating.value = true;
    try {
      final outPath = await pdfService.generateFinalPdf(
        originalPdfPath: pdfPath,
        fields: fields.toList(),
      );

      Get.to(() => PreviewPage(
        pdfPath: outPath,
        originalPdfPath: pdfPath,
        fieldCount: fields.length,
        userId: uid,
      ));
    } catch (e) {
      Get.snackbar("PDF generation failed", e.toString());
    } finally {
      generating.value = false;
    }
  }

  String getFieldValueLabel(DocumentField f) {
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

  void exportJson() {
    final map = {
      "fields": fields
          .map((f) => f.toJson(pageW: pageSize.value.width, pageH: pageSize.value.height))
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

  void importJson(String jsonText) {
    try {
      if (jsonText.trim().isEmpty) return;

      final decoded = jsonDecode(jsonText);
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
          pageW: pageSize.value.width,
          pageH: pageSize.value.height,
        );
      }).toList();

      fields.assignAll(newFields);
      Get.back();
    } catch (e) {
      Get.snackbar("Invalid JSON", e.toString());
    }
  }

  void showImportJsonDialog() {
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
        importJson(ctrl.text);
      },
    );
  }
}

