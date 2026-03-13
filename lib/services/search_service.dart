import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
// ── Model ──────────────────────────────────────────────────────────────────────
 
class PolicyResult {
  final String id;
  final String title;
  final String ministry;
  final String date;
  final String excerpt;
  final String status;
  final int pages;
 
  const PolicyResult({
    required this.id,
    required this.title,
    required this.ministry,
    required this.date,
    required this.excerpt,
    required this.status,
    required this.pages,
  });
 
  factory PolicyResult.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PolicyResult(
      id: doc.id,
      title: data['title'] ?? '',
      ministry: data['ministry'] ?? '',
      date: data['date'] ?? '',
      excerpt: data['excerpt'] ?? '',
      status: data['status'] ?? '',
      pages: data['pages'] ?? 0,
    );
  }
}
//new added
class WebResult {
  final String title;
  final String link;
  final String snippet;

  WebResult({
    required this.title,
    required this.link,
    required this.snippet,
  });

  factory WebResult.fromJson(Map<String, dynamic> json) {
    return WebResult(
      title: json['title'] ?? '',
      link: json['link'] ?? '',
      snippet: json['snippet'] ?? '',
    );
  }
}
// ── Search Service ─────────────────────────────────────────────────────────────
 
class SearchService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
    static const String apiKey = "AIzaSyCzOp8HFnKz5MuZVS305s0hmMIT1GwQ5lo";
  static const String cx = "55e6560ed443a486a";
 
  // ── Search policies from Firestore ─────────────────────────────────────────
 
  Future<List<PolicyResult>> searchPolicies({
    String? query,
    String? ministry,
    String? year,
    String? status,
  }) async {
    try {
      Query<Map<String, dynamic>> ref = _db.collection('policies');
 
      // Filter by ministry
      if (ministry != null && ministry != 'All') {
        ref = ref.where('ministry', isEqualTo: ministry);
      }
 
      // Filter by status
      if (status != null && status != 'All') {
        ref = ref.where('status', isEqualTo: status.toLowerCase());
      }
 
      final snapshot = await ref.get();
 
      List<PolicyResult> results = snapshot.docs
          .map((doc) => PolicyResult.fromFirestore(doc))
          .toList();
 
      // Filter by year (client side)
      if (year != null && year != 'All') {
        results = results
            .where((p) => p.date.contains(year))
            .toList();
      }
 
      // Filter by search query (client side — searches title, ministry, excerpt)
      if (query != null && query.isNotEmpty) {
        final q = query.toLowerCase();
        results = results.where((p) {
          return p.title.toLowerCase().contains(q) ||
              p.ministry.toLowerCase().contains(q) ||
              p.excerpt.toLowerCase().contains(q);
        }).toList();
      }
 
      return results;
    } catch (e) {
      throw Exception('Search failed: $e');
    }
  }
 
 Future<List<WebResult>> searchWeb(String query) async {
  try {
    final url = Uri.parse(
      "https://www.googleapis.com/customsearch/v1?key=$apiKey&cx=$cx&q=$query",
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data["items"] == null) return [];

      return (data["items"] as List)
          .map((item) => WebResult.fromJson(item))
          .toList();
    } else {
      throw Exception("Google search failed");
    }
  } catch (e) {
    throw Exception("Web search error: $e");
  }
}
  // ── Get single policy by ID ────────────────────────────────────────────────
 
  Future<PolicyResult?> getPolicyById(String id) async {
    try {
      final doc = await _db.collection('policies').doc(id).get();
      if (!doc.exists) return null;
      return PolicyResult.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get policy: $e');
    }
  }
 
  // ── Get all ministries for filter chips ───────────────────────────────────
 
  Future<List<String>> getMinistries() async {
    try {
      final snapshot = await _db.collection('policies').get();
      final ministries = snapshot.docs
          .map((doc) => doc.data()['ministry'] as String? ?? '')
          .toSet()
          .toList();
      ministries.sort();
      return ['All', ...ministries];
    } catch (e) {
      return ['All', 'MeitY', 'MoE', 'MHA', 'MNRE'];
    }
  }
}