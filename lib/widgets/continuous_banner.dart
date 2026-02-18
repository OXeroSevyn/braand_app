import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/supabase_service.dart';
import '../constants.dart';

class ContinuousBanner extends StatefulWidget {
  final bool isDark;

  const ContinuousBanner({
    super.key,
    required this.isDark,
  });

  @override
  State<ContinuousBanner> createState() => _ContinuousBannerState();
}

class _ContinuousBannerState extends State<ContinuousBanner> {
  final SupabaseService _supabaseService = SupabaseService();

  List<String> _messages = [];
  bool _isLoading = true;
  StreamSubscription? _bannerSubscription;
  Timer? _pollingTimer;
  Timer? _carouselTimer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadBannerContent();

    // Listen to real-time updates
    _bannerSubscription =
        _supabaseService.streamBannerAnnouncements().listen((event) {
      if (mounted) {
        _loadBannerContent();
      }
    });

    // Fallback Polling every 30s for data
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _loadBannerContent();
    });

    // Carousel Timer - switch message every 4 seconds
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted && _messages.isNotEmpty) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _messages.length;
        });
      }
    });
  }

  @override
  void didUpdateWidget(ContinuousBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadBannerContent();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _carouselTimer?.cancel();
    _bannerSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadBannerContent() async {
    try {
      final List<String> messages = [];

      final announcements = await _supabaseService.getBannerAnnouncements();

      final now = DateTime.now().toUtc();
      for (final announcement in announcements) {
        bool isActive = true;
        if (announcement['expires_at'] != null) {
          final expiry = DateTime.parse(announcement['expires_at']);
          if (expiry.isBefore(now)) {
            isActive = false;
          }
        }

        if (isActive) {
          messages.add('${announcement['message']}');
        }
      }

      if (messages.isEmpty) {
        messages.add('📢 Welcome to ${AppConstants.appName}! Stay productive.');
      }

      final uniqueMessages = messages.toSet().toList();

      if (mounted) {
        setState(() {
          _messages = uniqueMessages;
          _isLoading = false;
          // Reset index if out of bounds (e.g. messages removed)
          if (_currentIndex >= _messages.length) {
            _currentIndex = 0;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading banner content: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _messages = ['Welcome to ${AppConstants.appName}'];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _messages.isEmpty) {
      return const SizedBox(height: 36);
    }

    return Container(
      width: double.infinity,
      height: 36,
      color: AppColors.brand,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          transitionBuilder: (Widget child, Animation<double> animation) {
            // Simple Switcher Transition: Fade and slightly slide up
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.5),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: Text(
            _messages[_currentIndex % _messages.length],
            key: ValueKey<int>(_currentIndex), // Important for animation
            style: GoogleFonts.spaceMono(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
