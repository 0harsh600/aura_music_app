import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/music_models.dart';
import '../services/music_service.dart';
import 'artist_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final MusicService _musicService = MusicService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Artist> _searchResults = [];
  List<String> _searchHistory = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _searchHistory = prefs.getStringList('search_history') ?? [];
    });
  }

  Future<void> _saveSearchHistory(String query) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList('search_history') ?? [];
    
    // Remove if exists to bring to top
    history.remove(query);
    history.insert(0, query);
    
    // Keep only last 10
    if (history.length > 10) history = history.sublist(0, 10);
    
    await prefs.setStringList('search_history', history);
    setState(() {
      _searchHistory = history;
    });
  }

  Future<void> _deleteHistoryItem(String query) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList('search_history') ?? [];
    history.remove(query);
    await prefs.setStringList('search_history', history);
    setState(() {
      _searchHistory = history;
    });
  }

  void _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    
    _saveSearchHistory(query.trim());
    
    setState(() => _isSearching = true);
    final results = await _musicService.searchArtists(query);
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSearchActive = _searchController.text.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Text(
                'Search',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: CupertinoSearchTextField(
                controller: _searchController,
                onSubmitted: _performSearch,
                onChanged: (val) {
                  if (val.isEmpty) {
                    setState(() => _searchResults = []);
                  }
                },
                style: const TextStyle(color: Colors.white, fontSize: 16),
                backgroundColor: Colors.white.withOpacity(0.1),
                placeholder: 'What do you want to listen to?',
                prefixIcon: const Icon(CupertinoIcons.search, color: Colors.white54),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            
            Expanded(
              child: isSearchActive || _searchResults.isNotEmpty
                  ? _buildSearchResults()
                  : _buildSearchHistory(),
            ),
            
            const SizedBox(height: 80), // Padding for mini player
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHistory() {
    if (_searchHistory.isEmpty) {
      return const Center(
        child: Text('Play what you love.', style: TextStyle(color: Colors.white54, fontSize: 16)),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Text(
            'Recent searches',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: _searchHistory.length,
            itemBuilder: (context, index) {
              final query = _searchHistory[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                leading: const Icon(Icons.history, color: Colors.white54),
                title: Text(query, style: const TextStyle(fontSize: 16)),
                trailing: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                  onPressed: () => _deleteHistoryItem(query),
                ),
                onTap: () {
                  _searchController.text = query;
                  _performSearch(query);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF1DB954)));
    }
    if (_searchResults.isEmpty) {
      return const Center(
        child: Text('No artists found.', style: TextStyle(color: Colors.white54)),
      );
    }
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        if (index >= _searchResults.length) return const SizedBox();
        final artist = _searchResults[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          leading: CircleAvatar(
            radius: 28,
            backgroundImage: NetworkImage(artist.photoUrl ?? ''),
            backgroundColor: Colors.white10,
          ),
          title: Text(
            artist.name, 
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          subtitle: const Text('Artist', style: TextStyle(color: Colors.white54)),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ArtistScreen(artist: artist)),
            );
          },
        );
      },
    );
  }
}
