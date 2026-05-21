import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/exercise_library/screens/exercise_library_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/reports/screens/reports_screen.dart';
import 'features/workout_templates/screens/workout_list_screen.dart';

class OverloadApp extends StatelessWidget {
  const OverloadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Overload',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  final _screens = const [
    WorkoutListScreen(),
    ExerciseLibraryScreen(),
    ReportsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.fitness_center),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_books),
            label: 'Exercícios',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart),
            label: 'Relatórios',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
