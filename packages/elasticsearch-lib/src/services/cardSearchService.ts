import { Client } from '@elastic/elasticsearch';
import { 
  ElasticsearchCard, 
  SearchOptions, 
  SearchFilters,
  DeckBuildingContext,
  CardSuggestion 
} from '../types/types';
import { getElasticsearchConfig, validateElasticsearchConfig } from '../utils/config';

export class CardSearchService {
  private client: Client;
  private indexName: string;

  constructor() {
    validateElasticsearchConfig();
    const config = getElasticsearchConfig();
    
    this.indexName = config.indexName;
    
    const clientOptions: any = {
      node: config.node,
      maxRetries: config.maxRetries,
      requestTimeout: config.requestTimeout
    };

    // Add authentication if provided
    if (config.auth) {
      clientOptions.auth = config.auth;
    }

    // Add serverMode if specified (for Elastic Cloud serverless)
    if (config.serverMode === 'serverless') {
      clientOptions.serverMode = 'serverless';
    }

    this.client = new Client(clientOptions);
  }

  async createIndex(): Promise<void> {
    const indexMapping = require('../mappings/card_index_mapping.json');
    
    const exists = await this.client.indices.exists({ index: this.indexName });
    
    if (exists) {
      console.log(`Index ${this.indexName} already exists`);
      return;
    }

    await this.client.indices.create({
      index: this.indexName,
      body: indexMapping
    });
    
    console.log(`Index ${this.indexName} created successfully`);
  }

  async deleteIndex(): Promise<void> {
    const exists = await this.client.indices.exists({ index: this.indexName });
    
    if (exists) {
      await this.client.indices.delete({ index: this.indexName });
      console.log(`Index ${this.indexName} deleted`);
    }
  }

  async indexCard(card: ElasticsearchCard): Promise<void> {
    await this.client.index({
      index: this.indexName,
      id: card.uuid,
      body: card
    });
  }

  async bulkIndexCards(cards: ElasticsearchCard[]): Promise<void> {
    const operations = cards.flatMap(card => [
      { index: { _index: this.indexName, _id: card.uuid } },
      card
    ]);

    const response = await this.client.bulk({
      refresh: true,
      operations
    });

    if (response.errors) {
      const erroredDocuments: any[] = [];
      response.items.forEach((action, i) => {
        const operation = Object.keys(action)[0] as string;
        const actionResult = (action as any)[operation];
        if (actionResult && actionResult.error) {
          erroredDocuments.push({
            status: actionResult.status,
            error: actionResult.error,
            operation: operations[i * 2],
            document: operations[i * 2 + 1]
          });
        }
      });
      console.error('Bulk indexing errors:', erroredDocuments);
    }

    console.log(`Indexed ${cards.length} cards`);
  }

  async searchCards(options: SearchOptions): Promise<{
    cards: ElasticsearchCard[];
    total: number;
    aggregations?: any;
  }> {
    const query = this.buildQuery(options);
    
    const response = await this.client.search({
      index: this.indexName,
      body: query
    });

    return {
      cards: response.hits.hits.map((hit: any) => hit._source as ElasticsearchCard),
      total: typeof response.hits.total === 'number' 
        ? response.hits.total 
        : response.hits.total?.value || 0,
      aggregations: response.aggregations
    };
  }

