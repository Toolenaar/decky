export interface ElasticsearchCard {
  // Primary identifiers
  uuid: string; // MTGJSON UUID
  firestore_id?: string; // Firestore document ID
  name: string;
  ascii_name?: string;
  
  // Mana and costs
  mana_cost?: string;
  mana_value: number;
  converted_mana_cost: number; // MTGJSON field
  
  // Colors
  colors: string[];
  color_identity: string[];
  color_indicator?: string[];
  
  // Types
  type_line: string;
  types: string[];
  subtypes: string[];
  supertypes: string[];
  
  // Text and abilities
  oracle_text?: string;
  keywords?: string[];
  power?: string;
  toughness?: string;
  loyalty?: string;
  defense?: string;
  
  // Set information
  rarity: string;
  set_code: string;
  set_name?: string;
  collector_number: string;
  
  // Legalities
  legalities: CardLegalities;
  
  // Pricing
  prices?: CardPrices;
  purchase_urls?: {
    tcgplayer?: string;
    cardmarket?: string;
    cardkingdom?: string;
  };
  
  // Rankings and metrics
  edhrec_rank?: number;
  edhrec_saltiness?: number;
  
  // Physical properties
  layout: string;
  border_color: string;
  frame_version: string;
  frame_effects?: string[];
  finishes: string[];
  has_foil: boolean;
  has_non_foil: boolean;
  
  // Flags
  is_reserved?: boolean;
  is_full_art?: boolean;
  is_promo?: boolean;
  is_reprint?: boolean;
  is_alternative?: boolean;
  is_textless?: boolean;
  is_oversized?: boolean;
  is_funny?: boolean;
  
  // Dates
  release_date?: string;
  original_release_date?: string;
  
  // Metadata
  artist?: string;
  artist_ids?: string[];
  flavor_text?: string;
  language: string;
  
  // Images - prioritize Firebase Storage URLs
  image_uris?: {
    small?: string;
    normal?: string;
    large?: string;
    png?: string;
    art_crop?: string;
    border_crop?: string;
  };
  preview_image?: string; // Quick access to small/normal image for search results
  
  // Scryfall integration
  scryfall_id?: string;
  scryfall_oracle_id?: string;
  scryfall_illustration_id?: string;
  
  // Other identifiers
  identifiers?: {
    mtgo_id?: string;
    arena_id?: string;
    tcgplayer_id?: string;
    cardmarket_id?: string;
    multiverse_id?: string;
  };
  
  // Rulings and relationships
  rulings_count?: number;
  produced_mana?: string[];
  card_faces?: CardFace[];
  other_face_ids?: string[];
  variations?: string[];
  
  // AI and analysis fields
  synergy_themes?: string[];
  deck_archetypes?: string[];
  combo_potential?: number;
  popularity_score?: number;
  ai_embeddings?: number[];
  related_cards?: string[];
  tribal_types?: string[];
  mechanic_categories?: string[];
  color_weight?: ColorWeight;
  format_playability?: FormatPlayability;
}

export interface CardLegalities {
  standard?: string;
  modern?: string;
  legacy?: string;
  vintage?: string;
  commander?: string;
  pioneer?: string;
  historic?: string;
  explorer?: string;
  alchemy?: string;
  brawl?: string;
  pauper?: string;
  penny?: string;
  duel?: string;
  oldschool?: string;
  premodern?: string;
  predh?: string;
  oathbreaker?: string;
  paupercommander?: string;
  gladiator?: string;
  timeless?: string;
  standardbrawl?: string;
  historicbrawl?: string;
  future?: string;
}

export interface CardPrices {
  usd?: number;
  usd_foil?: number;
  eur?: number;
  eur_foil?: number;
  tix?: number;
}

export interface CardFace {
  name: string;
  mana_cost?: string;
  type_line: string;
  oracle_text?: string;
  power?: string;
  toughness?: string;
  loyalty?: string;
  defense?: string;
}

export interface ColorWeight {
  white: number;
  blue: number;
  black: number;
  red: number;
  green: number;
  colorless: number;
}

export interface FormatPlayability {
  standard?: number;
  modern?: number;
  legacy?: number;
  vintage?: number;
  commander?: number;
  pioneer?: number;
  pauper?: number;
}

export interface SearchFilters {
  name?: string;
  text?: string;
  colors?: string[];
  colorIdentity?: string[];
  types?: string[];
  subtypes?: string[];
  keywords?: string[];
  manaCost?: string;
  manaValue?: {
    min?: number;
    max?: number;
  };
  power?: {
    min?: number;
    max?: number;
  };
  toughness?: {
    min?: number;
    max?: number;
  };
  rarity?: string[];
  sets?: string[];
  formats?: {
    [format: string]: 'legal' | 'restricted' | 'banned';
  };
  price?: {
    min?: number;
    max?: number;
    currency?: 'usd' | 'eur' | 'tix';
  };
  artist?: string;
  isReserved?: boolean;
  isPromo?: boolean;
  synergyThemes?: string[];
  deckArchetypes?: string[];
}

export interface SearchOptions {
  filters?: SearchFilters;
  sort?: SortOption[];
  pagination?: {
    from: number;
    size: number;
  };
  includeRelated?: boolean;
  includeSimilar?: boolean;
  vectorSearch?: {
    embedding: number[];
    threshold?: number;
  };
}

export interface SortOption {
  field: 'name' | 'mana_value' | 'price' | 'edhrec_rank' | 'release_date' | 'popularity_score';
  order: 'asc' | 'desc';
}

export interface DeckBuildingContext {
  format: string;
  commander?: string;
  theme?: string;
  budget?: number;
  existingCards: string[];
  colorIdentity: string[];
  strategyPreference?: 'aggro' | 'control' | 'combo' | 'midrange' | 'ramp';
}

export interface CardSuggestion {
  card: ElasticsearchCard;
  score: number;
  reasons: string[];
  synergyScore: number;
  budgetFit: boolean;
  roleInDeck: string;
}