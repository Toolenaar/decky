import { ElasticsearchCard, ColorWeight, FormatPlayability } from '../types/types';

export class CardTransformer {
  /**
   * Transform a Firestore card document (MTGJSON + Scryfall enriched) to Elasticsearch format
   * @param firestoreCard - Card data from Firestore (matches MtgCard model)
   * @param firestoreDocId - Optional Firestore document ID for reference
   */
  static transformForElasticsearch(firestoreCard: any, firestoreDocId?: string): ElasticsearchCard {
    const esCard: ElasticsearchCard = {
      // Primary identifiers
      uuid: firestoreCard.uuid || firestoreCard.id,
      firestore_id: firestoreDocId || firestoreCard.id,
      name: firestoreCard.name,
      ascii_name: firestoreCard.asciiName,
      
      // Mana and costs
      mana_cost: firestoreCard.manaCost,
      mana_value: firestoreCard.manaValue || firestoreCard.convertedManaCost || 0,
      converted_mana_cost: firestoreCard.convertedManaCost || firestoreCard.manaValue || 0,
      
      // Colors
      colors: firestoreCard.colors || [],
      color_identity: firestoreCard.colorIdentity || [],
      color_indicator: firestoreCard.colorIndicator,
      
      // Types
      type_line: firestoreCard.type,
      types: firestoreCard.types || [],
      subtypes: firestoreCard.subtypes || [],
      supertypes: firestoreCard.supertypes || [],
      
      // Text and abilities
      oracle_text: firestoreCard.text,
      keywords: firestoreCard.keywords,
      power: firestoreCard.power,
      toughness: firestoreCard.toughness,
      loyalty: firestoreCard.loyalty,
      defense: firestoreCard.defense,
      
      // Set information
      rarity: firestoreCard.rarity,
      set_code: firestoreCard.setCode,
      collector_number: firestoreCard.number,
      
      // Legalities
      legalities: this.transformLegalities(firestoreCard.legalities),
      
      // Rankings and metrics
      edhrec_rank: firestoreCard.edhrecRank,
      edhrec_saltiness: firestoreCard.edhrecSaltiness,
      
      // Physical properties
      layout: firestoreCard.layout,
      border_color: firestoreCard.borderColor,
      frame_version: firestoreCard.frameVersion,
      frame_effects: firestoreCard.frameEffects,
      finishes: firestoreCard.finishes || [],
      has_foil: firestoreCard.hasFoil || false,
      has_non_foil: firestoreCard.hasNonFoil || false,
      
      // Flags
      is_reserved: firestoreCard.isReserved,
      is_full_art: firestoreCard.isFullArt,
      is_promo: firestoreCard.isPromo,
      is_reprint: firestoreCard.isReprint,
      is_alternative: firestoreCard.isAlternative,
      is_textless: firestoreCard.isTextless,
      is_oversized: firestoreCard.isOversized,
      is_funny: firestoreCard.isFunny,
      
      // Dates
      release_date: firestoreCard.releaseDate,
      original_release_date: firestoreCard.originalReleaseDate,
      
      // Metadata
      artist: firestoreCard.artist,
      artist_ids: firestoreCard.artistIds,
      flavor_text: firestoreCard.flavorText,
      language: firestoreCard.language,
      
      // Rulings and relationships
      rulings_count: firestoreCard.rulings?.length || 0,
      other_face_ids: firestoreCard.otherFaceIds,
      variations: firestoreCard.variations,
    };

    // Purchase URLs for direct linking
    if (firestoreCard.purchaseUrls) {
      esCard.purchase_urls = {
        tcgplayer: firestoreCard.purchaseUrls.tcgplayer,
        cardmarket: firestoreCard.purchaseUrls.cardmarket,
        cardkingdom: firestoreCard.purchaseUrls.cardKingdom
      };
      esCard.prices = this.extractPrices(firestoreCard.purchaseUrls);
    }

    // Scryfall data enrichment
    if (firestoreCard.scryfallData) {
      if (firestoreCard.scryfallData.prices) {
        esCard.prices = {
          ...esCard.prices,
          ...this.extractScryfallPrices(firestoreCard.scryfallData.prices)
        };
      }
      
      // Fallback to Scryfall images if Firebase images not available
      if (!firestoreCard.firebaseImageUris && firestoreCard.scryfallData.image_uris) {
        esCard.image_uris = this.transformImageUris(firestoreCard.scryfallData.image_uris);
      }
    }

    // Prioritize Firebase Storage images
    if (firestoreCard.firebaseImageUris) {
      esCard.image_uris = this.transformImageUris(firestoreCard.firebaseImageUris);
      // Set preview image for quick access in search results
      esCard.preview_image = firestoreCard.firebaseImageUris.small || 
                             firestoreCard.firebaseImageUris.normal || 
                             firestoreCard.firebaseImageUris.large;
    } else if (esCard.image_uris) {
      // Fallback preview from Scryfall
      esCard.preview_image = esCard.image_uris.small || 
                             esCard.image_uris.normal || 
                             esCard.image_uris.large;
    }

    // Identifiers for cross-referencing
    if (firestoreCard.identifiers) {
      esCard.scryfall_id = firestoreCard.identifiers.scryfallId;
      esCard.scryfall_oracle_id = firestoreCard.identifiers.scryfallOracleId;
      esCard.scryfall_illustration_id = firestoreCard.identifiers.scryfallIllustrationId;
      
      esCard.identifiers = {
        mtgo_id: firestoreCard.identifiers.mtgoId,
        arena_id: firestoreCard.identifiers.mtgArenaId,
        tcgplayer_id: firestoreCard.identifiers.tcgplayerProductId,
        cardmarket_id: firestoreCard.identifiers.mcmId,
        multiverse_id: firestoreCard.identifiers.multiverseId
      };
    }

    // Handle multi-face cards
    if (firestoreCard.faceName) {
      esCard.card_faces = [{
        name: firestoreCard.faceName,
        mana_cost: firestoreCard.manaCost,
        type_line: firestoreCard.type,
        oracle_text: firestoreCard.text,
        power: firestoreCard.power,
        toughness: firestoreCard.toughness,
        loyalty: firestoreCard.loyalty,
        defense: firestoreCard.defense
      }];
    }

    // Related cards for combo detection
    if (firestoreCard.relatedCards) {
      esCard.related_cards = this.extractRelatedCardIds(firestoreCard.relatedCards);
    }

    esCard.synergy_themes = this.detectSynergyThemes(firestoreCard);
    esCard.deck_archetypes = this.detectDeckArchetypes(firestoreCard);
    esCard.combo_potential = this.calculateComboPotential(firestoreCard);
    esCard.popularity_score = this.calculatePopularityScore(firestoreCard);
    esCard.tribal_types = this.extractTribalTypes(firestoreCard);
    esCard.mechanic_categories = this.extractMechanicCategories(firestoreCard);
    esCard.color_weight = this.calculateColorWeight(firestoreCard);
    esCard.format_playability = this.calculateFormatPlayability(firestoreCard);

    return esCard;
  }

