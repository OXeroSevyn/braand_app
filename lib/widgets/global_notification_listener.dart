import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/supabase_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/neo_card.dart';

class GlobalNotificationListener extends StatefulWidget {
  final Widget child;

  const GlobalNotificationListener({super.key, required this.child});

  @override
  State<GlobalNotificationListener> createState() =>
      _GlobalNotificationListenerState();
}

class _GlobalNotificationListenerState
    extends State<GlobalNotificationListener> {
  final SupabaseService _supabaseService = SupabaseService();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    // Defer initialization to allow AuthProvider to be available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initListener();
    });
  }

  void _initListener() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Only listen if user is authenticated
    if (authProvider.user != null && !_isListening) {
      _startListening();
    }

    // Listen for auth changes to start/stop listening
    authProvider.addListener(_authListener);
  }

  void _authListener() {
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user != null && !_isListening) {
      _startListening();
    } else if (authProvider.user == null && _isListening) {
      // Stop listening if logged out (stream closes on dispose but good to know)
      _isListening = false;
    }
  }

  void _startListening() {
    _isListening = true;
    debugPrint('🔔 Starting custom notification listener...');
    _supabaseService.subscribeToCustomNotifications().listen((data) {
      debugPrint('🔔 Received custom notification: $data');
      if (!mounted) return;
      _showNotificationDialog(
        data['title'] ?? 'Notice',
        data['message'] ?? '',
      );
    }, onError: (e) {
      debugPrint('❌ Error in notification stream: $e');
    });
  }

  void _showNotificationDialog(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false, // User must tap OK
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: NeoCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.campaign, color: Colors.amber, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title.toUpperCase(),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: GoogleFonts.spaceMono(
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    'ACKNOWLEDGE',
                    style: GoogleFonts.spaceMono(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.removeListener(_authListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
