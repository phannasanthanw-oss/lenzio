// จุดเริ่มต้นแอป Lenzio — กำหนด Theme และ Shell (Bottom Navigation)
import 'package:flutter/material.dart';
import 'core/constants.dart';
import 'screens/home/home_page.dart';
import 'screens/camera/camera_list_page.dart';
import 'screens/lens/lens_list_page.dart';
import 'screens/recipe/recipe_page.dart';
import 'screens/review/review_page.dart';

void main() => runApp(const LenzioApp());

class LenzioApp extends StatelessWidget {
  const LenzioApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lenzio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: kPrimary),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: const Shell(),
    );
  }
}

/// Shell — Bottom Navigation Bar ควบคุม 5 Tab หลัก
class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _index = 0;
  final _pages = const [
    HomePage(),
    CameraListPage(),
    LensListPage(),
    RecipePage(),
    ReviewPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _index, children: _pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.photo_camera_outlined), selectedIcon: Icon(Icons.photo_camera), label: 'กล้อง'),
          NavigationDestination(icon: Icon(Icons.camera_outlined), selectedIcon: Icon(Icons.camera), label: 'เลนส์'),
          NavigationDestination(icon: Icon(Icons.auto_awesome_outlined), selectedIcon: Icon(Icons.auto_awesome), label: 'Recipe'),
          NavigationDestination(icon: Icon(Icons.favorite_border), selectedIcon: Icon(Icons.favorite), label: 'รีวิว'),
        ],
      ),
    );
  }
}
