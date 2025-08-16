# @decky/elasticsearch-lib

Shared Elasticsearch library for the Decky MTG platform, providing search capabilities and data synchronization.

## Features

- 🔍 **Advanced Search**: Full-text search with fuzzy matching and filtering
- 🤖 **AI Integration**: Vector embeddings for semantic similarity
- 🔄 **Real-time Sync**: Automatic syncing with Firestore triggers
- 📊 **Deck Building Support**: Context-aware card suggestions
- 🎯 **MTG-Optimized**: Custom analyzers for mana costs and card text

## Installation

```bash
npm install @decky/elasticsearch-lib
```

## Quick Start

```typescript
import { CardSearchService, ElasticsearchSyncService } from '@decky/elasticsearch-lib';

// Initialize services
const searchService = new CardSearchService();
const syncService = new ElasticsearchSyncService();

// Search for cards
const results = await searchService.searchCards({
  filters: {
    name: "Lightning Bolt",
    formats: { modern: "legal" },
    manaValue: { max: 3 }
  }
});

// Sync a card
await syncService.syncCard(cardData, firestoreId);
```

## Data Model

The library uses an optimized Elasticsearch mapping designed for MTG cards:

### Core Fields
- **uuid**: MTGJSON card identifier
- **firestore_id**: Reference to Firestore document
- **name**: Card name with autocomplete support
- **oracle_text**: Rules text with MTG-specific analysis
- **preview_image**: Quick access image URL for search results

### Search Features
- **Mana Cost Analysis**: Normalized {W}{U}{B}{R}{G} symbols
- **Synonym Expansion**: "destroy" → "removal", "counter" → "counterspell"
- **Edge N-gram Tokenization**: Fast autocomplete
- **Faceted Filtering**: Colors, types, formats, price ranges

## Search Examples

### Basic Search
```typescript
const results = await searchService.searchCards({
  filters: {
    text: "destroy target creature",
    colors: ["B"],
    rarity: ["rare", "mythic"]
  },
  sort: [{ field: "mana_value", order: "asc" }]
});
```

### AI-Powered Deck Suggestions
```typescript
const suggestions = await searchService.suggestCardsForDeck({
  format: "commander",
  commander: "Atraxa, Praetors' Voice",
  theme: "proliferate",
  colorIdentity: ["W", "U", "B", "G"],
  budget: 100
});
```

### Vector Similarity Search
```typescript
const similar = await searchService.searchCards({
  vectorSearch: {
    embedding: cardEmbedding, // 768-dimensional vector
    threshold: 0.8
  }
});
```

## Sync Service

### Individual Card Sync
```typescript
// Sync single card
await syncService.syncCard(cardData, firestoreId);

// Bulk sync
await syncService.bulkSyncCards([
  { data: card1, id: "doc1" },
  { data: card2, id: "doc2" }
]);
```

### Index Management
```typescript
// Initialize index
await syncService.initializeIndex();

// Recreate index (clean sync)
await syncService.recreateIndex();
```

## Environment Variables

### Modern Setup (Elastic Cloud - Recommended)
```bash
# Elastic Cloud with API Key (recommended)
ELASTICSEARCH_URL=https://your-deployment.es.region.gcp.elastic.cloud:443
ELASTICSEARCH_API_KEY=your_base64_encoded_api_key
ELASTICSEARCH_SERVER_MODE=serverless
ELASTICSEARCH_INDEX_NAME=mtg_cards
```

### Legacy Setup (Self-hosted)
```bash
# Traditional username/password
ELASTICSEARCH_URL=http://localhost:9200
ELASTICSEARCH_USERNAME=elastic
ELASTICSEARCH_PASSWORD=your_password
ELASTICSEARCH_INDEX_NAME=mtg_cards
```

### Creating API Keys

For Elastic Cloud:
1. Go to your deployment → Security → API Keys
2. Create new API key with appropriate permissions
3. Copy the encoded key directly to your `.env`

For self-managed Elasticsearch:
```typescript
import { encodeApiKey } from '@decky/elasticsearch-lib';

// If you have separate id and key from Elasticsearch API
const encoded = encodeApiKey('api-key-id', 'api-key-secret');
console.log('ELASTICSEARCH_API_KEY=' + encoded);
```

## Firestore Integration

The library is designed to work with MTGJSON + Scryfall enriched data stored in Firestore:

```typescript
// Automatic field mapping
const firestoreCard = {
  uuid: "card-uuid",
  name: "Lightning Bolt",
  manaCost: "{R}",
  manaValue: 1,
  type: "Instant",
  text: "Lightning Bolt deals 3 damage to any target.",
  firebaseImageUris: {
    small: "https://...",
    normal: "https://...",
    large: "https://..."
  },
  // ... other MTGJSON fields
};

// Transforms to optimized Elasticsearch document
const esCard = CardTransformer.transformForElasticsearch(firestoreCard);
```

## Types

All TypeScript types are exported:

```typescript
import { 
  ElasticsearchCard,
  SearchOptions,
  SearchFilters,
  DeckBuildingContext,
  CardSuggestion 
} from '@decky/elasticsearch-lib';
```

## Development

```bash
# Build library
npm run build

# Watch mode
npm run watch

# Clean build
npm run clean
```

## Performance

- **Shards**: 2 (optimized for medium datasets)
- **Replicas**: 1 (redundancy)
- **Batch Size**: 500 cards per bulk operation
- **Vector Dimensions**: 768 (compatible with popular embedding models)

## Integration with Firebase Functions

Use with Firestore triggers for real-time sync:

```typescript
// In your Firebase function
import { ElasticsearchSyncService } from '@decky/elasticsearch-lib';

export const onCardChange = functions
  .firestore
  .document('cards/{cardId}')
  .onWrite(async (change, context) => {
    const syncService = new ElasticsearchSyncService();
    const cardData = change.after.data();
    await syncService.syncCard(cardData, context.params.cardId);
  });
```