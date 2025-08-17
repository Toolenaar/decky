import 'dart:convert';
import 'dart:async';
import 'package:decky_core/static.dart';
import 'package:http/http.dart' as http;
import '../model/search/elasticsearch_response.dart';
import '../model/search/card_search_result.dart';
import '../model/search/search_filters.dart';
import '../model/search/filter_options.dart';

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

  Future<List<CardSearchResult>> searchCardsWithFilters({
    SearchFilters filters = const SearchFilters(),
    int size = 20,
    int from = 0,
  }) async {
    try {
      final searchBody = _buildFilteredQuery(filters, size, from);

      final headers = <String, String>{'Content-Type': 'application/json'};

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
        final responseBody = jsonDecode(response.body);
        final elasticsearchResponse = ElasticsearchResponse.fromJson(responseBody);

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

  Future<FilterOptions> getFilterOptions() async {
    try {
      final searchBody = {
        'query': {'match_all': {}},
        'size': 0,
        'aggs': {
          'colors': {
            'terms': {'field': 'colors', 'size': 10},
          },
          'types': {
            'terms': {'field': 'types', 'size': 20},
          },
          'subtypes': {
            'terms': {'field': 'subtypes', 'size': 100},
          },
          'supertypes': {
            'terms': {'field': 'supertypes', 'size': 10},
          },
          'rarities': {
            'terms': {'field': 'rarity', 'size': 10},
          },
          'sets': {
            'terms': {'field': 'set_code', 'size': 100},
          },
          'keywords': {
            'terms': {'field': 'keywords', 'size': 100},
          },
          'layouts': {
            'terms': {'field': 'layout', 'size': 20},
          },
          'frame_effects': {
            'terms': {'field': 'frame_effects', 'size': 20},
          },
        },
      };

      final headers = <String, String>{'Content-Type': 'application/json'};

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
        final responseData = jsonDecode(response.body);
        final aggregations = responseData['aggregations'] as Map<String, dynamic>;

        return _parseFilterOptions(aggregations);
      } else {
        return FilterOptions.defaults();
      }
    } catch (e) {
      return FilterOptions.defaults();
    }
  }

  Future<List<String>> getAutocompleteSuggestions(String query, {int limit = 10}) async {
    if (query.isEmpty) return [];

    try {
      final searchBody = {
        'suggest': {
          'card_suggest': {
            'prefix': query,
            'completion': {'field': 'suggest', 'size': limit},
          },
        },
      };

      final headers = <String, String>{'Content-Type': 'application/json'};

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
        final responseData = jsonDecode(response.body);
        final suggestions = responseData['suggest']?['card_suggest']?[0]?['options'] as List?;

        if (suggestions != null) {
          return suggestions.map((option) => option['text'] as String).toList();
        }
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  Map<String, dynamic> _buildFilteredQuery(SearchFilters filters, int size, int from) {
    final must = <Map<String, dynamic>>[];
    final filter = <Map<String, dynamic>>[];
    final should = <Map<String, dynamic>>[];

    // Text search
    if (filters.query?.isNotEmpty == true) {
      must.add({
        'bool': {
          'should': [
            {
              'match': {
                'name': {'query': filters.query, 'boost': 3.0, 'fuzziness': 'AUTO'},
              },
            },
            {
              'match': {
                'text': {'query': filters.query, 'boost': 1.0, 'fuzziness': 'AUTO'},
              },
            },
            {
              'match': {
                'type': {'query': filters.query, 'boost': 2.0, 'fuzziness': 'AUTO'},
              },
            },
            {
              'match': {
                'subtypes': {'query': filters.query, 'boost': 1.5, 'fuzziness': 'AUTO'},
              },
            },
          ],
          'minimum_should_match': 1,
        },
      });
    }

    // Oracle text search
    if (filters.oracleText?.isNotEmpty == true) {
      must.add({
        'match': {
          'text': {'query': filters.oracleText, 'operator': 'and'},
        },
      });
    }

    // Colors
    if (filters.colors?.isNotEmpty == true) {
      // Try multiple field variations to handle different Elasticsearch mappings
      filter.add({
        'bool': {
          'should': [
            {
              'terms': {'colors': filters.colors},
            }, // Standard array field
            {
              'terms': {'colors.keyword': filters.colors},
            }, // Keyword mapped field
            {
              'terms': {'color': filters.colors},
            }, // Alternative singular field name
          ],
          'minimum_should_match': 1,
        },
      });
    }

    // Color Identity
    if (filters.colorIdentity?.isNotEmpty == true) {
      filter.add({
        'terms': {'color_identity': filters.colorIdentity},
      });
    }

    // Types
    if (filters.types?.isNotEmpty == true) {
      filter.add({
        'terms': {'types': filters.types},
      });
    }

    // Subtypes
    if (filters.subtypes?.isNotEmpty == true) {
      filter.add({
        'terms': {'subtypes': filters.subtypes},
      });
    }

    // Supertypes
    if (filters.supertypes?.isNotEmpty == true) {
      filter.add({
        'terms': {'supertypes': filters.supertypes},
      });
    }

    // Keywords
    if (filters.keywords?.isNotEmpty == true) {
      filter.add({
        'terms': {'keywords': filters.keywords},
      });
    }

    // Mana Value Range
    if (filters.manaValue?.hasValue == true) {
      final rangeQuery = <String, dynamic>{};
      if (filters.manaValue!.min != null) {
        rangeQuery['gte'] = filters.manaValue!.min;
      }
      if (filters.manaValue!.max != null) {
        rangeQuery['lte'] = filters.manaValue!.max;
      }
      filter.add({
        'range': {'mana_value': rangeQuery},
      });
    }

    // Power Range
    if (filters.power?.hasValue == true) {
      final rangeQuery = <String, dynamic>{};
      if (filters.power!.min != null) {
        rangeQuery['gte'] = filters.power!.min;
      }
      if (filters.power!.max != null) {
        rangeQuery['lte'] = filters.power!.max;
      }
      filter.add({
        'range': {'power.numeric': rangeQuery},
      });
    }

    // Toughness Range
    if (filters.toughness?.hasValue == true) {
      final rangeQuery = <String, dynamic>{};
      if (filters.toughness!.min != null) {
        rangeQuery['gte'] = filters.toughness!.min;
      }
      if (filters.toughness!.max != null) {
        rangeQuery['lte'] = filters.toughness!.max;
      }
      filter.add({
        'range': {'toughness.numeric': rangeQuery},
      });
    }

    // Rarities
    if (filters.rarities?.isNotEmpty == true) {
      filter.add({
        'terms': {'rarity': filters.rarities},
      });
    }

    // Sets
    if (filters.sets?.isNotEmpty == true) {
      filter.add({
        'terms': {'set_code': filters.sets},
      });
    }

    // Format Legalities
    if (filters.formatLegalities?.isNotEmpty == true) {
      for (final entry in filters.formatLegalities!.entries) {
        filter.add({
          'term': {'legalities.${entry.key}': entry.value},
        });
      }
    }

    // Price Range
    if (filters.price?.hasValue == true) {
      final priceField = 'prices.${filters.priceCurrency ?? 'usd'}';
      final rangeQuery = <String, dynamic>{};
      if (filters.price!.min != null) {
        rangeQuery['gte'] = filters.price!.min;
      }
      if (filters.price!.max != null) {
        rangeQuery['lte'] = filters.price!.max;
      }
      filter.add({
        'range': {priceField: rangeQuery},
      });
    }

    // Boolean filters
    if (filters.isReserved != null) {
      filter.add({
        'term': {'is_reserved': filters.isReserved},
      });
    }
    if (filters.isPromo != null) {
      filter.add({
        'term': {'is_promo': filters.isPromo},
      });
    }
    if (filters.isFullArt != null) {
      filter.add({
        'term': {'is_full_art': filters.isFullArt},
      });
    }
    if (filters.isReprint != null) {
      filter.add({
        'term': {'is_reprint': filters.isReprint},
      });
    }

    // Layout
    if (filters.layout?.isNotEmpty == true) {
      filter.add({
        'term': {'layout': filters.layout},
      });
    }

    // Frame Effects
    if (filters.frameEffects?.isNotEmpty == true) {
      filter.add({
        'terms': {'frame_effects': filters.frameEffects},
      });
    }

    // Artist
    if (filters.artist?.isNotEmpty == true) {
      must.add({
        'match': {
          'artist': {'query': filters.artist, 'fuzziness': 'AUTO'},
        },
      });
    }

    final query = {
      'query': {
        'bool': {
          'must': must.isEmpty
              ? [
                  {'match_all': {}},
                ]
              : must,
          'filter': filter,
          'should': should,
        },
      },
      'size': size,
      'from': from,
      '_source': ['uuid', 'name', 'mana_cost', 'type', 'set_code', 'rarity', 'colors', 'image_uris', 'mana_value'],
      'highlight': {
        'fields': {'name': {}, 'text': {}, 'type': {}},
      },
    };

    // Add sorting
    if (filters.sortBy?.isNotEmpty == true) {
      query['sort'] = [
        {
          filters.sortBy!: {'order': filters.sortOrder ?? 'desc'},
        },
      ];
    } else {
      query['sort'] = [
        {
          '_score': {'order': 'desc'},
        },
        {
          'name.keyword': {'order': 'asc'},
        },
      ];
    }

    return query;
  }

  FilterOptions _parseFilterOptions(Map<String, dynamic> aggregations) {
    final defaults = FilterOptions.defaults();

    // Parse sets from aggregations
    final sets = <SetOption>[];
    final setsAgg = aggregations['sets']?['buckets'] as List?;
    if (setsAgg != null) {
      for (final bucket in setsAgg) {
        sets.add(
          SetOption(
            code: bucket['key'],
            name: bucket['key'], // Would need set name mapping
            cardCount: bucket['doc_count'],
          ),
        );
      }
    }

    // Parse other aggregations
    final subtypes = <String>[];
    final subtypesAgg = aggregations['subtypes']?['buckets'] as List?;
    if (subtypesAgg != null) {
      subtypes.addAll(subtypesAgg.map((bucket) => bucket['key'] as String));
    }

    final keywords = <String>[];
    final keywordsAgg = aggregations['keywords']?['buckets'] as List?;
    if (keywordsAgg != null) {
      keywords.addAll(keywordsAgg.map((bucket) => bucket['key'] as String));
    }

    return defaults.copyWith(sets: sets, subtypes: subtypes, keywords: keywords);
  }

  void dispose() {
    _client.close();
  }
}
