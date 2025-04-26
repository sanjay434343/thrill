import 'package:flutter/material.dart';
import '../widgets/comic_pattern.dart';
import '../services/music_service.dart';
import 'dart:math' as math;
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';

// Define the CornerClipper class at the top level
class CornerClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// Define the EnhancedSpeechBubblePointer class at the top level
class EnhancedSpeechBubblePointer extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);

    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class CardsPage extends StatefulWidget {
  final String type;
  final List<Map<String, dynamic>> cards;

  const CardsPage({
    super.key,
    required this.type,
    required this.cards,
  });

  @override
  State<CardsPage> createState() => _CardsPageState();
}

class _CardsPageState extends State<CardsPage> with TickerProviderStateMixin {
  int? _revealedCardIndex;
  late List<AnimationController> _animationControllers;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<double>> _elevationAnimations;
  late List<Animation<double>> _rotationAnimations;
  late List<Animation<Offset>> _flyAnimations;
  late PageController _pageController;
  late List<Map<String, dynamic>> _randomizedCards;
  int? _selectedCardIndex;
  Timer? _autoScrollTimer;
  Timer? _autoHomeTimer; // New timer for auto-navigation to home
  bool _userInteracting = false;
  bool _cardSelected = false;
  bool _isLoading = true;
  List<Map<String, dynamic>> _truthQuestions = [];
  List<Map<String, dynamic>> _questions = [];
  bool _isScrollingStopped = false;
  int _currentCardIndex = 0;
  bool _completedFullRound = false;
  int _totalScrolledCards = 0;
  final MusicService _musicService = MusicService();
  bool _isMuted = false;

  // Animation controller for continuous animations
  late AnimationController _continuousAnimationController;
  int _remainingSeconds = 15; // Track remaining seconds for countdown display
  Timer? _countdownTimer; // Separate timer for UI updates

  @override
  void initState() {
    super.initState();

    // Initialize continuous animation controller for selected card with more dramatic effect
    _continuousAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    // Make sure any previously playing music is stopped when entering this page
    _musicService.stopMusic();

    // Load questions based on the type
    if (widget.type == 'Truth') {
      _loadTruthQuestions();
    } else if (widget.type == 'Dare') {
      _loadDareQuestions();
    } else if (widget.type == 'Mixed') {
      _loadMixedQuestions();
    } else {
      _initializeWithCards(widget.cards);
    }

    // Auto-stopping is now handled inside _startAutoScroll
  }

  // Load truth questions from JSON file
  Future<void> _loadTruthQuestions() async {
    try {
      // Load the JSON file from assets
      final String response = await rootBundle.loadString('assets/files/truth_questions.json');
      final data = await json.decode(response);

      _questions = List<Map<String, dynamic>>.from(
        data['truthQuestions'].map((question) => {
          'type': 'Truth',
          'content': question['question'],
          'category': question['category'],
          'id': question['id'],
          'color': const Color(0xFF4CAF50), // Updated to brighter green
        })
      );

      setState(() {
        _isLoading = false;
        _initializeWithCards(_questions);
      });
    } catch (e) {
      print('Error loading truth questions: $e');
      setState(() {
        _isLoading = false;
        _initializeWithCards(widget.cards);
      });
    }
  }

  // Load dare questions from JSON file
  Future<void> _loadDareQuestions() async {
    try {
      // Load the JSON file from assets
      final String response = await rootBundle.loadString('assets/files/dare_questions.json');
      final data = await json.decode(response);

      _questions = List<Map<String, dynamic>>.from(
        data['dareQuestions'].map((question) => {
          'type': 'Dare',
          'content': question['question'],
          'category': question['category'],
          'id': question['id'],
          'color': const Color(0xFFF44336), // Updated to brighter red
        })
      );

      setState(() {
        _isLoading = false;
        _initializeWithCards(_questions);
      });
    } catch (e) {
      print('Error loading dare questions: $e');
      setState(() {
        _isLoading = false;
        _initializeWithCards(widget.cards);
      });
    }
  }

