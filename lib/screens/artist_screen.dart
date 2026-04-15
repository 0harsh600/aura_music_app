import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/music_models.dart';
import '../services/music_service.dart';
import '../providers/audio_provider.dart';

class ArtistScreen extends StatefulWidget {
  final Artist artist;
  const ArtistScreen({Key? key, required this.artist}) : super(key: key);

  @override
  State<ArtistScreen> createState() => _ArtistScreenState();
}

class _ArtistScreenState extends State<ArtistScreen> {
  final MusicService _musicService = MusicService();
  List<Song> _songs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSongs();
  }

  Future<void> _fetchSongs() async {
    final songs = await _musicService.getArtistSongs(widget.artist.id);
    if (mounted) {
      setState(() {
        _songs = songs;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: const Color(0xFF121212),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.artist.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              background: widget.artist.photoUrl != null
                  ? CachedNetworkImage(
                      imageUrl: widget.artist.photoUrl!,
                      fit: BoxFit.cover,
                      color: Colors.black.withOpacity(0.5),
                      colorBlendMode: BlendMode.darken,
                    )
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF1DB954), Color(0xFF121212)],
                        ),
                      ),
                    ),
            ),
          ),

          // Play all button
          if (!_isLoading && _songs.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        context.read<AudioProvider>().playArtistQueue(_songs, 0);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1DB954),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.play_arrow_rounded, color: Colors.black, size: 22),
                            SizedBox(width: 4),
                            Text('Play All', style: TextStyle(
                              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${_songs.length} songs',
                      style: const TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: Color(0xFF1DB954))),
            )
          else if (_songs.isEmpty)
            const SliverFillRemaining(
              child: Center(child: Text('No songs found', style: TextStyle(color: Colors.white54))),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index >= _songs.length) return const SizedBox(height: 120);
                  final song = _songs[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                    title: Text(song.title,
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(song.artistName,
                      style: const TextStyle(color: Colors.white54, fontSize: 13)),
                    trailing: Consumer<AudioProvider>(
                      builder: (context, audio, _) {
                        final liked = audio.isSongLiked(song.id);
                        return IconButton(
                          icon: Icon(
                            liked ? Icons.favorite : Icons.favorite_border,
                            color: liked ? const Color(0xFF1DB954) : Colors.white38, size: 20),
                          onPressed: () => audio.toggleLike(song),
                        );
                      },
                    ),
                    onTap: () {
                      context.read<AudioProvider>().playArtistQueue(_songs, index);
                    },
                  );
                },
                childCount: _songs.length + 1, // +1 for bottom padding
              ),
            ),
        ],
      ),
    );
  }
}
