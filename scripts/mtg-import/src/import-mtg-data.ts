#!/usr/bin/env tsx

import * as fs from 'fs';
import * as path from 'path';
import { initializeApp, cert, getApps } from 'firebase-admin/app';
import { getFirestore, WriteBatch } from 'firebase-admin/firestore';
import type {
  AllPrintingsFile,
  Set,
  CardSet,
  CardToken,
  DeckSet,
  SealedProduct
} from './AllMTGJSONTypes';

// Firestore document type definitions
export interface FirestoreSetDoc {
  baseSetSize: number;
  block?: string;
  cardsphereSetId?: number;
  code: string;
  codeV3?: string;
  isForeignOnly?: boolean;
  isFoilOnly: boolean;
  isNonFoilOnly?: boolean;
  isOnlineOnly: boolean;
  isPaperOnly?: boolean;
  isPartialPreview?: boolean;
  keyruneCode: string;
  languages?: string[];
  mcmId?: number;
  mcmIdExtras?: number;
  mcmName?: string;
  mtgoCode?: string;
  name: string;
  parentCode?: string;
  releaseDate: string;
  tcgplayerGroupId?: number;
  tokenSetCode?: string;
  totalSetSize: number;
  type: string;
  translations: Record<string, string>;
  // Counts for related documents
  cardCount: number;
  tokenCount: number;
  deckCount: number;
  sealedProductCount: number;
}

export interface FirestoreCardDoc extends Omit<CardSet, 'setCode'> {
  setCode: string;
}

export interface FirestoreTokenDoc extends Omit<CardToken, 'setCode'> {
  setCode: string;
}

export interface FirestoreDeckDoc extends Omit<DeckSet, 'code'> {
  code: string;
  setCode: string;
}

export interface FirestoreSealedProductDoc extends Omit<SealedProduct, 'uuid'> {
  uuid: string;
  setCode: string;
}

// Configuration
const SERVICE_ACCOUNT_PATH = path.join(__dirname, '../../data', 'dev-service-account.json');
const MTGJSON_DATA_PATH = path.join(__dirname, '../../data', 'AllPrintings.json');
const BATCH_SIZE = 500; // Firestore batch limit
const TEST_MODE = process.argv.includes('--test');
const FORCE_MODE = process.argv.includes('--force');
const TEST_SET_LIMIT = 5; // Only process first 5 sets in test mode

/**
 * MTG Data Import Script
 * 
 * Imports MTG data from MTGJSON into Firebase Firestore
 * Uses separate collections for optimal querying and to avoid document size limits
 * 
 * Features:
 * - Compares card counts before importing to avoid unnecessary re-imports
 * - Supports --test flag to process only first 5 sets
 * - Supports --force flag to skip count check and force reimport
 */
async function main() {
  const startTime = Date.now();
  console.log('🎴 Starting MTG Data Import...');
  console.log(`📊 Test mode: ${TEST_MODE}`);
  console.log(`🔄 Force mode: ${FORCE_MODE}`);
  console.log(`⏰ Started at: ${new Date().toISOString()}`);
  
  try {
    // Initialize Firebase
    await initializeFirebase();
    
    // Load and parse MTG data
    console.log('\n📖 Step 1: Loading MTG data...');
    const mtgData = await loadMTGData();
    
    // Check if import is needed (unless forced)
    if (!FORCE_MODE) {
      console.log('\n🔍 Step 2: Checking if import is needed...');
      const importNeeded = await checkIfImportNeeded(mtgData);
      
      if (!importNeeded) {
        console.log('\n⏭️  Skipping import - data already up to date!');
        console.log('   Run with --force flag to reimport anyway.');
        const endTime = Date.now();
        const duration = Math.round((endTime - startTime) / 1000);
        console.log(`\n✅ Check completed in ${duration} seconds!`);
        return;
      }
    } else {
      console.log('\n🔄 Step 2: Force mode enabled - skipping count check...');
    }
    
    // Transform and import data
    console.log('\n🔄 Step 3: Transforming and importing data...');
    await importData(mtgData);
    
    const endTime = Date.now();
    const duration = Math.round((endTime - startTime) / 1000);
    console.log(`\n✅ Import completed successfully in ${duration} seconds!`);
    console.log(`⏰ Finished at: ${new Date().toISOString()}`);
    
  } catch (error) {
    console.error('\n❌ Import failed:', error);
    console.error('\n🔍 Error details:', {
      message: error instanceof Error ? error.message : String(error),
      stack: error instanceof Error ? error.stack : undefined
    });
    process.exit(1);
  }
}

/**
 * Initialize Firebase Admin SDK
 */
async function initializeFirebase() {
  console.log('🔥 Initializing Firebase...');
  
  if (getApps().length === 0) {
    const serviceAccount = JSON.parse(fs.readFileSync(SERVICE_ACCOUNT_PATH, 'utf8'));
    
    initializeApp({
      credential: cert(serviceAccount),
      projectId: serviceAccount.project_id
    });
  }
  
  console.log('✅ Firebase initialized');
}

