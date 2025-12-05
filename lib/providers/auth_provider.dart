import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../models/user.dart';
import '../services/storage_service.dart';
import '../services/supabase_service.dart';
import '../services/notification_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = true;
  final StorageService _storageService = StorageService();
  final SupabaseService _supabaseService = SupabaseService();
  final supabase.SupabaseClient _supabase = supabase.Supabase.instance.client;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isPending {
    if (_user?.role == 'Admin') return false;
    if (_user?.email == 'subhamdey.one@gmail.com') return false; // Dev bypass
    return _user?.status == 'pending';
  }

  bool get isRejected => _user?.status == 'rejected';

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    // Listen to auth state changes
    _supabase.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        _loadUserFromSession(session.user);
      } else {
        _user = null;
        _isLoading = false;
        notifyListeners();
      }
    });

    // Check current session
    final session = _supabase.auth.currentSession;
    if (session != null) {
      await _loadUserFromSession(session.user);
    } else {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadUserFromSession(supabase.User supabaseUser) async {
    try {
      debugPrint('Loading user profile for: ${supabaseUser.id}');

      // Try to fetch full profile from DB first
      final profile = await _supabaseService.getUserProfile(supabaseUser.id);

      if (profile != null) {
        debugPrint('Profile loaded successfully: ${profile.name}');
        _user = profile;

        // Auto-approve Admin OR specific dev user if pending
        if ((_user!.role == 'Admin' ||
                _user!.email == 'subhamdey.one@gmail.com') &&
            _user!.status == 'pending') {
          debugPrint('👑 Auto-approving User/Admin...');
          try {
            await _supabaseService.updateUserStatus(_user!.id, 'active');
            _user = _user!.copyWith(status: 'active');
            debugPrint('✅ User auto-approved successfully');
          } catch (e) {
            debugPrint('⚠️ Failed to auto-approve (might be RLS): $e');
            // We still continue, as isPending logic will let them in
          }
        }
      } else {
        debugPrint('Profile not found in DB, creating from metadata');
        // Profile missing! Create it from metadata.
        // This handles cases where the user signed up but profile creation failed
        // (e.g. before tables were created).
        final userData = {
          'id': supabaseUser.id,
          'email': supabaseUser.email,
          'user_metadata': supabaseUser.userMetadata,
        };
        _user = User.fromSupabase(userData);

        // Attempt to create the profile in DB so FK constraints work
        try {
          await _supabaseService.createProfile(_user!);
          debugPrint('Profile created successfully in DB');

          // If created as Admin, ensure active
          if (_user!.role == 'Admin') {
            await _supabaseService.updateUserStatus(_user!.id, 'active');
            _user = _user!.copyWith(status: 'active');
          }
        } catch (e) {
          debugPrint('Error creating missing profile: $e');
        }
      }

      await _storageService.saveUser(_user!); // Keep local copy if needed

      // Schedule notifications for the authenticated user
      debugPrint('Scheduling notifications for user: ${_user!.name}');
      await NotificationService().loadAndScheduleNotifications();

      // Start listening for custom notifications
      NotificationService().listenForCustomNotifications(_user!.id);
    } on supabase.AuthException catch (e) {
      debugPrint('Auth error loading user: ${e.message}');
    } catch (e) {
      debugPrint('Error loading user: $e');
      debugPrint('Error type: ${e.runtimeType}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('Attempting login for: $email');
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      debugPrint('Login successful');
      return null; // Success
    } on supabase.AuthException catch (e) {
      debugPrint('Auth error during login: ${e.message}');
      _isLoading = false;
      notifyListeners();
      return e.message;
    } catch (e) {
      debugPrint('Unexpected error during login: $e');
      debugPrint('Error type: ${e.runtimeType}');
      _isLoading = false;
      notifyListeners();

      // Check if it's a network error
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup')) {
        return 'Network error: Please check your internet connection';
      }
      return 'An unexpected error occurred: ${e.toString()}';
    }
  }

  Future<String?> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
    required String department,
  }) async {
    _isLoading = true;
    notifyListeners();

    debugPrint('📝 Signing up user: $email with role: $role');

    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'role': role,
          'department': department,
        },
      );

      if (response.user != null) {
        // Create profile in DB
        final newUser = User(
          id: response.user!.id,
          name: name,
          email: email,
          role: role,
          department: department,
          avatar: null,
          status: 'pending',
        );
        await _supabaseService.createProfile(newUser);
      }

      return null; // Success
    } on supabase.AuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.message;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'An unexpected error occurred: $e';
    }
  }

  Future<bool> refreshUserProfile() async {
    if (_user == null) return false;

    try {
      debugPrint('Refreshing user profile for: ${_user!.id}');
      final updatedProfile = await _supabaseService.getUserProfile(_user!.id);

      if (updatedProfile != null) {
        _user = updatedProfile;
        await _storageService.saveUser(_user!);
        notifyListeners();
        debugPrint('User profile refreshed successfully: ${_user!.status}');
        return true;
      } else {
        debugPrint('❌ Failed to refresh profile: Profile is null');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error refreshing user profile: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
    await _storageService.clearUser();
    _user = null;
    notifyListeners();
  }
}