  private static transformImageUris(imageUris: any): any {
    if (!imageUris) return undefined;
    
    return {
      small: imageUris.small,
      normal: imageUris.normal,
      large: imageUris.large,
      png: imageUris.png,
      art_crop: imageUris.artCrop || imageUris.art_crop,
      border_crop: imageUris.borderCrop || imageUris.border_crop
    };
  }

  private static transformLegalities(legalities: any): any {
    if (!legalities) return {};
    
    const transformed: any = {};
    Object.keys(legalities).forEach(format => {
      if (legalities[format]) {
        transformed[format.toLowerCase()] = legalities[format].toLowerCase();
      }
    });
    return transformed;
  }

  private static extractPrices(purchaseUrls: any): any {
    const prices: any = {};
    
    if (purchaseUrls.tcgplayer) {
      const match = purchaseUrls.tcgplayer.match(/price=(\d+\.?\d*)/);
      if (match) {
        prices.usd = parseFloat(match[1]);
      }
    }
    
    if (purchaseUrls.cardmarket) {
      const match = purchaseUrls.cardmarket.match(/price=(\d+\.?\d*)/);
      if (match) {
        prices.eur = parseFloat(match[1]);
      }
    }
    
    return prices;
  }

  private static extractScryfallPrices(scryfallPrices: any): any {
    return {
      usd: scryfallPrices.usd ? parseFloat(scryfallPrices.usd) : undefined,
      usd_foil: scryfallPrices.usd_foil ? parseFloat(scryfallPrices.usd_foil) : undefined,
      eur: scryfallPrices.eur ? parseFloat(scryfallPrices.eur) : undefined,
      eur_foil: scryfallPrices.eur_foil ? parseFloat(scryfallPrices.eur_foil) : undefined,
      tix: scryfallPrices.tix ? parseFloat(scryfallPrices.tix) : undefined,
    };
  }

