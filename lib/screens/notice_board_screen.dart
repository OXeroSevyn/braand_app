import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/notice.dart';
import '../models/user.dart';
import '../services/supabase_service.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants.dart';

class NoticeBoardScreen extends StatefulWidget {
  final User user;

  const NoticeBoardScreen({
    super.key,
    required this.user,
  });

  @override
  State<NoticeBoardScreen> createState() => _NoticeBoardScreenState();
}

class _NoticeBoardScreenState extends State<NoticeBoardScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Notice> _notices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotices();
  }

  Future<void> _loadNotices() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final notices = await _supabaseService.getNotices();

    if (mounted) {
      setState(() {
        _notices = notices;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteNotice(String id) async {
    try {
      await _supabaseService.deleteNotice(id);
      _loadNotices();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notice deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting notice: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.user.role == 'Admin';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'NOTICE BOARD',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotices,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notices.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.notifications_off_outlined,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'No notices yet',
                        style: GoogleFonts.spaceMono(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notices.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final notice = _notices[index];
                    return NoticeCard(
                      notice: notice,
                      isAdmin: isAdmin,
                      onDelete: () => _deleteNotice(notice.id),
                      onEdit: () async {
                        final result = await showDialog(
                          context: context,
                          builder: (context) => AddNoticeDialog(notice: notice),
                        );
                        if (result == true) {
                          _loadNotices();
                        }
                      },
                    );
                  },
                ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await showDialog(
                  context: context,
                  builder: (context) => const AddNoticeDialog(),
                );
                if (result == true) {
                  _loadNotices();
                }
              },
              backgroundColor: AppColors.brand,
              icon: const Icon(Icons.add, color: Colors.black),
              label: Text(
                'POST NOTICE',
                style: GoogleFonts.spaceMono(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            )
          : null,
    );
  }
}

class NoticeCard extends StatelessWidget {
  final Notice notice;
  final bool isAdmin;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;

  const NoticeCard({
    super.key,
    required this.notice,
    required this.isAdmin,
    required this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    // Styling based on priority
    Color bgColor;
    Color textColor;
    Color accentColor;

    switch (notice.priority.toLowerCase()) {
      case 'urgent':
        bgColor = Colors.red;
        textColor = Colors.white;
        accentColor = Colors.white.withOpacity(0.8);
        break;
      case 'medium':
        bgColor = Colors.yellow;
        textColor = Colors.black;
        accentColor = Colors.black87;
        break;
      case 'normal':
      default:
        // Custom Green
        bgColor = const Color(0xFFA7FE2B);
        textColor = Colors.black;
        accentColor = Colors.black87;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: textColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: textColor.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              notice.priority.toUpperCase(),
                              style: GoogleFonts.spaceMono(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: textColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              notice.category.toUpperCase(),
                              style: GoogleFonts.spaceMono(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        notice.title,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isAdmin) ...[
                  IconButton(
                    icon: Icon(Icons.edit, color: textColor),
                    onPressed: onEdit,
                    tooltip: 'Edit Notice',
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: textColor),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Notice?'),
                          content: const Text(
                              'Are you sure you want to delete this notice?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('CANCEL'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                onDelete();
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('DELETE'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),

          // Divider
          Divider(height: 1, color: textColor.withOpacity(0.2)),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: RichText(
              text: TextSpan(
                children: _parseContent(notice.content, accentColor),
              ),
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(12),
              ),
            ),
            child: Text(
              DateFormat('MMM d, yyyy • h:mm a').format(notice.createdAt),
              style: GoogleFonts.spaceMono(
                fontSize: 10,
                color: accentColor,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  List<InlineSpan> _parseContent(String text, Color textColor) {
    final List<InlineSpan> spans = [];
    final RegExp urlRegex = RegExp(
      r'(https?:\/\/[^\s]+)',
      caseSensitive: false,
    );

    int start = 0;
    for (final Match match in urlRegex.allMatches(text)) {
      // Add text before the URL
      if (match.start > start) {
        spans.add(TextSpan(
          text: text.substring(start, match.start),
          style: GoogleFonts.spaceMono(
            fontSize: 14,
            color: textColor,
            height: 1.5,
          ),
        ));
      }

      // Add the URL
      final String url = match.group(0)!;
      spans.add(TextSpan(
        text: url,
        style: GoogleFonts.spaceMono(
          fontSize: 14,
          color: Colors.blue, // Hyperlink color
          decoration: TextDecoration.underline,
          height: 1.5,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () async {
            final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
      ));

      start = match.end;
    }

    // Add remaining text
    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: GoogleFonts.spaceMono(
          fontSize: 14,
          color: textColor,
          height: 1.5,
        ),
      ));
    }

    return spans;
  }
}

class AddNoticeDialog extends StatefulWidget {
  final Notice? notice;

  const AddNoticeDialog({super.key, this.notice});

  @override
  State<AddNoticeDialog> createState() => _AddNoticeDialogState();
}

class _AddNoticeDialogState extends State<AddNoticeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _categoryController = TextEditingController();
  String _priority = 'normal';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.notice != null) {
      _titleController.text = widget.notice!.title;
      _contentController.text = widget.notice!.content;
      _categoryController.text = widget.notice!.category;
      _priority = widget.notice!.priority;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      if (widget.notice != null) {
        // Edit Mode
        final updatedNotice = Notice(
          id: widget.notice!.id,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          priority: _priority,
          category: _categoryController.text.trim(),
          createdAt: widget.notice!.createdAt,
          createdBy: widget.notice!.createdBy,
        );
        await SupabaseService().updateNotice(updatedNotice);
      } else {
        // Create Mode
        final notice = Notice(
          id: '', // Generated by DB
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          priority: _priority,
          category: _categoryController.text.trim(),
          createdAt: DateTime.now(),
          createdBy: '', // Handled by service
        );
        await SupabaseService().createNotice(notice);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  widget.notice != null ? 'Notice updated' : 'Notice posted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.notice != null ? 'Edit Notice' : 'Post New Notice',
        style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g., Office Closed Tomorrow',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  hintText: 'e.g., HR, General, Holiday',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _priority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                      child: Text('Normal (Green)'), value: 'normal'),
                  DropdownMenuItem(
                      child: Text('Medium (Yellow)'), value: 'medium'),
                  DropdownMenuItem(
                      child: Text('Urgent (Red)'), value: 'urgent'),
                ],
                onChanged: (v) => setState(() => _priority = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brand,
            foregroundColor: Colors.black,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.notice != null ? 'UPDATE' : 'POST'),
        ),
      ],
    );
  }
}
