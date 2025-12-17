import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/dish_model.dart';

class ApiService {
  static const String baseUrl =
      'https://8b648f3c-b624-4ceb-9e7b-8028b7df0ad0.mock.pstmn.io/dishes/v1/';

  Future<Map<String, dynamic>> fetchDishes() async {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode != 200) {
      throw Exception('Failed to load dishes');
    }

    final data = json.decode(response.body);

    final List<Dish> dishes = [];
    final List<PopularDish> popular = [];

    if (data['dishes'] != null) {
      for (final d in data['dishes']) {
        dishes.add(Dish.fromJson(d));
      }
    }

    if (data['popularDishes'] != null) {
      for (final p in data['popularDishes']) {
        final popularDish = PopularDish.fromJson(p);
        popular.add(popularDish);

        dishes.add(
          Dish(
            id: popularDish.id,
            name: popularDish.name,
            description: '',
            image: popularDish.image,
            rating: 0.0,
            isVeg: true,
            equipments: const [],
          ),
        );
      }
    }

    return {
      'dishes': dishes,
      'popularDishes': popular,
    };
  }

  Future<DishDetail> fetchDishDetail(String id) async {
    final response = await http.get(Uri.parse('$baseUrl$id'));

    if (response.statusCode != 200) {
      throw Exception('Dish detail not available');
    }

    return DishDetail.fromJson(json.decode(response.body));
  }
}
