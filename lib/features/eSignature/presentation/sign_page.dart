import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:weather_app/features/eSignature/presentation/signature_pad_page.dart';
import '../domain/document_field.dart';
import '../services/pdf_service.dart';
import 'preview_page.dart';
import 'dart:typed_data' as td;

class SignPage extends StatefulWidget {
  final String pdfPath;
  final List<DocumentField> fields;
  const SignPage({super.key, required this.pdfPath, required this.fields});

  @override
  State<SignPage> createState() => _SignPageState();
}

class _SignPageState extends State<SignPage> {
  final pdfService = PdfService();
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Signing Mode")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...widget.fields.map(_fieldInput),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: loading ? null : _finish,
            child: Text(loading ? "Generating..." : "Generate Final PDF"),
          ),
        ],
      ),
    );
  }

  Widget _fieldInput(DocumentField f) {
    switch (f.type) {
      case FieldType.text:
        return TextField(
          decoration: InputDecoration(labelText: f.id),
          onChanged: (v) => f.textValue = v,
        );
      case FieldType.checkbox:
        return SwitchListTile(
          title: Text(f.id),
          value: f.boolValue ?? false,
          onChanged: (v) => setState(() => f.boolValue = v),
        );
      case FieldType.date:
        return ListTile(
          title: Text(f.id),
          subtitle: Text(f.dateValue?.toIso8601String() ?? "Pick date"),
          onTap: () async {
            final now = DateTime.now();
            final d = await showDatePicker(
              context: context,
              firstDate: DateTime(now.year - 5),
              lastDate: DateTime(now.year + 5),
              initialDate: now,
            );
            if (d != null) setState(() => f.dateValue = d);
          },
        );
      case FieldType.signature:
        return ListTile(
          title: Text(f.id),
          subtitle: Text(
            f.signaturePngBytes == null
                ? "Tap to sign"
                : "Tap to edit signature",
          ),
          trailing: Icon(
            f.signaturePngBytes == null ? Icons.border_color : Icons.edit,
          ),

          onTap: () async {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Tapped!")),
            );
            final td.Uint8List? init = (f.signaturePngBytes == null)
                ? null
                : td.Uint8List.fromList(f.signaturePngBytes!);

            final td.Uint8List? bytes = await Navigator.of(context)
                .push<td.Uint8List>(
                  MaterialPageRoute(
                    builder: (_) => SignaturePadPage(initial: init),
                  ),
                );

            if (bytes != null) {
              setState(() => f.signaturePngBytes = bytes.toList());
            }
          },
        );
    }
  }

  Future<void> _finish() async {
    for (final f in widget.fields) {
      final ok = switch (f.type) {
        FieldType.text => (f.textValue ?? "").trim().isNotEmpty,
        FieldType.checkbox => f.boolValue != null,
        FieldType.date => f.dateValue != null,
        FieldType.signature => (f.signaturePngBytes != null),
      };
      if (!ok) {
        Get.snackbar("Missing", "Please fill ${f.id}");
        return;
      }
    }

    setState(() => loading = true);
    try {
      final outPath = await pdfService.generateFinalPdf(
        originalPdfPath: widget.pdfPath,
        fields: widget.fields,
      );
      Get.to(() => PreviewPage(
        pdfPath: outPath,
        originalPdfPath: widget.pdfPath,
        fieldCount: widget.fields.length,
        userId: null, // SignPage doesn't have user context
      ));
    } catch (e) {
      Get.snackbar("PDF generation failed", e.toString());
    } finally {
      setState(() => loading = false);
    }
  }
}
