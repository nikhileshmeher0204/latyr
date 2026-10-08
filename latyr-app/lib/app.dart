import 'dart:ui' as dart_ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:latyr_app/core/theme/app_theme.dart';
import 'package:latyr_app/features/collections/presentation/collections_screen.dart';
import 'package:latyr_app/features/home/presentation/home_screen.dart';
import 'package:latyr_app/features/search/presentation/search_screen.dart';

class LatyrApp extends StatelessWidget {
  const LatyrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'Latyr',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        DefaultMaterialLocalizations.delegate,
      ],
      theme: AppTheme.cupertinoTheme(),
      builder: (context, child) {
        return DefaultTextStyle.merge(
          style: const TextStyle(
            fontFamily: 'Inter',
            letterSpacing: -0.15,
            decoration: TextDecoration.none,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const LatyrTabNavigationScreen(),
    );
  }
}

class LatyrTabNavigationScreen extends StatefulWidget {
  const LatyrTabNavigationScreen({super.key});

  @override
  State<LatyrTabNavigationScreen> createState() => _LatyrTabNavigationScreenState();
}

class _LatyrTabNavigationScreenState extends State<LatyrTabNavigationScreen> {
  int _currentIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) return;
    setState(() {
      _currentIndex = index;
    });
    // iOS style smooth slide transition
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    SystemChrome.setSystemUIOverlayStyle(
      (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(
        statusBarColor: const Color(0x00000000), // Ensure transparent status bar
      ),
    );

    return Stack(
      children: [
        PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(), // Disable swipe-to-scroll to match tab bar behavior
          children: const [
            HomeScreen(),
            CollectionsScreen(),
            SearchScreen(),
          ],
        ),
        // Custom Floating Navigation Bar
        Positioned(
          bottom: 30, // Align below the FAB
          left: 0,
          right: 0,
          child: Center(
            child: _buildFloatingNavBar(isDark),
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingNavBar(bool isDark) {
    // Semi-transparent colors for frosted glass
    final bgColor = (isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white).withValues(alpha: 0.75);
    final shadowColor = isDark ? Colors.black54 : const Color(0x22000000);

    final tabs = [
      {'icon': CupertinoIcons.house_fill, 'label': 'Home'},
      {'icon': CupertinoIcons.folder_fill, 'label': 'Collections'},
      {'icon': CupertinoIcons.search, 'label': 'Search'},
    ];

    final int selectedIndex = _currentIndex;
    final activeBg = isDark ? const Color(0xFF3A3A3C).withValues(alpha: 0.9) : const Color(0xFFEFEFEF).withValues(alpha: 0.9);

    const double tabWidth = 80.0;
    const double padding = 6.0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: dart_ui.ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
          child: Container(
            padding: const EdgeInsets.all(padding),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(40),
            ),
            // Use IntrinsicHeight to let children size the container
            child: IntrinsicHeight(
        child: Stack(
          children: [
            // The sliding background pill
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              left: selectedIndex * tabWidth,
              top: 0,
              bottom: 0,
              child: Container(
                width: tabWidth,
                decoration: BoxDecoration(
                  color: activeBg,
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
            
            // The icons and labels
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(tabs.length, (index) {
                return _buildNavItem(
                  index: index,
                  icon: tabs[index]['icon'] as IconData,
                  label: tabs[index]['label'] as String,
                  isDark: isDark,
                  width: tabWidth,
                );
              }),
            ),
          ],
        ),
      ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isDark,
    required double width,
  }) {
    final isSelected = _currentIndex == index;
    final textColor = isDark ? Colors.white : const Color(0xFF1E1E1E);
    final inactiveTextColor = isDark ? CupertinoColors.systemGrey : const Color(0xFF1E1E1E);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        _onTabTapped(index);
      },
      child: SizedBox(
        width: width,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? textColor : inactiveTextColor,
                size: 24,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontFamily: 'InterRounded',
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? textColor : inactiveTextColor,
                  letterSpacing: 0.1,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
