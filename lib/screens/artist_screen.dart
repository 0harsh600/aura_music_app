import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/music_models.dart';
import '../services/music_service.dart';
import '../providers/audio_provider.dart';
import '../widgets/mini_player.dart';

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
    setState(() {
      _songs = songs;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    widget.artist.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  background: widget.artist.photoUrl != null
                    ? CachedNetworkImage(
                        imageUrl: widget.artist.photoUrl!,
                        fit: BoxFit.cover,
                        color: Colors.black.withOpacity(0.4),
                        colorBlendMode: BlendMode.darken,
                      )
                    : Container(color: Colors.grey[900]),
                ),
              ),
              
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_songs.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: Text('No songs found.')),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      // SAFEGUARD: Absolute bounds check to stop RangeError
                      if (index < 0 || index > _songs.length) return null;
                      
                      // Add padding at the bottom of the list for the MiniPlayer
                      if (index == _songs.length) return const SizedBox(height: 120);
                      
                      final song = _songs[index];
                      
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
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
                          // Play the whole list starting from the tapped index
                          context.read<AudioProvider>().playArtistQueue(_songs, index);
                        },
                      );
                    },
                    childCount: _songs.length + 1, // +1 for padding
                  ),
                ),
            ],
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
}
