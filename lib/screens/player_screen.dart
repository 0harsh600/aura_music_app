import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:palette_generator/palette_generator.dart';
import 'dart:ui';
import '../providers/audio_provider.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({Key? key}) : super(key: key);

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  Color _dominantColor = const Color(0xFF1C1C23);

  @override
  void initState() {
    super.initState();
    _updatePalette();
  }

  Future<void> _updatePalette() async {
    final currentSong = context.read<AudioProvider>().currentSong;
    if (currentSong?.albumArtUrl != null) {
      final PaletteGenerator paletteGenerator = await PaletteGenerator.fromImageProvider(
        NetworkImage(currentSong!.albumArtUrl!),
      );
      setState(() {
        _dominantColor = paletteGenerator.dominantColor?.color ?? const Color(0xFF1C1C23);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, size: 32, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Now Playing',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white70),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          )
        ],
      ),
      body: Consumer<AudioProvider>(
        builder: (context, audioProvider, child) {
          final currentSong = audioProvider.currentSong;
          if (currentSong == null) {
            return const Center(child: Text('No song playing'));
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              // Background Blur Effect
              if (currentSong.albumArtUrl != null)
                CachedNetworkImage(
                  imageUrl: currentSong.albumArtUrl!,
                  fit: BoxFit.cover,
                ),
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        _dominantColor.withOpacity(0.5),
                        const Color(0xFF0F0F13),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Content
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 1),
                      // Album Art
                      Hero(
                        tag: 'album_art_${currentSong.id}',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: currentSong.albumArtUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: currentSong.albumArtUrl!,
                                  width: MediaQuery.of(context).size.width - 48,
                                  height: MediaQuery.of(context).size.width - 48,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: MediaQuery.of(context).size.width - 48,
                                  height: MediaQuery.of(context).size.width - 48,
                                  color: Colors.white10,
                                  child: const Icon(Icons.music_note, size: 100, color: Colors.white54),
                                ),
                        ),
                      ),
                      const SizedBox(height: 48),
                      // Title & Artist
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          currentSong.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          currentSong.artistName,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white.withOpacity(0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Progress Bar
                      StreamBuilder<Duration>(
                        stream: audioProvider.player.positionStream,
                        builder: (context, snapshot) {
                          final position = snapshot.data ?? Duration.zero;
                          final duration = audioProvider.player.duration ?? Duration.zero;
                          return ProgressBar(
                            progress: position,
                            total: duration,
                            progressBarColor: Colors.white,
                            baseBarColor: Colors.white24,
                            thumbColor: Colors.white,
                            timeLabelTextStyle: const TextStyle(color: Colors.white70),
                            onSeek: (duration) {
                              audioProvider.player.seek(duration);
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      
                      // Controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.shuffle, color: Colors.white54),
                            onPressed: () {}, // Shuffle UI placeholder
                          ),
                          IconButton(
                            icon: const Icon(Icons.skip_previous_rounded, size: 40, color: Colors.white),
                            onPressed: () => audioProvider.skipToPrevious(),
                          ),
                          Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: StreamBuilder<bool>(
                              stream: audioProvider.player.playingStream,
                              builder: (context, snapshot) {
                                final isPlaying = snapshot.data ?? false;
                                return IconButton(
                                  icon: audioProvider.isLoading
                                      ? const Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                                        )
                                      : Icon(
                                          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                          color: Colors.black,
                                        ),
                                  iconSize: 48,
                                  onPressed: () => audioProvider.togglePlayPause(),
                                );
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.skip_next_rounded, size: 40, color: Colors.white),
                            onPressed: () => audioProvider.skipToNext(),
                          ),
                          IconButton(
                            icon: const Icon(Icons.repeat, color: Colors.white54),
                            onPressed: () {}, // Repeat UI placeholder
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
