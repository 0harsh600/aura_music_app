import 'package:flutter/services.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/music_models.dart';

/// A wrapper service around `yt_flutter_musicapi` and `youtube_explode_dart`.
class MusicService {
  static const MethodChannel _ytMusicChannel = MethodChannel('yt_flutter_musicapi');

  /// Searches for artists based on a query.
  Future<List<Artist>> searchArtists(String query) async {
    try {
      final List<dynamic>? result = await _ytMusicChannel.invokeMethod('search', {
        'query': query,
        'filter': 'artists' 
      });
      if (result == null) return [];
      return result.map((e) => Artist.fromMap(Map<String, dynamic>.from(e))).toList();
    } catch (e) {
      return [];
    }
  }

  /// Fetches an artist's songs
  Future<List<Song>> getArtistSongs(String artistId) async {
    try {
      final List<dynamic>? result = await _ytMusicChannel.invokeMethod('getArtistSongs', {
        'artistId': artistId
      });
      if (result == null) return [];
      return result.map((e) => Song.fromMap(Map<String, dynamic>.from(e))).toList();
    } catch (e) {
      return [];
    }
  }

  /// Fetches Top 100 Recommended / Global hits
  Future<List<Song>> getRecommendedSongs() async {
    try {
      final List<dynamic>? result = await _ytMusicChannel.invokeMethod('getTrending', {
        'region': 'GLOBAL'
      });
      if (result == null) return [];
      return result.map((e) => Song.fromMap(Map<String, dynamic>.from(e))).toList();
    } catch (e) {
      return [];
    }
  }

  /// Extracts the direct audio stream URL from a YouTube Video ID using YouTube Explode
  Future<String?> getAudioStreamUrl(String videoId) async {
    try {
      final yt = YoutubeExplode();
      var manifest = await yt.videos.streamsClient.getManifest(videoId);
      var streamInfo = manifest.audioOnly.withHighestBitrate();
      yt.close();
      return streamInfo.url.toString();
    } catch (e) {
      print('Error extracting stream URL: $e');
      return null;
    }
  }
}
