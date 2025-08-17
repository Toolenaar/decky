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
export declare function encodeApiKey(id: string, apiKey: string): string;
/**
 * Decodes a base64 API key back to its components
 * Useful for debugging or logging (be careful with sensitive data)
 *
 * @param encodedKey - Base64 encoded API key
 * @returns Object with id and apiKey components
 */
export declare function decodeApiKey(encodedKey: string): {
    id: string;
    apiKey: string;
};
/**
 * Validates that an API key is properly base64 encoded
 *
 * @param apiKey - The API key to validate
 * @returns true if valid, false otherwise
 */
export declare function isValidApiKey(apiKey: string): boolean;
/**
 * Example usage and instructions for generating API keys
 */
export declare const API_KEY_INSTRUCTIONS = "\nTo create an API key for Elasticsearch:\n\n1. **Elastic Cloud (recommended):**\n   - Go to your deployment in Elastic Cloud\n   - Navigate to Security > API Keys\n   - Click \"Create API key\"\n   - Copy the encoded key directly\n\n2. **Self-managed Elasticsearch:**\n   - Use Elasticsearch API or Kibana\n   - POST /_security/api_key\n   - Encode the response: encodeApiKey(id, api_key)\n\n3. **Using this utility:**\n   import { encodeApiKey } from './apiKey';\n   const encoded = encodeApiKey('your-id', 'your-api-key');\n   console.log('ELASTICSEARCH_API_KEY=' + encoded);\n\nExample .env configuration:\nELASTICSEARCH_URL=https://your-cluster.es.region.gcp.elastic.cloud:443\nELASTICSEARCH_API_KEY=encoded_key_here\nELASTICSEARCH_SERVER_MODE=serverless\nELASTICSEARCH_INDEX_NAME=mtg_cards\n";
//# sourceMappingURL=apiKey.d.ts.map