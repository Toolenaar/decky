# Getting Started with Decky

## Important: Run Commands from Project Root

All `npm run` commands should be executed from the **project root** (`/decky`), not from subfolders.

## Step-by-Step Setup

### 1. Prerequisites

```bash
# Make sure you're in the project root
cd /path/to/decky

# Verify you're in the right place
ls package.json  # Should exist
```

### 2. Install Dependencies

```bash
# Install all workspace dependencies
npm install

# This installs:
# - Root dependencies (for scripts)
# - All package dependencies (elasticsearch-lib, functions, etc.)
```

### 3. Build Required Libraries

```bash
# Build the elasticsearch library (required for scripts)
npm run build:elasticsearch-lib

# Or install everything and build
npm run install:all
```

### 4. Configure Environment

Create your `.env` file:

```bash
# Copy the example
cp .env.example .env

# Edit with your settings
nano .env
```

**Minimal .env for local development:**
```bash
# Elasticsearch Configuration
ELASTICSEARCH_URL=https://my-elasticsearch-project-bf1adb.es.europe-west1.gcp.elastic.cloud:443
ELASTICSEARCH_INDEX_NAME=dexy-cards-dev
ELASTICSEARCH_API_KEY=aFM3c3M1Z0J2NDdrRUNyejFHMGM6Tzd0ekdzMGpBeHM0SVFQejZkS254QQ==
ELASTICSEARCH_SERVER_MODE=serverless

# Firebase Configuration  
GOOGLE_APPLICATION_CREDENTIALS=path/to/your/service-account-key.json
FIREBASE_PROJECT_ID=your-project-id
NODE_ENV=development
```

### 5. Validate Setup

```bash
# Check if everything is configured correctly
npm run setup
```

This will verify:
- ✅ .env files exist
- ✅ Elasticsearch library is built  
- ✅ Elasticsearch configuration is valid
- ✅ Can connect to Elasticsearch
- ✅ Firebase configuration is present

### 6. Initialize Elasticsearch

```bash
# Create index and sync data from Firestore
npm run sync:elasticsearch:clean
```

## Available Commands

All commands run from project root:

### Core Operations
```bash
npm run setup                    # Validate environment
npm run build                    # Build elasticsearch library
npm run install:all              # Install deps + build library
```

### Elasticsearch Operations  
```bash
npm run sync:elasticsearch       # Incremental sync from Firestore
npm run sync:elasticsearch:clean # Full sync (recreate index)
npm run validate:elasticsearch   # Validate sync integrity
```

### Firebase Functions
```bash
npm run functions:build          # Build functions
npm run functions:serve          # Local development server
npm run functions:deploy         # Deploy to Firebase
```

## Troubleshooting

### "Cannot find module" Errors

**Problem:** Scripts can't find elasticsearch library
**Solution:** 
```bash
npm run build:elasticsearch-lib
# Then try your command again
```

### "ELASTICSEARCH_URL is required"

**Problem:** Environment not configured
**Solution:**
```bash
# Make sure .env exists in project root
ls .env

# Check the contents
cat .env

# Copy from example if needed
cp .env.example .env
```

### "Elasticsearch connection failed"

**Problem:** Can't connect to Elasticsearch
**Solutions:**
```bash
# For local Docker:
docker ps  # Check if elasticsearch is running

# For Elastic Cloud:
# - Verify URL in .env
# - Check API key is correct
# - Test in browser: https://your-url (should show Elasticsearch info)
```

### Commands Run from Wrong Directory

**Problem:** Running commands from `/scripts` folder
**Solution:** Always run from project root
```bash
# Wrong:
cd scripts
npm run setup  # ❌ Won't work

# Correct:  
cd /path/to/decky  # Project root
npm run setup     # ✅ Works
```

## Project Structure

```
decky/                           # 👈 Run commands from here
├── package.json                 # 👈 Contains all npm scripts
├── .env                         # 👈 Main configuration
├── scripts/                     # Script files (don't run from here)
│   ├── setup.ts
│   ├── fullElasticsearchSync.ts
│   └── validateElasticsearchSync.ts
├── packages/
│   ├── elasticsearch-lib/       # Must be built first
│   └── backend/functions/
└── node_modules/                # Contains dependencies for scripts
```

## Development Workflow

### Daily Development
```bash
# 1. Start from project root
cd /path/to/decky

# 2. Pull latest changes  
git pull

# 3. Update dependencies if needed
npm install

# 4. Rebuild library if changed
npm run build:elasticsearch-lib

# 5. Run your commands
npm run sync:elasticsearch
npm run functions:serve
```

### Adding New Cards
```bash
# Sync new cards from Firestore to Elasticsearch
npm run sync:elasticsearch

# Validate everything synced correctly
npm run validate:elasticsearch
```

## Need Help?

1. **Check setup:** `npm run setup`
2. **Verify location:** Make sure you're in project root with `package.json`
3. **Build library:** `npm run build:elasticsearch-lib`
4. **Check .env:** Make sure configuration is correct

Remember: All commands run from **project root**, not from subfolders!