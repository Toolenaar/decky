import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { onCall, CallableRequest } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { ElasticsearchSyncService } from "./lib/elasticsearch-lib";
import { CardTransformer } from "./lib/elasticsearch-lib/services/cardTransformer";

// Initialize admin if not already done
if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();
const storage = admin.storage().bucket();

// Initialize Elasticsearch sync service
let elasticsearchSyncService: ElasticsearchSyncService | null = null;

/**
 * Get or create the Elasticsearch sync service instance
 * @return {ElasticsearchSyncService} The sync service instance
 */
function getElasticsearchSyncService(): ElasticsearchSyncService {
  if (!elasticsearchSyncService) {
    elasticsearchSyncService = new ElasticsearchSyncService();
  }
  return elasticsearchSyncService;
}

interface TaskData {
  id: string;
  taskType: string;
  status: string;
  metadata: Record<string, unknown>;
  createdAt: admin.firestore.Timestamp;
  updatedAt?: admin.firestore.Timestamp;
  startedAt?: admin.firestore.Timestamp;
  completedAt?: admin.firestore.Timestamp;
  errorMessage?: string;
}

interface CardUpdateMetadata {
  cardId: string;
  forceUpdate?: boolean;
  skipImageDownload?: boolean;
  reason?: string;
}

// Trigger when a new task is created
export const onTaskCreated = onDocumentCreated(
  {
    document: "tasks/{taskId}",
    region: "europe-west3",
  },
  async (event) => {
    const taskId = event.params.taskId;
    const taskData = event.data?.data() as TaskData;

    if (!taskData || taskData.status !== 'pending') {
      return;
    }

    logger.info(`Processing new task: ${taskId} of type: ${taskData.taskType}`);

    try {
      await processTask(taskId, taskData);
    } catch (error) {
      logger.error(`Failed to process task ${taskId}:`, error);
      await updateTaskStatus(taskId, 'failed', error instanceof Error ? error.message : 'Unknown error');
    }
  }
);

/**
 * Manual task processor for testing or manual triggers
 * @param {CallableRequest} request - The callable request
 * @return {Promise<{success: boolean, message: string}>} Result of processing
 */
export const processTaskManually = onCall(
  { region: "europe-west3" },
  async (request: CallableRequest) => {
    const { taskId } = request.data;

    if (!taskId || typeof taskId !== 'string') {
      throw new Error('taskId is required and must be a string');
    }

    const taskDoc = await db.collection('tasks').doc(taskId).get();
    if (!taskDoc.exists) {
      throw new Error('Task not found');
    }

    const taskData = { ...taskDoc.data(), id: taskId } as TaskData;

    try {
      await processTask(taskId, taskData);
      return { success: true, message: 'Task processed successfully' };
    } catch (error) {
      logger.error(`Failed to process task ${taskId}:`, error);
      await updateTaskStatus(taskId, 'failed', error instanceof Error ? error.message : 'Unknown error');
      throw error;
    }
  }
);

// Scheduled cleanup of completed tasks
export const cleanupCompletedTasks = onSchedule(
  {
    schedule: "0 2 * * *", // Run daily at 2 AM
    timeZone: "Europe/Amsterdam",
    region: "europe-west3",
  },
  async () => {
    logger.info("Starting cleanup of completed tasks");

    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - 7); // Delete tasks older than 7 days

    try {
      const tasksToDelete = await db
        .collection('tasks')
        .where('status', 'in', ['completed', 'failed'])
        .where('completedAt', '<', admin.firestore.Timestamp.fromDate(cutoffDate))
        .get();

      const batch = db.batch();
      tasksToDelete.docs.forEach((doc) => {
        batch.delete(doc.ref);
      });

      if (tasksToDelete.docs.length > 0) {
        await batch.commit();
        logger.info(`Deleted ${tasksToDelete.docs.length} completed tasks`);
      } else {
        logger.info("No completed tasks to delete");
      }
    } catch (error) {
      logger.error("Failed to cleanup completed tasks:", error);
    }
  }
);

