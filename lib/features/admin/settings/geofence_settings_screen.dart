import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_providers.dart';
import '../../attendance/providers/attendance_providers.dart';

class GeofenceSettingsScreen extends ConsumerStatefulWidget {
  const GeofenceSettingsScreen({super.key});

  @override
  ConsumerState<GeofenceSettingsScreen> createState() => _GeofenceSettingsScreenState();
}

class _GeofenceSettingsScreenState extends ConsumerState<GeofenceSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();
  final TextEditingController _radiusController = TextEditingController(text: '100');

  bool _isLoading = true;
  bool _isGettingLocation = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final settings = await ref.read(geofenceSettingsProvider.future);
    if (mounted) {
      if (settings != null) {
        _latController.text = settings.latitude.toString();
        _lngController.text = settings.longitude.toString();
        _radiusController.text = settings.radiusMeters.toString();
      } else {
        _latController.text = '19.3833';
        _lngController.text = '72.8333';
        _radiusController.text = '100';
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition();
        if (mounted) {
          setState(() {
            _latController.text = pos.latitude.toString();
            _lngController.text = pos.longitude.toString();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Current GPS location captured!')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  Future<void> _saveGeofence() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isSaving = true);
    try {
      final lat = double.parse(_latController.text.trim());
      final lng = double.parse(_lngController.text.trim());
      final radius = int.parse(_radiusController.text.trim());

      await ref.read(attendanceRepositoryProvider).updateGeofenceSettings(
            lat: lat,
            lng: lng,
            radiusMeters: radius,
            updatedBy: user.id,
          );

      ref.invalidate(geofenceSettingsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Geofence settings updated successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving geofence: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Geofence Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Geofence Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Card(
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, color: AppColors.primary, size: 32),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Teachers entering within this radius will be automatically marked present on app open.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _latController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Institute Latitude *',
                  hintText: 'e.g. 19.383333',
                  prefixIcon: Icon(Icons.my_location),
                  border: OutlineInputBorder(),
                ),
                validator: (val) => (val == null || double.tryParse(val.trim()) == null) ? 'Enter a valid latitude' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _lngController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Institute Longitude *',
                  hintText: 'e.g. 72.833333',
                  prefixIcon: Icon(Icons.my_location),
                  border: OutlineInputBorder(),
                ),
                validator: (val) => (val == null || double.tryParse(val.trim()) == null) ? 'Enter a valid longitude' : null,
              ),
              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: _isGettingLocation ? null : _getCurrentLocation,
                icon: _isGettingLocation
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.gps_fixed),
                label: const Text('Use Current Device Location'),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _radiusController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Allowed Radius (Meters) *',
                  hintText: 'e.g. 100',
                  prefixIcon: Icon(Icons.radar),
                  border: OutlineInputBorder(),
                  helperText: 'Radius around institute location where check-in is valid',
                ),
                validator: (val) => (val == null || int.tryParse(val.trim()) == null) ? 'Enter a valid radius' : null,
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _isSaving ? null : _saveGeofence,
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'SAVE GEOFENCE SETTINGS',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
