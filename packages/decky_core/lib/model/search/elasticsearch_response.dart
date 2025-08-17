class ElasticsearchResponse {
  final ElasticsearchHits hits;
  final int took;
  final bool timedOut;

  ElasticsearchResponse({
    required this.hits,
    required this.took,
    required this.timedOut,
  });

  factory ElasticsearchResponse.fromJson(Map<String, dynamic> json) {
    return ElasticsearchResponse(
      hits: ElasticsearchHits.fromJson(json['hits']),
      took: json['took'] ?? 0,
      timedOut: json['timed_out'] ?? false,
    );
  }
}

class ElasticsearchHits {
  final List<ElasticsearchHit> hits;
  final int total;
  final double? maxScore;

  ElasticsearchHits({
    required this.hits,
    required this.total,
    this.maxScore,
  });

  factory ElasticsearchHits.fromJson(Map<String, dynamic> json) {
    final totalValue = json['total'];
    int total = 0;
    
    if (totalValue is int) {
      total = totalValue;
    } else if (totalValue is Map<String, dynamic>) {
      total = totalValue['value'] ?? 0;
    }

    return ElasticsearchHits(
      hits: (json['hits'] as List<dynamic>)
          .map((hit) => ElasticsearchHit.fromJson(hit))
          .toList(),
      total: total,
      maxScore: json['max_score']?.toDouble(),
    );
  }
}

class ElasticsearchHit {
  final String index;
  final String id;
  final double? score;
  final Map<String, dynamic> source;
  final Map<String, List<String>>? highlight;

  ElasticsearchHit({
    required this.index,
    required this.id,
    this.score,
    required this.source,
    this.highlight,
  });

  factory ElasticsearchHit.fromJson(Map<String, dynamic> json) {
    Map<String, List<String>>? highlight;
    if (json['highlight'] != null) {
      highlight = {};
      final highlightData = json['highlight'] as Map<String, dynamic>;
      highlightData.forEach((key, value) {
        if (value is List) {
          highlight![key] = value.map((e) => e.toString()).toList();
        }
      });
    }

    return ElasticsearchHit(
      index: json['_index'] ?? '',
      id: json['_id'] ?? '',
      score: json['_score']?.toDouble(),
      source: json['_source'] ?? {},
      highlight: highlight,
    );
  }
}