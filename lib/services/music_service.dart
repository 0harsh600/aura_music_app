import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/music_models.dart';

/// A pure-Dart wrapper service around `youtube_explode_dart`
class MusicService {
  final yt = YoutubeExplode();

  /// Searches for artists. Returns unique channel authors from video search.
  Future<List<Artist>> searchArtists(String query) async {
    try {
      var searchResults = await yt.search.search(query);
      var uniqueArtists = <String, Artist>{};
      for (var video in searchResults) {
        if (!uniqueArtists.containsKey(video.author)) {
          uniqueArtists[video.author] = Artist(
            id: video.channelId.value,
            name: video.author,
            photoUrl: 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(video.author)}&background=random&size=150',
          );
        }
      }
      return uniqueArtists.values.toList();
    } catch (e) {
      return [];
    }
  }

  /// Fetches an artist's songs by pulling latest uploads from their Channel
  Future<List<Song>> getArtistSongs(String artistId) async {
    try {
      var uploads = await yt.channels.getUploads(ChannelId(artistId));
      return uploads.take(30).map((video) => Song(
        id: video.id.value,
        title: video.title,
        artistName: video.author,
        artistId: artistId,
        albumArtUrl: video.thumbnails.highResUrl,
      )).toList();
    } catch (e) {
      return [];
    }
  }

  /// Fetches Top 100/Recommended Global hits from a popular Youtube Playlist
  Future<List<Song>> getRecommendedSongs() async {
    try {
      var playlistId = 'PL4fGSI1pCORvfTf668z_F_u9d1c1P4_3M'; // standard top hits playlist
      var videos = await yt.playlists.getVideos(playlistId).take(20).toList();
      return videos.map((video) => Song(
        id: video.id.value,
        title: video.title,
        artistName: video.author,
        artistId: video.channelId.value,
        albumArtUrl: video.thumbnails.highResUrl,
      )).toList();
    } catch (e) {
      return [];
    }
  }

  /// Extracts the direct audio stream URL
  Future<String?> getAudioStreamUrl(String videoId) async {
    try {
      var manifest = await yt.videos.streamsClient.getManifest(videoId);
      var streamInfo = manifest.audioOnly.withHighestBitrate();
      return streamInfo.url.toString();
    } catch (e) {
      return null;
    }
  }
}
