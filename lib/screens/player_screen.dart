import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:palette_generator/palette_generator.dart';
import 'dart:ui';
import '../providers/audio_provider.dart';
import 'queue_screen.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({Key? key}) : super(key: key);

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  Color _dominantColor = const Color(0xFF121212);

  @override
  void initState() {
    super.initState();
    _updatePalette();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updatePalette();
  }

  Future<void> _updatePalette() async {
    try {
      final currentSong = context.read<AudioProvider>().currentSong;
      if (currentSong?.albumArtUrl != null) {
        final palette = await PaletteGenerator.fromImageProvider(
          NetworkImage(currentSong!.albumArtUrl!),
          maximumColorCount: 4,
        );
        if (mounted) {
          setState(() {
            _dominantColor = palette.dominantColor?.color ?? const Color(0xFF121212);
          });
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 34, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Now Playing',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white70)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.queue_music_rounded, color: Colors.white),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const QueueScreen()));
            },
          ),
        ],
      ),
      body: Consumer<AudioProvider>(
        builder: (context, audio, child) {
          final song = audio.currentSong;
          if (song == null) {
            return const Center(child: Text('No song playing', style: TextStyle(color: Colors.white54)));
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              // Blurred background
              if (song.albumArtUrl != null)
                CachedNetworkImage(imageUrl: song.albumArtUrl!, fit: BoxFit.cover),
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        _dominantColor.withOpacity(0.6),
                        const Color(0xFF121212),
                      ],
                    ),
                  ),
                ),
              ),

              // Content
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      const Spacer(flex: 1),

                      // Album Art
                      Hero(
                        tag: 'album_art',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: song.albumArtUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: song.albumArtUrl!,
                                  width: MediaQuery.of(context).size.width - 56,
                                  height: MediaQuery.of(context).size.width - 56,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: MediaQuery.of(context).size.width - 56,
                                  height: MediaQuery.of(context).size.width - 56,
                                  color: Colors.white10,
                                  child: const Icon(Icons.music_note, size: 80, color: Colors.white38),
                                ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Title + Like
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(song.title,
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Text(song.artistName,
                                  style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.7)),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              audio.isSongLiked(song.id) ? Icons.favorite : Icons.favorite_border,
                              color: audio.isSongLiked(song.id) ? const Color(0xFF1DB954) : Colors.white,
                              size: 28,
                            ),
                            onPressed: () => audio.toggleLike(song),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Progress Bar
                      StreamBuilder<Duration>(
                        stream: audio.player.positionStream,
                        builder: (context, snapshot) {
                          final position = snapshot.data ?? Duration.zero;
                          final duration = audio.player.duration ?? Duration.zero;
                          return ProgressBar(
                            progress: position,
                            total: duration,
                            progressBarColor: Colors.white,
                            baseBarColor: Colors.white24,
                            bufferedBarColor: Colors.white38,
                            thumbColor: Colors.white,
                            thumbRadius: 6,
                            barHeight: 3,
                            timeLabelTextStyle: const TextStyle(color: Colors.white70, fontSize: 12),
                            onSeek: (d) => audio.seekTo(d),
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      // Controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Shuffle
                          IconButton(
                            icon: Icon(Icons.shuffle_rounded,
                              color: audio.shuffleOn ? const Color(0xFF1DB954) : Colors.white54, size: 24),
                            onPressed: () => audio.toggleShuffle(),
                          ),
                          // Previous
                          IconButton(
                            icon: const Icon(Icons.skip_previous_rounded, size: 40, color: Colors.white),
                            onPressed: () => audio.skipToPrevious(),
                          ),
                          // Play/Pause
                          Container(
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: StreamBuilder<bool>(
                              stream: audio.player.playingStream,
                              builder: (context, snapshot) {
                                final isPlaying = snapshot.data ?? false;
                                return IconButton(
                                  icon: audio.isLoading
                                      ? const SizedBox(width: 28, height: 28,
                                          child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5))
                                      : Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                          color: Colors.black),
                                  iconSize: 44,
                                  onPressed: () => audio.togglePlayPause(),
                                );
                              },
                            ),
                          ),
                          // Next
                          IconButton(
                            icon: const Icon(Icons.skip_next_rounded, size: 40, color: Colors.white),
                            onPressed: () => audio.skipToNext(),
                          ),
                          // Repeat
                          IconButton(
                            icon: Icon(
                              audio.LoopMode == LoopMode.one ? Icons.repeat_one_rounded : Icons.repeat_rounded,
                              color: audio.LoopMode != LoopMode.off ? const Color(0xFF1DB954) : Colors.white54,
                              size: 24,
                            ),
                            onPressed: () => audio.toggleRepeat(),
                          ),
                        ],
                      ),

                      const Spacer(flex: 2),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
