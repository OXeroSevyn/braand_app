import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'glass_container.dart';
import '../constants.dart';

class LootBoxView extends StatefulWidget {
  final VoidCallback onOpened;
  final String rewardTitle;
  final String rewardIcon;

  const LootBoxView({
    super.key,
    required this.onOpened,
    required this.rewardTitle,
    required this.rewardIcon,
  });

  @override
  State<LootBoxView> createState() => _LootBoxViewState();
}

class _LootBoxViewState extends State<LootBoxView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shakeAnimation;
  late Animation<double> _scaleAnimation;
  bool _isOpening = false;
  bool _isOpened = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.elasticIn),
    ));

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.bounceOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() async {
    if (_isOpening || _isOpened) return;

    setState(() => _isOpening = true);

    // Haptic feedback sequence
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    HapticFeedback.heavyImpact();

    await _controller.forward();

    setState(() {
      _isOpening = false;
      _isOpened = true;
    });

    widget.onOpened();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: _handleTap,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_shakeAnimation.value, 0),
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: _isOpened ? _buildRewardContent() : _buildBoxContent(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBoxContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Glow effect
            if (_isOpening)
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color:
                          AppColors.brand.withOpacity(0.5 * _controller.value),
                      blurRadius: 50 * _controller.value,
                      spreadRadius: 20 * _controller.value,
                    ),
                  ],
                ),
              ),

            GlassContainer(
              width: 120,
              height: 120,
              opacity: 0.2,
              borderRadius: BorderRadius.circular(30),
              child: const Center(
                child: Icon(
                  Icons.card_giftcard,
                  size: 60,
                  color: AppColors.brand,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          _isOpening ? 'OPENING...' : 'TAP TO OPEN BRAAND BOX',
          style: GoogleFonts.spaceMono(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: _isOpening ? AppColors.brand : Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildRewardContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'REWARD UNLOCKED!',
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: AppColors.brand,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withOpacity(0.4),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Text(
            widget.rewardIcon,
            style: const TextStyle(fontSize: 80),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          widget.rewardTitle,
          style: GoogleFonts.spaceMono(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brand,
            foregroundColor: Colors.black,
          ).copyWith(
            padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            ),
          ),
          child: Text(
            'CLAIM',
            style: GoogleFonts.spaceMono(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
