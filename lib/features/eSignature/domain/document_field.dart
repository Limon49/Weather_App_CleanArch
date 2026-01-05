enum FieldType { signature, text, checkbox, date }

class DocumentField {
  final String id;
  final FieldType type;

  double nx;
  double ny;
  double nw;
  double nh;

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
    return {
      "id": id,
      "type": type.name,
      "x": (nx * pageW),
      "y": (ny * pageH),
      "width": (nw * pageW),
      "height": (nh * pageH),
      "textValue": textValue,
      "boolValue": boolValue,
      "dateValue": dateValue?.toIso8601String(),
      "signaturePngBytes": signaturePngBytes,
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

    final field = DocumentField(
      id: json["id"],
      type: t,
      nx: x / pageW,
      ny: y / pageH,
      nw: w / pageW,
      nh: h / pageH,
    );

    // Restore field values
    if (json.containsKey("textValue") && json["textValue"] != null) {
      field.textValue = json["textValue"] as String;
    }
    if (json.containsKey("boolValue") && json["boolValue"] != null) {
      field.boolValue = json["boolValue"] as bool;
    }
    if (json.containsKey("dateValue") && json["dateValue"] != null) {
      field.dateValue = DateTime.parse(json["dateValue"] as String);
    }
    if (json.containsKey("signaturePngBytes") && json["signaturePngBytes"] != null) {
      field.signaturePngBytes = List<int>.from(json["signaturePngBytes"] as List);
    }

    return field;
  }
}
