import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/comic_pattern.dart';
import 'cards_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..forward();
    
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToCardsPage(String type) {
    // Provide haptic feedback
    HapticFeedback.mediumImpact();
    
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => CardsPage(
          type: type,
          cards: const [], // Empty list as the cards are loaded inside CardsPage
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeOutQuint;
          
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          
          return SlideTransition(position: offsetAnimation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: ComicPattern(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              
              // Animated logo and title
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        width: 120,
                        height: 120,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'THRILL',
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'TRUTH OR DARE',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 60),
              
              // Game mode selection text
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'SELECT GAME MODE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey[800],
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Game mode buttons
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // Truth button
                      _buildGameModeButton(
                        title: 'TRUTH',
                        subtitle: 'Answer personal questions with honesty',
                        icon: Icons.record_voice_over,
                        color: const Color(0xFF2E7D32),
                        onTap: () => _navigateToCardsPage('Truth'),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Dare button
                      _buildGameModeButton(
                        title: 'DARE',
                        subtitle: 'Accept challenges that test your courage',
                        icon: Icons.flash_on,
                        color: const Color(0xFFC0392B),
                        onTap: () => _navigateToCardsPage('Dare'),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Mixed mode button
                      _buildGameModeButton(
                        title: 'MIXED',
                        subtitle: 'Truth or dare questions combined',
                        icon: Icons.shuffle,
                        color: const Color(0xFF3498DB),
                        onTap: () => _navigateToCardsPage('Mixed'),
                      ),
                    ],
                  ),
                ),
              ),
              
              // App version
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'v1.0.0',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildGameModeButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    // Brighter gradient colors for each mode
    final gradient = title == 'MIXED'
        ? const LinearGradient(
            colors: [
              Color(0xFF4CAF50), // Brighter green for Truth
              Color(0xFFF44336), // Brighter red for Dare
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : LinearGradient(
            colors: [
              // Use brighter base color
              title == 'TRUTH' 
                  ? const Color(0xFF4CAF50)  // Brighter green
                  : title == 'DARE' 
                      ? const Color(0xFFF44336)  // Brighter red
                      : const Color(0xFF2196F3), // Brighter blue
              // Slightly less bright for gradient effect
              title == 'TRUTH'
                  ? const Color(0xFF45A049)
                  : title == 'DARE'
                      ? const Color(0xFFE53935)
                      : const Color(0xFF1E88E5),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
    
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: title == 'MIXED'
                      ? Colors.purple.withOpacity(0.3) // Special shadow for Mixed
                      : color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
