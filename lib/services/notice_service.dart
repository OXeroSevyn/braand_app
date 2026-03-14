import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notice.dart';

class NoticeService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch all notices ordered by creation date (newest first)
  Future<List<Notice>> getNotices() async {
    try {
      final response = await _supabase
          .from('notices')
          .select()
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => Notice.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching notices: $e');
      return [];
    }
  }

  /// Create a new notice
  Future<void> createNotice(Notice notice) async {
    try {
      await _supabase.from('notices').insert({
        'title': notice.title,
        'content': notice.content,
        'priority': notice.priority,
        'category': notice.category,
        'created_by': _supabase.auth.currentUser!.id,
      });
      debugPrint('✅ Notice created successfully');
    } catch (e) {
      debugPrint('❌ Error creating notice: $e');
      rethrow;
    }
  }

  /// Update an existing notice
  Future<void> updateNotice(Notice notice) async {
    try {
      await _supabase.from('notices').update({
        'title': notice.title,
        'content': notice.content,
        'priority': notice.priority,
        'category': notice.category,
      }).eq('id', notice.id);
      debugPrint('✅ Notice updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating notice: $e');
      rethrow;
    }
  }

  /// Delete a notice
  Future<void> deleteNotice(String id) async {
    try {
      await _supabase.from('notices').delete().eq('id', id);
      debugPrint('✅ Notice deleted successfully');
    } catch (e) {
      debugPrint('❌ Error deleting notice: $e');
      rethrow;
    }
  }
}
