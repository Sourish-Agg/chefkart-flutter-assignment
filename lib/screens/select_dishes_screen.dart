import 'package:flutter/material.dart';
import '../models/dish_model.dart';
import '../services/api_service.dart';
import 'dish_detail_screen.dart';

class SelectDishesScreen extends StatefulWidget {
  const SelectDishesScreen({super.key});

  @override
  State<SelectDishesScreen> createState() => _SelectDishesScreenState();
}

class _SelectDishesScreenState extends State<SelectDishesScreen> {
  final ApiService api = ApiService();

  List<Dish> dishes = [];
  List<PopularDish> popular = [];
  bool loading = true;
  int cartCount = 0;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final Map<String, dynamic> data = await api.fetchDishes();
    setState(() {
      dishes = List.generate(4, (_) => data['dishes'][0]); // show Masala Mughlai 4 times
      popular = data['popularDishes'];
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Select Dishes',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black),
        ),
        leading: const BackButton(color: Colors.black),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          ListView(
            padding: EdgeInsets.only(bottom: cartCount > 0 ? 100 : 20),
            children: [
              _dateTimeCard(),
              _filters(),
              _popular(),
              _recommended(),
            ],
          ),
          if (cartCount > 0) _cartBar(),
        ],
      ),
    );
  }

  Widget _dateTimeCard() {
    return Container(
      height: 90,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black, Colors.transparent],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 20),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Row(
                children: [
                  Icon(Icons.calendar_today),
                  SizedBox(width: 10),
                  Text('21 May 2021'),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.access_time),
                  SizedBox(width: 10),
                  Text('10:30 Pm-12:30 Pm'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: ['Italian', 'Indian', 'Indian', 'Indian']
              .map(
                (e) => Container(
              margin: const EdgeInsets.only(right: 12),
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.orange),
              ),
              child: Text(
                e,
                style: const TextStyle(
                    color: Colors.orange, fontWeight: FontWeight.w600),
              ),
            ),
          )
              .toList(),
        ),
      ),
    );
  }

  Widget _popular() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 0, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Popular Dishes',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: popular.length,
              itemBuilder: (_, i) {
                final p = popular[i];
                return Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 16),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundImage: NetworkImage(p.image),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        p.name,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                        maxLines: 2,
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

  Widget _recommended() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Recommended',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                const Text('Menu', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(
            dishes.length,
                (i) => _dishCard(dishes[i], i),
          ),
        ],
      ),
    );
  }

  Widget _dishCard(Dish dish, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 20),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      dish.name,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.green),
                      ),
                      child: const Icon(Icons.circle,
                          size: 8, color: Colors.green),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Text(
                            dish.rating.toStringAsFixed(1),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12),
                          ),
                          const Icon(Icons.star,
                              size: 12, color: Colors.white),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _appliance(),
                    const SizedBox(width: 12),
                    _appliance(),
                    const SizedBox(width: 18),
                    GestureDetector(
                      onTap: index == 0
                          ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DishDetailScreen(
                              dishId: dish.id,
                              dish: dish,
                            ),
                          ),
                        );
                      }
                          : null,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Ingredients',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                          SizedBox(height: 2),
                          Text('View list >',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.orange)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  dish.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Color(0xFF7A7A7A),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  dish.image,
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => setState(() => cartCount++),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border:
                      Border.all(color: Colors.orange, width: 1.5),
                    ),
                    child: const Text(
                      'Add',
                      style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _appliance() {
    return Column(
      children: const [
        Icon(Icons.kitchen, size: 18, color: Colors.grey),
        SizedBox(height: 4),
        Text('Refrigerator',
            style: TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _cartBar() {
    return Positioned(
      bottom: 20,
      left: 16,
      right: 16,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            const Icon(Icons.shopping_bag, color: Colors.white),
            const SizedBox(width: 12),
            Text(
              '$cartCount food items selected',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
