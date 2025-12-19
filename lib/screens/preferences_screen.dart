import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  final List<String> _commonAllergens = [
    'Молоко',
    'Яйца',
    'Рыба',
    'Ракообразные',
    'Орехи',
    'Арахис',
    'Пшеница',
    'Соя',
    'Кунжут',
    'Глютен',
    'Лактоза',
    'Морепродукты',
    'Горчица',
    'Сельдерей',
    'Сухофрукты',
  ];

  final Set<String> _selectedAllergies = {};
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final preferences = await ApiService.getPreferences();
      
      setState(() {
        _selectedAllergies.clear();
        
        if (preferences['allergies'] != null) {
          final allergies = List<String>.from(preferences['allergies']);
          _selectedAllergies.addAll(allergies);
        }
      });
    } catch (e) {
      print('❌ Ошибка загрузки предпочтений: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка загрузки: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _savePreferences() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final success = await ApiService.updatePreferences(
        allergies: _selectedAllergies.toList(),
        dietaryPreferences: [],
        forbiddenProducts: [],
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Настройки сохранены'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Не удалось сохранить настройки');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка сохранения: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки питания'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _savePreferences,
              tooltip: 'Сохранить',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Аллергии
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Аллергии',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Отметьте продукты, на которые у вас аллергия. Рецепты с этими аллергенами будут скрыты или помечены.',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _commonAllergens.map((allergen) {
                              final isSelected = _selectedAllergies.contains(allergen);
                              return FilterChip(
                                label: Text(allergen),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedAllergies.add(allergen);
                                    } else {
                                      _selectedAllergies.remove(allergen);
                                    }
                                  });
                                },
                                selectedColor: Colors.red.withOpacity(0.2),
                                checkmarkColor: Colors.red,
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Кнопка сохранения
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _savePreferences,
                      icon: const Icon(Icons.save),
                      label: const Text('Сохранить настройки'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Информация
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue),
                              SizedBox(width: 8),
                              Text(
                                'Как это работает',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '• Рецепты будут фильтроваться по вашим аллергиям\n'
                            '• Вы увидите предупреждения о наличии аллергенов\n'
                            '• Можете включить фильтр "Только безопасные"\n'
                            '• Настройки влияют на все ваши рецепты',
                            style: TextStyle(color: Colors.blue[800]),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}