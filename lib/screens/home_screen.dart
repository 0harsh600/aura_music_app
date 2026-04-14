import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/music_models.dart';
import '../services/music_service.dart';
import '../providers/audio_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MusicService _musicService = MusicService();
  List<Song> _recommendedSongs = [];
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Uses parent Scaffold
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Text(
                'Good evening', // Spotify-like greeting
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            
            Expanded(
              child: _buildRecommendedSection(),
            ),
            
            // Padding for mini player is now handled in MainLayout, but adding bottom safety
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendedSection() {
    if (_isLoadingRecommended) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF1DB954)));
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
          padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Text(
            'Global Top Hits',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _recommendedSongs.length,
            // SAFEGUARD: Ensure index is rigidly bound
            itemBuilder: (context, index) {
              if (index >= _recommendedSongs.length) return const SizedBox();
              
              final song = _recommendedSongs[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(4), // Spotify style square edges
                  child: song.albumArtUrl != null
                      ? CachedNetworkImage(
                          imageUrl: song.albumArtUrl!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 56,
                          height: 56,
                          color: Colors.white10,
                          child: const Icon(Icons.music_note, color: Colors.white54),
                        ),
                ),
                title: Text(
                  song.title,
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    song.artistName,
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ),
                trailing: const Icon(Icons.more_vert, color: Colors.white54),
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
