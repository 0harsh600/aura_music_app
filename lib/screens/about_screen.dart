import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App icon
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1DB954), Color(0xFF191414)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF1DB954).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: const Icon(Icons.music_note_rounded, color: Colors.white, size: 48),
                ),
                const SizedBox(height: 28),
                const Text('Aura Music',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('v2.0.0', style: TextStyle(color: Colors.white54, fontSize: 12)),
                ),
                const SizedBox(height: 32),

                // Divider
                Container(height: 1, color: Colors.white10),
                const SizedBox(height: 32),

                const Text('BUILT BY',
                  style: TextStyle(color: Colors.white38, fontSize: 12, letterSpacing: 3, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                const Text('Harshvardhan Sing Rathore',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),

                const SizedBox(height: 32),
                Container(height: 1, color: Colors.white10),
                const SizedBox(height: 24),

                // Features list
                const _FeatureRow(icon: Icons.music_note, text: 'Full-length songs from YouTube'),
                const _FeatureRow(icon: Icons.favorite, text: 'Like & save your favorites'),
                const _FeatureRow(icon: Icons.shuffle, text: 'Shuffle & repeat modes'),
                const _FeatureRow(icon: Icons.queue_music, text: 'Queue management'),
                const _FeatureRow(icon: Icons.search, text: 'Search with history'),
                const _FeatureRow(icon: Icons.headphones, text: 'Background playback'),

                const SizedBox(height: 32),
                Text('Made with ❤️ in India',
                  style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1DB954), size: 18),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }
}
