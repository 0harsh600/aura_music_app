import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'liked_songs_screen.dart';
import 'about_screen.dart';
import '../widgets/mini_player.dart';
import '../providers/audio_provider.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({Key? key}) : super(key: key);

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    SearchScreen(),
    LikedSongsScreen(),
    AboutScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    final showMiniPlayer = audioProvider.currentSong != null;

    return Scaffold(
      body: Stack(
        children: [
          // Use IndexedStack to preserve state across tabs
          IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),

          // Persistent Mini Player
          if (showMiniPlayer)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  MiniPlayer(),
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
            backgroundColor: const Color(0xFF121212),
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.grey[600],
            selectedFontSize: 11,
            unselectedFontSize: 11,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Padding(padding: EdgeInsets.only(bottom: 3), child: Icon(CupertinoIcons.house_fill, size: 24)),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Padding(padding: EdgeInsets.only(bottom: 3), child: Icon(CupertinoIcons.search, size: 24)),
                label: 'Search',
              ),
              BottomNavigationBarItem(
                icon: Padding(padding: EdgeInsets.only(bottom: 3), child: Icon(CupertinoIcons.heart_fill, size: 24)),
                label: 'Liked',
              ),
              BottomNavigationBarItem(
                icon: Padding(padding: EdgeInsets.only(bottom: 3), child: Icon(CupertinoIcons.person_fill, size: 24)),
                label: 'About',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
