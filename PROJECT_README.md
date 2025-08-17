# Decky - Magic: The Gathering Deck Building Platform

A comprehensive MTG deck-building platform with AI-powered card suggestions and advanced search capabilities.

## Project Structure

```
decky/
├── packages/
│   ├── elasticsearch-lib/          # Shared Elasticsearch library
│   ├── decky_core/                 # Shared Dart models and logic
│   ├── decky_admin/                # Flutter admin dashboard
│   ├── decky_app/                  # Flutter user application
│   └── backend/
│       └── functions/              # Firebase Functions
├── scripts/                        # Build and sync scripts
├── package.json                    # Root workspace configuration
└── tsconfig.json                   # TypeScript config for scripts
```

## Quick Start

### 1. Install Dependencies
```bash
# Install all workspace dependencies
npm run install:all
```

### 2. Set up Elasticsearch

#### Option A: Elastic Cloud (Recommended)
1. Sign up for [Elastic Cloud](https://cloud.elastic.co/)
2. Create a new deployment
3. Go to Security → API Keys → Create API key
4. Copy the encoded API key for your `.env`

#### Option B: Local Docker
```bash
# Start Elasticsearch with Docker
docker run -d --name elasticsearch \
  -p 9200:9200 \
  -e "discovery.type=single-node" \
  -e "xpack.security.enabled=false" \
  elasticsearch:8.11.0
```

### 3. Configure Environment
Create `.env` file in project root (copy from `.env.example`):
```bash
# Elasticsearch Configuration (Elastic Cloud - Recommended)
ELASTICSEARCH_URL=https://your-deployment.es.region.gcp.elastic.cloud:443
ELASTICSEARCH_API_KEY=your_base64_encoded_api_key
ELASTICSEARCH_SERVER_MODE=serverless
ELASTICSEARCH_INDEX_NAME=mtg_cards

# OR for local development
# ELASTICSEARCH_URL=http://localhost:9200
# ELASTICSEARCH_USERNAME=elastic
# ELASTICSEARCH_PASSWORD=changeme

# Firebase Configuration
GOOGLE_APPLICATION_CREDENTIALS=path/to/service-account-key.json
FIREBASE_PROJECT_ID=your-project-id

# Development Environment
NODE_ENV=development
```

### 4. Initial Elasticsearch Sync
```bash
# Full sync from Firestore to Elasticsearch
npm run sync:elasticsearch:clean
```

## Available Scripts

### Elasticsearch Management
```bash
npm run sync:elasticsearch        # Incremental sync
npm run sync:elasticsearch:clean  # Full sync (recreate index)
npm run validate:elasticsearch    # Validate sync integrity
```

### Firebase Functions
```bash
npm run functions:build   # Build functions with elasticsearch library
npm run functions:deploy  # Deploy to Firebase
npm run functions:serve   # Local development server
```

### Development
```bash
npm run build                     # Build elasticsearch library
```

## Packages Overview

### [`packages/elasticsearch-lib/`](packages/elasticsearch-lib/README.md)
Shared TypeScript library for Elasticsearch operations:
- **CardSearchService**: Advanced search with filtering and aggregations
- **CardTransformer**: MTGJSON → Elasticsearch data transformation
- **ElasticsearchSyncService**: Sync operations with Firestore

### `packages/decky_core/`
Shared Dart models and business logic:
- MTG card, deck, set, and token models
- Firebase integration
- User management

### `packages/decky_admin/`
Flutter admin dashboard:
- Card management (CRUD operations)
- Bulk data imports from Scryfall
- Set and collection management

### `packages/backend/functions/`
Firebase Functions for real-time sync:
- **onCardCreated**: Auto-sync new cards to Elasticsearch
- **onCardUpdated**: Update cards in Elasticsearch
- **onCardDeleted**: Remove deleted cards
- **batchSyncCards**: Bulk sync API

## Data Flow

```mermaid
graph LR
    A[Scryfall API] --> B[Admin Dashboard]
    B --> C[Firestore]
    C --> D[Firebase Function Triggers]
    D --> E[Elasticsearch]
    E --> F[Search API]
    F --> G[User Application]
```

## Real-time Sync

The platform maintains real-time synchronization between Firestore and Elasticsearch:

1. **Card CRUD** in Admin Dashboard → **Firestore**
2. **Firestore Triggers** → **Firebase Functions**  
3. **Functions** → **Elasticsearch Index**
4. **Search Queries** → **Elasticsearch** → **Results**

## Development Workflow

### Adding New Cards
1. Use admin dashboard to import from Scryfall
2. Cards automatically sync to Elasticsearch via triggers
3. Search immediately available in user application

### Elasticsearch Schema Changes
1. Update mapping in `packages/elasticsearch-lib/src/mappings/`
2. Update types in `packages/elasticsearch-lib/src/types/`
3. Run `npm run sync:elasticsearch:clean` to recreate index

### Function Deployment
1. Update function code in `packages/backend/functions/src/`
2. Run `npm run functions:deploy`
3. Functions automatically include latest elasticsearch library

## Search Features

- **Full-text search** on card names and oracle text
- **Advanced filtering** by colors, types, formats, price
- **Fuzzy matching** for typo tolerance
- **Autocomplete** suggestions
- **AI-powered deck suggestions** based on context
- **Vector similarity search** for semantic matching

## Monitoring

- **Firebase Console**: Function logs and performance
- **Elasticsearch**: Index health and query performance
- **Validation Scripts**: Data integrity checks

## Contributing

1. Follow existing code style and patterns
2. Update tests for new functionality
3. Ensure Elasticsearch sync works with changes
4. Test functions locally before deployment

## Environment Variables

All configuration is managed via `.env` files. Copy `.env.example` to `.env` and update values.

### Elasticsearch Configuration
- `ELASTICSEARCH_URL`: Elasticsearch cluster endpoint (default: http://localhost:9200)
- `ELASTICSEARCH_INDEX_NAME`: Index name for MTG cards (default: mtg_cards)
- `ELASTICSEARCH_USERNAME`: Auth username (optional)
- `ELASTICSEARCH_PASSWORD`: Auth password (optional)
- `ELASTICSEARCH_MAX_RETRIES`: Connection retry limit (default: 3)
- `ELASTICSEARCH_REQUEST_TIMEOUT`: Request timeout in ms (default: 30000)

### Firebase Configuration
- `GOOGLE_APPLICATION_CREDENTIALS`: Firebase service account key path
- `FIREBASE_PROJECT_ID`: Firebase project ID
- `NODE_ENV`: Environment (development/production)

### Firebase Functions Deployment
For production, set Firebase Functions config:
```bash
firebase functions:config:set \
  elasticsearch.url="http://your-production-url:9200" \
  elasticsearch.username="elastic" \
  elasticsearch.password="your-password"
```

Or use environment variables in production (Firebase Functions v2):
- Functions automatically load from `.env` during local development
- In production, set via Firebase console or deployment scripts