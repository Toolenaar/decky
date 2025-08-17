# Quick Start Guide

Get up and running with Decky in 5 minutes!

## 1. Prerequisites

- Node.js 18+ 
- Firebase project
- Elasticsearch (local Docker or Elastic Cloud)

## 2. Configure Environment

### Option A: Local Elasticsearch (Easiest)

1. **Start Elasticsearch with Docker:**
   ```bash
   docker run -d --name elasticsearch \
     -p 9200:9200 \
     -e "discovery.type=single-node" \
     -e "xpack.security.enabled=false" \
     elasticsearch:8.11.0
   ```

2. **Configure project .env file:**
   ```bash
   # Create .env in project root
   cat > .env << 'EOF'
   # Elasticsearch Configuration
   ELASTICSEARCH_URL=http://localhost:9200
   ELASTICSEARCH_INDEX_NAME=mtg_cards
   
   # Firebase Configuration
   GOOGLE_APPLICATION_CREDENTIALS=path/to/your/service-account-key.json
   FIREBASE_PROJECT_ID=your-project-id
   
   # Environment
   NODE_ENV=development
   EOF
   ```

3. **Configure functions .env file:**
   ```bash
   # Create .env in packages/backend/functions/
   mkdir -p packages/backend/functions
   cat > packages/backend/functions/.env << 'EOF'
   # Elasticsearch Configuration for Functions
   ELASTICSEARCH_URL=http://localhost:9200
   ELASTICSEARCH_INDEX_NAME=mtg_cards
   
   # Environment
   NODE_ENV=development
   EOF
   ```

### Option B: Elastic Cloud (Production Ready)

1. **Create Elastic Cloud deployment** at [cloud.elastic.co](https://cloud.elastic.co)

2. **Get your API key:**
   - Go to your deployment → Security → API Keys
   - Create new API key
   - Copy the encoded key

3. **Configure .env files with API key:**
   ```bash
   # In project root .env
   ELASTICSEARCH_URL=https://your-deployment.es.region.gcp.elastic.cloud:443
   ELASTICSEARCH_API_KEY=your_base64_encoded_api_key
   ELASTICSEARCH_SERVER_MODE=serverless
   ELASTICSEARCH_INDEX_NAME=mtg_cards
   ```

## 3. Install and Setup

```bash
# Install all dependencies
npm run install:all

# Validate configuration
npm run setup

# Build libraries
npm run build
```

## 4. Initialize Elasticsearch

```bash
# Create index and sync data from Firestore
npm run sync:elasticsearch:clean
```

## 5. Deploy Functions (Optional)

```bash
# Build and deploy Firebase Functions
npm run functions:deploy
```

## 6. Verify Everything Works

```bash
# Validate sync
npm run validate:elasticsearch

# Test local functions
npm run functions:serve
```

## Troubleshooting

### "Elasticsearch connection failed"
- Make sure Elasticsearch is running: `curl http://localhost:9200`
- Check your ELASTICSEARCH_URL in .env
- For Elastic Cloud, verify your API key

### "Firebase permission denied"
- Download service account key from Firebase Console
- Set correct path in GOOGLE_APPLICATION_CREDENTIALS
- Make sure your Firebase project ID is correct

### "Module not found"
- Run `npm run install:all` to install all dependencies
- Run `npm run build` to build the elasticsearch library

### "Index creation failed"
- Check Elasticsearch logs: `docker logs elasticsearch`
- Verify authentication in .env file
- Make sure you have write permissions

## Next Steps

- 📖 Read the full [PROJECT_README.md](PROJECT_README.md)
- 🔍 Check the [Elasticsearch library docs](packages/elasticsearch-lib/README.md)
- 🔧 Explore the [Functions documentation](packages/backend/functions/README.md)

## Development Commands

```bash
# Development
npm run setup                    # Validate environment
npm run build                    # Build libraries
npm run sync:elasticsearch       # Sync data
npm run validate:elasticsearch   # Check sync integrity

# Functions
npm run functions:serve          # Local development
npm run functions:build          # Build functions
npm run functions:deploy         # Deploy to Firebase
```

## File Structure

```
.env                             # Main configuration
packages/backend/functions/.env  # Functions-specific config
packages/elasticsearch-lib/      # Shared search library
scripts/                         # Sync and utility scripts
```