/**
 * Count cards in Firestore
 */
async function countFirestoreCards(): Promise<number> {
  console.log('🔢 Counting cards in Firestore...');
  
  const db = getFirestore();
  const cardsCollection = db.collection('cards');
  
  try {
    const snapshot = await cardsCollection.count().get();
    const count = snapshot.data().count;
    console.log(`📊 Found ${count} cards in Firestore`);
    return count;
  } catch (error) {
    console.warn('⚠️  Could not count Firestore cards (collection may not exist yet):', error);
    return 0;
  }
}

/**
 * Count total cards in AllPrintings.json
 */
function countAllPrintingsCards(mtgData: AllPrintingsFile): number {
  console.log('🔢 Counting cards in AllPrintings.json...');
  
  let totalCards = 0;
  const sets = Object.entries(mtgData.data);
  
  for (const [_setCode, setData] of sets) {
    totalCards += setData.cards.length;
  }
  
  console.log(`📊 Found ${totalCards} cards in AllPrintings.json`);
  return totalCards;
}

/**
 * Compare card counts and determine if import should proceed
 */
async function checkIfImportNeeded(mtgData: AllPrintingsFile): Promise<boolean> {
  console.log('\n🔍 Checking if import is needed...');
  
  const firestoreCount = await countFirestoreCards();
  const allPrintingsCount = countAllPrintingsCards(mtgData);
  
  console.log('\n📈 Card Count Comparison:');
  console.log(`   Firestore:      ${firestoreCount.toLocaleString()}`);
  console.log(`   AllPrintings:   ${allPrintingsCount.toLocaleString()}`);
  console.log(`   Difference:     ${(allPrintingsCount - firestoreCount).toLocaleString()}`);
  
  if (firestoreCount === allPrintingsCount) {
    console.log('\n✅ Card counts match! All cards appear to already be imported.');
    return false;
  } else if (firestoreCount > allPrintingsCount) {
    console.log('\n⚠️  Warning: Firestore has MORE cards than AllPrintings.json');
    console.log('   This could indicate duplicate entries or data issues.');
    console.log('   Proceeding with import...');
    return true;
  } else {
    console.log('\n📥 Import needed: Firestore has fewer cards than AllPrintings.json');
    return true;
  }
}

/**
 * Load and parse MTG JSON data
 */
async function loadMTGData(): Promise<AllPrintingsFile> {
  console.log('📖 Loading MTG data...');
  
  if (!fs.existsSync(MTGJSON_DATA_PATH)) {
    throw new Error(`MTG data file not found: ${MTGJSON_DATA_PATH}`);
  }
  
  console.log('📄 Reading AllPrintings.json (this may take a moment)...');
  const rawData = fs.readFileSync(MTGJSON_DATA_PATH, 'utf8');
  
  console.log('🔍 Parsing JSON data...');
  const mtgData: AllPrintingsFile = JSON.parse(rawData);
  
  const setCount = Object.keys(mtgData.data).length;
  console.log(`✅ Loaded ${setCount} sets from MTGJSON v${mtgData.meta.version}`);
  
  return mtgData;
}

/**
 * Convert undefined values to null to make it Firestore compatible
 */
function convertUndefinedToNull(obj: any): any {
  if (obj === undefined) {
    return null;
  }
  
  if (obj === null) {
    return null;
  }
  
  if (Array.isArray(obj)) {
    return obj.map(convertUndefinedToNull);
  }
  
  if (typeof obj === 'object') {
    const cleaned: any = {};
    for (const [key, value] of Object.entries(obj)) {
      cleaned[key] = convertUndefinedToNull(value);
    }
    return cleaned;
  }
  
  return obj;
}

/**
 * Transform MTG set data for Firestore
 */
function transformSetData(_setCode: string, setData: Set): FirestoreSetDoc {
  const transformed = {
    baseSetSize: setData.baseSetSize,
    block: setData.block,
    cardsphereSetId: setData.cardsphereSetId,
    code: setData.code,
    codeV3: setData.codeV3,
    isForeignOnly: setData.isForeignOnly,
    isFoilOnly: setData.isFoilOnly,
    isNonFoilOnly: setData.isNonFoilOnly,
    isOnlineOnly: setData.isOnlineOnly,
    isPaperOnly: setData.isPaperOnly,
    isPartialPreview: setData.isPartialPreview,
    keyruneCode: setData.keyruneCode,
    languages: setData.languages,
    mcmId: setData.mcmId,
    mcmIdExtras: setData.mcmIdExtras,
    mcmName: setData.mcmName,
    mtgoCode: setData.mtgoCode,
    name: setData.name,
    parentCode: setData.parentCode,
    releaseDate: setData.releaseDate,
    tcgplayerGroupId: setData.tcgplayerGroupId,
    tokenSetCode: setData.tokenSetCode,
    totalSetSize: setData.totalSetSize,
    type: setData.type,
    translations: setData.translations,
    cardCount: setData.cards.length,
    tokenCount: setData.tokens.length,
    deckCount: setData.decks?.length || 0,
    sealedProductCount: setData.sealedProduct?.length || 0
  };
  
  return convertUndefinedToNull(transformed);
}

