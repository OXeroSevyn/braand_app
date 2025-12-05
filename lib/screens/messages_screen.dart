import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../constants.dart';
import '../models/user.dart';
import '../services/supabase_service.dart';

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
  String? _employeeAdminId; // Store admin ID for employee

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
    // Auto-refresh every 0.5 seconds
    _refreshTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) {
        _loadMessages(silent: true);
      }
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      if (widget.isAdminView) {
        // Admin: load all employees
        final users = await _supabaseService.getAllEmployees();
        if (mounted) {
          setState(() {
            _allUsers = users;
            if (users.isNotEmpty && _selectedUser == null) {
              _selectedUser = users.first;
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

      if (widget.isAdminView && _selectedUser != null) {
        // Admin: load conversation with selected user
        messages = await _supabaseService.getConversation(
          widget.user.id,
          _selectedUser!.id,
        );
      } else {
        // Employee: load conversation with admin
        // First, try to get any message to find the admin
        final receivedMessages = await _supabaseService.getMessagesForUser(
          widget.user.id,
        );

        if (receivedMessages.isNotEmpty) {
          // Get the admin ID from the first message
          final adminId = receivedMessages.first['sender_id'];
          _employeeAdminId = adminId;

          // Load full conversation with that admin
          messages = await _supabaseService.getConversation(
            widget.user.id,
            adminId,
          );
        } else {
          messages = [];
        }
      }

      if (mounted) {
        // Check if new messages arrived
        final hasNewMessages = messages.length > _previousMessageCount;

        setState(() {
          _messages = messages;
        });

        // Play sound if new message arrived (only when not silent and not first load)
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
      // Play system notification sound
      await SystemSound.play(SystemSoundType.alert);
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    if (widget.isAdminView && _selectedUser == null) return;
    if (!widget.isAdminView && _employeeAdminId == null && _messages.isEmpty) {
      // Employee has no admin to send to yet
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No admin to send message to')),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final recipientId = widget.isAdminView
          ? _selectedUser!.id
          : _employeeAdminId ?? _messages.first['sender_id'];

      await _supabaseService.sendMessage(
        senderId: widget.user.id,
        recipientId: recipientId,
        message: _messageController.text.trim(),
      );

      _messageController.clear();
      await _loadMessages();

      // Scroll to bottom
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send message: $e')));
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

    return RefreshIndicator(
      onRefresh: () => _loadMessages(),
      child: Column(
        children: [
          _buildHeader(),
          if (widget.isAdminView && _allUsers.isNotEmpty) _buildUserSelector(),
          Expanded(child: _buildMessageList()),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: AppColors.brand, width: 4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MESSAGES',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.isAdminView
                      ? 'Chat with employees'
                      : 'Chat with admin',
                  style: GoogleFonts.spaceMono(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          border: Border.all(
            color: isDark ? Colors.white : Colors.black,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.white : Colors.black,
              offset: const Offset(4, 4),
            ),
          ],
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<User>(
            value: _selectedUser,
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down),
            style: GoogleFonts.spaceMono(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isDark ? Colors.white : Colors.black,
            ),
            dropdownColor: isDark ? AppColors.darkSurface : Colors.white,
            items: _allUsers.map((user) {
              return DropdownMenuItem<User>(
                value: user,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: AppColors.brand,
                      child: Text(
                        user.name.isNotEmpty ? user.name[0] : '?',
                        style: GoogleFonts.spaceMono(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        user.name,
                        style: GoogleFonts.spaceMono(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (User? newUser) {
              if (newUser != null) {
                setState(() {
                  _selectedUser = newUser;
                  _previousMessageCount = 0; // Reset count for new conversation
                });
                _loadMessages();
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No messages yet',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.isAdminView
                  ? 'Start a conversation'
                  : 'No messages from admin',
              style: GoogleFonts.spaceMono(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isMe = message['sender_id'] == widget.user.id;
        final senderName = message['sender']?['name'] ?? 'Unknown';
        final messageText = message['message'] ?? '';
        final createdAt = DateTime.parse(message['created_at']);

        return _buildMessageBubble(messageText, senderName, createdAt, isMe);
      },
    );
  }

  Widget _buildMessageBubble(
    String message,
    String senderName,
    DateTime timestamp,
    bool isMe,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.brand,
              child: Text(
                senderName.isNotEmpty ? senderName[0] : '?',
                style: GoogleFonts.spaceMono(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMe
                    ? AppColors.brand
                    : (isDark ? AppColors.darkSurface : Colors.white),
                border: Border.all(
                  color: isDark ? Colors.white : Colors.black,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.white : Colors.black,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Text(
                      senderName.toUpperCase(),
                      style: GoogleFonts.spaceMono(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.brand,
                      ),
                    ),
                  Text(
                    message,
                    style: GoogleFonts.spaceMono(
                      fontSize: 14,
                      color: isMe ? Colors.black : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM d, h:mm a').format(timestamp),
                    style: GoogleFonts.spaceMono(
                      fontSize: 10,
                      color: isMe ? Colors.black54 : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white : Colors.black,
            width: 2,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.black : Colors.grey[100],
                border: Border.all(
                  color: isDark ? Colors.white : Colors.black,
                  width: 2,
                ),
              ),
              child: TextField(
                controller: _messageController,
                style: GoogleFonts.spaceMono(),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: GoogleFonts.spaceMono(color: Colors.grey),
                  border: InputBorder.none,
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _isSending ? null : _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.brand,
                border: Border.all(
                  color: isDark ? Colors.white : Colors.black,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.white : Colors.black,
                    offset: const Offset(4, 4),
                  ),
                ],
              ),
              child: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.black, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}
