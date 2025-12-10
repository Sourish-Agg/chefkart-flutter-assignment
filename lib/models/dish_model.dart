import 'package:flutter/foundation.dart';

class Dish {
  final String id;
  final String name;
  final String description;
  final String image;
  final double rating;
  final bool isVeg;
  final List<String> equipments;

  Dish({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
    required this.rating,
    required this.isVeg,
    required this.equipments,
  });

  factory Dish.fromJson(Map<String, dynamic> json) {
    return Dish(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'Unknown Dish',
      description: json['description'] ?? '',
      image: json['image'] ?? '',
      rating: _parseRating(json['rating']),
      // default to false unless JSON explicitly says true
      isVeg: (json['isVeg'] ?? json['is_veg']) != null ? (json['isVeg'] ?? json['is_veg']) == true : false,
      equipments: _parseEquipments(json['equipments'] ?? json['storage'] ?? json['equipments_list']),
    );
  }

  static double _parseRating(dynamic rating) {
    if (rating == null) return 0.0;
    if (rating is double) return rating;
    if (rating is int) return rating.toDouble();
    if (rating is String) return double.tryParse(rating) ?? 0.0;
    return 0.0;
  }

  static List<String> _parseEquipments(dynamic equipments) {
    if (equipments == null) return [];
    if (equipments is List) {
      return equipments.map((e) {
        if (e is String) return e;
        if (e is Map) {
          if (e.containsKey('name')) return e['name'].toString();
          final firstValue = e.values.isNotEmpty ? e.values.first : '';
          return firstValue.toString();
        }
        return e.toString();
      }).toList();
    }
    if (equipments is String) {
      return equipments.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    }
    return [];
  }
}

class Category {
  final String id;
  final String name;

  Category({
    required this.id,
    required this.name,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? json['title'] ?? '',
    );
  }
}

class PopularDish {
  final String id;
  final String name;
  final String image;

  PopularDish({
    required this.id,
    required this.name,
    required this.image,
  });

  factory PopularDish.fromJson(Map<String, dynamic> json) {
    return PopularDish(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      image: json['image'] ?? '',
    );
  }
}

// DISH DETAIL CLASSES
class DishDetail {
  final String id;
  final String name;
  final String description;
  final String image;
  final double rating;
  final String cookingTime;
  final String servings;
  final List<IngredientCategory> ingredients;
  final List<String> appliances;

  DishDetail({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
    required this.rating,
    required this.cookingTime,
    required this.servings,
    required this.ingredients,
    required this.appliances,
  });

  factory DishDetail.fromJson(Map<String, dynamic> json) {
    final List<IngredientCategory> ingredientsList = [];
    final List<String> appliancesList = [];

    final ingredientsObj = json['ingredients'];
    if (ingredientsObj is Map) {
      ingredientsObj.forEach((key, value) {
        if (key.toString().toLowerCase() == 'appliances') {
          if (value is List) {
            for (var appliance in value) {
              if (appliance is String) {
                appliancesList.add(appliance);
              } else if (appliance is Map) {
                if (appliance['name'] != null) appliancesList.add(appliance['name'].toString());
                else if (appliance.values.isNotEmpty) appliancesList.add(appliance.values.first.toString());
              }
            }
          } else if (value is String) {
            appliancesList.addAll(value.split(',').map((s) => s.trim()));
          }
        } else {
          // other ingredient categories (vegetables, spices, etc.)
          if (value is List) {
            final items = value.whereType<Map>().map((m) => IngredientItem.fromJson(Map<String, dynamic>.from(m))).toList();
            if (items.isNotEmpty) {
              final categoryName = key.toString().isNotEmpty ? (key[0].toUpperCase() + key.substring(1)) : 'Ingredients';
              ingredientsList.add(IngredientCategory(name: categoryName, items: items, isExpanded: true));
            }
          } else if (value is Map) {
            // sometimes category may have nested 'items' key
            final itemsList = value['items'];
            if (itemsList is List) {
              final items = itemsList.whereType<Map>().map((m) => IngredientItem.fromJson(Map<String, dynamic>.from(m))).toList();
              if (items.isNotEmpty) {
                final categoryName = key.toString().isNotEmpty ? (key[0].toUpperCase() + key.substring(1)) : 'Ingredients';
                ingredientsList.add(IngredientCategory(name: categoryName, items: items, isExpanded: true));
              }
            }
          }
        }
      });
    }

    return DishDetail(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'Unknown Dish',
      description: json['description'] ?? '',
      image: json['image'] ?? '',
      rating: Dish._parseRating(json['rating'] ?? json['rating_value'] ?? json['score']),
      cookingTime: json['timeToPrepare'] ?? json['cookingTime'] ?? json['cooking_time'] ?? '1 hour',
      servings: json['servings']?.toString() ?? json['serves']?.toString() ?? '2',
      ingredients: ingredientsList,
      appliances: appliancesList,
    );
  }
}

class IngredientCategory {
  final String name;
  final List<IngredientItem> items;
  bool isExpanded;

  IngredientCategory({
    required this.name,
    required this.items,
    this.isExpanded = true,
  });
}

class IngredientItem {
  final String name;
  final String quantity;

  IngredientItem({
    required this.name,
    required this.quantity,
  });

  factory IngredientItem.fromJson(Map<String, dynamic> json) {
    return IngredientItem(
      name: json['name'] ?? json['item'] ?? '',
      quantity: json['quantity']?.toString() ?? json['amount']?.toString() ?? '',
    );
  }
}
