import 'dart:io';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PreviewPage extends StatelessWidget {
  final String pdfPath;
  const PreviewPage({super.key, required this.pdfPath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Final PDF Preview")),
      body: SfPdfViewer.file(File(pdfPath)),
    );
  }
}
