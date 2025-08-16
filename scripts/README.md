# MTG Data Import Script

This script imports MTG data from MTGJSON into Firebase Firestore using an optimized database structure.

## Database Architecture

The script creates separate Firestore collections for optimal querying:

- `/sets/{setCode}` - Set metadata without cards array
- `/cards/{cardUuid}` - Individual cards with setCode reference
- `/tokens/{tokenUuid}` - Token cards with setCode reference  
- `/decks/{deckCode}` - Preconstructed decks with setCode reference
- `/sealed-products/{uuid}` - Sealed products with setCode reference

## Setup

1. Install dependencies:
```bash
npm install
```

2. Ensure you have the Firebase service account file at `data/dev-service-account.json`

3. Ensure you have the MTG data file at `data/AllPrintings.json`

## Usage

### Test Mode (First 5 sets only)
```bash
npm run import:test
```

### Full Import
```bash
npm run import
```

## Features

- **Batch Processing**: Uses Firestore's 500-document batch limit
- **Progress Tracking**: Detailed console output with timing
- **Error Handling**: Comprehensive error reporting
- **Test Mode**: Process only first 5 sets for testing
- **Type Safety**: Full TypeScript type definitions

## Data Sources

Data is fetched from [MTGJSON](https://mtgjson.com/) and should be placed in `data/AllPrintings.json`.

## Collections Created

1. **sets**: Set metadata with card/token/deck counts
2. **cards**: Individual cards with set references
3. **tokens**: Token cards with set references
4. **decks**: Preconstructed decks (if available)
5. **sealed-products**: Sealed products like booster packs (if available)

This structure enables efficient queries like:
- Find all cards in a set: `cards.where('setCode', '==', 'DOM')`
- Find all cards with a name: `cards.where('name', '==', 'Lightning Bolt')`
- Get set metadata: `sets.doc('DOM').get()`