/**
 * Get a card from Elasticsearch by ID
 * @param {string} cardId - The card ID
 * @return {Promise<any>} The Elasticsearch card data or null if not found
 */
async function getCardFromElasticsearch(cardId: string): Promise<any> {
  try {
    const syncService = getElasticsearchSyncService();
    const searchService = syncService.getSearchService();
    
    // Use the internal client to get the document by ID
    const client = (searchService as any).client;
    const response = await client.get({
      index: 'mtg_cards',
      id: cardId
    });
    
    return response._source;
  } catch (error: any) {
    if (error.statusCode === 404) {
      logger.info(`Card ${cardId} not found in Elasticsearch`);
      return null;
    }
    logger.warn(`Error retrieving card ${cardId} from Elasticsearch:`, error);
    return null;
  }
}

/**
 * Compare Firestore card data with Elasticsearch data, focusing on images
 * @param {any} firestoreData - The card data from Firestore
 * @param {any} elasticsearchData - The card data from Elasticsearch
 * @return {boolean} True if data is in sync, false otherwise
 */
function isCardDataInSync(firestoreData: any, elasticsearchData: any): boolean {
  if (!elasticsearchData) {
    return false; // Elasticsearch doesn't have the card
  }

  // Transform Firestore data to Elasticsearch format for comparison
  const expectedEsData = CardTransformer.transformForElasticsearch(firestoreData);

  // Key fields to check for synchronization
  const fieldsToCompare = [
    'name',
    'mana_cost',
    'mana_value',
    'oracle_text',
    'type_line',
    'power',
    'toughness',
    'rarity',
    'set_code',
    'collector_number'
  ];

  // Check basic fields
  for (const field of fieldsToCompare) {
    const expectedValue = (expectedEsData as any)[field];
    const actualValue = (elasticsearchData as any)[field];
    if (expectedValue !== actualValue) {
      logger.info(`Field mismatch for ${field}: expected ${expectedValue}, got ${actualValue}`);
      return false;
    }
  }

  // Special check for image data - this is the main concern
  if (firestoreData.firebaseImageUris) {
    // Check if Elasticsearch has the image_uris field
    if (!elasticsearchData.image_uris) {
      logger.info('Image URIs missing in Elasticsearch');
      return false;
    }

    // Compare image URIs (Firestore firebaseImageUris maps to ES image_uris)
    const firestoreImageFormats = Object.keys(firestoreData.firebaseImageUris);
    const elasticsearchImageFormats = Object.keys(elasticsearchData.image_uris);

    if (firestoreImageFormats.length !== elasticsearchImageFormats.length) {
      logger.info('Image format count mismatch');
      return false;
    }

    for (const format of firestoreImageFormats) {
      // Handle camelCase to snake_case conversion for some formats
      const esFormat = format === 'artCrop' ? 'art_crop' : 
                      format === 'borderCrop' ? 'border_crop' : format;
      
      if (firestoreData.firebaseImageUris[format] !== elasticsearchData.image_uris[esFormat]) {
        logger.info(`Image URI mismatch for format ${format}/${esFormat}`);
        return false;
      }
    }
  }

  // Note: imageDataStatus from Firestore is not mapped to Elasticsearch, so we don't check it

  return true;
}

/**
 * Sync card data to Elasticsearch
 * @param {string} cardId - The card ID
 * @param {any} cardData - The card data from Firestore
 * @return {Promise<void>} Promise that resolves when sync is complete
 */
async function syncCardToElasticsearch(cardId: string, cardData: any): Promise<void> {
  try {
    const syncService = getElasticsearchSyncService();
    await syncService.syncCard(cardData, cardId);
    logger.info(`Successfully synced card ${cardId} to Elasticsearch`);
  } catch (error) {
    logger.error(`Failed to sync card ${cardId} to Elasticsearch:`, error);
    throw error;
  }
}

