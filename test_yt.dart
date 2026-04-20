import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  print('Starting test...');
  final yt = YoutubeExplode();
  
  try {
    print('Testing search...');
    final results = await yt.search.search('trending music');
    print('Search results: ${results.length}');
    for (var i = 0; i < 3 && i < results.length; i++) {
        print('- ${results[i].title}');
    }
  } catch (e) {
    print('Search failed: $e');
  }

  try {
    print('\nTesting playlist 1...');
    final vids = await yt.playlists.getVideos('PLDIoUOhQQPlXr63I_vwF9GD8sAKh77dWU').take(5).toList();
    print('Playlist 1 results: ${vids.length}');
  } catch (e) {
    print('Playlist 1 failed: $e');
  }

  try {
    print('\nTesting playlist 2...');
    final vids = await yt.playlists.getVideos('PLx0sYbCqOb8TBPRdmBHs5Iftvv9TPboYG').take(5).toList();
    print('Playlist 2 results: ${vids.length}');
  } catch (e) {
    print('Playlist 2 failed: $e');
  }

  yt.close();
  print('Test finished.');
}
