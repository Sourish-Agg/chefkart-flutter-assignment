import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/dish_model.dart';

class ApiService {
  static const String allDishesUrl =
      'https://8b648f3c-b624-4ceb-9e7b-8028b7df0ad0.mock.pstmn.io/dishes/v1/';
  static const String singleDishBaseUrl =
      'https://8b648f3c-b624-4ceb-9e7b-8028b7df0ad0.mock.pstmn.io/dishes/v1/';

  Future<Map<String, dynamic>> fetchDishes() async {
    try {
      final response = await http.get(
        Uri.parse(allDishesUrl),
        headers: {'Content-Type': 'application/json'},
      );

      final body = response.body;

      if (response.statusCode != 200) {
        // Print body for debugging non-200 responses too
        print('API /dishes returned status ${response.statusCode}. Body: $body');
        throw Exception('Failed to load dishes. Status: ${response.statusCode}');
      }

      // Print the raw body once to inspect actual shape (remove later)
      print(
          'DEBUG: /dishes raw response (truncated to 2000 chars): ${body.length > 2000 ? body.substring(0, 2000) + " ...[truncated]" : body}');

      final data = json.decode(body);

      final List<dynamic> candidateLists = [];
      Map<String, dynamic>? candidateMap; // in case API returns a map of dishes

      void addIfList(dynamic maybeList) {
        if (maybeList is List) candidateLists.addAll(maybeList);
      }

      if (data is List) {
        candidateLists.addAll(data);
      } else if (data is Map) {
        final keysToCheck = [
          'dishes',
          'data',
          'items',
          'results',
          'payload',
          'rows',
          'list'
        ];

        for (var k in keysToCheck) {
          if (data.containsKey(k)) {
            final v = data[k];
            if (v is List) {
              candidateLists.addAll(v);
            } else if (v is Map) {
              if (v.containsKey('dishes') && v['dishes'] is List) {
                candidateLists.addAll(v['dishes']);
              } else if (v.containsKey('items') && v['items'] is List) {
                candidateLists.addAll(v['items']);
              } else if (v.containsKey('results') && v['results'] is List) {
                candidateLists.addAll(v['results']);
              } else {
                try {
                  candidateMap = Map<String, dynamic>.from(v);
                } catch (_) {
                  candidateMap = v.map((key, value) => MapEntry(key.toString(), value));
                }
              }
            } else if (v is String) {
              try {
                final parsed = json.decode(v);
                if (parsed is List) candidateLists.addAll(parsed);
                else if (parsed is Map) {
                  try {
                    candidateMap = Map<String, dynamic>.from(parsed);
                  } catch (_) {
                    candidateMap = parsed.map((key, value) => MapEntry(key.toString(), value));
                  }
                }
              } catch (_) {}
            }
          }
        }

        if (candidateLists.isEmpty) {
          bool looksLikeDishMap = true;
          int examined = 0;
          for (var val in data.values.take(5)) {
            if (!(val is Map || val is List)) {
              looksLikeDishMap = false;
              break;
            }
            examined++;
          }
          if (looksLikeDishMap) {
            try {
              candidateMap = Map<String, dynamic>.from(data);
            } catch (_) {
              candidateMap = data.map((key, value) => MapEntry(key.toString(), value));
            }
          }
        }
      }

      if (candidateMap != null && candidateLists.isEmpty) {
        candidateLists.addAll(candidateMap!.values);
      }

      final List<Dish> dishes = [];
      for (var item in candidateLists) {
        try {
          if (item is Map) {
            dishes.add(Dish.fromJson(Map<String, dynamic>.from(item)));
          } else if (item is String) {
            final parsed = json.decode(item);
            if (parsed is Map) dishes.add(Dish.fromJson(Map<String, dynamic>.from(parsed)));
            else {
              dishes.add(Dish(
                  id: '',
                  name: item.toString(),
                  description: '',
                  image: '',
                  rating: 0.0,
                  isVeg: false,
                  equipments: []));
            }
          } else {
            dishes.add(Dish(
                id: '',
                name: item.toString(),
                description: '',
                image: '',
                rating: 0.0,
                isVeg: false,
                equipments: []));
          }
        } catch (e) {
          print('DEBUG: skipping malformed dish item: $e');
        }
      }

      final List<PopularDish> popularDishes = [];
      final List<Category> categories = [];

      try {
        if (data is Map && data['popularDishes'] is List) {
          for (var p in data['popularDishes']) {
            if (p is Map) popularDishes.add(PopularDish.fromJson(Map<String, dynamic>.from(p)));
          }
        } else if (data is Map && data['popular'] is List) {
          for (var p in data['popular']) {
            if (p is Map) popularDishes.add(PopularDish.fromJson(Map<String, dynamic>.from(p)));
          }
        }
      } catch (_) {}

      try {
        if (data is Map && data['categories'] is List) {
          for (var c in data['categories']) {
            if (c is Map) categories.add(Category.fromJson(Map<String, dynamic>.from(c)));
          }
        }
      } catch (_) {}

      // Debug summary: print counts + first few names/ids
      print('DEBUG: Parsed dishes count = ${dishes.length}');
      if (dishes.isNotEmpty) {
        final sample = dishes.take(5).map((d) => '${d.id.isNotEmpty ? d.id : '-'}:${d.name}').toList();
        print('DEBUG: sample dishes => ${sample.join(' | ')}');
      }

      return {
        'dishes': dishes,
        'popularDishes': popularDishes,
        'categories': categories,
      };
    } catch (e) {
      print('ERROR in fetchDishes: $e');
      throw Exception('Error fetching dishes: $e');
    }
  }

  Future<DishDetail> fetchDishDetail(String dishId) async {
    try {
      final String dishDetailUrl = '$singleDishBaseUrl$dishId';
      final response = await http.get(
        Uri.parse(dishDetailUrl),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        print('API /dishes/$dishId returned status ${response.statusCode}. Body: ${response.body}');
        throw Exception('Failed to load dish detail. Status: ${response.statusCode}');
      }

      final data = json.decode(response.body);
      if (data is Map) {
        return DishDetail.fromJson(Map<String, dynamic>.from(data));
      } else {
        throw Exception('Unexpected dish detail format');
      }
    } catch (e) {
      print('ERROR in fetchDishDetail: $e');
      throw Exception('Error fetching dish detail: $e');
    }
  }
}
