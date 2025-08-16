class LeadershipSkills {
  final bool brawl;
  final bool commander;
  final bool oathbreaker;

  LeadershipSkills({
    required this.brawl,
    required this.commander,
    required this.oathbreaker,
  });

  factory LeadershipSkills.fromJson(Map<String, dynamic> json) {
    return LeadershipSkills(
      brawl: json['brawl'] ?? false,
      commander: json['commander'] ?? false,
      oathbreaker: json['oathbreaker'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'brawl': brawl,
      'commander': commander,
      'oathbreaker': oathbreaker,
    };
  }
}