  // Load truth and dare questions for mixed mode
  Future<void> _loadMixedQuestions() async {
    try {
      // Load Truth questions
      final String truthResponse = await rootBundle.loadString('assets/files/truth_questions.json');
      final truthData = await json.decode(truthResponse);
      final truthQuestions = List<Map<String, dynamic>>.from(
        truthData['truthQuestions'].map((question) => {
          'type': 'Truth',
          'content': question['question'],
          'category': question['category'],
          'id': question['id'],
          'color': const Color(0xFF4CAF50), // Brighter green
        }),
      );

      // Load Dare questions
      final String dareResponse = await rootBundle.loadString('assets/files/dare_questions.json');
      final dareData = await json.decode(dareResponse);
      final dareQuestions = List<Map<String, dynamic>>.from(
        dareData['dareQuestions'].map((question) => {
          'type': 'Dare',
          'content': question['question'],
          'category': question['category'],
          'id': question['id'],
          'color': const Color(0xFFF44336), // Brighter red
        }),
      );

      // Combine Truth and Dare questions
      _questions = [...truthQuestions, ...dareQuestions];

      setState(() {
        _isLoading = false;
        _initializeWithCards(_questions);
      });
    } catch (e) {
      print('Error loading mixed questions: $e');
      setState(() {
        _isLoading = false;
        _initializeWithCards(widget.cards);
      });
    }
  }

  void _initializeWithCards(List<Map<String, dynamic>> cardsToUse) {
    // Randomize the cards
    _randomizedCards = List.from(cardsToUse)..shuffle();

    // Initialize page controller for carousel with slightly adjusted viewportFraction
    _pageController = PageController(
      viewportFraction: 0.7, // Increased from 0.65 to create more gap between cards
      initialPage: 0,
    );

    _animationControllers = List.generate(
      _randomizedCards.length,
          (index) => AnimationController(
        duration: const Duration(milliseconds: 700),
        vsync: this,
      ),
    );

    // Set scale animations to fixed values (no zooming)
    _scaleAnimations = _animationControllers
        .map((controller) =>
        Tween<double>(begin: 1.0, end: 1.0).animate(
          CurvedAnimation(parent: controller, curve: Curves.easeOutBack),
        ))
        .toList();

    // Remove elevation animations
    _elevationAnimations = _animationControllers
        .map((controller) =>
        Tween<double>(begin: 0.0, end: 0.0).animate(
          CurvedAnimation(parent: controller, curve: Curves.easeOut),
        ))
        .toList();

    // Remove rotation animations
    _rotationAnimations = _animationControllers
        .map((controller) =>
        Tween<double>(begin: 0.0, end: 0.0).animate(
          CurvedAnimation(parent: controller, curve: Curves.elasticOut),
        ))
        .toList();

    // Keep fly animations for functional purposes but minimize movement
    _flyAnimations = _animationControllers
        .map((controller) =>
        Tween<Offset>(
          begin: Offset.zero,
          end: Offset.zero, // No movement
        ).animate(
          CurvedAnimation(parent: controller, curve: Curves.easeOutQuad),
        ))
        .toList();

    // Start auto-scrolling
    _startAutoScroll();
  }

