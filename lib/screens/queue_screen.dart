import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/audio_provider.dart';

class QueueScreen extends StatelessWidget {
  const QueueScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        title: const Text('Queue', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Consumer<AudioProvider>(
        builder: (context, audio, _) {
          final queue = audio.queue;
          final currentIndex = audio.currentIndex;

          if (queue.isEmpty) {
            return const Center(
              child: Text('Queue is empty', style: TextStyle(color: Colors.white54)),
            );
          }

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: queue.length,
            itemBuilder: (context, index) {
              if (index >= queue.length) return const SizedBox();
              final song = queue[index];
              final isCurrent = index == currentIndex;

              return Container(
                color: isCurrent ? Colors.white.withOpacity(0.05) : null,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: song.albumArtUrl != null
                        ? CachedNetworkImage(
                            imageUrl: song.albumArtUrl!, width: 44, height: 44, fit: BoxFit.cover,
                            placeholder: (_, __) => Container(width: 44, height: 44, color: Colors.white10),
                            errorWidget: (_, __, ___) => Container(width: 44, height: 44, color: Colors.white10,
                              child: const Icon(Icons.music_note, color: Colors.white38)),
                          )
                        : Container(width: 44, height: 44, color: Colors.white10,
                            child: const Icon(Icons.music_note, color: Colors.white38)),
                  ),
                  title: Text(
                    song.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 15,
                      color: isCurrent ? const Color(0xFF1DB954) : Colors.white,
                    ),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(song.artistName,
                    style: const TextStyle(color: Colors.white54, fontSize: 13)),
                  trailing: isCurrent
                      ? const Icon(Icons.graphic_eq, color: Color(0xFF1DB954), size: 20)
                      : Text('${index + 1}', style: const TextStyle(color: Colors.white38, fontSize: 13)),
                  onTap: () => audio.playFromQueueAt(index),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
