import { CardSearchService } from './cardSearchService';
export interface SyncOptions {
    batchSize?: number;
    createIndex?: boolean;
}
export declare class ElasticsearchSyncService {
    private cardSearchService;
    constructor();
    /**
     * Initialize the Elasticsearch index
     */
    initializeIndex(): Promise<void>;
    /**
     * Delete and recreate the index (for clean sync)
     */
    recreateIndex(): Promise<void>;
    /**
     * Sync a single card to Elasticsearch
     */
    syncCard(cardData: any, firestoreId?: string): Promise<void>;
    /**
     * Bulk sync multiple cards
     */
    bulkSyncCards(cards: Array<{
        data: any;
        id?: string;
    }>): Promise<void>;
    /**
     * Delete a card from Elasticsearch
     */
    deleteCard(cardId: string): Promise<void>;
    /**
     * Get the search service for direct queries
     */
    getSearchService(): CardSearchService;
}
//# sourceMappingURL=syncService.d.ts.map