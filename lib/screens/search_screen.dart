import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/music_models.dart';
import '../services/music_service.dart';
import '../providers/audio_provider.dart';
import 'artist_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final MusicService _musicService = MusicService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<Artist> _artistResults = [];
  List<Song> _songResults = [];
  List<String> _searchHistory = [];
  bool _isSearching = false;
  String _searchMode = 'songs'; // 'songs' or 'artists'

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _searchHistory = prefs.getStringList('search_history') ?? [];
      });
    }
  }

  Future<void> _saveToHistory(String query) async {
    final prefs = await SharedPreferences.getInstance();
    var history = prefs.getStringList('search_history') ?? [];
    history.remove(query);
    history.insert(0, query);
    if (history.length > 15) history = history.sublist(0, 15);
    await prefs.setStringList('search_history', history);
    setState(() => _searchHistory = history);
  }

  Future<void> _deleteHistoryItem(String query) async {
    final prefs = await SharedPreferences.getInstance();
    var history = prefs.getStringList('search_history') ?? [];
    history.remove(query);
    await prefs.setStringList('search_history', history);
    setState(() => _searchHistory = history);
  }

  Future<void> _clearAllHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('search_history');
    setState(() => _searchHistory = []);
  }

  void _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    _saveToHistory(query.trim());
    setState(() => _isSearching = true);

    final songs = await _musicService.searchSongs(query);
    final artists = await _musicService.searchArtists(query);

    if (mounted) {
      setState(() {
        _songResults = songs;
        _artistResults = artists;
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasResults = _songResults.isNotEmpty || _artistResults.isNotEmpty;
    final showHistory = _searchController.text.isEmpty && !hasResults;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Text('Search', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CupertinoSearchTextField(
                controller: _searchController,
                focusNode: _focusNode,
                onSubmitted: _performSearch,
                onChanged: (val) {
                  if (val.isEmpty) {
                    setState(() {
                      _songResults = [];
                      _artistResults = [];
                    });
                  }
                },
                style: const TextStyle(color: Colors.white, fontSize: 16),
                backgroundColor: Colors.white.withOpacity(0.1),
                placeholder: 'Songs, artists...',
                prefixIcon: const Icon(CupertinoIcons.search, color: Colors.white54),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),

            // Tabs for search mode
            if (hasResults)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    _buildFilterChip('Songs', 'songs'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Artists', 'artists'),
                  ],
                ),
              ),

            const SizedBox(height: 8),

            // Content
            Expanded(
              child: _isSearching
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF1DB954)))
                  : showHistory
                      ? _buildHistory()
                      : _searchMode == 'songs'
                          ? _buildSongResults()
                          : _buildArtistResults(),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String mode) {
    final selected = _searchMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _searchMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1DB954) : Colors.white12,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildHistory() {
    if (_searchHistory.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.search, color: Colors.white24, size: 48),
            SizedBox(height: 16),
            Text('Search for your favorite\nmusic and artists',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 16)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent searches', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: _clearAllHistory,
                child: const Text('Clear all', style: TextStyle(color: Color(0xFF1DB954), fontSize: 13)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: _searchHistory.length,
            itemBuilder: (context, index) {
              final query = _searchHistory[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                leading: const Icon(Icons.history, color: Colors.white54),
                title: Text(query, style: const TextStyle(fontSize: 15)),
                trailing: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white38, size: 18),
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

  Widget _buildSongResults() {
    if (_songResults.isEmpty) {
      return const Center(child: Text('No songs found', style: TextStyle(color: Colors.white54)));
    }
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: _songResults.length,
      itemBuilder: (context, index) {
        if (index >= _songResults.length) return const SizedBox();
        final song = _songResults[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: song.albumArtUrl != null
                ? CachedNetworkImage(
                    imageUrl: song.albumArtUrl!, width: 48, height: 48, fit: BoxFit.cover,
                    placeholder: (_, __) => Container(width: 48, height: 48, color: Colors.white10),
                    errorWidget: (_, __, ___) => Container(width: 48, height: 48, color: Colors.white10,
                      child: const Icon(Icons.music_note, color: Colors.white38)),
                  )
                : Container(width: 48, height: 48, color: Colors.white10,
                    child: const Icon(Icons.music_note, color: Colors.white38)),
          ),
          title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
          subtitle: Text(song.artistName, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          trailing: Icon(Icons.play_circle_fill, color: Colors.white.withOpacity(0.7)),
          onTap: () {
            context.read<AudioProvider>().playArtistQueue(_songResults, index);
          },
        );
      },
    );
  }

  Widget _buildArtistResults() {
    if (_artistResults.isEmpty) {
      return const Center(child: Text('No artists found', style: TextStyle(color: Colors.white54)));
    }
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: _artistResults.length,
      itemBuilder: (context, index) {
        if (index >= _artistResults.length) return const SizedBox();
        final artist = _artistResults[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          leading: CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white10,
            backgroundImage: artist.photoUrl != null ? NetworkImage(artist.photoUrl!) : null,
          ),
          title: Text(artist.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          subtitle: const Text('Artist', style: TextStyle(color: Colors.white54, fontSize: 12)),
          trailing: const Icon(Icons.chevron_right, color: Colors.white38),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => ArtistScreen(artist: artist)));
          },
        );
      },
    );
  }
}
