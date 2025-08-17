import { ElasticsearchCard } from '../types/types';
export declare class CardTransformer {
    /**
     * Transform a Firestore card document (MTGJSON + Scryfall enriched) to Elasticsearch format
     * @param firestoreCard - Card data from Firestore (matches MtgCard model)
     * @param firestoreDocId - Optional Firestore document ID for reference
     */
    static transformForElasticsearch(firestoreCard: any, firestoreDocId?: string): ElasticsearchCard;
    private static transformImageUris;
    private static transformLegalities;
    private static extractPrices;
    private static extractScryfallPrices;
    private static extractRelatedCardIds;
    private static detectSynergyThemes;
    private static detectDeckArchetypes;
    private static calculateComboPotential;
    private static calculatePopularityScore;
    private static extractTribalTypes;
    private static extractMechanicCategories;
    private static calculateColorWeight;
    private static calculateFormatPlayability;
}
//# sourceMappingURL=cardTransformer.d.ts.map