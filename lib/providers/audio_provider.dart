import 'dart:math';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/music_models.dart';
import '../services/music_service.dart';

enum LoopMode { off, all, one }

class AudioProvider extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  final MusicService _musicService = MusicService();

  List<Song> _queue = [];
  List<Song> _originalQueue = []; // kept for un-shuffling
  int _currentIndex = -1;
  bool _isLoading = false;
  bool _shuffleOn = false;
  LoopMode _loopMode = LoopMode.off;

  // Pre-cached next URL
  String? _cachedNextUrl;
  int? _cachedNextIndex;

  // Liked songs
  List<Song> _likedSongs = [];

  AudioProvider() {
    _loadLikedSongs();

    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _onSongCompleted();
      }
      notifyListeners();
    });

    // Throttle position updates to avoid excessive rebuilds
    _player.positionStream.listen((_) {
      notifyListeners();
    });
  }

  // --- Getters ---
  AudioPlayer get player => _player;
  List<Song> get queue => _queue;
  int get currentIndex => _currentIndex;
  Song? get currentSong => (_currentIndex >= 0 && _currentIndex < _queue.length) ? _queue[_currentIndex] : null;
  bool get isLoading => _isLoading;
  bool get shuffleOn => _shuffleOn;
  LoopMode get loopMode => _loopMode;
  List<Song> get likedSongs => _likedSongs;

  bool isSongLiked(String songId) => _likedSongs.any((s) => s.id == songId);

  // --- Queue Management ---
  Future<void> playArtistQueue(List<Song> songs, int initialIndex) async {
    if (songs.isEmpty || initialIndex < 0 || initialIndex >= songs.length) return;

    _originalQueue = List.from(songs);
    _queue = List.from(songs);
    _currentIndex = initialIndex;
    _cachedNextUrl = null;
    _cachedNextIndex = null;

    if (_shuffleOn) {
      _applyShuffle();
    }

    notifyListeners();
    await _playCurrent();
  }

  Future<void> playSingle(Song song) async {
    _originalQueue = [song];
    _queue = [song];
    _currentIndex = 0;
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
      // Check pre-cache first
      final url = (_currentIndex == _cachedNextIndex && _cachedNextUrl != null)
          ? _cachedNextUrl
          : await _musicService.getAudioStreamUrl(song.id);

      if (url == null) {
        _isLoading = false;
        notifyListeners();
        // Skip unplayable
        skipToNext();
        return;
      }

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
      await _player.play();

      // Pre-load next in background
      _preloadNextSong();
    } catch (e) {
      // Auto-skip on error
      skipToNext();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _onSongCompleted() {
    switch (_loopMode) {
      case LoopMode.one:
        _player.seek(Duration.zero);
        _player.play();
        break;
      case LoopMode.all:
        if (_currentIndex >= _queue.length - 1) {
          _currentIndex = 0;
          _playCurrent();
        } else {
          skipToNext();
        }
        break;
      case LoopMode.off:
        skipToNext();
        break;
    }
  }

  Future<void> _preloadNextSong() async {
    final nextIndex = _currentIndex + 1;
    if (nextIndex < _queue.length) {
      try {
        _cachedNextUrl = await _musicService.getAudioStreamUrl(_queue[nextIndex].id);
        _cachedNextIndex = nextIndex;
      } catch (_) {
        _cachedNextUrl = null;
        _cachedNextIndex = null;
      }
    }
  }

  void skipToNext() {
    if (_queue.isEmpty) return;
    if (_currentIndex < _queue.length - 1) {
      _currentIndex++;
      _playCurrent();
    } else if (_loopMode == LoopMode.all) {
      _currentIndex = 0;
      _playCurrent();
    }
  }

  void skipToPrevious() {
    // If more than 3 seconds in, restart current song
    if ((_player.position.inSeconds) > 3) {
      _player.seek(Duration.zero);
      return;
    }
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

  void seekTo(Duration position) {
    _player.seek(position);
  }

  // --- Shuffle ---
  void toggleShuffle() {
    _shuffleOn = !_shuffleOn;
    if (_shuffleOn) {
      _applyShuffle();
    } else {
      // Restore original order, find current song in it
      final current = currentSong;
      _queue = List.from(_originalQueue);
      if (current != null) {
        _currentIndex = _queue.indexWhere((s) => s.id == current.id);
        if (_currentIndex < 0) _currentIndex = 0;
      }
    }
    _cachedNextUrl = null;
    _cachedNextIndex = null;
    notifyListeners();
  }

  void _applyShuffle() {
    final current = currentSong;
    final remaining = List<Song>.from(_queue);
    if (current != null) remaining.removeWhere((s) => s.id == current.id);
    remaining.shuffle(Random());
    _queue = current != null ? [current, ...remaining] : remaining;
    _currentIndex = 0;
  }

  // --- Repeat ---
  void toggleRepeat() {
    switch (_loopMode) {
      case LoopMode.off:
        _loopMode = LoopMode.all;
        break;
      case LoopMode.all:
        _loopMode = LoopMode.one;
        break;
      case LoopMode.one:
        _loopMode = LoopMode.off;
        break;
    }
    notifyListeners();
  }

  // --- Liked Songs ---
  Future<void> _loadLikedSongs() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('liked_songs') ?? [];
    _likedSongs = data.map((jsonStr) {
      final map = Map<String, String>.from(json.decode(jsonStr));
      return Song.fromStorageMap(map);
    }).toList();
    notifyListeners();
  }

  Future<void> toggleLike(Song song) async {
    final prefs = await SharedPreferences.getInstance();
    final isLiked = _likedSongs.any((s) => s.id == song.id);
    if (isLiked) {
      _likedSongs.removeWhere((s) => s.id == song.id);
    } else {
      _likedSongs.insert(0, song);
    }
    final data = _likedSongs.map((s) => json.encode(s.toMap())).toList();
    await prefs.setStringList('liked_songs', data);
    notifyListeners();
  }

  // --- Play from queue at index ---
  void playFromQueueAt(int index) {
    if (index >= 0 && index < _queue.length) {
      _currentIndex = index;
      _cachedNextUrl = null;
      _cachedNextIndex = null;
      _playCurrent();
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
