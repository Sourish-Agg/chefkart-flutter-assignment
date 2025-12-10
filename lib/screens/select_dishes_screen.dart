import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/dish_model.dart';
import '../services/api_service.dart';
import 'dish_detail_screen.dart';

class SelectDishesScreen extends StatefulWidget {
  const SelectDishesScreen({super.key});

  @override
  State<SelectDishesScreen> createState() => _SelectDishesScreenState();
}

class _SelectDishesScreenState extends State<SelectDishesScreen> {
  final ApiService _apiService = ApiService();
  List<Dish> _allDishes = [];
  List<PopularDish> _popularDishes = [];
  List<Category> _categories = [];
  List<Dish> _filteredDishes = [];
  Set<String> _selectedDishIds = {};
  String _selectedCategory = '';
  bool _isLoading = true;
  String _errorMessage = '';

  DateTime _selectedDate = DateTime.now();
  String _selectedTime = '';

  @override
  void initState() {
    super.initState();
    _loadDishes();
  }

  Future<void> _loadDishes() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final data = await _apiService.fetchDishes();

      final List<Dish> dishes = (data['dishes'] as List<Dish>?) ?? [];
      final List<PopularDish> popular = (data['popularDishes'] as List<PopularDish>?) ?? [];
      final List<Category> cats = (data['categories'] as List<Category>?) ?? [];

      final merged = _mergeAndDedupeDishes(dishes, popular);

      setState(() {
        _allDishes = merged;
        _popularDishes = popular;
        _categories = cats;
        _selectedCategory = _categories.isNotEmpty ? _categories.first.name : 'All';
        _filterDishesByCategory();
        _isLoading = false;
      });

      _fillMissingRatings();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Dish> _mergeAndDedupeDishes(List<Dish> dishes, List<PopularDish> popular) {
    final Map<String, Dish> map = {};

    for (var d in dishes) {
      final key = d.id.isNotEmpty ? d.id : '${d.name}-${d.image}';
      map[key] = d;
    }

    for (var p in popular) {
      final key = p.id.isNotEmpty ? p.id : '${p.name}-${p.image}';
      if (map.containsKey(key)) {
        continue;
      }

      Dish? foundByName;
      for (var v in map.values) {
        if (v.name.toLowerCase() == p.name.toLowerCase()) {
          foundByName = v;
          break;
        }
      }

      if (foundByName != null) {
        map[key] = foundByName;
        continue;
      }

      map[key] = Dish(
        id: p.id ?? '',
        name: p.name,
        description: '',
        image: p.image ?? '',
        rating: -1.0,
        isVeg: false,
        equipments: [],
      );
    }

    return map.values.toList();
  }

  Future<void> _fillMissingRatings() async {
    for (int i = 0; i < _allDishes.length; i++) {
      final dish = _allDishes[i];
      if ((dish.rating <= 0.0) && dish.id.isNotEmpty) {
        try {
          final detail = await _api_service_fetchDishDetailSafe(dish.id);
          final newRating = detail.rating > 0.0 ? detail.rating : dish.rating;
          final updatedDish = Dish(
            id: dish.id,
            name: dish.name,
            description: dish.description,
            image: dish.image.isNotEmpty ? dish.image : detail.image,
            rating: newRating,
            isVeg: dish.isVeg,
            equipments: dish.equipments.isNotEmpty ? dish.equipments : detail.appliances,
          );
          setState(() {
            _allDishes[i] = updatedDish;
            for (int j = 0; j < _filteredDishes.length; j++) {
              if (_filteredDishes[j].id == updatedDish.id || (_filteredDishes[j].id.isEmpty && _filteredDishes[j].name == updatedDish.name)) {
                _filteredDishes[j] = updatedDish;
              }
            }
          });
        } catch (_) {}
      }
    }
  }

  Future<DishDetail> _api_service_fetchDishDetailSafe(String id) async {
    try {
      return await _apiService.fetchDishDetail(id);
    } catch (_) {
      return DishDetail(
        id: id,
        name: '',
        description: '',
        image: '',
        rating: 0.0,
        cookingTime: '',
        servings: '2',
        ingredients: [],
        appliances: [],
      );
    }
  }

  void _filterDishesByCategory() {
    if (_selectedCategory.isEmpty || _selectedCategory == 'All') {
      setState(() {
        _filteredDishes = List<Dish>.from(_allDishes);
      });
      return;
    }
    setState(() {
      _filteredDishes = _allDishes.where((d) {
        final cat = (d as dynamic).category ?? '';
        return cat.toString().toLowerCase() == _selectedCategory.toLowerCase();
      }).toList();
    });
  }

