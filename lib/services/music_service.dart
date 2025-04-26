import 'package:flutter/material.dart';
// Use only audioplayers package
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class MusicService {
  AudioPlayer? _audioPlayer;
  bool _isPlaying = false;
  String? _currentCategory;
  Timer? _audioTimer;
  
  // Available music files based on the paths provided
  final Set<String> _availableMusicFiles = {
    'aspirational', 'childhood', 'confession', 'controversial',
    'deep', 'digital', 'embarrassing', 'emotional', 'entertainment',
    'family', 'food', 'funny', 'gross', 'horror', 'hypothetical',
    'mental', 'personal', 'physical', 'social', 'spooky',
    'thrilling', 'unique', 'weird', 'work',
    // Default types
    'truth', 'dare'
  };
  
  // Map categories to their closest match in available files
  final Map<String, String> _categoryMapping = {
    // Direct mappings
    'aspirational': 'aspirational',
    'childhood': 'childhood',
    'confession': 'confession',
    'controversial': 'controversial',
    'deep': 'deep',
    'digital': 'digital',
    'embarrassing': 'embarrassing',
    'emotional': 'emotional',
    'entertainment': 'entertainment',
    'family': 'family',
    'food': 'food',
    'funny': 'funny',
    'gross': 'gross',
    'horror': 'horror',
    'hypothetical': 'hypothetical',
    'mental': 'mental',
    'personal': 'personal',
    'physical': 'physical',
    'social': 'social',
    'spooky': 'spooky',
    'thrilling': 'thrilling',
    'unique': 'unique',
    'weird': 'weird',
    'work': 'work',
    
    // Common synonyms or related categories
    'challenging': 'thrilling',
    'memories': 'childhood',
    'job': 'work',
    'career': 'work',
    'education': 'work',
    'school': 'work',
    'college': 'work',
    'humorous': 'funny',
    'comedy': 'funny',
    'joke': 'funny',
    'humor': 'funny',
    'romantic': 'emotional',
    'relationship': 'emotional',
    'dating': 'emotional',
    'love': 'emotional',
    'friendship': 'social',
    'friends': 'social',
    'awkward': 'embarrassing',
    'uncomfortable': 'embarrassing',
    'internet': 'digital',
    'technology': 'digital',
    'online': 'digital',
    'social_media': 'digital',
    'thoughtful': 'deep',
    'philosophical': 'deep',
    'reflective': 'deep',
    'creepy': 'spooky',
    'scary': 'horror',
    'terrifying': 'horror',
    'strange': 'weird',
    'odd': 'weird',
    'unusual': 'weird',
    'bizarre': 'weird',
    'culinary': 'food',
    'eating': 'food',
    'cooking': 'food',
    'private': 'personal',
    'intimate': 'personal',
    'action': 'physical',
    'activities': 'physical',
    'movement': 'physical',
    'sports': 'physical',
    'exercise': 'physical',
  };

  Future<void> playMusic(String category) async {
    if (_isPlaying && _currentCategory == category) {
      // Already playing this category
      return;
    }
    
    // Stop any currently playing audio
    await stopMusic();
    
    _currentCategory = category.toLowerCase();
    debugPrint('🎧 Attempting to play category: $_currentCategory');
    
    // Initialize audio player if needed
    _audioPlayer ??= AudioPlayer();
    
    try {
      // Check if the exact category is available
      if (_availableMusicFiles.contains(_currentCategory)) {
        await _playAudioFile(_currentCategory!);
        return;
      }
      
      // Try to find a mapping for this category
      final mappedCategory = _categoryMapping[_currentCategory];
      if (mappedCategory != null) {
        debugPrint('🔄 Mapped "$_currentCategory" to "$mappedCategory"');
        await _playAudioFile(mappedCategory);
        return;
      }
      
      // If category has underscores, try the first word
      if (_currentCategory!.contains('_')) {
        final firstWord = _currentCategory!.split('_')[0];
        debugPrint('🔍 Trying first word: $firstWord');
        
        // Check if first word exists directly
        if (_availableMusicFiles.contains(firstWord)) {
          await _playAudioFile(firstWord);
          return;
        }
        
        // Try to find a mapping for the first word
        final mappedFirstWord = _categoryMapping[firstWord];
        if (mappedFirstWord != null) {
          debugPrint('🔄 Mapped first word "$firstWord" to "$mappedFirstWord"');
          await _playAudioFile(mappedFirstWord);
          return;
        }
      }
      
      // If all else fails, use a fallback based on type
      final fallbackFile = _determineDefaultFile(_currentCategory!);
      debugPrint('⚠️ Using fallback category: $fallbackFile');
      await _playAudioFile(fallbackFile);
      
    } catch (e) {
      debugPrint('❌ Error playing music: $e');
      _isPlaying = false;
    }
  }
  
  String _determineDefaultFile(String category) {
    // Categories more likely to be dares
    final dareCategories = [
      'physical', 'action', 'movement', 'sports', 'exercise',
      'embarrassing', 'awkward', 'uncomfortable', 
      'gross', 'thrilling', 'challenging', 'spooky'
    ];
    
    // Check if any dare-related keywords are in the category
    for (final keyword in dareCategories) {
      if (category.contains(keyword)) {
        return 'dare';
      }
    }
    
    // Default to truth for other categories
    return 'truth';
  }
  
  Future<void> _playAudioFile(String filename) async {
    try {
      final path = 'assets/music/$filename.mp3';
      debugPrint('🔊 Playing: $path');
      
      // Set up player configuration before playing to ensure no looping
      await _audioPlayer!.setReleaseMode(ReleaseMode.stop); // Ensures audio stops when complete
      await _audioPlayer!.setSourceAsset(path.replaceFirst('assets/', ''));
      await _audioPlayer!.resume(); // Use resume instead of play
      
      _isPlaying = true;
      debugPrint('✅ Success! Now playing: $path (will play for 20 seconds max)');
      
      // Cancel any existing timer
      _audioTimer?.cancel();
      
      // Create a new timer to stop audio after 20 seconds (increased from 5 seconds)
      _audioTimer = Timer(const Duration(seconds: 20), () {
        stopMusic();
        debugPrint('⏱️ Audio stopped after 20 seconds');
      });
    } catch (e) {
      debugPrint('❌ Failed to play audio: $e');
      
      // If not truth or dare and failed, try those as fallbacks
      if (filename != 'truth' && filename != 'dare') {
        final fallback = _determineDefaultFile(filename);
        debugPrint('🔄 Trying final fallback: $fallback');
        await _playAudioFile(fallback);
      }
    }
  }

  Future<void> stopMusic() async {
    // Cancel the timer if it exists
    _audioTimer?.cancel();
    _audioTimer = null;
    
    if (_audioPlayer != null) {
      try {
        await _audioPlayer!.stop();
        // Explicitly release resources to prevent memory leaks
        await _audioPlayer!.release();
      } catch (e) {
        debugPrint('Error stopping music: $e');
      }
      _isPlaying = false;
      _currentCategory = null;
    }
  }

  void dispose() {
    // Cancel the timer if it exists
    _audioTimer?.cancel();
    _audioTimer = null;
    
    if (_audioPlayer != null) {
      try {
        _audioPlayer!.dispose();
      } catch (e) {
        debugPrint('Error disposing audio player: $e');
      }
      _audioPlayer = null;
    }
  }
}
