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
            tooltip: "Clear",
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _save,
            tooltip: "Save",
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.grey.shade200,
              child: RepaintBoundary(
                child: Stack(
                  children: [
                    if (widget.initial != null)
                      Positioned.fill(
                        child: RepaintBoundary(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Image.memory(
                              widget.initial!,
                              fit: BoxFit.contain,
                              color: Colors.black54,
                              cacheWidth: 800, // Limit image size for performance
                            ),
                          ),
                        ),
                      ),
                    Positioned.fill(
                      child: Signature(
                        controller: controller,
                        backgroundColor: Colors.white.withOpacity(0.0),
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                const Text(
                  "Draw your signature. Tap ✓ to save.",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
