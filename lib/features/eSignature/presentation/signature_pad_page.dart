import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'dart:typed_data' as td;

class SignaturePadPage extends StatefulWidget {
  final td.Uint8List? initial;
  const SignaturePadPage({super.key, this.initial});

  @override
  State<SignaturePadPage> createState() => _SignaturePadPageState();
}

class _SignaturePadPageState extends State<SignaturePadPage> {
  late final SignatureController controller;

  @override
  void initState() {
    super.initState();
    controller = SignatureController(
      penStrokeWidth: 3,
      exportBackgroundColor: Colors.white,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    // If user didn't draw but already had an old signature, return it
    if (controller.isEmpty) {
      if (widget.initial != null) {
        Navigator.of(context).pop(widget.initial);
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please draw your signature")),
      );
      return;
    }

    final td.Uint8List? bytes = await controller.toPngBytes();
    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to export signature")),
      );
      return;
    }

    Navigator.of(context).pop(bytes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Draw Signature"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: controller.clear,
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _save,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.grey.shade200,
              child: Stack(
                children: [
                  if (widget.initial != null)
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Image.memory(
                          widget.initial!,
                          fit: BoxFit.contain,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  Positioned.fill(
                    child: Signature(
                      controller: controller,
                      backgroundColor: Colors.white.withOpacity(0.0),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text("Draw inside the box. Trash = clear, ✓ = save."),
          ),
        ],
      ),
    );
  }
}
