class Rulings {
  final String date;
  final String text;

  Rulings({
    required this.date,
    required this.text,
  });

  factory Rulings.fromJson(Map<String, dynamic> json) {
    return Rulings(
      date: json['date'],
      text: json['text'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'text': text,
    };
  }
}