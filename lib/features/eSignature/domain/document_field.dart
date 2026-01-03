enum FieldType { signature, text, checkbox, date }

class DocumentField {
  final String id;
  final FieldType type;

  // Normalized 0..1 relative to PDF page
  double nx;
  double ny;
  double nw;
  double nh;

  // filled values for signing mode
  String? textValue;
  bool? boolValue;
  DateTime? dateValue;
  List<int>? signaturePngBytes;

  DocumentField({
    required this.id,
    required this.type,
    required this.nx,
    required this.ny,
    required this.nw,
    required this.nh,
  });

  Map<String, dynamic> toJson({required double pageW, required double pageH}) {
    // Export in required format (x/y/width/height) :contentReference[oaicite:3]{index=3}
    return {
      "id": id,
      "type": type.name,
      "x": (nx * pageW),
      "y": (ny * pageH),
      "width": (nw * pageW),
      "height": (nh * pageH),
    };
  }

  static DocumentField fromJson(
      Map<String, dynamic> json, {
        required double pageW,
        required double pageH,
      }) {
    final t = FieldType.values.firstWhere((e) => e.name == json["type"]);
    final x = (json["x"] as num).toDouble();
    final y = (json["y"] as num).toDouble();
    final w = (json["width"] as num).toDouble();
    final h = (json["height"] as num).toDouble();

    return DocumentField(
      id: json["id"],
      type: t,
      nx: x / pageW,
      ny: y / pageH,
      nw: w / pageW,
      nh: h / pageH,
    );
  }
}