/**
 * Transform card data for Firestore
 */
function transformCardData(card: CardSet, setCode: string): FirestoreCardDoc {
  return convertUndefinedToNull({
    ...card,
    setCode
  });
}

/**
 * Transform token data for Firestore
 */
function transformTokenData(token: CardToken, setCode: string): FirestoreTokenDoc {
  return convertUndefinedToNull({
    ...token,
    setCode
  });
}

/**
 * Transform deck data for Firestore
 */
function transformDeckData(deck: DeckSet, setCode: string): FirestoreDeckDoc {
  return convertUndefinedToNull({
    ...deck,
    setCode
  });
}

/**
 * Transform sealed product data for Firestore
 */
function transformSealedProductData(product: SealedProduct, setCode: string): FirestoreSealedProductDoc {
  return convertUndefinedToNull({
    ...product,
    setCode
  });
}

/**
 * Write documents to Firestore in batches
 */
async function writeBatch(db: any, collection: string, docs: Array<{id: string, data: any}>) {
  const batches: WriteBatch[] = [];
  let currentBatch = db.batch();
  let currentBatchSize = 0;
  
  for (const doc of docs) {
    const docRef = db.collection(collection).doc(doc.id);
    currentBatch.set(docRef, doc.data);
    currentBatchSize++;
    
    if (currentBatchSize >= BATCH_SIZE) {
      batches.push(currentBatch);
      currentBatch = db.batch();
      currentBatchSize = 0;
    }
  }
  
  if (currentBatchSize > 0) {
    batches.push(currentBatch);
  }
  
  console.log(`📝 Writing ${docs.length} documents to ${collection} in ${batches.length} batches...`);
  
  for (let i = 0; i < batches.length; i++) {
    const batch = batches[i];
    try {
      await batch.commit();
      console.log(`✅ Batch ${i + 1}/${batches.length} committed successfully`);
    } catch (error) {
      console.error(`❌ Failed to commit batch ${i + 1}/${batches.length}:`, error);
      throw error;
    }
  }
}

/**
 * Import data to Firestore
 */
async function importData(mtgData: AllPrintingsFile) {
  console.log('🔄 Starting data import...');
  
  const db = getFirestore();
  const sets = Object.entries(mtgData.data);
  const setsToProcess = TEST_MODE ? sets.slice(0, TEST_SET_LIMIT) : sets;
  
  console.log(`📦 Processing ${setsToProcess.length} sets...`);
  
  const allSets: Array<{id: string, data: FirestoreSetDoc}> = [];
  const allCards: Array<{id: string, data: FirestoreCardDoc}> = [];
  const allTokens: Array<{id: string, data: FirestoreTokenDoc}> = [];
  const allDecks: Array<{id: string, data: FirestoreDeckDoc}> = [];
  const allSealedProducts: Array<{id: string, data: FirestoreSealedProductDoc}> = [];
  
  // Transform all data
  for (const [setCode, setData] of setsToProcess) {
    console.log(`🔄 Processing set: ${setData.name} (${setCode})`);
    
    // Transform set data
    allSets.push({
      id: setCode,
      data: transformSetData(setCode, setData)
    });
    
    // Transform cards
    for (const card of setData.cards) {
      allCards.push({
        id: card.uuid,
        data: transformCardData(card, setCode)
      });
    }
    
    // Transform tokens
    for (const token of setData.tokens) {
      allTokens.push({
        id: token.uuid,
        data: transformTokenData(token, setCode)
      });
    }
    
    // Transform decks
    if (setData.decks) {
      for (const deck of setData.decks) {
        allDecks.push({
          id: `${setCode}_${deck.code}`,
          data: transformDeckData(deck, setCode)
        });
      }
    }
    
    // Transform sealed products
    if (setData.sealedProduct) {
      for (const product of setData.sealedProduct) {
        allSealedProducts.push({
          id: product.uuid,
          data: transformSealedProductData(product, setCode)
        });
      }
    }
  }
  
  console.log(`📊 Data transformation complete:`);
  console.log(`   Sets: ${allSets.length}`);
  console.log(`   Cards: ${allCards.length}`);
  console.log(`   Tokens: ${allTokens.length}`);
  console.log(`   Decks: ${allDecks.length}`);
  console.log(`   Sealed Products: ${allSealedProducts.length}`);
  
  // Write to Firestore
  try {
    await writeBatch(db, 'sets', allSets);
    await writeBatch(db, 'cards', allCards);
    await writeBatch(db, 'tokens', allTokens);
    
    if (allDecks.length > 0) {
      await writeBatch(db, 'decks', allDecks);
    }
    
    if (allSealedProducts.length > 0) {
      await writeBatch(db, 'sealed-products', allSealedProducts);
    }
    
    console.log('✅ All data written to Firestore successfully!');
  } catch (error) {
    console.error('❌ Failed to write data to Firestore:', error);
    throw error;
  }
}

// Run the script
if (require.main === module) {
  main();
}