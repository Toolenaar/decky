import 'identifiers.dart';

class ForeignData {
  final String? faceName;
  final String? flavorText;
  final Identifiers identifiers;
  final String language;
  final String name;
  final String? text;
  final String? type;

  ForeignData({
    this.faceName,
    this.flavorText,
    required this.identifiers,
    required this.language,
    required this.name,
    this.text,
    this.type,
  });

  factory ForeignData.fromJson(Map<String, dynamic> json) {
    return ForeignData(
      faceName: json['faceName'],
      flavorText: json['flavorText'],
      identifiers: Identifiers.fromJson(json['identifiers']),
      language: json['language'],
      name: json['name'],
      text: json['text'],
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (faceName != null) 'faceName': faceName,
      if (flavorText != null) 'flavorText': flavorText,
      'identifiers': identifiers.toJson(),
      'language': language,
      'name': name,
      if (text != null) 'text': text,
      if (type != null) 'type': type,
    };
  }
}