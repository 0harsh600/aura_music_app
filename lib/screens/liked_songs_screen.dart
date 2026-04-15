import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/audio_provider.dart';

class LikedSongsScreen extends StatelessWidget {
  const LikedSongsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Consumer<AudioProvider>(
          builder: (context, audio, _) {
            final liked = audio.likedSongs;

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF1DB954), Color(0xFF121212)],
                        stops: [0.0, 1.0],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        const Icon(Icons.favorite, color: Colors.white, size: 48),
                        const SizedBox(height: 16),
                        const Text('Liked Songs',
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text('${liked.length} songs',
                          style: const TextStyle(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 16),
                        if (liked.isNotEmpty)
                          GestureDetector(
                            onTap: () => audio.playArtistQueue(liked, 0),
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
                      ],
                    ),
                  ),
                ),

                // Song list
                if (liked.isEmpty)
                  const SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.favorite_border, color: Colors.white24, size: 48),
                          SizedBox(height: 16),
                          Text('Songs you like will appear here',
                            style: TextStyle(color: Colors.white54, fontSize: 16)),
                        ],
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index >= liked.length) return const SizedBox(height: 120);
                        final song = liked[index];
                        return Dismissible(
                          key: Key(song.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            color: Colors.red.withOpacity(0.3),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (_) => audio.toggleLike(song),
                          child: ListTile(
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
                            onTap: () => audio.playArtistQueue(liked, index),
                          ),
                        );
                      },
                      childCount: liked.length + 1,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
