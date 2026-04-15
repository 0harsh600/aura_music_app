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
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchRecommended();
  }

  Future<void> _fetchRecommended() async {
    setState(() { _isLoading = true; _hasError = false; });
    final songs = await _musicService.getRecommendedSongs();
    if (mounted) {
      setState(() {
        _recommendedSongs = songs;
        _isLoading = false;
        _hasError = songs.isEmpty;
      });
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF1DB954),
          onRefresh: _fetchRecommended,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  child: Text(
                    _getGreeting(),
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                  ),
                ),
              ),

              // Content
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: Color(0xFF1DB954))),
                )
              else if (_hasError)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wifi_off, color: Colors.white38, size: 48),
                        const SizedBox(height: 16),
                        const Text('Could not load songs', style: TextStyle(color: Colors.white54)),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _fetchRecommended,
                          child: const Text('Tap to retry', style: TextStyle(color: Color(0xFF1DB954))),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                // Section title
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Text(
                      '🔥 Trending Right Now',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                // Song list
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= _recommendedSongs.length) return null;
                      final song = _recommendedSongs[index];
                      return _SongTile(
                        song: song,
                        index: index + 1,
                        onTap: () {
                          context.read<AudioProvider>().playArtistQueue(_recommendedSongs, index);
                        },
                      );
                    },
                    childCount: _recommendedSongs.length,
                  ),
                ),

                // Bottom padding for mini player
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SongTile extends StatelessWidget {
  final Song song;
  final int index;
  final VoidCallback onTap;

  const _SongTile({required this.song, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            // Track number
            SizedBox(
              width: 28,
              child: Text(
                '$index',
                style: const TextStyle(color: Colors.white54, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 12),
            // Album art
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: song.albumArtUrl != null
                  ? CachedNetworkImage(
                      imageUrl: song.albumArtUrl!,
                      width: 48, height: 48,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(width: 48, height: 48, color: Colors.white10),
                      errorWidget: (_, __, ___) => Container(
                        width: 48, height: 48, color: Colors.white10,
                        child: const Icon(Icons.music_note, color: Colors.white38, size: 24),
                      ),
                    )
                  : Container(
                      width: 48, height: 48, color: Colors.white10,
                      child: const Icon(Icons.music_note, color: Colors.white38, size: 24),
                    ),
            ),
            const SizedBox(width: 12),
            // Title & Artist
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    song.artistName,
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Like button
            Consumer<AudioProvider>(
              builder: (context, audio, _) {
                final liked = audio.isSongLiked(song.id);
                return IconButton(
                  icon: Icon(
                    liked ? Icons.favorite : Icons.favorite_border,
                    color: liked ? const Color(0xFF1DB954) : Colors.white38,
                    size: 22,
                  ),
                  onPressed: () => audio.toggleLike(song),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
