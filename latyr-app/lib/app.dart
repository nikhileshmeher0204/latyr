import 'package:flutter/material.dart';
import 'package:latyr_app/core/theme/app_theme.dart';
import 'package:latyr_app/features/collections/presentation/collections_screen.dart';
import 'package:latyr_app/features/feed/presentation/capture_feed_screen.dart';
import 'package:latyr_app/features/subscription/presentation/paywall_modal.dart';

class LatyrApp extends StatelessWidget {
  const LatyrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Latyr',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: const LatyrHomeScreen(),
    );
  }
}

class LatyrHomeScreen extends StatefulWidget {
  const LatyrHomeScreen({super.key});

  @override
  State<LatyrHomeScreen> createState() => _LatyrHomeScreenState();
}

class _LatyrHomeScreenState extends State<LatyrHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    CaptureFeedScreen(),
    CollectionsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 2) {
            // Open Pro Paywall Modal with valid Navigator context
            PaywallModal.show(context);
          } else {
            setState(() => _currentIndex = index);
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dynamic_feed_rounded),
            label: 'Feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_copy_outlined),
            activeIcon: Icon(Icons.folder_copy_rounded),
            label: 'Collections',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star_rounded, color: AppTheme.warning),
            label: 'Pro',
          ),
        ],
      ),
    );
  }
}
