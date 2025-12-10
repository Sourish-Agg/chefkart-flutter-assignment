import 'package:flutter/material.dart';
import '../models/dish_model.dart';
import '../services/api_service.dart';

class DishDetailScreen extends StatefulWidget {
  final String dishId;
  final Dish dish;

  const DishDetailScreen({super.key, required this.dishId, required this.dish});

  @override
  State<DishDetailScreen> createState() => _DishDetailScreenState();
}

class _DishDetailScreenState extends State<DishDetailScreen> {
  final ApiService _apiService = ApiService();
  DishDetail? _dishDetail;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadDishDetail();
  }

  Future<void> _loadDishDetail() async {
    try {
      final detail = await _apiService.fetchDishDetail(widget.dishId);
      final effectiveRating = (detail.rating <= 0.0) ? widget.dish.rating : detail.rating;
      setState(() {
        _dishDetail = DishDetail(
          id: detail.id,
          name: detail.name,
          description: detail.description,
          image: detail.image.isNotEmpty ? detail.image : widget.dish.image,
          rating: effectiveRating,
          cookingTime: detail.cookingTime,
          servings: detail.servings,
          ingredients: detail.ingredients,
          appliances: detail.appliances,
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  String _getValidImageUrl(String imageUrl) {
    if (imageUrl.isEmpty || !imageUrl.startsWith('http')) {
      return 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800';
    }
    return imageUrl;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(child: Text('Error: $_errorMessage'))
          : _dishDetail == null
          ? const Center(child: Text('No data available'))
          : SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildHeader(),
          _buildCookingTime(),
          _buildIngredientsSection(),
          _buildAppliancesSection(),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              _dishDetail!.name,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.5),
            ),
            const SizedBox(height: 8),
            Text(
              _dishDetail!.description,
              style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black54),
            ),
          ]),
        ),
        if (_dishDetail!.rating > 0)
          Container(
            margin: const EdgeInsets.only(left: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.green.shade600, borderRadius: BorderRadius.circular(8)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(_dishDetail!.rating.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              const SizedBox(width: 6),
              const Icon(Icons.star, size: 14, color: Colors.white),
            ]),
          ),
      ]),
    );
  }

  Widget _buildCookingTime() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(children: [
        const Icon(Icons.access_time, size: 22, color: Colors.black54),
        const SizedBox(width: 10),
        Text(_dishDetail!.cookingTime, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildIngredientsSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Stack(children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            image: DecorationImage(image: NetworkImage(_getValidImageUrl(_dishDetail!.image)), fit: BoxFit.cover, alignment: Alignment.centerRight),
          ),
        ),
        Container(
          height: 200,
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [Colors.white, Colors.white.withOpacity(0.9), Colors.transparent]),
          ),
        ),
      ]),
      Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Ingredients', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('For ${_dishDetail!.servings} people', style: const TextStyle(fontSize: 14, color: Colors.black54)),
          const SizedBox(height: 18),
          ..._dishDetail!.ingredients.map((category) => _buildIngredientCategory(category)).toList(),
        ]),
      ),
    ]);
  }

  Widget _buildIngredientCategory(IngredientCategory category) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      InkWell(
        onTap: () {
          setState(() {
            category.isExpanded = !category.isExpanded;
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${category.name} (${category.items.length.toString().padLeft(2, '0')})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            Icon(category.isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 26, color: Colors.black54),
          ]),
        ),
      ),
      if (category.isExpanded)
        ...category.items.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(item.name, style: const TextStyle(fontSize: 16)),
              Text(item.quantity, style: const TextStyle(fontSize: 16, color: Colors.black54)),
            ]),
          );
        }).toList(),
      const Divider(height: 24),
    ]);
  }

  Widget _buildAppliancesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Appliances', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _dishDetail!.appliances.length,
            itemBuilder: (context, index) {
              final appliance = _dishDetail!.appliances[index];
              return Container(
                width: 140,
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.kitchen, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(appliance, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                ]),
              );
            },
          ),
        ),
      ]),
    );
  }
}
