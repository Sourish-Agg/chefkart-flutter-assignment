import 'package:flutter/material.dart';
import '../models/dish_model.dart';
import '../services/api_service.dart';

class DishDetailScreen extends StatefulWidget {
  final String dishId;
  final Dish dish;

  const DishDetailScreen({
    super.key,
    required this.dishId,
    required this.dish,
  });

  @override
  State<DishDetailScreen> createState() => _DishDetailScreenState();
}

class _DishDetailScreenState extends State<DishDetailScreen> {
  final ApiService api = ApiService();
  DishDetail? detail;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final d = await api.fetchDishDetail(widget.dishId);
    setState(() {
      detail = d;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(context),
            _ingredients(),
            _appliances(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: SizedBox(
        height: 240,
        child: Stack(
          children: [
            Positioned(
              right: -90,
              top: -40,
              child: Container(
                width: 280,
                height: 280,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF5EA),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: -40,
              top: 30,
              child: Image.network(
                'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe',
                width: 180,
                fit: BoxFit.contain,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.dish.name,
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Text(
                            widget.dish.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Icon(
                            Icons.star,
                            size: 14,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.6,
                  child: Text(
                    widget.dish.description,
                    style: const TextStyle(
                      color: Colors.black54,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.6,
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        detail!.cookingTime,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _ingredients() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ingredients',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'For 2 people',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 20),
          _ingredientBlock(
              'Vegetables (05)', detail!.ingredients.first.items),
          _ingredientBlock(
              'Spices (10)', detail!.ingredients.last.items),
        ],
      ),
    );
  }

  Widget _ingredientBlock(String title, List<IngredientItem> items) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              const Icon(Icons.keyboard_arrow_down),
            ],
          ),
        ),
        ...items.map(
              (i) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Text(i.name, style: const TextStyle(fontSize: 16)),
                const Spacer(),
                Text(i.quantity,
                    style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
        ),
        const Divider(height: 24),
      ],
    );
  }

  Widget _appliances() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Appliances',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 130,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              itemBuilder: (_, __) {
                return Container(
                  width: 110,
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.kitchen,
                          size: 40, color: Colors.grey),
                      SizedBox(height: 10),
                      Text(
                        'Refrigerator',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
