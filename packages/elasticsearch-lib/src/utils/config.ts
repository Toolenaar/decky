import * as dotenv from 'dotenv';
import * as path from 'path';

// Load environment variables from .env file
dotenv.config({ path: path.resolve(process.cwd(), '.env') });

export interface ElasticsearchConfig {
  node: string;
  auth?: 
    | { apiKey: string }
    | { username: string; password: string };
  indexName: string;
  maxRetries?: number;
  requestTimeout?: number;
  serverMode?: 'serverless' | 'traditional';
}

export function getElasticsearchConfig(): ElasticsearchConfig {
  const config: ElasticsearchConfig = {
    node: process.env.ELASTICSEARCH_URL || 'http://localhost:9200',
    indexName: process.env.ELASTICSEARCH_INDEX_NAME || 'mtg_cards',
    maxRetries: process.env.ELASTICSEARCH_MAX_RETRIES ? parseInt(process.env.ELASTICSEARCH_MAX_RETRIES) : 3,
    requestTimeout: process.env.ELASTICSEARCH_REQUEST_TIMEOUT ? parseInt(process.env.ELASTICSEARCH_REQUEST_TIMEOUT) : 30000,
    serverMode: (process.env.ELASTICSEARCH_SERVER_MODE as 'serverless' | 'traditional') || 'traditional'
  };

  // Prioritize API key authentication (modern approach)
  if (process.env.ELASTICSEARCH_API_KEY) {
    config.auth = {
      apiKey: process.env.ELASTICSEARCH_API_KEY
    };
  }
  // Fallback to username/password authentication
  else if (process.env.ELASTICSEARCH_USERNAME) {
    config.auth = {
      username: process.env.ELASTICSEARCH_USERNAME,
      password: process.env.ELASTICSEARCH_PASSWORD || ''
    };
  }

  return config;
}

export function validateElasticsearchConfig(): void {
  const config = getElasticsearchConfig();
  
  if (!config.node) {
    throw new Error('ELASTICSEARCH_URL is required in environment variables');
  }

  // Validate authentication configuration
  if (config.auth) {
    if ('apiKey' in config.auth && !config.auth.apiKey) {
      throw new Error('ELASTICSEARCH_API_KEY cannot be empty when using API key authentication');
    }
    if ('username' in config.auth && !config.auth.username) {
      throw new Error('ELASTICSEARCH_USERNAME is required when using username/password authentication');
    }
  }

  const authType = config.auth 
    ? ('apiKey' in config.auth ? 'API Key' : 'Username/Password')
    : 'No Auth';
  
  console.log(`Elasticsearch config loaded: ${config.node} (index: ${config.indexName}, auth: ${authType}, mode: ${config.serverMode})`);
}