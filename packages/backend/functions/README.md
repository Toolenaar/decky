# Firebase Functions - Elasticsearch Sync

This directory contains Firebase Functions for real-time Elasticsearch synchronization with Firestore.

## Functions Overview

### Firestore Triggers (v2 API)
- **onCardCreated**: Automatically syncs new cards to Elasticsearch
- **onCardUpdated**: Updates cards in Elasticsearch when Firestore documents change
- **onCardDeleted**: Removes cards from Elasticsearch when deleted from Firestore

### HTTP Functions
- **batchSyncCards**: Callable function for bulk synchronization of specific card IDs

## Setup & Deployment

### 1. Install Dependencies
```bash
cd packages/backend/functions
npm install
```

### 2. Build with Elasticsearch Library
The build process automatically includes our shared Elasticsearch library:

```bash
npm run build
```

This will:
1. Build the `@decky/elasticsearch-lib` package
2. Copy the built library to `src/lib/elasticsearch-lib/`
3. Compile TypeScript functions

### 3. Environment Variables

#### Local Development
Functions automatically load configuration from the project root `.env` file:

```bash
# .env (in project root)
ELASTICSEARCH_URL=http://localhost:9200
ELASTICSEARCH_INDEX_NAME=mtg_cards
ELASTICSEARCH_USERNAME=elastic
ELASTICSEARCH_PASSWORD=changeme
NODE_ENV=development
```

#### Production Deployment
For production, set Firebase Functions config:

```bash
firebase functions:config:set \
  elasticsearch.url="http://your-production-url:9200" \
  elasticsearch.username="elastic" \
  elasticsearch.password="your-password" \
  elasticsearch.index_name="mtg_cards"
```

The functions will automatically use Firebase config in production and `.env` in development.

### 4. Deploy Functions
```bash
npm run deploy
```

## Local Development

### Start Emulator
```bash
npm run serve
```

### Watch Mode
```bash
npm run build:watch
```

## Function Details

### Real-time Sync Triggers

The functions use Firebase Functions v2 API with modern syntax:

```typescript
// Auto-sync on card creation
export const onCardCreated = onDocumentCreated('cards/{cardId}', async (event) => {
  const cardId = event.params?.cardId;
  const cardData = event.data?.data();
  // ... sync logic
});
```

### Security Considerations

- **Authentication**: The batch sync function is currently set to `invoker: 'public'` for testing. Update this based on your security requirements.
- **Error Handling**: Sync failures are logged but don't throw errors to prevent infinite retries.
- **Memory**: Functions are configured with appropriate memory limits for Elasticsearch operations.

### Monitoring

Monitor function execution in the Firebase Console:
- Function logs: `npm run logs`
- Real-time monitoring: Firebase Console > Functions

### Troubleshooting

1. **Import Errors**: Ensure the elasticsearch library is built before functions:
   ```bash
   cd ../../elasticsearch-lib
   npm run build
   cd ../backend/functions
   npm run build
   ```

2. **Elasticsearch Connection**: Verify environment variables and network access from Firebase Functions to your Elasticsearch cluster.

3. **Memory Issues**: Increase memory allocation in function configuration if needed:
   ```typescript
   export const onCardCreated = onDocumentCreated(
     { document: 'cards/{cardId}', memory: '1GiB' },
     handler
   );
   ```

## Architecture

```
packages/backend/functions/
├── src/
│   ├── lib/elasticsearch-lib/     # Copied during build
│   ├── cardSync.ts               # Sync functions
│   └── index.ts                  # Function exports
├── scripts/
│   └── build-with-lib.js         # Build script
└── package.json                  # Dependencies
```

The shared Elasticsearch library is built and copied into the functions directory during the build process, ensuring all dependencies are properly bundled for deployment.