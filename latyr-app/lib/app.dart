import 'package:flutter/material.dart';
import 'package:latyr_app/core/theme/app_theme.dart';
import 'package:latyr_app/features/collections/presentation/collections_screen.dart';
import 'package:latyr_app/features/feed/presentation/capture_feed_screen.dart';
import 'package:latyr_app/features/subscription/presentation/paywall_modal.dart';

class LatyrApp extends StatefulWidget {
  const LatyrApp({super.key});

  @override
  State<LatyrApp> createState() => _LatyrAppState();
}

class _LatyrAppState extends State<LatyrApp> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    CaptureFeedScreen(),
    CollectionsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Latyr',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            if (index == 2) {
              // Open Pro Paywall Modal
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
      ),
    );
  }
}
