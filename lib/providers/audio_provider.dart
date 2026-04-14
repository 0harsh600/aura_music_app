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

  String? _cachedNextUrl;
  int? _cachedNextIndex;

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
  Future<void> playArtistQueue(List<Song> songs, int initialIndex) async {
    _queue = songs;
    _currentIndex = initialIndex;
    _cachedNextUrl = null; 
    _cachedNextIndex = null;
    notifyListeners();
    await _playCurrent();
  }

  Future<void> _playCurrent() async {
    if (_currentIndex < 0 || _currentIndex >= _queue.length) return;
    final song = _queue[_currentIndex];
    
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Instant Start: Check if we pre-loaded the raw URL of this exact song!
      final url = (_currentIndex == _cachedNextIndex && _cachedNextUrl != null) 
          ? _cachedNextUrl 
          : await _musicService.getAudioStreamUrl(song.id);
          
      if (url == null) {
        // Fallback: Drop song and skip if unplayable streams are hit
        skipToNext();
        return;
      }

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
      
      // 3. BACKGROUND PRE-PULL NEXT: Ensure the next song's URL is loaded silently!
      _preloadNextSong();
      
    } catch (e) {
      print('Error playing song: $e');
      skipToNext(); // Auto-skip on failure
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _preloadNextSong() async {
    final nextIndex = _currentIndex + 1;
    if (nextIndex < _queue.length) {
      final nextSong = _queue[nextIndex];
      try {
        _cachedNextUrl = await _musicService.getAudioStreamUrl(nextSong.id);
        _cachedNextIndex = nextIndex;
      } catch(e) {
        _cachedNextUrl = null;
      }
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
