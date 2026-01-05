import 'package:flutter/material.dart';
import '../domain/document_field.dart';
import 'signature_pad_page.dart';
import 'dart:typed_data';


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

            // Editor content
            _buildEditorByType(context, f),

            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  // Persist text changes
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
                  Uint8List.fromList(f.signaturePngBytes!),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: () async {
                final Uint8List? init = (f.signaturePngBytes == null)
                    ? null
                    : Uint8List.fromList(f.signaturePngBytes!);

                final Uint8List? bytes = await Navigator.of(context).push<Uint8List>(
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
