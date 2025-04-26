import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'dart:math' as math;
import 'screens/home_page.dart'; // Adjust import path as needed

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations to portrait only
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style (status bar)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Thrill',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Poppins', // Use your preferred font
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          secondary: const Color(0xFFC0392B),
        ),
        useMaterial3: true,
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontWeight: FontWeight.bold),
          displayMedium: TextStyle(fontWeight: FontWeight.bold),
          titleLarge: TextStyle(fontWeight: FontWeight.w700),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AudioPlayer _audioPlayer;
  late AnimationController _animationController;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _titleFadeAnimation;
  late Animation<double> _subTitleFadeAnimation;
  late Animation<Color?> _backgroundColorAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _subtleShakeAnimation; // Renamed from horrorShakeAnimation for clarity
  // Removed _glitchAnimation - no more flickering
  Timer? _splashTimer;
  Timer? _audioFadeTimer;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize audio player
    _audioPlayer = AudioPlayer();
    
    // Initialize animation controller with longer duration (7 seconds)
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 7000),
      vsync: this,
    );
    
    // Create background color animation from black to white with delayed transition
    _backgroundColorAnimation = ColorTween(
      begin: Colors.black,
      end: const Color(0xFFF5F6F8),
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.5, curve: Curves.easeOut),
      ),
    );
    
    // Logo fade in with smooth effect
    _logoFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.1, 0.4, curve: Curves.easeIn),
      ),
    );
    
    // Subtle shake animation - very minimal movement
    _subtleShakeAnimation = Tween<double>(
      begin: 0.0,
      end: 0.6, // Reduced from 1.0 to make shake more subtle
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.9, curve: Curves.easeInOut),
      ),
    );
    
    // Title fade in with delay
    _titleFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 0.7, curve: Curves.easeIn),
      ),
    );
    
    // Subtitle fade in last
    _subTitleFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.6, 0.9, curve: Curves.easeIn),
      ),
    );
    
    // Scale animation for subtle pulsing effect
    _scaleAnimation = Tween<double>(
      begin: 0.97,
      end: 1.03, // Reduced range for subtler pulsing (was 0.95 to 1.05)
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeInOut),
      ),
    );
    
    // Play intro sound immediately
    _playIntroSound();
    
    // Start animations
    _animationController.forward();
    
    // Start audio fade timer after 3 seconds
    _audioFadeTimer = Timer(const Duration(seconds: 3), () {
      _fadeOutAudio();
    });
    
    // Auto navigate to home page after 7 seconds
    _splashTimer = Timer(const Duration(seconds: 7), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    });
  }
  
  Future<void> _playIntroSound() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      await _audioPlayer.setSourceAsset('music/intro.mp3');
      await _audioPlayer.setVolume(1.0); // Start at full volume
      await _audioPlayer.resume();
    } catch (e) {
      debugPrint('Error playing intro sound: $e');
    }
  }
  
  // New method to fade out audio gradually
  void _fadeOutAudio() {
    const fadeOutDuration = Duration(seconds: 4); // 4 second fade out
    const steps = 20; // Number of volume reduction steps for smoother fade
    const interval = 4000 / steps; // Milliseconds between volume adjustments
    
    double currentVolume = 1.0;
    final volumeStep = 1.0 / steps;
    
    // Create a periodic timer to reduce volume gradually
    Timer.periodic(Duration(milliseconds: interval.round()), (timer) {
      currentVolume -= volumeStep;
      
      if (currentVolume <= 0.0) {
        // Stop timer and audio when volume reaches zero
        timer.cancel();
        _audioPlayer.stop();
        return;
      }
      
      // Set the new volume level
      _audioPlayer.setVolume(currentVolume);
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _splashTimer?.cancel();
    _audioFadeTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        // Get screen size to position elements at the bottom
        final screenSize = MediaQuery.of(context).size;
        
        // Determine text color based on background color transition
        final isDarkBackground = _animationController.value < 0.4;
        final textColor = isDarkBackground ? Colors.white : const Color(0xFF2C3E50);
        final subtitleColor = isDarkBackground ? Colors.white70 : const Color(0xFF7F8C8D);
        
        // Calculate subtle shake effect - minimal movement
        final double shakeX = _subtleShakeAnimation.value * math.sin(_animationController.value * 30) * 1.5;
        final double shakeY = _subtleShakeAnimation.value * math.cos(_animationController.value * 30) * 1.0;
        
        return Scaffold(
          backgroundColor: _backgroundColorAnimation.value,
          body: Stack(
            children: [
              // Logo with subtle effects (no more glitching)
              Positioned(
                top: screenSize.height * 0.35,
                left: 0,
                right: 0,
                child: Transform.translate(
                  offset: Offset(shakeX, shakeY), // Subtle movement
                  child: Opacity(
                    opacity: _logoFadeAnimation.value,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Center(
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 180,
                          height: 180,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Title and subtitle at bottom with very subtle effects
              Positioned(
                bottom: screenSize.height * 0.08,
                left: 0,
                right: 0,
                child: Transform.translate(
                  offset: Offset(shakeX * 0.3, shakeY * 0.3), // Even more subtle movement for text
                  child: Column(
                    children: [
                      // Title with smooth effect - removed shadows
                      Opacity(
                        opacity: _titleFadeAnimation.value,
                        child: Text(
                          'THRILL',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            color: textColor, // Dynamic color based on background
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Subtitle - removed shadows
                      Opacity(
                        opacity: _subTitleFadeAnimation.value,
                        child: Text(
                          'Truth or Dare Like Never Before',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: subtitleColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}
