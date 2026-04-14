class Song {
  final String id; // usually the YouTube Video ID
  final String title;
  final String artistName;
  final String artistId;
  final String? albumArtUrl;

  Song({
    required this.id,
    required this.title,
    required this.artistName,
    required this.artistId,
    this.albumArtUrl,
  });

  factory Song.fromMap(Map<String, dynamic> map) {
    return Song(
      id: map['videoId'] ?? map['id'] ?? '',
      title: map['title'] ?? 'Unknown',
      artistName: map['artist'] ?? map['artistName'] ?? 'Unknown Artist',
      artistId: map['artistId'] ?? '',
      albumArtUrl: map['thumbnail'] ?? map['albumArtUrl'],
    );
  }
}

class Artist {
  final String id;
  final String name;
  final String? photoUrl;

  Artist({
    required this.id,
    required this.name,
    this.photoUrl,
  });

  factory Artist.fromMap(Map<String, dynamic> map) {
    return Artist(
      id: map['browseId'] ?? map['id'] ?? '',
      name: map['artist'] ?? map['name'] ?? 'Unknown Artist',
      photoUrl: map['thumbnail'] ?? map['photoUrl'],
    );
  }
}
