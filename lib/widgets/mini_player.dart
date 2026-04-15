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
      builder: (context, audio, child) {
        final song = audio.currentSong;
        if (song == null) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, animation, __) => const PlayerScreen(),
                transitionsBuilder: (_, animation, __, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 1),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutExpo)),
                    child: child,
                  );
                },
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF282828),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Mini progress bar at top
                StreamBuilder<Duration>(
                  stream: audio.player.positionStream,
                  builder: (context, snapshot) {
                    final position = snapshot.data ?? Duration.zero;
                    final duration = audio.player.duration ?? Duration.zero;
                    final progress = duration.inMilliseconds > 0
                        ? position.inMilliseconds / duration.inMilliseconds
                        : 0.0;
                    return LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      backgroundColor: Colors.transparent,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1DB954)),
                      minHeight: 2,
                    );
                  },
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    children: [
                      // Album Art
                      Hero(
                        tag: 'album_art',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: song.albumArtUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: song.albumArtUrl!, width: 44, height: 44, fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(width: 44, height: 44, color: Colors.white10),
                                  errorWidget: (_, __, ___) => Container(width: 44, height: 44, color: Colors.white10),
                                )
                              : Container(width: 44, height: 44, color: Colors.white10,
                                  child: const Icon(Icons.music_note, color: Colors.white54, size: 20)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Title & Artist
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(song.title,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text(song.artistName,
                              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      // Like
                      IconButton(
                        icon: Icon(
                          audio.isSongLiked(song.id) ? Icons.favorite : Icons.favorite_border,
                          color: audio.isSongLiked(song.id) ? const Color(0xFF1DB954) : Colors.white54,
                          size: 20,
                        ),
                        onPressed: () => audio.toggleLike(song),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      ),
                      // Play/Pause
                      StreamBuilder<bool>(
                        stream: audio.player.playingStream,
                        builder: (context, snapshot) {
                          final isPlaying = snapshot.data ?? false;
                          return IconButton(
                            icon: audio.isLoading
                                ? const SizedBox(width: 20, height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                    color: Colors.white, size: 28),
                            onPressed: () => audio.togglePlayPause(),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
