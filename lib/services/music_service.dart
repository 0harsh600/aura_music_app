import 'package:flutter/services.dart';
import '../models/music_models.dart';

/// A wrapper service around `yt_flutter_musicapi` and `flutter_ytdlp_plugin`.
/// Note: Since exact method names of these packages may vary slightly depending on their
/// versions, this facade pattern makes it easy to adjust them centrally.
class MusicService {
  static const MethodChannel _ytMusicChannel = MethodChannel('yt_flutter_musicapi');
  static const MethodChannel _ytdlpChannel = MethodChannel('flutter_ytdlp_plugin');

  /// Searches for artists based on a query.
  Future<List<Artist>> searchArtists(String query) async {
    try {
      // Mocking/Wrapping the actual call
      final List<dynamic>? result = await _ytMusicChannel.invokeMethod('search', {
        'query': query,
        'filter': 'artists' // Assuming a filter parameter exists
      });
      
      if (result == null) return [];
      
      return result.map((e) => Artist.fromMap(Map<String, dynamic>.from(e))).toList();
    } catch (e) {
      print('Error searching artists: $e');
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
      print('Error fetching artist songs: $e');
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
      print('Error fetching recommended songs: $e');
      return [];
    }
  }

  /// Extracts the direct audio stream URL from a YouTube Video ID using flutter_ytdlp_plugin
  Future<String?> getAudioStreamUrl(String videoId) async {
    try {
      // Example implementation of flutter_ytdlp_plugin wrapper
      final String? streamUrl = await _ytdlpChannel.invokeMethod('getAudioUrl', {
        'videoId': videoId
      });
      return streamUrl;
    } catch (e) {
      print('Error extracting stream URL: $e');
      return null;
    }
  }
}
