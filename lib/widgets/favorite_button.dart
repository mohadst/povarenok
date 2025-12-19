// lib/widgets/favorite_button.dart
import 'package:flutter/material.dart';
import 'package:cooking_assistant/services/api_service.dart'; // Изменено с povarenok на cooking_assistant

class FavoriteButton extends StatefulWidget {
  final int recipeId;
  final double size;
  final Color color;
  final Function(bool)? onChanged;
  
  const FavoriteButton({
    Key? key,
    required this.recipeId,
    this.size = 30,
    this.color = Colors.red,
    this.onChanged,
  }) : super(key: key);

  @override
  _FavoriteButtonState createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  bool _isFavorite = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    try {
      setState(() => _isLoading = true);
      final isFav = await ApiService.isFavorite(widget.recipeId);
      setState(() {
        _isFavorite = isFav;
        _isLoading = false;
      });
    } catch (e) {
      print('Ошибка проверки избранного: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    final bool success;
    
    if (_isFavorite) {
      success = await ApiService.removeFromFavorites(widget.recipeId);
    } else {
      success = await ApiService.addToFavorites(widget.recipeId);
    }
    
    if (success && mounted) {
      setState(() {
        _isFavorite = !_isFavorite;
        _isLoading = false;
      });
      widget.onChanged?.call(_isFavorite);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isFavorite 
              ? 'Добавлено в избранное' 
              : 'Удалено из избранного'),
          duration: Duration(seconds: 1),
        ),
      );
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при обновлении избранного'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: _isLoading
          ? SizedBox(
              width: widget.size,
              height: widget.size,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(widget.color),
              ),
            )
          : Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? widget.color : Colors.grey,
              size: widget.size,
            ),
      onPressed: _toggleFavorite,
    );
  }
}