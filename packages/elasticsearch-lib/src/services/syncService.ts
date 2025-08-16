import { CardSearchService } from './cardSearchService';
import { CardTransformer } from './cardTransformer';
import { ElasticsearchCard } from '../types/types';
import { validateElasticsearchConfig } from '../utils/config';

export interface SyncOptions {
  batchSize?: number;
  createIndex?: boolean;
}

export class ElasticsearchSyncService {
  private cardSearchService: CardSearchService;

  constructor() {
    validateElasticsearchConfig();
    this.cardSearchService = new CardSearchService();
  }

  /**
   * Initialize the Elasticsearch index
   */
  async initializeIndex(): Promise<void> {
    await this.cardSearchService.createIndex();
  }

  /**
   * Delete and recreate the index (for clean sync)
   */
  async recreateIndex(): Promise<void> {
    await this.cardSearchService.deleteIndex();
    await this.cardSearchService.createIndex();
  }

  /**
   * Sync a single card to Elasticsearch
   */
  async syncCard(cardData: any, firestoreId?: string): Promise<void> {
    const esCard = CardTransformer.transformForElasticsearch(cardData, firestoreId);
    await this.cardSearchService.indexCard(esCard);
  }

  /**
   * Bulk sync multiple cards
   */
  async bulkSyncCards(cards: Array<{ data: any; id?: string }>): Promise<void> {
    const esCards: ElasticsearchCard[] = cards.map(card => 
      CardTransformer.transformForElasticsearch(card.data, card.id)
    );
    
    if (esCards.length > 0) {
      await this.cardSearchService.bulkIndexCards(esCards);
    }
  }

  /**
   * Delete a card from Elasticsearch
   */
  async deleteCard(cardId: string): Promise<void> {
    try {
      const client = (this.cardSearchService as any).client;
      await client.delete({
        index: 'mtg_cards',
        id: cardId
      });
    } catch (error: any) {
      if (error.statusCode !== 404) {
        throw error;
      }
      // Card doesn't exist in ES, that's okay
    }
  }

  /**
   * Get the search service for direct queries
   */
  getSearchService(): CardSearchService {
    return this.cardSearchService;
  }
}