  void _toggleDishSelection(String dishId) {
    setState(() {
      if (_selectedDishIds.contains(dishId)) {
        _selectedDishIds.remove(dishId);
      } else {
        _selectedDishIds.add(dishId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)), title: const Text('Select Dishes', style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w600))),
      body: _isLoading
          ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Loading dishes...')]))
          : _errorMessage.isNotEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Error loading data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_errorMessage, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _loadDishes, child: const Text('Retry'))
          ]),
        ),
      )
          : Column(children: [
        _buildDateTimeSection(),
        _buildCategoryTabs(),
        _buildPopularDishes(),
        _buildDishList(),
        if (_selectedDishIds.isNotEmpty) _buildBottomBar()
      ]),
    );
  }

  Widget _buildDateTimeSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Row(children: [
        Expanded(
          child: Row(children: [
            const Icon(Icons.calendar_today, size: 20),
            const SizedBox(width: 8),
            Text(DateFormat('dd MMM yyyy').format(_selectedDate), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))
          ]),
        ),
        Container(width: 1, height: 30, color: Colors.grey.shade300, margin: const EdgeInsets.symmetric(horizontal: 16)),
        Expanded(
          child: Row(children: [
            const Icon(Icons.access_time, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(_selectedTime.isNotEmpty ? _selectedTime : 'Select time', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)))
          ]),
        )
      ]),
    );
  }

  Widget _buildCategoryTabs() {
    if (_categories.isEmpty) {
      return Container(height: 50, padding: const EdgeInsets.symmetric(horizontal: 16), child: ListView(scrollDirection: Axis.horizontal, children: [_buildCategoryChip('All')]));
    }
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final name = cat.name.isNotEmpty ? cat.name : 'Category';
          return _buildCategoryChip(name);
        },
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final isSelected = _selectedCategory == category;
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: ChoiceChip(
        label: Text(category),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = category;
            _filterDishesByCategory();
          });
        },
        labelStyle: TextStyle(color: isSelected ? Colors.orange : Colors.grey, fontWeight: FontWeight.w600),
        backgroundColor: Colors.white,
        selectedColor: Colors.white,
        side: BorderSide(color: isSelected ? Colors.orange : Colors.grey.shade300, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
  }

  Widget _buildPopularDishes() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Padding(padding: EdgeInsets.fromLTRB(16, 20, 16, 12), child: Text('Popular Dishes', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800))),
      SizedBox(
        height: 110,
        child: _popularDishes.isEmpty
            ? const Center(child: Text('No popular dishes'))
            : ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _popularDishes.length,
          itemBuilder: (context, index) {
            final popularDish = _popularDishes[index];
            return Container(
              margin: const EdgeInsets.only(right: 12),
              child: Column(children: [
                Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.orange, width: 3), image: DecorationImage(image: NetworkImage(popularDish.image.isNotEmpty ? popularDish.image : 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=400'), fit: BoxFit.cover)),
                  child: Center(
                    child: Text(popularDish.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, shadows: [Shadow(color: Colors.black26, blurRadius: 3)])),
                  ),
                ),
              ]),
            );
          },
        ),
      ),
    ]);
  }

  Widget _buildDishList() {
    if (_filteredDishes.isEmpty) {
      return const Expanded(child: Center(child: Text('No dishes available')));
    }

    return Expanded(
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: const [Text('Recommended', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)), SizedBox(width: 8), Icon(Icons.keyboard_arrow_down, color: Colors.grey)]),
            Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)), child: const Text('Menu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)))
          ]),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filteredDishes.length,
            itemBuilder: (context, index) {
              return _buildDishCard(_filteredDishes[index]);
            },
          ),
        ),
      ]),
    );
  }

  Widget _buildDishCard(Dish dish) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(dish.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700))),
                const SizedBox(width: 8),
                Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(border: Border.all(color: Colors.green, width: 1.5), borderRadius: BorderRadius.circular(6)), child: Icon(dish.isVeg ? Icons.circle : Icons.change_history, color: Colors.green, size: 12)),
                const SizedBox(width: 8),
                if (dish.rating > 0)
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.green.shade600, borderRadius: BorderRadius.circular(6)), child: Row(mainAxisSize: MainAxisSize.min, children: [Text(dish.rating.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)), const SizedBox(width: 4), const Icon(Icons.star, color: Colors.white, size: 12)]))
                else
                  const SizedBox.shrink()
              ]),
              const SizedBox(height: 12),
              Row(children: [
                ..._buildEquipmentsWidgets(dish),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => DishDetailScreen(dishId: dish.id, dish: dish)));
                  },
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [Text('Ingredients', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)), SizedBox(height: 2), Row(children: [Text('View list', style: TextStyle(color: Colors.orange, fontSize: 12)), SizedBox(width: 4), Icon(Icons.arrow_forward_ios, color: Colors.orange, size: 10)])]),
                )
              ]),
              const SizedBox(height: 12),
              Text(dish.description, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            ]),
          ),
          const SizedBox(width: 12),
          Stack(children: [
            ClipRRect(borderRadius: BorderRadius.circular(16), child: dish.image.isNotEmpty && dish.image.startsWith('http') ? Image.network(dish.image, width: 130, height: 130, fit: BoxFit.cover, errorBuilder: (context, err, st) => Container(width: 130, height: 130, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.restaurant, size: 40))) : Container(width: 130, height: 130, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.restaurant, size: 40))),
            Positioned(bottom: 10, right: 10, child: GestureDetector(onTap: () => _toggleDishSelection(dish.id), child: Container(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange, width: 2), boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.12), blurRadius: 8, offset: const Offset(0, 3))]), child: Text(_selectedDishIds.contains(dish.id) ? 'Added' : 'Add', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 15))))),
          ]),
        ]),
      ]),
    );
  }

  List<Widget> _buildEquipmentsWidgets(Dish dish) {
    final List<Widget> widgets = [];
    final count = dish.equipments.length >= 2 ? 2 : dish.equipments.length;
    for (int i = 0; i < count; i++) {
      widgets.add(Padding(padding: const EdgeInsets.only(right: 12), child: Column(children: [Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300, width: 1), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.kitchen, size: 22, color: Colors.grey[700])), const SizedBox(height: 6), Text(dish.equipments[i], style: TextStyle(fontSize: 10, color: Colors.grey[600]))])));
    }
    return widgets;
  }

  Widget _buildBottomBar() {
    return Container(padding: const EdgeInsets.all(16), decoration: const BoxDecoration(color: Colors.black, borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))), child: SafeArea(child: Row(children: [const Icon(Icons.restaurant_menu, color: Colors.white, size: 24), const SizedBox(width: 12), Expanded(child: Text('${_selectedDishIds.length} food items selected', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600))), const Icon(Icons.arrow_forward, color: Colors.white, size: 24)])));
  }
}
