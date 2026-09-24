import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:latyr_app/core/design/latyr_colors.dart';
import 'package:latyr_app/features/collections/presentation/collections_screen.dart';
import 'package:latyr_app/features/feed/presentation/capture_feed_screen.dart';
import 'package:latyr_app/features/search/presentation/search_screen.dart';
import 'package:latyr_app/features/subscription/presentation/pro_screen.dart';

class LatyrApp extends StatelessWidget {
  const LatyrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'Latyr',
      debugShowCheckedModeBanner: false,
      theme: CupertinoThemeData(
        primaryColor: LColors.brandAmber,
      ),
      home: LatyrTabNavigationScreen(),
    );
  }
}

class LatyrTabNavigationScreen extends StatefulWidget {
  const LatyrTabNavigationScreen({super.key});

  @override
  State<LatyrTabNavigationScreen> createState() => _LatyrTabNavigationScreenState();
}

class _LatyrTabNavigationScreenState extends State<LatyrTabNavigationScreen> {
  final CupertinoTabController _tabController = CupertinoTabController();

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    SystemChrome.setSystemUIOverlayStyle(
      isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    );

    return CupertinoTabScaffold(
      controller: _tabController,
      tabBar: CupertinoTabBar(
        activeColor: LColors.brandAmber,
        inactiveColor: CupertinoColors.inactiveGray,
        backgroundColor: CupertinoColors.systemBackground.resolveFrom(context).withValues(
          alpha: isDark ? 0.85 : 0.9,
        ),
        border: Border(
          top: BorderSide(
            color: CupertinoColors.separator.resolveFrom(context).withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.rectangle_stack),
            activeIcon: Icon(CupertinoIcons.rectangle_stack_fill),
            label: 'Captures',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.folder),
            activeIcon: Icon(CupertinoIcons.folder_fill),
            label: 'Collections',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.sparkles),
            label: 'Latyr Pro',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        switch (index) {
          case 0:
            return const CaptureFeedScreen();
          case 1:
            return const CollectionsScreen();
          case 2:
            return const SearchScreen();
          case 3:
            return const LatyrProScreen();
          default:
            return const CaptureFeedScreen();
        }
      },
    );
  }
}
