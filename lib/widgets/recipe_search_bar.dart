// lib/widgets/recipe_search_bar.dart
import 'package:flutter/material.dart';

class RecipeSearchBar extends StatefulWidget {
  final ValueChanged<String> onSearchChanged;
  final String initialText;
  
  const RecipeSearchBar({
    Key? key,
    required this.onSearchChanged,
    this.initialText = '',
  }) : super(key: key);

  @override
  _RecipeSearchBarState createState() => _RecipeSearchBarState();
}

class _RecipeSearchBarState extends State<RecipeSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialText;
    _controller.addListener(_onTextChanged);
  }
  
  void _onTextChanged() {
    widget.onSearchChanged(_controller.text);
  }
  
  void _clearSearch() {
    _controller.clear();
    _focusNode.unfocus();
  }
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        decoration: InputDecoration(
          hintText: 'Поиск рецептов...',
          prefixIcon: Icon(Icons.search),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: _clearSearch,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
      ),
    );
  }
}