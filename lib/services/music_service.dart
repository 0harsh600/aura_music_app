import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/music_models.dart';

/// Pure-Dart music service using youtube_explode_dart.
/// Singleton pattern to avoid creating multiple HTTP clients.
class MusicService {
  static final MusicService _instance = MusicService._internal();
  factory MusicService() => _instance;
  MusicService._internal();

  final YoutubeExplode _yt = YoutubeExplode();

  /// Search for songs directly (returns playable song results)
  Future<List<Song>> searchSongs(String query) async {
    try {
      final results = await _yt.search.search(query);
      return results.take(25).map((video) => Song(
        id: video.id.value,
        title: video.title,
        artistName: video.author,
        artistId: video.channelId.value,
        albumArtUrl: video.thumbnails.highResUrl,
        duration: video.duration,
      )).toList();
    } catch (e) {
      return [];
    }
  }

  /// Search for artists (unique channels from search results)
  Future<List<Artist>> searchArtists(String query) async {
    try {
      final results = await _yt.search.search('$query artist');
      final uniqueArtists = <String, Artist>{};
      for (final video in results) {
        final channelId = video.channelId.value;
        if (!uniqueArtists.containsKey(channelId)) {
          uniqueArtists[channelId] = Artist(
            id: channelId,
            name: video.author,
            photoUrl: 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(video.author)}&background=1DB954&color=fff&size=200&bold=true',
          );
        }
      }
      return uniqueArtists.values.take(15).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get artist songs from their channel uploads
  Future<List<Song>> getArtistSongs(String channelId) async {
    try {
      final uploads = await _yt.channels.getUploads(ChannelId(channelId));
      return uploads.take(30).map((video) => Song(
        id: video.id.value,
        title: video.title,
        artistName: video.author,
        artistId: channelId,
        albumArtUrl: video.thumbnails.highResUrl,
        duration: video.duration,
      )).toList();
    } catch (e) {
      return [];
    }
  }

  /// Recommended songs from popular playlists
  Future<List<Song>> getRecommendedSongs() async {
    try {
      // Use multiple playlists for variety
      final playlistIds = [
        'PLDIoUOhQQPlXr63I_vwF9GD8sAKh77dWU', // Top 50 Global
        'PLx0sYbCqOb8TBPRdmBHs5Iftvv9TPboYG', // Trending
      ];
      
      final allSongs = <Song>[];
      for (final pid in playlistIds) {
        try {
          final videos = await _yt.playlists.getVideos(pid).take(15).toList();
          allSongs.addAll(videos.map((video) => Song(
            id: video.id.value,
            title: video.title,
            artistName: video.author,
            artistId: video.channelId.value,
            albumArtUrl: video.thumbnails.highResUrl,
            duration: video.duration,
          )));
        } catch (_) {}
        if (allSongs.length >= 20) break;
      }
      
      // Fallback: search for trending if playlists fail
      if (allSongs.isEmpty) {
        return await searchSongs('top hits 2026 music');
      }
      
      return allSongs.take(25).toList();
    } catch (e) {
      // Ultimate fallback
      return await searchSongs('trending music 2026');
    }
  }

  /// Extract the direct audio stream URL from a video ID
  Future<String?> getAudioStreamUrl(String videoId) async {
    try {
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);
      final audioStreams = manifest.audioOnly.sortByBitrate();
      if (audioStreams.isEmpty) return null;
      // Use highest bitrate audio-only stream
      return audioStreams.last.url.toString();
    } catch (e) {
      return null;
    }
  }
}
