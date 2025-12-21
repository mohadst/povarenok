// lib/widgets/favorite_button.dart
import 'package:flutter/material.dart';
import 'package:cooking_assistant/services/api_service.dart'; // Изменено с povarenok на cooking_assistant

class FavoriteButton extends StatefulWidget {
  final int recipeId;
  final double size;
  final Color color;
  final Function(bool)? onChanged;

  const FavoriteButton({
    super.key,
    required this.recipeId,
    this.size = 30,
    this.color = Colors.red,
    this.onChanged,
  });

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
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
      final isFav = await ApiService.isFavorite(widget.recipeId);
      if (mounted) {
        setState(() => _isFavorite = isFav);
      }
    } catch (_) {}
  }

  Future<void> _toggleFavorite() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    bool success;
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

      // 🔥 УВЕДОМЛЯЕМ РОДИТЕЛЯ
      widget.onChanged?.call(_isFavorite);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isFavorite ? 'Добавлено в избранное' : 'Удалено из избранного',
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: _isLoading
          ? SizedBox(
              width: widget.size,
              height: widget.size,
              child: const CircularProgressIndicator(strokeWidth: 2),
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