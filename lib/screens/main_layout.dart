import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'about_screen.dart';
import '../widgets/mini_player.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({Key? key}) : super(key: key);

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    const SearchScreen(),
    const AboutScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Determine if MiniPlayer should be shown to apply padding to navigation body
    final audioProvider = context.watch<AudioProvider>();
    final showMiniPlayer = audioProvider.currentSong != null;

    return Scaffold(
      body: Stack(
        children: [
          // Render Tab
          _pages[_currentIndex],
          
          // Persistent Mini Player above BottomNav
          if (showMiniPlayer)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: MiniPlayer(),
            ),
        ],
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: const Color(0xFF121212), // Spotify Dark
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey[600],
          selectedFontSize: 12,
          unselectedFontSize: 12,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(CupertinoIcons.house_fill, size: 26)),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(CupertinoIcons.search, size: 26)),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(CupertinoIcons.person_fill, size: 26)),
              label: 'About',
            ),
          ],
        ),
      ),
    );
  }
}
