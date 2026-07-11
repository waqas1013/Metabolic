import 'package:flutter/material.dart';
import 'package:workout_journal/theme/app_theme.dart';
import 'package:workout_journal/screens/home_screen.dart';
import 'package:workout_journal/screens/history_screen.dart';
import 'package:workout_journal/screens/trends_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WorkoutJournalApp());
}

class WorkoutJournalApp extends StatelessWidget {
  const WorkoutJournalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Workout Journal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final _historyKey = GlobalKey<HistoryScreenState>();
  final _trendsKey = GlobalKey<TrendsScreenState>();

  void _onEntrySaved() {
    _historyKey.currentState?.refresh();
    _trendsKey.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(onEntrySaved: _onEntrySaved),
          HistoryScreen(key: _historyKey),
          TrendsScreen(key: _trendsKey),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.06),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() => _currentIndex = index);
            // Refresh data when switching to History or Trends
            if (index == 1) {
              _historyKey.currentState?.refresh();
            } else if (index == 2) {
              _trendsKey.currentState?.refresh();
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.fitness_center),
              activeIcon: Icon(Icons.fitness_center),
              label: 'Log',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              activeIcon: Icon(Icons.history),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.show_chart),
              activeIcon: Icon(Icons.show_chart),
              label: 'Trends',
            ),
          ],
        ),
      ),
    );
  }
}
