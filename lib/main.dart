import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:metabolic/firebase_options.dart';
import 'package:metabolic/theme/app_theme.dart';
import 'package:metabolic/screens/home_screen.dart';
import 'package:metabolic/screens/history_screen.dart';
import 'package:metabolic/screens/trends_screen.dart';
import 'package:metabolic/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MetabolicApp());
}

class MetabolicApp extends StatelessWidget {
  const MetabolicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Metabolic',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Still loading auth state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              ),
            );
          }

          // User is signed in → show main app
          if (snapshot.hasData) {
            return const MainNavigation();
          }

          // User is not signed in → show login
          return LoginScreen(
            onLoginSuccess: () {
              // StreamBuilder will automatically rebuild when auth state changes
            },
          );
        },
      ),
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
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
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
      ),
    );
  }
}