/**
 * Process a task based on its type
 * @param {string} taskId - The task ID
 * @param {TaskData} taskData - The task data
 * @return {Promise<void>} Promise that resolves when processing is complete
 */
async function processTask(taskId: string, taskData: TaskData): Promise<void> {
  await updateTaskStatus(taskId, 'processing');

  switch (taskData.taskType) {
    case 'cardUpdate':
      await processCardUpdateTask(taskId, taskData.metadata as unknown as CardUpdateMetadata);
      break;
    default:
      throw new Error(`Unknown task type: ${taskData.taskType}`);
  }
}

/**
 * Process a card update task
 * @param {string} taskId - The task ID
 * @param {CardUpdateMetadata} metadata - The card update metadata
 * @return {Promise<void>} Promise that resolves when processing is complete
 */
async function processCardUpdateTask(taskId: string, metadata: CardUpdateMetadata): Promise<void> {
  const { cardId, skipImageDownload = false, reason } = metadata;

  logger.info(`Processing card update task for card: ${cardId}, reason: ${reason}`);

  // Get the card document
  const cardDoc = await db.collection('cards').doc(cardId).get();
  if (!cardDoc.exists) {
    throw new Error(`Card not found: ${cardId}`);
  }

  const cardData = cardDoc.data();
  const scryfallId = cardData?.identifiers?.scryfallId;

  if (!scryfallId) {
    throw new Error(`No Scryfall ID found for card: ${cardId}`);
  }

  // Fetch data from Scryfall
  logger.info(`Fetching Scryfall data for card: ${cardId} (scryfallId: ${scryfallId})`);
  const scryfallResponse = await fetch(`https://api.scryfall.com/cards/${scryfallId}`);

  if (!scryfallResponse.ok) {
    throw new Error(`Scryfall API error: ${scryfallResponse.status} ${scryfallResponse.statusText}`);
  }

  const scryfallCard = await scryfallResponse.json();

  // Prepare update data
  const updateData: Record<string, unknown> = {
    scryfallData: scryfallCard,
    updatedAt: admin.firestore.Timestamp.now(),
    importError: null, // Clear any previous errors
  };

  // Download and upload images if needed
  if (!skipImageDownload && scryfallCard.image_uris) {
    logger.info(`Processing images for card: ${cardId}`);

    try {
      const firebaseImageUris = await processCardImages(cardId, scryfallCard.image_uris);
      updateData.firebaseImageUris = firebaseImageUris;
      updateData.imageDataStatus = 'synced';
    } catch (imageError) {
      logger.warn(`Failed to process images for card ${cardId}:`, imageError);
      updateData.imageDataStatus = 'error';
      updateData.importError = `Image processing failed: ${imageError instanceof Error ? imageError.message : 'Unknown error'}`;
    }
  } else if (skipImageDownload && !cardData?.firebaseImageUris) {
    // If we're skipping image download but card has no images, mark as needs_images
    updateData.imageDataStatus = 'needs_images';
  }

  // Update the card document
  await db.collection('cards').doc(cardId).update(updateData);

  logger.info(`Successfully updated card: ${cardId}`);

  // Get the updated card data for Elasticsearch sync validation
  const updatedCardDoc = await db.collection('cards').doc(cardId).get();
  const updatedCardData = updatedCardDoc.data();

  if (updatedCardData) {
    try {
      // Check if Elasticsearch data is in sync
      logger.info(`Validating Elasticsearch sync for card: ${cardId}`);
      const elasticsearchData = await getCardFromElasticsearch(cardId);
      const isInSync = isCardDataInSync(updatedCardData, elasticsearchData);

      if (!isInSync) {
        logger.info(`Card ${cardId} is out of sync with Elasticsearch, syncing now...`);
        await syncCardToElasticsearch(cardId, updatedCardData);
        logger.info(`Successfully synced card ${cardId} to Elasticsearch`);
      } else {
        logger.info(`Card ${cardId} is already in sync with Elasticsearch`);
      }
    } catch (syncError) {
      // Log the error but don't fail the entire task
      logger.warn(`Failed to sync card ${cardId} to Elasticsearch, but card update was successful:`, syncError);
    }
  }

  // Mark task as completed
  await updateTaskStatus(taskId, 'completed');
}

