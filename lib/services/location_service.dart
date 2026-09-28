import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

/// Geolokasi device: permission sekali di awal app, koordinat untuk cuaca
/// (Open-Meteo) dan fitur lokasi lain, plus label tempat (reverse geocode
/// gratis tanpa API key via BigDataCloud).
class LocationService {
  LocationService._();

  static const double fallbackLat = -6.2; // Jakarta
  static const double fallbackLon = 106.816666;

  static bool _permissionRequested = false;
  static Position? _cached;
  static String? _placeLabel;

  static bool get permissionRequested => _permissionRequested;
  static Position? get cachedPosition => _cached;
  static bool get hasPosition => _cached != null;

  /// Dipanggil sekali saat awal app (lihat main.dart). Sengaja tidak await
  /// dialog permission agar UI tidak tertahan — permission tetap diminta
  /// saat startup.
  static Future<void> init() => requestPermission();

  /// Minta izin lokasi (cek service → cek izin → request). Aman dipanggil
  /// berulang; hanya melakukan request OS sekali.
  static Future<bool> requestPermission() async {
    if (_permissionRequested && _cached != null) return true;
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _permissionRequested = true;
        debugPrint('LocationService: layanan lokasi mati.');
        return false;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      _permissionRequested = true;
      final granted = permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
      if (!granted) {
        debugPrint('LocationService: izin lokasi ditolak ($permission).');
      }
      return granted;
    } catch (e) {
      // Platform tidak mendukung (mis. test/web) — bukan fatal.
      _permissionRequested = true;
      debugPrint('LocationService: gagal minta izin lokasi: $e');
      return false;
    }
  }

  /// Koordinat device (cache). Bila izin/service tidak tersedia, fallback ke
  /// Jakarta agar fitur seperti cuaca tetap jalan.
  static Future<Position> currentCoordinates({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cached != null) return _cached!;
    try {
      final granted = await requestPermission();
      if (granted) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 15),
          ),
        ).timeout(const Duration(seconds: 20));
        _cached = position;
        return position;
      }
    } catch (e) {
      debugPrint('LocationService: gagal ambil posisi: $e');
    }
    if (_cached != null) return _cached!;
    // Fallback sintetis (Jakarta) agar alur cuaca tidak rusak.
    return Position(
      latitude: fallbackLat,
      longitude: fallbackLon,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }

  /// Label tempat untuk tampilan, mis. "Jakarta, DKI Jakarta".
  /// Reverse geocode gratis (BigDataCloud, tanpa API key); cache in-memory.
  /// Bila gagal → "Lokasi Anda".
  static Future<String> placeLabel() async {
    if (_placeLabel != null) return _placeLabel!;
    try {
      final pos = await currentCoordinates();
      final uri = Uri.https('api.bigdatacloud.net',
          '/data/reverse-geocode-client', {
        'latitude': pos.latitude.toString(),
        'longitude': pos.longitude.toString(),
        'localityLanguage': 'id',
      });
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final city = (json['city'] as String?) ?? '';
        final locality = (json['locality'] as String?) ?? '';
        final province = (json['principalSubdivision'] as String?) ?? '';
        final name = city.isNotEmpty ? city : (locality.isNotEmpty ? locality : province);
        if (name.isNotEmpty) {
          _placeLabel = province.isNotEmpty && province != name
              ? '$name, $province'
              : name;
          return _placeLabel!;
        }
      }
    } catch (e) {
      debugPrint('LocationService: reverse geocode gagal: $e');
    }
    _placeLabel = 'Lokasi Anda';
    return _placeLabel!;
  }

  /// Untuk teks tampilan cuaca: "Jakarta, DKI Jakarta".
  static Future<String> displayLocation() => placeLabel();
}
