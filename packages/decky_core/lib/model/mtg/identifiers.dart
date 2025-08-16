class Identifiers {
  final String? abuId;
  final String? cardKingdomEtchedId;
  final String? cardKingdomFoilId;
  final String? cardKingdomId;
  final String? cardsphereId;
  final String? cardsphereFoilId;
  final String? cardtraderId;
  final String? csiId;
  final String? mcmId;
  final String? mcmMetaId;
  final String? miniaturemarketId;
  final String? mtgArenaId;
  final String? mtgjsonFoilVersionId;
  final String? mtgjsonNonFoilVersionId;
  final String? mtgjsonV4Id;
  final String? mtgoFoilId;
  final String? mtgoId;
  final String? multiverseId;
  final String? scgId;
  final String? scryfallId;
  final String? scryfallCardBackId;
  final String? scryfallOracleId;
  final String? scryfallIllustrationId;
  final String? tcgplayerProductId;
  final String? tcgplayerEtchedProductId;
  final String? tntId;

  Identifiers({
    this.abuId,
    this.cardKingdomEtchedId,
    this.cardKingdomFoilId,
    this.cardKingdomId,
    this.cardsphereId,
    this.cardsphereFoilId,
    this.cardtraderId,
    this.csiId,
    this.mcmId,
    this.mcmMetaId,
    this.miniaturemarketId,
    this.mtgArenaId,
    this.mtgjsonFoilVersionId,
    this.mtgjsonNonFoilVersionId,
    this.mtgjsonV4Id,
    this.mtgoFoilId,
    this.mtgoId,
    this.multiverseId,
    this.scgId,
    this.scryfallId,
    this.scryfallCardBackId,
    this.scryfallOracleId,
    this.scryfallIllustrationId,
    this.tcgplayerProductId,
    this.tcgplayerEtchedProductId,
    this.tntId,
  });

  factory Identifiers.fromJson(Map<String, dynamic> json) {
    return Identifiers(
      abuId: json['abuId'],
      cardKingdomEtchedId: json['cardKingdomEtchedId'],
      cardKingdomFoilId: json['cardKingdomFoilId'],
      cardKingdomId: json['cardKingdomId'],
      cardsphereId: json['cardsphereId'],
      cardsphereFoilId: json['cardsphereFoilId'],
      cardtraderId: json['cardtraderId'],
      csiId: json['csiId'],
      mcmId: json['mcmId'],
      mcmMetaId: json['mcmMetaId'],
      miniaturemarketId: json['miniaturemarketId'],
      mtgArenaId: json['mtgArenaId'],
      mtgjsonFoilVersionId: json['mtgjsonFoilVersionId'],
      mtgjsonNonFoilVersionId: json['mtgjsonNonFoilVersionId'],
      mtgjsonV4Id: json['mtgjsonV4Id'],
      mtgoFoilId: json['mtgoFoilId'],
      mtgoId: json['mtgoId'],
      multiverseId: json['multiverseId'],
      scgId: json['scgId'],
      scryfallId: json['scryfallId'],
      scryfallCardBackId: json['scryfallCardBackId'],
      scryfallOracleId: json['scryfallOracleId'],
      scryfallIllustrationId: json['scryfallIllustrationId'],
      tcgplayerProductId: json['tcgplayerProductId'],
      tcgplayerEtchedProductId: json['tcgplayerEtchedProductId'],
      tntId: json['tntId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (abuId != null) 'abuId': abuId,
      if (cardKingdomEtchedId != null) 'cardKingdomEtchedId': cardKingdomEtchedId,
      if (cardKingdomFoilId != null) 'cardKingdomFoilId': cardKingdomFoilId,
      if (cardKingdomId != null) 'cardKingdomId': cardKingdomId,
      if (cardsphereId != null) 'cardsphereId': cardsphereId,
      if (cardsphereFoilId != null) 'cardsphereFoilId': cardsphereFoilId,
      if (cardtraderId != null) 'cardtraderId': cardtraderId,
      if (csiId != null) 'csiId': csiId,
      if (mcmId != null) 'mcmId': mcmId,
      if (mcmMetaId != null) 'mcmMetaId': mcmMetaId,
      if (miniaturemarketId != null) 'miniaturemarketId': miniaturemarketId,
      if (mtgArenaId != null) 'mtgArenaId': mtgArenaId,
      if (mtgjsonFoilVersionId != null) 'mtgjsonFoilVersionId': mtgjsonFoilVersionId,
      if (mtgjsonNonFoilVersionId != null) 'mtgjsonNonFoilVersionId': mtgjsonNonFoilVersionId,
      if (mtgjsonV4Id != null) 'mtgjsonV4Id': mtgjsonV4Id,
      if (mtgoFoilId != null) 'mtgoFoilId': mtgoFoilId,
      if (mtgoId != null) 'mtgoId': mtgoId,
      if (multiverseId != null) 'multiverseId': multiverseId,
      if (scgId != null) 'scgId': scgId,
      if (scryfallId != null) 'scryfallId': scryfallId,
      if (scryfallCardBackId != null) 'scryfallCardBackId': scryfallCardBackId,
      if (scryfallOracleId != null) 'scryfallOracleId': scryfallOracleId,
      if (scryfallIllustrationId != null) 'scryfallIllustrationId': scryfallIllustrationId,
      if (tcgplayerProductId != null) 'tcgplayerProductId': tcgplayerProductId,
      if (tcgplayerEtchedProductId != null) 'tcgplayerEtchedProductId': tcgplayerEtchedProductId,
      if (tntId != null) 'tntId': tntId,
    };
  }
}