  private static extractRelatedCardIds(relatedCards: any): string[] {
    const ids: string[] = [];
    
    if (relatedCards.tokens) ids.push(...relatedCards.tokens);
    if (relatedCards.reverseRelated) ids.push(...relatedCards.reverseRelated);
    if (relatedCards.spellbook) ids.push(...relatedCards.spellbook);
    
    return ids;
  }

  private static detectSynergyThemes(card: any): string[] {
    const themes: string[] = [];
    const text = (card.text || '').toLowerCase();
    const types = (card.types || []).map((t: string) => t.toLowerCase());
    const subtypes = (card.subtypes || []).map((t: string) => t.toLowerCase());
    
    if (text.includes('graveyard')) themes.push('graveyard');
    if (text.includes('discard')) themes.push('discard');
    if (text.includes('+1/+1 counter')) themes.push('counters');
    if (text.includes('artifact')) themes.push('artifacts');
    if (text.includes('enchantment')) themes.push('enchantments');
    if (text.includes('instant') && text.includes('sorcery')) themes.push('spellslinger');
    if (text.includes('sacrifice')) themes.push('sacrifice');
    if (text.includes('token')) themes.push('tokens');
    if (text.includes('lifegain') || text.includes('gain life')) themes.push('lifegain');
    if (text.includes('draw')) themes.push('card-draw');
    if (text.includes('landfall')) themes.push('landfall');
    if (text.includes('flying')) themes.push('flying');
    if (text.includes('enters the battlefield')) themes.push('etb');
    if (text.includes('dies')) themes.push('death-triggers');
    if (text.includes('storm')) themes.push('storm');
    if (text.includes('cascade')) themes.push('cascade');
    
    if (subtypes.includes('elf')) themes.push('tribal-elves');
    if (subtypes.includes('goblin')) themes.push('tribal-goblins');
    if (subtypes.includes('zombie')) themes.push('tribal-zombies');
    if (subtypes.includes('vampire')) themes.push('tribal-vampires');
    if (subtypes.includes('dragon')) themes.push('tribal-dragons');
    if (subtypes.includes('angel')) themes.push('tribal-angels');
    if (subtypes.includes('demon')) themes.push('tribal-demons');
    if (subtypes.includes('merfolk')) themes.push('tribal-merfolk');
    
    if (types.includes('planeswalker')) themes.push('superfriends');
    if (types.includes('equipment')) themes.push('equipment');
    if (types.includes('aura')) themes.push('auras');
    
    return [...new Set(themes)];
  }

  private static detectDeckArchetypes(card: any): string[] {
    const archetypes: string[] = [];
    const manaValue = card.manaValue || card.convertedManaCost || 0;
    const text = (card.text || '').toLowerCase();
    const types = (card.types || []).map((t: string) => t.toLowerCase());
    
    if (manaValue <= 2 && types.includes('creature')) {
      archetypes.push('aggro');
    }
    
    if (text.includes('counter') || text.includes('draw') || manaValue >= 4) {
      archetypes.push('control');
    }
    
    if (text.includes('search your library') || text.includes('win the game')) {
      archetypes.push('combo');
    }
    
    if (manaValue >= 3 && manaValue <= 5 && types.includes('creature')) {
      archetypes.push('midrange');
    }
    
    if (text.includes('add') && text.includes('mana')) {
      archetypes.push('ramp');
    }
    
    if (text.includes('mill') || text.includes('library')) {
      archetypes.push('mill');
    }
    
    if (text.includes('damage') && !types.includes('creature')) {
      archetypes.push('burn');
    }
    
    return [...new Set(archetypes)];
  }

  private static calculateComboPotential(card: any): number {
    let score = 0;
    const text = (card.text || '').toLowerCase();
    
    if (text.includes('win the game')) score += 100;
    if (text.includes('extra turn')) score += 80;
    if (text.includes('search your library')) score += 60;
    if (text.includes('untap')) score += 40;
    if (text.includes('copy')) score += 40;
    if (text.includes('storm')) score += 70;
    if (text.includes('cascade')) score += 50;
    if (text.includes('whenever') && text.includes('cast')) score += 30;
    if (text.includes('enters the battlefield')) score += 20;
    if (text.includes('dies')) score += 20;
    
    return Math.min(100, score);
  }

  private static calculatePopularityScore(card: any): number {
    let score = 50;
    
    if (card.edhrecRank) {
      score = Math.max(0, 100 - (card.edhrecRank / 200));
    }
    
    if (card.isReserved) score += 10;
    if (card.isPromo) score += 5;
    if (card.rarity === 'mythic') score += 10;
    if (card.rarity === 'rare') score += 5;
    
    return Math.min(100, score);
  }

