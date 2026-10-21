import 'package:geolocator/geolocator.dart';

/// Raised when a position cannot be obtained; [message] is user-facing.
class LocationUnavailableException implements Exception {
  LocationUnavailableException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Thin wrapper over geolocator for the teacher check-in flow. The decision
/// whether the position is inside the geofence is made on the server
/// (`mark_teacher_present`), never here.
class GeofenceService {
  /// Current position. With [promptForPermission] false (silent auto
  /// check-in) it returns null instead of asking when permission is missing.
  Future<Position?> currentPosition({bool promptForPermission = true}) async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      if (!promptForPermission) return null;
      throw LocationUnavailableException(
        'Location is turned off. Enable GPS and try again.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied && promptForPermission) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (!promptForPermission) return null;
      throw LocationUnavailableException(
        permission == LocationPermission.deniedForever
            ? 'Location permission is blocked. Enable it in the phone Settings.'
            : 'Location permission is required to check in.',
      );
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 20),
    );
  }
}
