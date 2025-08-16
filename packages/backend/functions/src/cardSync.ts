import { onDocumentCreated, onDocumentUpdated, onDocumentDeleted } from 'firebase-functions/v2/firestore';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { ElasticsearchSyncService } from './lib/elasticsearch-lib';
import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import * as logger from 'firebase-functions/logger';
import * as dotenv from 'dotenv';
import * as path from 'path';

// Load environment variables for local development
if (process.env.NODE_ENV !== 'production') {
  // Try functions/.env first, then fall back to project root .env
  dotenv.config({ path: path.resolve(__dirname, '../../.env') });
  dotenv.config({ path: path.resolve(__dirname, '../../../../.env') });
}

// Initialize Firebase Admin
initializeApp();

// Initialize sync service
let syncService: ElasticsearchSyncService;

/**
 * Get or create the Elasticsearch sync service instance
 * @return {ElasticsearchSyncService} The sync service instance
 */
function getSyncService(): ElasticsearchSyncService {
  if (!syncService) {
    syncService = new ElasticsearchSyncService();
  }
  return syncService;
}

/**
 * Firestore trigger: Sync card on create
 */
export const onCardCreated = onDocumentCreated('cards/{cardId}', async (event) => {
  const cardId = event.params?.cardId;
  const cardData = event.data?.data();

  if (!cardId || !cardData) {
    logger.warn('Missing card ID or data in create event');
    return;
  }

  try {
    const service = getSyncService();
    await service.syncCard(cardData, cardId);
    logger.info(`Successfully synced new card: ${cardId}`);
  } catch (error) {
    logger.error(`Failed to sync new card ${cardId}:`, error);
    // Don't throw - we don't want to retry indefinitely
  }
});

/**
 * Firestore trigger: Sync card on update
 */
export const onCardUpdated = onDocumentUpdated('cards/{cardId}', async (event) => {
  const cardId = event.params?.cardId;
  // const before = event.data?.before.data();
  const after = event.data?.after.data();

  if (!cardId || !after) {
    logger.warn('Missing card ID or data in update event');
    return;
  }

  // Optional: Check if relevant fields changed
  // For now, we'll sync on any change
  try {
    const service = getSyncService();
    await service.syncCard(after, cardId);
    logger.info(`Successfully updated card in ES: ${cardId}`);
  } catch (error) {
    logger.error(`Failed to update card ${cardId} in ES:`, error);
  }
});

/**
 * Firestore trigger: Remove card on delete
 */
export const onCardDeleted = onDocumentDeleted('cards/{cardId}', async (event) => {
  const cardId = event.params?.cardId;

  if (!cardId) {
    logger.warn('Missing card ID in delete event');
    return;
  }

  try {
    const service = getSyncService();
    await service.deleteCard(cardId);
    logger.info(`Successfully removed card from ES: ${cardId}`);
  } catch (error) {
    logger.error(`Failed to remove card ${cardId} from ES:`, error);
  }
});

/**
 * Batch sync trigger - can be called via HTTP
 */
export const batchSyncCards = onCall(
  {
    timeoutSeconds: 540,
    memory: '2GiB',
    invoker: 'public', // Adjust security as needed
  },
  async (request) => {
    // Check authentication if needed
    // if (!request.auth) {
    //   throw new HttpsError('unauthenticated', 'User must be authenticated');
    // }

    const { cardIds } = request.data;

    if (!Array.isArray(cardIds) || cardIds.length === 0) {
      throw new HttpsError('invalid-argument', 'cardIds must be a non-empty array');
    }

    try {
      const service = getSyncService();
      const db = getFirestore();

      // Fetch cards from Firestore
      const cards = await Promise.all(
        cardIds.map(async (id: string) => {
          const doc = await db.collection('cards').doc(id).get();
          if (doc.exists) {
            return { data: doc.data(), id: doc.id };
          }
          return null;
        })
      );

      // Filter out nulls and sync
      const validCards = cards.filter((c) => c !== null) as Array<{ data: FirebaseFirestore.DocumentData; id: string }>;
      await service.bulkSyncCards(validCards);

      return {
        success: true,
        synced: validCards.length,
        failed: cardIds.length - validCards.length,
      };
    } catch (error) {
      logger.error('Batch sync failed:', error);
      throw new HttpsError('internal', 'Failed to sync cards');
    }
  }
);