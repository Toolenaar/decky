/**
 * Utility functions for Elasticsearch API key management
 */

/**
 * Creates a base64 encoded API key from id and key components
 * This is useful when you have separate id and api_key values from Elasticsearch
 * 
 * @param id - The API key id
 * @param apiKey - The API key value
 * @returns Base64 encoded API key for use in client configuration
 */
export function encodeApiKey(id: string, apiKey: string): string {
  const combined = `${id}:${apiKey}`;
  return Buffer.from(combined).toString('base64');
}

/**
 * Decodes a base64 API key back to its components
 * Useful for debugging or logging (be careful with sensitive data)
 * 
 * @param encodedKey - Base64 encoded API key
 * @returns Object with id and apiKey components
 */
export function decodeApiKey(encodedKey: string): { id: string; apiKey: string } {
  const decoded = Buffer.from(encodedKey, 'base64').toString('utf-8');
  const [id, apiKey] = decoded.split(':');
  return { id, apiKey };
}

/**
 * Validates that an API key is properly base64 encoded
 * 
 * @param apiKey - The API key to validate
 * @returns true if valid, false otherwise
 */
export function isValidApiKey(apiKey: string): boolean {
  try {
    const decoded = Buffer.from(apiKey, 'base64').toString('utf-8');
    return decoded.includes(':') && decoded.split(':').length === 2;
  } catch {
    return false;
  }
}

/**
 * Example usage and instructions for generating API keys
 */
export const API_KEY_INSTRUCTIONS = `
To create an API key for Elasticsearch:

1. **Elastic Cloud (recommended):**
   - Go to your deployment in Elastic Cloud
   - Navigate to Security > API Keys
   - Click "Create API key"
   - Copy the encoded key directly

2. **Self-managed Elasticsearch:**
   - Use Elasticsearch API or Kibana
   - POST /_security/api_key
   - Encode the response: encodeApiKey(id, api_key)

3. **Using this utility:**
   import { encodeApiKey } from './apiKey';
   const encoded = encodeApiKey('your-id', 'your-api-key');
   console.log('ELASTICSEARCH_API_KEY=' + encoded);

Example .env configuration:
ELASTICSEARCH_URL=https://your-cluster.es.region.gcp.elastic.cloud:443
ELASTICSEARCH_API_KEY=encoded_key_here
ELASTICSEARCH_SERVER_MODE=serverless
ELASTICSEARCH_INDEX_NAME=mtg_cards
`;