  private static extractTribalTypes(card: any): string[] {
    const tribalTypes: string[] = [];
    const subtypes = (card.subtypes || []).map((t: string) => t.toLowerCase());
    const text = (card.text || '').toLowerCase();
    
    const tribalKeywords = [
      'elf', 'goblin', 'zombie', 'vampire', 'dragon', 'angel', 'demon',
      'merfolk', 'wizard', 'warrior', 'knight', 'soldier', 'human',
      'beast', 'elemental', 'spirit', 'faerie', 'giant', 'treefolk',
      'shaman', 'cleric', 'rogue', 'artifact creature', 'sliver'
    ];
    
    tribalKeywords.forEach(tribe => {
      if (subtypes.includes(tribe) || text.includes(tribe)) {
        tribalTypes.push(tribe);
      }
    });
    
    return [...new Set(tribalTypes)];
  }

  private static extractMechanicCategories(card: any): string[] {
    const mechanics: string[] = [];
    const text = (card.text || '').toLowerCase();
    const keywords = card.keywords || [];
    
    const mechanicKeywords: Record<string, string> = {
      'flying': 'evasion',
      'trample': 'evasion',
      'menace': 'evasion',
      'unblockable': 'evasion',
      'first strike': 'combat',
      'double strike': 'combat',
      'deathtouch': 'combat',
      'lifelink': 'combat',
      'vigilance': 'combat',
      'haste': 'tempo',
      'flash': 'tempo',
      'hexproof': 'protection',
      'shroud': 'protection',
      'indestructible': 'protection',
      'protection': 'protection',
      'regenerate': 'protection'
    };
    
    keywords.forEach((keyword: string) => {
      const category = mechanicKeywords[keyword.toLowerCase()];
      if (category) mechanics.push(category);
    });
    
    if (text.includes('draw')) mechanics.push('card-advantage');
    if (text.includes('discard')) mechanics.push('disruption');
    if (text.includes('destroy')) mechanics.push('removal');
    if (text.includes('exile')) mechanics.push('removal');
    if (text.includes('counter')) mechanics.push('permission');
    if (text.includes('return') && text.includes('hand')) mechanics.push('bounce');
    if (text.includes('tap') && text.includes("doesn't untap")) mechanics.push('control');
    if (text.includes('sacrifice')) mechanics.push('sacrifice');
    if (text.includes('token')) mechanics.push('token-generation');
    
    return [...new Set(mechanics)];
  }

  private static calculateColorWeight(card: any): ColorWeight {
    const manaCost = card.manaCost || '';
    const colors = card.colors || [];
    
    const weight: ColorWeight = {
      white: 0,
      blue: 0,
      black: 0,
      red: 0,
      green: 0,
      colorless: 0
    };
    
    const matches = manaCost.match(/\{([WUBRGC\d]+)\}/g) || [];
    let totalPips = 0;
    
    matches.forEach((match: string) => {
      const pip = match.replace(/[{}]/g, '');
      if (pip === 'W') { weight.white++; totalPips++; }
      else if (pip === 'U') { weight.blue++; totalPips++; }
      else if (pip === 'B') { weight.black++; totalPips++; }
      else if (pip === 'R') { weight.red++; totalPips++; }
      else if (pip === 'G') { weight.green++; totalPips++; }
      else if (pip === 'C' || /^\d+$/.test(pip)) { weight.colorless++; totalPips++; }
    });
    
    if (totalPips > 0) {
      Object.keys(weight).forEach(color => {
        weight[color as keyof ColorWeight] = weight[color as keyof ColorWeight] / totalPips;
      });
    } else if (colors.length === 0) {
      weight.colorless = 1;
    }
    
    return weight;
  }

  private static calculateFormatPlayability(card: any): FormatPlayability {
    const playability: FormatPlayability = {};
    const legalities = card.legalities || {};
    
    const formatWeights = {
      standard: 0,
      modern: 0,
      legacy: 0,
      vintage: 0,
      commander: 0,
      pioneer: 0,
      pauper: 0
    };
    
    Object.keys(formatWeights).forEach(format => {
      if (legalities[format] === 'Legal' || legalities[format] === 'legal') {
        let score = 50;
        
        if (card.edhrecRank && format === 'commander') {
          score = Math.max(0, 100 - (card.edhrecRank / 200));
        }
        
        if (card.rarity === 'mythic') score += 10;
        if (card.rarity === 'rare') score += 5;
        
        playability[format as keyof FormatPlayability] = Math.min(100, score);
      }
    });
    
    return playability;
  }
}