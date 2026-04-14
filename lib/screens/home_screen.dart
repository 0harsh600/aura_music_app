import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/music_models.dart';
import '../services/music_service.dart';
import '../providers/audio_provider.dart';
import '../widgets/mini_player.dart';
import 'artist_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MusicService _musicService = MusicService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Artist> _searchResults = [];
  List<Song> _recommendedSongs = [];
  
  bool _isSearching = false;
  bool _isLoadingRecommended = true;

  @override
  void initState() {
    super.initState();
    _fetchRecommended();
  }

  Future<void> _fetchRecommended() async {
    final songs = await _musicService.getRecommendedSongs();
    if (mounted) {
      setState(() {
        _recommendedSongs = songs;
        _isLoadingRecommended = false;
      });
    }
  }

  void _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    
    setState(() => _isSearching = true);
    final results = await _musicService.searchArtists(query);
    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSearchActive = _searchController.text.isNotEmpty;

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 32, 24, 16),
                  child: Text(
                    'Discover',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: CupertinoSearchTextField(
                    controller: _searchController,
                    onSubmitted: _performSearch,
                    onChanged: (val) {
                      if (val.isEmpty) {
                        setState(() => _searchResults = []);
                      }
                    },
                    style: const TextStyle(color: Colors.white),
                    backgroundColor: Colors.white10,
                    placeholder: 'Search for artists...',
                    prefixIcon: const Icon(CupertinoIcons.search, color: Colors.white54),
                  ),
                ),
                const SizedBox(height: 24),
                
                Expanded(
                  child: isSearchActive
                      ? _buildSearchResults()
                      : _buildRecommendedSection(),
                ),
                // Padding for mini player
                const SizedBox(height: 80),
              ],
            ),
          ),
          
          // MiniPlayer Overlay
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(child: MiniPlayer()),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_searchResults.isEmpty) {
      return const Center(
        child: Text('No artists found.', style: TextStyle(color: Colors.white54)),
      );
    }
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final artist = _searchResults[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          leading: CircleAvatar(
            radius: 30,
            backgroundImage: artist.photoUrl != null ? NetworkImage(artist.photoUrl!) : null,
            backgroundColor: Colors.white10,
            child: artist.photoUrl == null ? const Icon(Icons.person, color: Colors.white) : null,
          ),
          title: Text(
            artist.name, 
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
          ),
          trailing: const Icon(CupertinoIcons.chevron_right, size: 20, color: Colors.white54),
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

  Widget _buildRecommendedSection() {
    if (_isLoadingRecommended) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_recommendedSongs.isEmpty) {
      return const Center(
        child: Text('Could not load recommended songs.', style: TextStyle(color: Colors.white54)),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Text(
            'Global Top Hits',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _recommendedSongs.length,
            itemBuilder: (context, index) {
              final song = _recommendedSongs[index];
              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: song.albumArtUrl != null
                      ? CachedNetworkImage(
                          imageUrl: song.albumArtUrl!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 48,
                          height: 48,
                          color: Colors.white10,
                          child: const Icon(Icons.music_note, color: Colors.white54),
                        ),
                ),
                title: Text(
                  song.title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  song.artistName,
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
                trailing: const Icon(Icons.play_circle_fill, color: Colors.white54),
                onTap: () {
                  context.read<AudioProvider>().playArtistQueue(_recommendedSongs, index);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
