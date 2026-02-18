import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../constants.dart';
import '../models/user.dart';
import '../services/supabase_service.dart';
import '../widgets/glass_container.dart';
import '../widgets/user_avatar.dart';
import '../widgets/messages/quick_contact_selector.dart';
import '../widgets/messages/gradient_message_bubble.dart';
import '../widgets/messages/floating_input_bar.dart';

class MessagesScreen extends StatefulWidget {
  final User user;
  final bool isAdminView;

  const MessagesScreen({
    super.key,
    required this.user,
    this.isAdminView = false,
  });

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<User> _allUsers = [];
  User? _selectedUser;
  List<Map<String, dynamic>> _messages = [];
  int _previousMessageCount = 0;
  bool _isLoading = true;
  bool _isSending = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted && _selectedUser != null) {
        _loadMessages(silent: true);
      }
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      if (widget.isAdminView) {
        final users = await _supabaseService.getAllEmployees();
        if (mounted) {
          setState(() {
            _allUsers = users;
            if (users.isNotEmpty && _selectedUser == null) {
              _selectedUser = users.first;
            }
          });
        }
      } else {
        final admins = await _supabaseService.getAllAdmins();
        if (mounted) {
          setState(() {
            _allUsers = admins;
            if (admins.isNotEmpty && _selectedUser == null) {
              _selectedUser = admins.first;
            }
          });
        }
      }

      await _loadMessages();
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadMessages({bool silent = false}) async {
    try {
      List<Map<String, dynamic>> messages;

      if (_selectedUser != null) {
        messages = await _supabaseService.getConversation(
          widget.user.id,
          _selectedUser!.id,
        );
      } else {
        messages = [];
      }

      if (mounted) {
        final hasNewMessages = messages.length > _previousMessageCount;

        setState(() {
          _messages = messages;
        });

        if (hasNewMessages && !silent && _previousMessageCount > 0) {
          _playNotificationSound();
        }

        _previousMessageCount = messages.length;
      }
    } catch (e) {
      debugPrint('Error loading messages: $e');
    }
  }

  Future<void> _playNotificationSound() async {
    try {
      await SystemSound.play(SystemSoundType.alert);
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    if (_selectedUser == null) return;

    setState(() => _isSending = true);

    try {
      final recipientId = _selectedUser!.id;

      await _supabaseService.sendMessage(
        senderId: widget.user.id,
        recipientId: recipientId,
        message: _messageController.text.trim(),
      );

      _messageController.clear();
      await _loadMessages();

      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to send message: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      ),
      child: Column(
        children: [
          _buildHeader(isDark),
          if (_allUsers.isNotEmpty)
            QuickContactSelector(
              users: _allUsers,
              selectedUser: _selectedUser,
              onUserSelected: (user) {
                setState(() {
                  _selectedUser = user;
                  _previousMessageCount = 0;
                });
                _loadMessages();
              },
            ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.black : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                child: Column(
                  children: [
                    Expanded(child: _buildMessageList(isDark)),
                    FloatingInputBar(
                      controller: _messageController,
                      onSend: _sendMessage,
                      isSending: _isSending,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MESSAGES',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                      letterSpacing: -1,
                    ),
                  ),
                  Text(
                    widget.isAdminView ? 'TEAM CHAT' : 'ADMIN SUPPORT',
                    style: GoogleFonts.spaceMono(
                      fontSize: 12,
                      color: AppColors.brand,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              GlassContainer(
                padding: const EdgeInsets.all(10),
                borderRadius: BorderRadius.circular(50),
                opacity: 0.1,
                child: Icon(Icons.chat_bubble_outline,
                    color: isDark ? Colors.white : Colors.black),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(bool isDark) {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GlassContainer(
              padding: const EdgeInsets.all(32),
              borderRadius: BorderRadius.circular(100),
              opacity: 0.05,
              child: Icon(Icons.mark_chat_unread_outlined,
                  size: 48, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Text(
              'Start a conversation',
              style: GoogleFonts.spaceMono(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isMe = message['sender_id'] == widget.user.id;
        final messageText = message['message'] ?? '';
        final createdAt = DateTime.parse(message['created_at']);

        // Check if next message is from same sender (to group bubbles)
        // Since list is reversed, "next" is actually index - 1
        bool isFirstInSequence = true;
        if (index < _messages.length - 1) {
          final prevMsg = _messages[index + 1]; // "Previous" message in time
          if (prevMsg['sender_id'] == message['sender_id']) {
            isFirstInSequence = false;
          }
        }

        return GradientMessageBubble(
          message: messageText,
          timestamp: createdAt,
          isMe: isMe,
          isFirstInSequence: isFirstInSequence,
        );
      },
    );
  }
}
