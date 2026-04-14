import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/audio_provider.dart';
import '../screens/player_screen.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, child) {
        final currentSong = audioProvider.currentSong;
        if (currentSong == null) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => const PlayerScreen(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 1),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutExpo,
                    )),
                    child: child,
                  );
                },
              ),
            );
          },
          child: Container(
            height: 70,
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 8),
                // Album Art
                Hero(
                  tag: 'album_art_${currentSong.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: currentSong.albumArtUrl != null
                        ? CachedNetworkImage(
                            imageUrl: currentSong.albumArtUrl!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 50,
                            height: 50,
                            color: Colors.grey[800],
                            child: const Icon(Icons.music_note, color: Colors.white54),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                // Titles
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentSong.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currentSong.artistName,
                        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Play/Pause button
                StreamBuilder<bool>(
                  stream: audioProvider.player.playingStream,
                  builder: (context, snapshot) {
                    final isPlaying = snapshot.data ?? false;
                    return IconButton(
                      icon: audioProvider.isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                      onPressed: () => audioProvider.togglePlayPause(),
                      iconSize: 32,
                      color: Colors.white,
                    );
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}
