import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants.dart';
import '../glass_container.dart';

class FloatingInputBar extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isSending;

  const FloatingInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    required this.isSending,
  });

  @override
  State<FloatingInputBar> createState() => _FloatingInputBarState();
}

class _FloatingInputBarState extends State<FloatingInputBar> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateState);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateState);
    super.dispose();
  }

  void _updateState() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasText = widget.controller.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16), // Padding around the floating bar
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        borderRadius: BorderRadius.circular(30),
        opacity: isDark ? 0.1 : 0.8,
        color: isDark ? Colors.black : Colors.white,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: widget.controller,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  color: isDark ? Colors.white : Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: GoogleFonts.spaceMono(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                maxLines: 5,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) {
                  if (hasText && !widget.isSending) widget.onSend();
                },
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: (hasText && !widget.isSending) ? widget.onSend : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: hasText
                      ? AppColors.brand
                      : (isDark ? Colors.white10 : Colors.grey[300]),
                  shape: BoxShape.circle,
                  boxShadow: hasText
                      ? [
                          BoxShadow(
                            color: AppColors.brand.withOpacity(0.4),
                            blurRadius: 10,
                            spreadRadius: 2,
                          )
                        ]
                      : null,
                ),
                child: widget.isSending
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black),
                      )
                    : Icon(
                        Icons.send_rounded,
                        color: hasText ? Colors.black : Colors.grey,
                        size: 20,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
