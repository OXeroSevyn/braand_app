import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import '../constants.dart';
import '../models/office_location.dart';
import '../services/supabase_service.dart';
import '../widgets/neo_card.dart';

class OfficeLocationsScreen extends StatefulWidget {
  const OfficeLocationsScreen({super.key});

  @override
  State<OfficeLocationsScreen> createState() => _OfficeLocationsScreenState();
}

class _OfficeLocationsScreenState extends State<OfficeLocationsScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<OfficeLocation> _locations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    setState(() => _isLoading = true);
    try {
      final locations = await _supabaseService.getOfficeLocations();
      if (mounted) {
        setState(() {
          _locations = locations;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading locations: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading locations: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _showAddLocationDialog() async {
    final nameController = TextEditingController();
    final latController = TextEditingController();
    final lngController = TextEditingController();
    final radiusController = TextEditingController(text: '100');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Add Office Location',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Location Name',
                  hintText: 'e.g., Main Office',
                ),
                style: GoogleFonts.spaceMono(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: latController,
                decoration: const InputDecoration(
                  labelText: 'Latitude',
                  hintText: 'e.g., 40.7128',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                style: GoogleFonts.spaceMono(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: lngController,
                decoration: const InputDecoration(
                  labelText: 'Longitude',
                  hintText: 'e.g., -74.0060',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                style: GoogleFonts.spaceMono(),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    final position = await Geolocator.getCurrentPosition();
                    latController.text = position.latitude.toStringAsFixed(6);
                    lngController.text = position.longitude.toStringAsFixed(6);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error getting location: $e')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.my_location),
                label: Text('USE CURRENT LOCATION',
                    style: GoogleFonts.spaceMono(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  foregroundColor: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: radiusController,
                decoration: const InputDecoration(
                  labelText: 'Radius (meters)',
                  hintText: '100',
                ),
                keyboardType: TextInputType.number,
                style: GoogleFonts.spaceMono(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('CANCEL', style: GoogleFonts.spaceMono()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand),
            child:
                Text('ADD', style: GoogleFonts.spaceMono(color: Colors.black)),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      try {
        final name = nameController.text.trim();
        final lat = double.tryParse(latController.text.trim());
        final lng = double.tryParse(lngController.text.trim());
        final radius = int.tryParse(radiusController.text.trim()) ?? 100;

        if (name.isEmpty || lat == null || lng == null) {
          _showError('Please fill in all fields correctly');
          return;
        }

        debugPrint(
            'Creating office location: $name at ($lat, $lng) with radius $radius');
        await _supabaseService.createOfficeLocation(
          name: name,
          latitude: lat,
          longitude: lng,
          radiusMeters: radius,
        );

        _showSuccess('Office location added successfully');
        debugPrint('Reloading locations...');
        await _loadLocations();
        debugPrint('Locations reloaded. Count: ${_locations.length}');
      } catch (e) {
        _showError('Error adding location: ${e.toString()}');
      }
    }
  }

  Future<void> _deleteLocation(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Location',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete this office location?',
          style: GoogleFonts.spaceMono(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('CANCEL', style: GoogleFonts.spaceMono()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('DELETE',
                style: GoogleFonts.spaceMono(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _supabaseService.deleteOfficeLocation(id);
        _showSuccess('Location deleted successfully');
        await _loadLocations();
      } catch (e) {
        _showError('Error deleting location: ${e.toString()}');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.spaceMono()),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.spaceMono()),
        backgroundColor: AppColors.brand,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'OFFICE LOCATIONS',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadLocations,
              child: _locations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.location_off,
                              size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            'No office locations configured',
                            style: GoogleFonts.spaceMono(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _locations.length,
                      itemBuilder: (context, index) {
                        final location = _locations[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: NeoCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.location_on,
                                        color: AppColors.brand),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        location.name,
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () =>
                                          _deleteLocation(location.id),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _buildInfoRow('Latitude',
                                    location.latitude.toStringAsFixed(6)),
                                const SizedBox(height: 8),
                                _buildInfoRow('Longitude',
                                    location.longitude.toStringAsFixed(6)),
                                const SizedBox(height: 8),
                                _buildInfoRow(
                                    'Radius', '${location.radiusMeters}m'),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddLocationDialog,
        backgroundColor: AppColors.brand,
        label: Text('ADD LOCATION',
            style: GoogleFonts.spaceMono(color: Colors.black)),
        icon: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: GoogleFonts.spaceMono(fontSize: 12, color: Colors.grey),
        ),
        Text(
          value,
          style:
              GoogleFonts.spaceMono(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