  private buildQuery(options: SearchOptions): any {
    const must: any[] = [];
    const filter: any[] = [];
    const should: any[] = [];

    if (options.filters) {
      const filters = options.filters;

      if (filters.name) {
        must.push({
          match: {
            'name.suggest': {
              query: filters.name,
              operator: 'and'
            }
          }
        });
      }

      if (filters.text) {
        must.push({
          match: {
            oracle_text: {
              query: filters.text,
              operator: 'and'
            }
          }
        });
      }

      if (filters.colors && filters.colors.length > 0) {
        filter.push({
          terms: { colors: filters.colors }
        });
      }

      if (filters.colorIdentity && filters.colorIdentity.length > 0) {
        filter.push({
          terms: { color_identity: filters.colorIdentity }
        });
      }

      if (filters.types && filters.types.length > 0) {
        filter.push({
          terms: { types: filters.types }
        });
      }

      if (filters.subtypes && filters.subtypes.length > 0) {
        filter.push({
          terms: { subtypes: filters.subtypes }
        });
      }

      if (filters.keywords && filters.keywords.length > 0) {
        filter.push({
          terms: { keywords: filters.keywords }
        });
      }

      if (filters.manaValue) {
        const rangeQuery: any = {};
        if (filters.manaValue.min !== undefined) {
          rangeQuery.gte = filters.manaValue.min;
        }
        if (filters.manaValue.max !== undefined) {
          rangeQuery.lte = filters.manaValue.max;
        }
        filter.push({ range: { mana_value: rangeQuery } });
      }

      if (filters.rarity && filters.rarity.length > 0) {
        filter.push({
          terms: { rarity: filters.rarity }
        });
      }

      if (filters.sets && filters.sets.length > 0) {
        filter.push({
          terms: { set_code: filters.sets }
        });
      }

      if (filters.formats) {
        Object.entries(filters.formats).forEach(([format, legality]) => {
          filter.push({
            term: { [`legalities.${format}`]: legality }
          });
        });
      }

      if (filters.price) {
        const priceField = `prices.${filters.price.currency || 'usd'}`;
        const rangeQuery: any = {};
        if (filters.price.min !== undefined) {
          rangeQuery.gte = filters.price.min;
        }
        if (filters.price.max !== undefined) {
          rangeQuery.lte = filters.price.max;
        }
        filter.push({ range: { [priceField]: rangeQuery } });
      }
    }

    if (options.vectorSearch) {
      must.push({
        script_score: {
          query: { match_all: {} },
          script: {
            source: "cosineSimilarity(params.query_vector, 'ai_embeddings') + 1.0",
            params: {
              query_vector: options.vectorSearch.embedding
            }
          }
        }
      });
    }

    const query: any = {
      query: {
        bool: {
          must: must.length > 0 ? must : [{ match_all: {} }],
          filter,
          should
        }
      }
    };

    if (options.sort) {
      query.sort = options.sort.map(s => ({
        [s.field]: { order: s.order }
      }));
    }

    if (options.pagination) {
      query.from = options.pagination.from;
      query.size = options.pagination.size;
    } else {
      query.size = 20;
    }

    query.aggs = {
      colors: {
        terms: { field: 'colors', size: 10 }
      },
      types: {
        terms: { field: 'types', size: 20 }
      },
      rarities: {
        terms: { field: 'rarity', size: 10 }
      },
      mana_curve: {
        histogram: {
          field: 'mana_value',
          interval: 1,
          min_doc_count: 1
        }
      }
    };

    return query;
  }

  async suggestCardsForDeck(context: DeckBuildingContext): Promise<CardSuggestion[]> {
    const must: any[] = [];
    const should: any[] = [];
    const filter: any[] = [];

    filter.push({
      term: { [`legalities.${context.format}`]: 'legal' }
    });

    if (context.colorIdentity && context.colorIdentity.length > 0) {
      filter.push({
        bool: {
          must: context.colorIdentity.map(color => ({
            terms: { color_identity: [color] }
          }))
        }
      });
    }

    if (context.commander) {
      should.push({
        match: {
          oracle_text: {
            query: context.commander,
            boost: 2
          }
        }
      });
      should.push({
        terms: {
          synergy_themes: ['commander-synergy'],
          boost: 1.5
        }
      });
    }

    if (context.theme) {
      should.push({
        match: {
          oracle_text: {
            query: context.theme,
            boost: 1.5
          }
        }
      });
      should.push({
        terms: {
          synergy_themes: [context.theme],
          boost: 2
        }
      });
      should.push({
        terms: {
          mechanic_categories: [context.theme],
          boost: 1.5
        }
      });
    }

    if (context.strategyPreference) {
      should.push({
        terms: {
          deck_archetypes: [context.strategyPreference],
          boost: 1.5
        }
      });
    }

    if (context.budget) {
      filter.push({
        range: {
          'prices.usd': { lte: context.budget }
        }
      });
    }

    if (context.existingCards && context.existingCards.length > 0) {
      filter.push({
        bool: {
          must_not: {
            terms: { id: context.existingCards }
          }
        }
      });
    }

    const query = {
      query: {
        bool: {
          must: must.length > 0 ? must : [{ match_all: {} }],
          should,
          filter
        }
      },
      size: 100,
      sort: [
        { _score: { order: 'desc' } },
        { popularity_score: { order: 'desc' } },
        { edhrec_rank: { order: 'asc' } }
      ] as any
    };

    const response = await this.client.search({
      index: this.indexName,
      body: query
    });

    return response.hits.hits.map((hit: any) => {
      const card = hit._source as ElasticsearchCard;
      return {
        card,
        score: hit._score,
        reasons: this.generateSuggestionReasons(card, context),
        synergyScore: this.calculateSynergyScore(card, context),
        budgetFit: !context.budget || (card.prices?.usd || 0) <= context.budget,
        roleInDeck: this.determineCardRole(card)
      };
    });
  }

