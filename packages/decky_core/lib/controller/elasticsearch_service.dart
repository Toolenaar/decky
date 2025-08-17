import 'dart:convert';
import 'dart:async';
import 'package:decky_core/static.dart';
import 'package:http/http.dart' as http;
import '../model/search/elasticsearch_response.dart';
import '../model/search/card_search_result.dart';

class ElasticsearchService {
  final String baseUrl;
  final String indexName;
  final String? apiKey;
  final String? username;
  final String? password;
  final Duration timeout;
  final http.Client _client;

  ElasticsearchService({
    this.baseUrl = Static.elasticsearchUrl,
    this.indexName = 'dexy-cards-dev',
    this.apiKey = Static.elasticsearchSearchKey,
    this.username,
    this.password,
    this.timeout = const Duration(seconds: 5),
    http.Client? client,
  }) : _client = client ?? http.Client();

  Future<List<CardSearchResult>> searchCards({required String query, int size = 10, int from = 0}) async {
    if (query.isEmpty) {
      return [];
    }

    try {
      final searchBody = {
        'query': {
          'bool': {
            'should': [
              {
                'match': {
                  'name': {'query': query, 'boost': 3.0, 'fuzziness': 'AUTO'},
                },
              },
              {
                'match': {
                  'text': {'query': query, 'boost': 1.0, 'fuzziness': 'AUTO'},
                },
              },
              {
                'match': {
                  'type': {'query': query, 'boost': 2.0, 'fuzziness': 'AUTO'},
                },
              },
              {
                'match': {
                  'subtypes': {'query': query, 'boost': 1.5, 'fuzziness': 'AUTO'},
                },
              },
              {
                'match': {
                  'setCode': {'query': query, 'boost': 1.5},
                },
              },
            ],
            'minimum_should_match': 1,
          },
        },
        'size': size,
        'from': from,
        '_source': ['uuid', 'name', 'mana_cost', 'type', 'set_code', 'rarity', 'colors', 'image_uris'],
        'highlight': {
          'fields': {'name': {}, 'text': {}, 'type': {}},
        },
      };

      final headers = <String, String>{'Content-Type': 'application/json'};

      // Add authentication headers
      if (apiKey != null) {
        headers['Authorization'] = 'ApiKey $apiKey';
      } else if (username != null && password != null) {
        final credentials = base64Encode(utf8.encode('$username:$password'));
        headers['Authorization'] = 'Basic $credentials';
      }

      final response = await _client
          .post(Uri.parse('$baseUrl/$indexName/_search'), headers: headers, body: jsonEncode(searchBody))
          .timeout(timeout);

      if (response.statusCode == 200) {
        final elasticsearchResponse = ElasticsearchResponse.fromJson(jsonDecode(response.body));

        return elasticsearchResponse.hits.hits.map((hit) {
          return CardSearchResult.fromElasticsearchHit(hit);
        }).toList();
      } else {
        throw Exception('Elasticsearch returned status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      if (e is TimeoutException) {
        throw Exception('Search request timed out');
      }
      rethrow;
    }
  }

  Future<bool> isHealthy() async {
    print('🔍 Testing Elasticsearch health...');
    print('📍 Base URL: $baseUrl');
    print('📂 Index: $indexName');
    print('🔑 API Key provided: ${apiKey != null}');

    final headers = <String, String>{'Content-Type': 'application/json'};

    // Add authentication headers
    if (apiKey != null) {
      headers['Authorization'] = 'ApiKey $apiKey';
      print('🔐 Using API Key authentication');
    } else if (username != null && password != null) {
      final credentials = base64Encode(utf8.encode('$username:$password'));
      headers['Authorization'] = 'Basic $credentials';
      print('🔐 Using Basic authentication');
    } else {
      print('❌ No authentication provided');
    }

    // For Serverless, try search first since cluster health is not available
    if (baseUrl.contains('.es.') && baseUrl.contains('elastic-cloud.com')) {
      print('🔭 Detected Elasticsearch Serverless, trying search endpoint directly...');
      return await _testSearchEndpoint(headers);
    }

    // For traditional Elasticsearch, try cluster health first
    try {
      print('🌐 Trying cluster health endpoint...');
      final response = await _client.get(Uri.parse('$baseUrl/_cluster/health'), headers: headers).timeout(timeout);

      print('📊 Cluster health response: ${response.statusCode}');
      if (response.statusCode == 200) {
        return true;
      } else {
        print('❌ Cluster health failed: ${response.body}');
      }
    } catch (e) {
      print('⚠️ Cluster health failed, trying search fallback: $e');
    }

    // Fallback to search endpoint
    return await _testSearchEndpoint(headers);
  }

  Future<bool> _testSearchEndpoint(Map<String, String> headers) async {
    try {
      final searchBody = {
        'query': {'match_all': {}},
        'size': 1,
      };

      print('🔍 Trying search endpoint...');
      final response = await _client
          .post(Uri.parse('$baseUrl/$indexName/_search'), headers: headers, body: jsonEncode(searchBody))
          .timeout(timeout);

      print('📊 Search response: ${response.statusCode}');
      if (response.statusCode != 200) {
        print('❌ Search failed: ${response.body}');
        return false;
      } else {
        print('✅ Search endpoint healthy!');
        return true;
      }
    } catch (e) {
      print('❌ Search endpoint failed: $e');
      return false;
    }
  }

  /// Test different authentication methods
  Future<void> testAuthentication() async {
    print('🧪 Testing different authentication methods...');

    // Test 1: No auth
    print('\n1️⃣ Testing without authentication...');
    await _testConnection({});

    // Test 2: API Key as provided
    if (apiKey != null) {
      print('\n2️⃣ Testing with API Key as provided...');
      await _testConnection({'Authorization': 'ApiKey $apiKey'});
    }

    // Test 3: API Key assuming it's already base64 encoded (Basic auth style)
    if (apiKey != null) {
      print('\n3️⃣ Testing API Key as Basic auth...');
      await _testConnection({'Authorization': 'Basic $apiKey'});
    }

    // Test 4: If the key looks like username:password encoded
    if (apiKey != null) {
      try {
        print('\n4️⃣ Testing if API key is encoded username:password...');
        final decoded = utf8.decode(base64Decode(apiKey!));
        print('🔓 Decoded key: $decoded');
        if (decoded.contains(':')) {
          await _testConnection({'Authorization': 'Basic $apiKey'});
        }
      } catch (e) {
        print('❌ Could not decode as base64: $e');
      }
    }
  }

  Future<void> _testConnection(Map<String, String> authHeaders) async {
    try {
      final headers = <String, String>{'Content-Type': 'application/json', ...authHeaders};

      // Try a simple search
      final searchBody = {
        'query': {'match_all': {}},
        'size': 1,
      };

      final response = await _client
          .post(Uri.parse('$baseUrl/$indexName/_search'), headers: headers, body: jsonEncode(searchBody))
          .timeout(timeout);

      print('📊 Response: ${response.statusCode}');
      if (response.statusCode != 200) {
        print('❌ Error: ${response.body}');
      } else {
        print('✅ Success!');
      }
    } catch (e) {
      print('❌ Connection failed: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}