  @override
  void dispose() {
    // Make sure to completely stop music when leaving the page
    _musicService.stopMusic();
    
    // Cancel auto-home timer
    _autoHomeTimer?.cancel();
    
    // Add try-catch to handle potential errors when disposing audio resources
    try {
      // Manually release audio resources
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _musicService.dispose();
        }
      });
    } catch (e) {
      debugPrint('Error disposing music service: $e');
    }
    
    _continuousAnimationController.dispose();
    _autoScrollTimer?.cancel();
    _countdownTimer?.cancel(); // Make sure to cancel countdown timer
    for (var controller in _animationControllers) {
      controller.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();

    // Track scroll start time
    final startTime = DateTime.now();
    
    // Define a shorter total scrolling duration (5 seconds)
    const totalScrollDuration = 5000; // 5 seconds in milliseconds
    
    // Track scrolling phase
    bool _isCardSelectionPhase = false;
    int _lastHapticFeedbackTime = 0;
    
    // Use smoother scrolling with controlled speed
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!_cardSelected && !_isScrollingStopped && _pageController.hasClients) {
        // Calculate progress based on elapsed time
        final currentTime = DateTime.now();
        final elapsedMilliseconds = currentTime.difference(startTime).inMilliseconds;
        
        // If we've reached the time limit, stop and select card
        if (elapsedMilliseconds >= totalScrollDuration) {
          if (!_isCardSelectionPhase) {
            _isCardSelectionPhase = true;
            _selectCurrentCard(); // Select the card at current position
            timer.cancel();
          }
          return;
        }
        
        // Provide haptic feedback periodically during scrolling
        if (elapsedMilliseconds - _lastHapticFeedbackTime > 800) {
          HapticFeedback.lightImpact();
          _lastHapticFeedbackTime = elapsedMilliseconds;
        }
        
        // Calculate smooth deceleration curve
        // Start at 100% speed, gradually reduce to 0% at the end
        final progress = elapsedMilliseconds / totalScrollDuration;
        final speedFactor = 1.0 - progress; // Linear deceleration
        
        // Base speed multiplied by deceleration factor
        // The base speed is higher (60.0) to make it visibly scroll
        final scrollSpeed = 60.0 * speedFactor;
        
        // Apply forward scrolling - only left to right
        _pageController.jumpTo(_pageController.position.pixels + scrollSpeed);
        
        // Loop back to the beginning when reaching the end
        if (_pageController.position.pixels >= _pageController.position.maxScrollExtent - 100) {
          _pageController.jumpTo(0);
        }
      }
    });
  }
  
  // New method to select the current card instead of a random one
  void _selectCurrentCard() {
    _autoScrollTimer?.cancel();
    
    // Get the nearest card index (the one currently most visible)
    final currentPage = _pageController.page!.round();
    
    setState(() {
      _isScrollingStopped = true;
      _currentCardIndex = currentPage;
      _selectedCardIndex = currentPage;
      _cardSelected = true;
      // Don't set _revealedCardIndex to require tap to reveal
    });
    
    // Immediately snap to the exact page
    _pageController.jumpToPage(currentPage);
    
    // Haptic feedback for card selection - make it stronger
    HapticFeedback.heavyImpact();
  }
  
  // Keep _selectRandomCard for backwards compatibility, but use _selectCurrentCard
  void _selectRandomCard() {
    _selectCurrentCard();
  }

  void _pauseAutoScroll() {
    _userInteracting = true;
    // Resume auto-scroll after 5 seconds of inactivity instead of 10
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && !_cardSelected) {
        setState(() {
          _userInteracting = false;
        });
      }
    });
  }

  void _toggleCardReveal(int index) {
    // Modified card reveal logic - only toggle from hidden to revealed, not back
    if (_revealedCardIndex == null) {
      // If no card is currently revealed, reveal this one
      _animationControllers[index].forward();
      setState(() {
        _revealedCardIndex = index;
      });

      // Play music for this card's category
      _playMusicForCard(_randomizedCards[index]);

      // Add haptic feedback when revealing
      HapticFeedback.mediumImpact();
      
      // Start the auto-home timer when card is revealed
      _startAutoHomeTimer();
    } 
    // Remove the else branch that would hide the card again
    // We want the card to stay revealed once it's tapped
  }

  // Updated method to play category music with improved error handling
  void _playMusicForCard(Map<String, dynamic> card) {
    // First stop any playing music
    _musicService.stopMusic();
    
    // Get category or type
    String soundToPlay = "";
    
    // Play music based on the card's category
    if (card['category'] != null) {
      // Get the category and sanitize it for filename
      String category = card['category'].toString().toLowerCase();
      
      // More comprehensive sanitization to match available audio files
      category = category.replaceAll(' ', '_')
                        .replaceAll("'", "")
                        .replaceAll("\"", "")
                        .replaceAll(",", "")
                        .replaceAll(".", "")
                        .replaceAll("-", "_")
                        .replaceAll("&", "and")
                        .replaceAll(":", "")
                        .replaceAll("(", "")
                        .replaceAll(")", "")
                        .replaceAll("!", "");
      
      debugPrint('⭐ Card category: ${card['category']} → Music file: $category.mp3');
      
      // Play the sound
      _musicService.playMusic(category.toLowerCase());
    } else {
      // If no category, use the card type (truth or dare)
      String type = card['type'].toString().toLowerCase();
      debugPrint('⭐ No category, using type: $type.mp3');
      _musicService.playMusic(type.toLowerCase());
    }
  }

  void _selectCard(int index) {
    // Add haptic feedback
    HapticFeedback.heavyImpact();

    setState(() {
      _selectedCardIndex = index;
      _cardSelected = true;
      _revealedCardIndex = index; // Ensure the card is revealed
    });

    // Stop auto-scrolling
    _autoScrollTimer?.cancel();

    // Ensure the selected card is centered
    if (_pageController.hasClients && _pageController.page!.round() != index) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }

    // Animate the card to become larger
    _animationControllers[index].forward();
    
    // Play music for this card
    _playMusicForCard(_randomizedCards[index]);
    
    // Start auto-home timer
    _startAutoHomeTimer();
  }

  // New method to handle auto-navigation to home page with countdown
  void _startAutoHomeTimer() {
    // Cancel any existing timers
    _autoHomeTimer?.cancel();
    _countdownTimer?.cancel();
    
    // Reset the countdown
    setState(() {
      _remainingSeconds = 15;
    });
    
    // Start countdown timer to update UI every second
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _remainingSeconds--;
        });
        
        // If countdown reaches 0, cancel the timer and navigate home
        if (_remainingSeconds <= 0) {
          timer.cancel();
          
          // Navigate back to home automatically
          if (mounted) {
            // Provide haptic feedback before navigating
            HapticFeedback.mediumImpact();
            Navigator.of(context).pop();
          }
        }
      }
    });
    
    // Remove the separate auto-home timer since we'll navigate directly in the countdown
  }

  void _stopScrolling() {
    _autoScrollTimer?.cancel();

    // Add haptic feedback
    HapticFeedback.heavyImpact();

    // Snap to the nearest card with a deceleration effect
    if (_pageController.hasClients) {
      final currentPage = _pageController.page!.round();

      setState(() {
        _isScrollingStopped = true;
        _currentCardIndex = currentPage;
        _selectedCardIndex = currentPage; // Auto-select the current card
        _cardSelected = true;
        // Don't set _revealedCardIndex to require tap to reveal
      });

      _pageController.animateToPage(
        currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      
      // Start auto-home timer when stopping (since card is selected)
      _startAutoHomeTimer();
    }
  }

  // Add a new method to explicitly stop scrolling (separate from selection)
  void _stopScrollingOnly() {
    _autoScrollTimer?.cancel();
    setState(() {
      _isScrollingStopped = true;
    });
    
    // Add haptic feedback
    HapticFeedback.mediumImpact();
    
    // Snap to nearest card without selecting it
    if (_pageController.hasClients) {
      final currentPage = _pageController.page!.round();
      _pageController.jumpToPage(currentPage); // Use jumpToPage instead of animateToPage
      
      setState(() {
        _currentCardIndex = currentPage;
        _selectedCardIndex = currentPage;
      });
      
      // Start auto-home timer when stopping
      _startAutoHomeTimer();
    }
  }

  Widget _buildCarousel() {
    return Expanded(
      child: GestureDetector(
        child: PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            // Only respond to manual page changes if not selected
            if (_isScrollingStopped && !_cardSelected) {
              // If we're stopped but not selected, update the current card index without revealing
              setState(() {
                _currentCardIndex = index;
                _selectedCardIndex = index;
              });
              
              // Close any previously opened card
              if (_revealedCardIndex != null && _revealedCardIndex != index) {
                _animationControllers[_revealedCardIndex!].reverse();
                _musicService.stopMusic(); // Stop music when changing cards
              }
              
              // Don't automatically reveal the card when changing pages manually
              // Let the user tap to reveal it instead
            } else if (!_isScrollingStopped) {
              _pauseAutoScroll();
              setState(() {
                _currentCardIndex = index;
              });
            }
            
            // Add light haptic feedback on each page change
            HapticFeedback.selectionClick();
          },
          // Always prevent manual scrolling, regardless of state
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _randomizedCards.length,
          scrollDirection: Axis.horizontal, // Ensure horizontal scrolling only
          itemBuilder: (context, index) {
            final card = _randomizedCards[index];
            final isRevealed = _revealedCardIndex == index;
            final isCurrentCard = _isScrollingStopped && index == _currentCardIndex;
            final isSelectedCard = _cardSelected && _selectedCardIndex == index;
            
            // Calculate distance from the current card for visibility
            final distance = (index - _currentCardIndex).abs();
            final shouldShowNeighbor = _isScrollingStopped && distance <= 1; // Show current and one neighbor on each side
            
            return AnimatedBuilder(
              animation: _animationControllers[index],
              builder: (context, child) {
                // Show current card and neighbors when scrolling is stopped
                final visible = !_isScrollingStopped || shouldShowNeighbor;
                
                // No scaling for any cards
                final scale = 1.0;
                
                return Visibility(
                  visible: visible,
                  maintainState: true,
                  maintainAnimation: true,
                  maintainSize: true,
                  child: Center(
                    child: GestureDetector(
                      // Simplified onTap - only reveal card if not already revealed
                      onTap: () {
                        if (_revealedCardIndex == null && (isCurrentCard || isSelectedCard)) {
                          _toggleCardReveal(index);
                        }
                        // Don't do anything if card is already revealed
                      },
                      child: Container(
                        height: 380,
                        width: 260,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 20, // Increased from 4 to create more separation
                          vertical: 20,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              card['color'],
                              card['color'].withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isSelectedCard || isCurrentCard
                                ? Colors.white
                                : Colors.black,
                            width: isSelectedCard ? 4 : (isCurrentCard ? 3 : 2),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // Improved corner design
                            Positioned(
                              right: 0,
                              top: 0,
                              child: ClipPath(
                                clipper: CornerClipper(),
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors.white,
                                ),
                              ),
                            ),

                            // Card ID at top left - keep this visible
                            Positioned(
                              top: 16,
                              left: 16,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.black, width: 1),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 3,
                                      offset: const Offset(1, 1),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  card['id'] != null ? "#${card['id']}" : "#${index + 1}",
                                  style: TextStyle(
                                    color: card['color'],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),

                            // Remove category badge from the front face of the card
                            // We'll only show it when the card is revealed

                            // Enhanced type badge with better placement
                            Positioned(
                              right: -10,
                              top: -10,
                              child: Transform.rotate(
                                angle: 0.2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.yellow[700],
                                    border: Border.all(color: Colors.black, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: const Offset(1, 1),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    card['type'].toUpperCase(),
                                    style: TextStyle(
                                      color: card['color'],
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Enhanced status indicator
                            if (isCurrentCard || isSelectedCard)
                              Positioned(
                                bottom: -12,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelectedCard ? Colors.yellow[600] : Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: Colors.black, width: 2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      isSelectedCard ? 'YOUR CHALLENGE!' : 'CARD SELECTED',
                                      style: TextStyle(
                                        color: card['color'],
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                            // Content - improved reveal animation
                            Center(
                              child: isRevealed
                                  ? _buildRevealedContent(card, isSelected: isSelectedCard, isCurrentCard: isCurrentCard)
                                  : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.question_mark,
                                    size: 80,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                  const SizedBox(height: 20),
                                  // Only show "TAP TO REVEAL" when card is selected but not during scrolling
                                  if (_isScrollingStopped && (isCurrentCard || isSelectedCard))
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.5),
                                          width: 2,
                                        ),
                                      ),
                                      child: const Text(
                                        'TAP TO REVEAL',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  // Method to determine appropriate colors based on card type
  Color _getColorForType(String type) {
    if (type == 'Truth') {
      return const Color(0xFF4CAF50); // Brighter green for Truth
    } else if (type == 'Dare') {
      return const Color(0xFFF44336); // Brighter red for Dare
    } else if (type == 'Mixed') {
      final currentCardType = _currentCardIndex < _randomizedCards.length 
          ? _randomizedCards[_currentCardIndex]['type'] 
          : 'Truth';
      return currentCardType == 'Truth' 
          ? const Color(0xFF4CAF50)  // Brighter green
          : const Color(0xFFF44336); // Brighter red
    }
    return const Color(0xFF2196F3); // Brighter blue for default
  }

  // Helper to get gradient colors for Mixed mode
  List<Color> _getMixedGradientColors() {
    return [
      const Color(0xFF4CAF50), // Brighter green
      const Color(0xFFF44336), // Brighter red
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F6F8),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Ensure all cards have the right color
    for (var card in _randomizedCards) {
      if (card['type'] == 'Truth') {
        card['color'] = const Color(0xFF4CAF50);
      } else if (card['type'] == 'Dare') {
        card['color'] = const Color(0xFFF44336);
      }
    }

    // Determine current color based on type or current card
    final currentColor = _getColorForType(widget.type);
    final isMixedMode = widget.type == 'Mixed';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      floatingActionButton: !_isScrollingStopped 
        ? FloatingActionButton( // Remove Container wrapper to eliminate shadow
            heroTag: 'stop',
            onPressed: _stopScrollingOnly,
            backgroundColor: Colors.transparent,
            elevation: 0, // Remove elevation
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isMixedMode
                  ? LinearGradient(
                      colors: _getMixedGradientColors(),
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : LinearGradient(
                      colors: [
                        currentColor,
                        currentColor.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              ),
              child: const Icon(
                Icons.stop_circle,
                color: Colors.white,
                size: 30,
              ),
            ),
          )
        : (_cardSelected
            ? FloatingActionButton( // Remove Container wrapper to eliminate shadow
                heroTag: 'countdown',
                onPressed: () {
                  // Cancel auto-home timer when manually going home
                  _autoHomeTimer?.cancel();
                  _countdownTimer?.cancel();
                  Navigator.of(context).pop();
                },
                backgroundColor: Colors.transparent,
                elevation: 0, // Remove elevation
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isMixedMode
                      ? (_selectedCardIndex != null && _selectedCardIndex! < _randomizedCards.length 
                          ? (_randomizedCards[_selectedCardIndex!]['type'] == 'Truth'
                              ? LinearGradient(
                                  colors: [
                                    const Color(0xFF4CAF50),
                                    const Color(0xFF4CAF50).withOpacity(0.8),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : LinearGradient(
                                  colors: [
                                    const Color(0xFFF44336),
                                    const Color(0xFFF44336).withOpacity(0.8),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ))
                          : LinearGradient(
                              colors: _getMixedGradientColors(),
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ))
                      : LinearGradient(
                          colors: [
                            currentColor,
                            currentColor.withOpacity(0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  ),
                  // Keep countdown display code
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Pulsing background circle for emphasis as time runs low
                      if (_remainingSeconds <= 5)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          width: 40 + (5 - _remainingSeconds) * 2.0,
                          height: 40 + (5 - _remainingSeconds) * 2.0,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(
                                _remainingSeconds <= 3 ? 0.3 : 0.2),
                          ),
                        ),
                      // Countdown number with animation
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          // Scale and fade transition for each number change
                          return FadeTransition(
                            opacity: animation,
                            child: ScaleTransition(
                              scale: animation.drive(
                                Tween<double>(begin: 1.5, end: 1.0)
                                    .chain(CurveTween(curve: Curves.easeOutBack))
                              ),
                              child: child,
                            ),
                          );
                        },
                        child: Text(
                          "$_remainingSeconds",
                          key: ValueKey<int>(_remainingSeconds), // Key for animation
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: _remainingSeconds < 10 ? 24 : 22, // Larger for single digits
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : null),
      
      body: ComicPattern(
        child: SafeArea(
          child: Column(
            children: [
              // Enhanced header with improved shadow and spacing
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Enhanced back button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => Navigator.pop(context),
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Icon(
                              Icons.arrow_back,
                              color: Color(0xFF2C3E50),
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Enhanced title container with gradient for Mixed mode
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          // For Mixed mode, use gradient of green and red
                          gradient: isMixedMode 
                              ? LinearGradient(
                                  colors: _getMixedGradientColors(),
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                )
                              : null,
                          color: isMixedMode ? null : currentColor,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 10,
                              offset: const Offset(2, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          _cardSelected
                              ? _getCurrentCardTypeTitle()
                              : widget.type.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Card carousel
              _buildCarousel(),

              // Added bottom padding
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // New method to get the appropriate title for the selected card
  String _getCurrentCardTypeTitle() {
    if (widget.type != 'Mixed' || _selectedCardIndex == null) {
      return 'YOUR ${widget.type.toUpperCase()} CHALLENGE';
    }
    
    // For Mixed mode, get the type from the selected card
    final selectedCardType = _randomizedCards[_selectedCardIndex!]['type'];
    return 'YOUR ${selectedCardType.toUpperCase()} CHALLENGE';
  }

  Widget _buildRevealedContent(Map<String, dynamic> card, {bool isSelected = false, bool isCurrentCard = false}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected 
              ? Colors.yellow 
              : Colors.black, 
          width: isSelected ? 3 : 2
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: const Offset(2, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Display question content with better styling
          Text(
            card['content'],
            textAlign: TextAlign.center,
            style: TextStyle(
              color: card['color'],
              fontSize: 20,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),

          // Show category only when the card is revealed
          // But without the "Category:" label
          if (card['category'] != null) ...[
            const SizedBox(height: 16),
            AnimatedOpacity(
              opacity: 1.0,
              duration: const Duration(milliseconds: 500),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: card['color'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: card['color'].withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  "${card['category']}", // Removed "Category: " label
                  style: TextStyle(
                    color: card['color'],
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Enhanced speech bubble pointer
          if (!isSelected && !isCurrentCard)
            Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    offset: const Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
              child: CustomPaint(
                size: const Size(24, 16),
                painter: EnhancedSpeechBubblePointer(),
              ),
            ),
        ],
      ),
    );
  }
}