/**
 * Process and upload card images from Scryfall URLs
 * @param {string} cardId - The card ID
 * @param {Record<string, string>} imageUris - Image URLs from Scryfall
 * @return {Promise<Record<string, string>>} Firebase image URLs
 */
async function processCardImages(cardId: string, imageUris: Record<string, string>): Promise<Record<string, string>> {
  const firebaseImageUris: Record<string, string> = {};

  const imageFormats = ['small', 'normal', 'large', 'png', 'art_crop', 'border_crop'];

  for (const format of imageFormats) {
    const url = imageUris[format];
    if (!url) continue;

    try {
      logger.info(`Downloading ${format} image for card: ${cardId}`);

      // Download image
      const response = await fetch(url);
      if (!response.ok) {
        logger.warn(`Failed to download ${format} image: ${response.status}`);
        continue;
      }

      const imageBuffer = Buffer.from(await response.arrayBuffer());

      // Determine file extension and content type
      const contentType = getContentType(url);
      const fileExtension = getFileExtension(contentType);
      const fileName = `${format}.${fileExtension}`;
      const storagePath = `cards/${cardId}/images/${fileName}`;

      // Upload to Firebase Storage
      const file = storage.file(storagePath);
      await file.save(imageBuffer, {
        metadata: {
          contentType: contentType,
        },
      });

      // Make the file publicly accessible
      await file.makePublic();

      // Get the download URL
      const downloadUrl = `https://storage.googleapis.com/${storage.name}/${storagePath}`;
      firebaseImageUris[format] = downloadUrl;

      logger.info(`Successfully uploaded ${format} image for card: ${cardId}`);
    } catch (error) {
      logger.warn(`Failed to process ${format} image for card ${cardId}:`, error);
      // Continue with other images
    }
  }

  if (Object.keys(firebaseImageUris).length === 0) {
    throw new Error('Failed to upload any images');
  }

  return firebaseImageUris;
}

/**
 * Update the status of a task in Firestore
 * @param {string} taskId - The task ID
 * @param {string} status - The new status
 * @param {string} errorMessage - Optional error message
 * @return {Promise<void>} Promise that resolves when update is complete
 */
async function updateTaskStatus(taskId: string, status: string, errorMessage?: string): Promise<void> {
  const updateData: Record<string, admin.firestore.FieldValue | string | admin.firestore.Timestamp> = {
    status,
    updatedAt: admin.firestore.Timestamp.now(),
  };

  if (status === 'processing') {
    updateData.startedAt = admin.firestore.Timestamp.now();
  }

  if (status === 'completed' || status === 'failed') {
    updateData.completedAt = admin.firestore.Timestamp.now();
  }

  if (errorMessage) {
    updateData.errorMessage = errorMessage;
  }

  await db.collection('tasks').doc(taskId).update(updateData);
}

/**
 * Get content type from URL
 * @param {string} url - The image URL
 * @return {string} The content type
 */
function getContentType(url: string): string {
  if (url.toLowerCase().includes('.png')) return 'image/png';
  if (url.toLowerCase().includes('.jpg') || url.toLowerCase().includes('.jpeg')) return 'image/jpeg';
  if (url.toLowerCase().includes('.webp')) return 'image/webp';
  return 'image/jpeg'; // Default fallback
}

/**
 * Get file extension from content type
 * @param {string} contentType - The content type
 * @return {string} The file extension
 */
function getFileExtension(contentType: string): string {
  switch (contentType) {
    case 'image/png':
      return 'png';
    case 'image/jpeg':
      return 'jpg';
    case 'image/webp':
      return 'webp';
    default:
      return 'jpg';
  }
}