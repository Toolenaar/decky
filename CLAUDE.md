# Decky - Magic: The Gathering Deck Building Platform

## Project Overview
Decky is a comprehensive Magic: The Gathering deck-building platform that leverages AI and smart search capabilities to help users create optimal decks. The platform consists of multiple integrated packages working together to provide an exceptional user experience.

## Architecture

### Packages Structure

#### 1. **decky_core** (Shared Core Library)
- **Purpose**: Central data models and shared logic
- **Key Components**:
  - MTG card models (MtgCard, MtgDeck, MtgSet, MtgToken, MtgSealedProduct)
  - Base models and controllers
  - User controller for authentication
  - Firestore integration for data persistence

#### 2. **decky_admin** (Admin Dashboard)
- **Purpose**: Admin interface for managing platform data
- **Technology**: Flutter (web/desktop)
- **Features**:
  - Cards management (CRUD operations)
  - Sets management
  - Decks management
  - Sealed products management
  - Tokens management
  - Bulk image import functionality
  - Scryfall integration service
  - Image synchronization service

#### 3. **decky_app** (User Application)
- **Purpose**: Main consumer-facing application
- **Technology**: Flutter (mobile/web)
- **Features**: (To be implemented)
  - Deck building interface
  - AI-powered card suggestions
  - Smart search functionality
  - Collection management
  - Social features

#### 4. **backend** (Firebase Functions)
- **Purpose**: Serverless backend functions
- **Technology**: TypeScript, Firebase Functions
- **Current Functions**:
  - Scryfall card data fetching
  - (AI agents to be implemented)
  - (Elasticsearch integration to be implemented)

## Tech Stack

### Frontend
- **Framework**: Flutter
- **State Management**: TBD (likely Riverpod or Provider)
- **Routing**: Go Router
- **UI Components**: Material Design

### Backend
- **Cloud Provider**: Firebase
- **Database**: Cloud Firestore
- **Functions**: Firebase Functions (Node.js/TypeScript)
- **Storage**: Firebase Storage (for card images)
- **Authentication**: Firebase Auth

### AI & Search
- **AI**: Firebase AI/Genkit (planned)
- **Search**: Elasticsearch (planned)
- **External APIs**: Scryfall API for MTG card data

## Data Models

### Core MTG Models
- **MtgCard**: Complete card information including:
  - Card attributes (name, mana cost, colors, etc.)
  - Legalities across formats
  - Image URIs
  - Rulings and related cards
  - Market prices and purchase URLs
  
- **MtgDeck**: Deck structure with card lists
- **MtgSet**: Card set information
- **MtgToken**: Token card data
- **MtgSealedProduct**: Booster packs, boxes, etc.

## Development Guidelines

### Code Organization
1. **Separation of Concerns**: Core logic in `decky_core`, UI in respective apps
2. **Modular Architecture**: Each package should be independently testable
3. **Shared Resources**: Common models and utilities in core package

### Flutter Best Practices
1. Use proper state management patterns
2. Implement responsive layouts for multi-platform support
3. Follow Material Design guidelines
4. Implement proper error handling and loading states

### Firebase Integration
1. Use Firestore for real-time data synchronization
2. Implement proper security rules
3. Optimize queries for performance
4. Use batch operations for bulk updates

### Testing Strategy
1. Unit tests for core business logic
2. Widget tests for UI components
3. Integration tests for critical user flows
4. Cloud function tests for backend logic

## Key Features to Implement

### Phase 1: Foundation
- ✅ Core data models
- ✅ Admin dashboard structure
- ✅ Basic CRUD operations
- ⏳ Complete Scryfall integration
- ⏳ Image management system

### Phase 2: Smart Search
- [ ] Elasticsearch setup
- [ ] Advanced card filtering
- [ ] Fuzzy search capabilities
- [ ] Format-specific searches
- [ ] Combo detection

### Phase 3: AI Integration
- [ ] Firebase Genkit setup
- [ ] Card suggestion engine
- [ ] Deck optimization recommendations
- [ ] Meta analysis
- [ ] Sideboard suggestions

### Phase 4: User Experience
- [ ] Deck builder interface
- [ ] Collection tracker
- [ ] Deck sharing and social features
- [ ] Tournament support
- [ ] Mobile optimization

## API Integrations

### Scryfall API
- Primary source for card data
- Bulk data imports
- Image URLs
- Price information
- Oracle text updates

### Future Integrations
- EDHREC for Commander recommendations
- TCGPlayer for pricing
- Tournament results APIs

## Security Considerations
1. Implement proper authentication flows
2. Secure API keys in environment variables
3. Rate limiting for API calls
4. Data validation on both client and server
5. Regular security audits

## Performance Optimization
1. Lazy loading for card images
2. Pagination for large datasets
3. Caching strategies for frequently accessed data
4. Optimize Firestore queries
5. CDN for static assets

## Monitoring & Analytics
1. Firebase Analytics for user behavior
2. Performance monitoring
3. Error tracking with Crashlytics
4. Custom events for feature usage

## Environment Setup

### Required Tools
- Flutter SDK (latest stable)
- Node.js (v18+)
- Firebase CLI
- IDE with Flutter support (VS Code/Android Studio)

### Configuration Files Needed
- `firebase.json` - Firebase project configuration
- `.env` files for API keys
- Service account keys for admin SDK

## Commands

### Development
```bash
# Run admin dashboard
cd packages/decky_admin
flutter run -d chrome

# Run user app
cd packages/decky_app
flutter run

# Deploy functions
cd packages/backend
npm run deploy

# Run tests
flutter test
```

### Build
```bash
# Build admin for web
cd packages/decky_admin
flutter build web

# Build app for iOS
cd packages/decky_app
flutter build ios

# Build app for Android
flutter build apk
```

## Troubleshooting

### Common Issues
1. **Firestore permissions**: Check security rules
2. **Image loading**: Verify Storage CORS configuration
3. **Function timeouts**: Increase timeout in function configuration
4. **Flutter dependencies**: Run `flutter pub get` in each package

## Contributing Guidelines
1. Follow the existing code style
2. Write tests for new features
3. Update documentation
4. Use conventional commits
5. Create feature branches

## Resources
- [Scryfall API Documentation](https://scryfall.com/docs/api)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Flutter Documentation](https://flutter.dev/docs)
- [MTG Comprehensive Rules](https://magic.wizards.com/en/rules)