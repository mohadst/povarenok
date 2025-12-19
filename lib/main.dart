import 'package:flutter/material.dart';
import 'screens/recipes_screen.dart';
import 'screens/create_recipe_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/login_page.dart';
import 'screens/register_page.dart';
import 'screens/preferences_screen.dart';
import 'services/api_service.dart';

void main() {
  runApp(const MyApp());  
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final loggedIn = await ApiService.isLoggedIn();
    setState(() {
      isLoggedIn = loggedIn;
    });
  }

  void login() {
    setState(() {
      isLoggedIn = true;
    });
  }

  void logout() {
    ApiService.logout();
    setState(() {
      isLoggedIn = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cooking Assistant',
      theme: ThemeData(
        primaryColor: Colors.orange,
        primarySwatch: Colors.orange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: isLoggedIn 
          ? MainNavigationScreen(onLogout: logout)
          : LoginRegisterWrapper(
              onLogin: login,
              onCheckLogin: _checkLoginStatus,
            ),
      routes: {
        '/preferences': (context) => const PreferencesScreen(),
        '/create_recipe': (context) => const CreateRecipeScreen(),
      },
    );
  }
}

class LoginRegisterWrapper extends StatefulWidget {
  final VoidCallback onLogin;
  final VoidCallback onCheckLogin;
  
  const LoginRegisterWrapper({
    super.key, 
    required this.onLogin,
    required this.onCheckLogin,
  });

  @override
  State<LoginRegisterWrapper> createState() => _LoginRegisterWrapperState();
}

class _LoginRegisterWrapperState extends State<LoginRegisterWrapper> {
  bool showLogin = true;

  void toggle() {
    setState(() {
      showLogin = !showLogin;
    });
  }

  @override
  void initState() {
    super.initState();
    // Проверяем при запуске
    widget.onCheckLogin();
  }

  @override
  Widget build(BuildContext context) {
    return showLogin
        ? LoginPage(
            onLoginSuccess: () {
              widget.onLogin();
              widget.onCheckLogin();
            },
            onRegisterTap: toggle,
          )
        : RegisterPage(
            onRegisterSuccess: () {
              widget.onLogin();
              widget.onCheckLogin();
            },
            onLoginTap: toggle,
          );
  }
}

class MainNavigationScreen extends StatefulWidget {
  final VoidCallback onLogout;
  
  const MainNavigationScreen({super.key, required this.onLogout});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const RecipesScreen(),
      const FavoritesScreen(),
      const CreateRecipeScreen(),
      ProfileScreen(onLogout: widget.onLogout), // ПЕРЕДАЕМ onLogout
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Рецепты',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Избранное',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Создать',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Профиль',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}