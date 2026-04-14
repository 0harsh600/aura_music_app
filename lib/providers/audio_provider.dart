import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../models/music_models.dart';
import '../services/music_service.dart';

class AudioProvider extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  final MusicService _musicService = MusicService();

  List<Song> _queue = [];
  int _currentIndex = -1;
  bool _isLoading = false;

  AudioProvider() {
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        skipToNext();
      }
      notifyListeners();
    });
    
    _player.positionStream.listen((event) {
      notifyListeners();
    });
  }

  AudioPlayer get player => _player;
  List<Song> get queue => _queue;
  Song? get currentSong => _currentIndex >= 0 && _currentIndex < _queue.length ? _queue[_currentIndex] : null;
  bool get isLoading => _isLoading;

  /// Loads an entire queue of songs and starts playing from the given index.
  /// This fulfills the requirement: when you play an artist, only that artist's songs play 
  /// and they automatically play next.
  Future<void> playArtistQueue(List<Song> songs, int initialIndex) async {
    _queue = songs;
    _currentIndex = initialIndex;
    notifyListeners();
    await _playCurrent();
  }

  Future<void> _playCurrent() async {
    if (_currentIndex < 0 || _currentIndex >= _queue.length) return;
    final song = _queue[_currentIndex];
    
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Get raw URL from YTDLP
      final url = await _musicService.getAudioStreamUrl(song.id);
      
      if (url != null) {
        // 2. Wrap it in AudioSource with MediaItem for lock screen controls
        final audioSource = AudioSource.uri(
          Uri.parse(url),
          tag: MediaItem(
            id: song.id,
            album: song.artistName,
            title: song.title,
            artist: song.artistName,
            artUri: song.albumArtUrl != null ? Uri.parse(song.albumArtUrl!) : null,
          ),
        );
        
        await _player.setAudioSource(audioSource);
        _player.play();
      }
    } catch (e) {
      print('Error playing song: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void skipToNext() {
    if (_currentIndex < _queue.length - 1) {
      _currentIndex++;
      _playCurrent();
    }
  }

  void skipToPrevious() {
    if (_currentIndex > 0) {
      _currentIndex--;
      _playCurrent();
    }
  }

  void togglePlayPause() {
    if (_player.playing) {
      _player.pause();
    } else {
      _player.play();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
