import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import 'neo_card.dart';

class ClockWidget extends StatefulWidget {
  const ClockWidget({super.key});

  @override
  State<ClockWidget> createState() => _ClockWidgetState();
}

class _ClockWidgetState extends State<ClockWidget> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return NeoCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.access_time,
                color: isDark ? AppColors.brand : Colors.black,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'LOCAL TIME',
                style: GoogleFonts.spaceMono(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            DateFormat('hh:mm:ss a').format(_now),
            style: GoogleFonts.spaceMono(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
              letterSpacing: -2,
            ),
          ),
          const SizedBox(height: 16),
          Transform.rotate(
            angle: -0.02,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              color: AppColors.brand,
              child: Text(
                DateFormat('EEE, MMM d, yyyy').format(_now).toUpperCase(),
                style: GoogleFonts.spaceMono(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
