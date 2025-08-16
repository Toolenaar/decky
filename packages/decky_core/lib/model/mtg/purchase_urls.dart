class PurchaseUrls {
  final String? cardKingdom;
  final String? cardKingdomEtched;
  final String? cardKingdomFoil;
  final String? cardmarket;
  final String? tcgplayer;
  final String? tcgplayerEtched;

  PurchaseUrls({
    this.cardKingdom,
    this.cardKingdomEtched,
    this.cardKingdomFoil,
    this.cardmarket,
    this.tcgplayer,
    this.tcgplayerEtched,
  });

  factory PurchaseUrls.fromJson(Map<String, dynamic> json) {
    return PurchaseUrls(
      cardKingdom: json['cardKingdom'],
      cardKingdomEtched: json['cardKingdomEtched'],
      cardKingdomFoil: json['cardKingdomFoil'],
      cardmarket: json['cardmarket'],
      tcgplayer: json['tcgplayer'],
      tcgplayerEtched: json['tcgplayerEtched'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (cardKingdom != null) 'cardKingdom': cardKingdom,
      if (cardKingdomEtched != null) 'cardKingdomEtched': cardKingdomEtched,
      if (cardKingdomFoil != null) 'cardKingdomFoil': cardKingdomFoil,
      if (cardmarket != null) 'cardmarket': cardmarket,
      if (tcgplayer != null) 'tcgplayer': tcgplayer,
      if (tcgplayerEtched != null) 'tcgplayerEtched': tcgplayerEtched,
    };
  }
}