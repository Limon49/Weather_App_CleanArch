import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

class PreviewPage extends StatefulWidget {
  final String pdfPath;
  const PreviewPage({super.key, required this.pdfPath});

  @override
  State<PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends State<PreviewPage> {
  late final PdfControllerPinch _controller;

  @override
  void initState() {
    super.initState();
    _controller = PdfControllerPinch(
      document: PdfDocument.openFile(widget.pdfPath),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Final PDF Preview")),
      body: PdfViewPinch(controller: _controller),
    );
  }
}