  private generateSuggestionReasons(card: ElasticsearchCard, context: DeckBuildingContext): string[] {
    const reasons: string[] = [];
    
    if (card.synergy_themes?.some(theme => context.theme && theme.includes(context.theme))) {
      reasons.push(`Synergizes with ${context.theme} theme`);
    }
    
    if (card.edhrec_rank && card.edhrec_rank < 1000) {
      reasons.push(`Popular card (EDHRec rank: ${card.edhrec_rank})`);
    }
    
    if (card.deck_archetypes?.includes(context.strategyPreference || '')) {
      reasons.push(`Fits ${context.strategyPreference} strategy`);
    }
    
    return reasons;
  }

  private calculateSynergyScore(card: ElasticsearchCard, context: DeckBuildingContext): number {
    let score = 0;
    
    if (card.synergy_themes?.some(theme => context.theme && theme.includes(context.theme))) {
      score += 30;
    }
    
    if (card.deck_archetypes?.includes(context.strategyPreference || '')) {
      score += 20;
    }
    
    if (card.edhrec_rank) {
      score += Math.max(0, 20 - (card.edhrec_rank / 500));
    }
    
    if (card.popularity_score) {
      score += card.popularity_score * 10;
    }
    
    return Math.min(100, score);
  }

  private determineCardRole(card: ElasticsearchCard): string {
    if (card.types.includes('Land')) {
      return 'Mana Base';
    }
    
    if (card.oracle_text?.toLowerCase().includes('draw')) {
      return 'Card Draw';
    }
    
    if (card.oracle_text?.toLowerCase().includes('destroy') || 
        card.oracle_text?.toLowerCase().includes('exile')) {
      return 'Removal';
    }
    
    if (card.types.includes('Creature')) {
      const power = parseFloat(card.power || '0');
      const manaValue = card.mana_value;
      
      if (power >= 5 || (power / manaValue > 1.5)) {
        return 'Threat';
      }
      return 'Creature';
    }
    
    if (card.oracle_text?.toLowerCase().includes('counter')) {
      return 'Counterspell';
    }
    
    if (card.oracle_text?.toLowerCase().includes('search your library')) {
      return 'Tutor';
    }
    
    if (card.oracle_text?.toLowerCase().includes('add') && 
        card.oracle_text?.toLowerCase().includes('mana')) {
      return 'Ramp';
    }
    
    return 'Utility';
  }

  async autocomplete(prefix: string, limit: number = 10): Promise<string[]> {
    const response = await this.client.search({
      index: this.indexName,
      body: {
        suggest: {
          card_suggest: {
            prefix,
            completion: {
              field: 'suggest',
              size: limit
            }
          }
        }
      }
    });

    const suggestions = response.suggest?.card_suggest?.[0]?.options;
    if (Array.isArray(suggestions)) {
      return suggestions.map((option: any) => option.text);
    }
    return [];
  }
}