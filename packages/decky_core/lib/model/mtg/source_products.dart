class SourceProducts {
  final List<String> etched;
  final List<String> foil;
  final List<String> nonfoil;

  SourceProducts({
    required this.etched,
    required this.foil,
    required this.nonfoil,
  });

  factory SourceProducts.fromJson(Map<String, dynamic> json) {
    return SourceProducts(
      etched: List<String>.from(json['etched'] ?? []),
      foil: List<String>.from(json['foil'] ?? []),
      nonfoil: List<String>.from(json['nonfoil'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'etched': etched,
      'foil': foil,
      'nonfoil': nonfoil,
    };
  }
}