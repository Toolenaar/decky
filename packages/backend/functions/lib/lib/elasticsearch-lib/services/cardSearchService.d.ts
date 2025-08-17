import { ElasticsearchCard, SearchOptions, DeckBuildingContext, CardSuggestion } from '../types/types';
export declare class CardSearchService {
    private client;
    private indexName;
    constructor();
    createIndex(): Promise<void>;
    deleteIndex(): Promise<void>;
    indexCard(card: ElasticsearchCard): Promise<void>;
    bulkIndexCards(cards: ElasticsearchCard[]): Promise<void>;
    searchCards(options: SearchOptions): Promise<{
        cards: ElasticsearchCard[];
        total: number;
        aggregations?: any;
    }>;
    private buildQuery;
    suggestCardsForDeck(context: DeckBuildingContext): Promise<CardSuggestion[]>;
    private generateSuggestionReasons;
    private calculateSynergyScore;
    private determineCardRole;
    autocomplete(prefix: string, limit?: number): Promise<string[]>;
}
//# sourceMappingURL=cardSearchService.d.ts.map