import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/supabase_service.dart';
import '../constants.dart';

class AdminReleaseScreen extends StatefulWidget {
  const AdminReleaseScreen({super.key});

  @override
  State<AdminReleaseScreen> createState() => _AdminReleaseScreenState();
}

class _AdminReleaseScreenState extends State<AdminReleaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _versionCodeController = TextEditingController();
  final _versionNameController = TextEditingController();
  final _apkUrlController = TextEditingController();
  final _releaseNotesController = TextEditingController();
  bool _forceUpdate = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _versionCodeController.dispose();
    _versionNameController.dispose();
    _apkUrlController.dispose();
    _releaseNotesController.dispose();
    super.dispose();
  }

  Future<void> _publishRelease() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await SupabaseService().publishAppVersion(
        versionCode: int.parse(_versionCodeController.text),
        versionName: _versionNameController.text.trim(),
        apkUrl: _apkUrlController.text.trim(),
        releaseNotes: _releaseNotesController.text.trim(),
        forceUpdate: _forceUpdate,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rocket 🚀 Update Published Successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'RELEASE MANAGER',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        titleTextStyle: TextStyle(color: isDark ? Colors.white : Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Publish New Update',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Push a new version to all users immediately.',
                style: GoogleFonts.spaceMono(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),

              // Version Code
              TextFormField(
                controller: _versionCodeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Version Code (Integer)',
                  hintText: 'e.g. 2',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.numbers),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (int.tryParse(value) == null) return 'Must be an integer';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Version Name
              TextFormField(
                controller: _versionNameController,
                decoration: InputDecoration(
                  labelText: 'Version Name',
                  hintText: 'e.g. 1.0.1',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.tag),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // APK URL
              TextFormField(
                controller: _apkUrlController,
                decoration: InputDecoration(
                  labelText: 'APK URL',
                  hintText: 'https://...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.link),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (!Uri.parse(value).isAbsolute) return 'Invalid URL';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Release Notes
              TextFormField(
                controller: _releaseNotesController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Release Notes',
                  hintText: 'What\'s new in this update?',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.notes),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Force Update Switch
              SwitchListTile(
                title: const Text('Force Update'),
                subtitle: const Text(
                  'Users MUST update to continue using the app.',
                ),
                value: _forceUpdate,
                onChanged: (value) => setState(() => _forceUpdate = value),
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.brand,
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _publishRelease,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : Text(
                          'PUBLISH UPDATE',
                          style: GoogleFonts.spaceMono(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
