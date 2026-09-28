import 'dart:convert';

import 'package:http/http.dart' as http;

import 'location_service.dart';

/// Cuaca realtime gratis via Open-Meteo (tanpa API key).
/// Endpoint: https://api.open-meteo.com/v1/forecast?latitude=..&longitude=..&current=temperature_2m,relative_humidity_2m&timezone=Asia%2FJakarta
class WeatherService {
  WeatherService._();

  /// Koordinat default Jakarta (WIB). Dipakai bila lokasi device tidak tersedia.
  static const double defaultLat = LocationService.fallbackLat;
  static const double defaultLon = LocationService.fallbackLon;

  /// Ambil cuaca di lokasi device (geolokasi) bila tersedia; fallback Jakarta.
  /// Parameter [latitude]/[longitude] opsional untuk override eksplisit.
  static Future<WeatherReading> fetchCurrent({
    double? latitude,
    double? longitude,
  }) async {
    double lat = latitude ?? defaultLat;
    double lon = longitude ?? defaultLon;
    if (latitude == null && longitude == null) {
      final pos = await LocationService.currentCoordinates();
      lat = pos.latitude;
      lon = pos.longitude;
    }
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': '$lat',
      'longitude': '$lon',
      'current': 'temperature_2m,relative_humidity_2m',
      'timezone': 'Asia/Jakarta',
    });
    final res = await http.get(uri).timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) {
      throw StateError('Gagal memuat cuaca (${res.statusCode}).');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final current = (json['current'] as Map<String, dynamic>?) ?? {};
    final temp = (current['temperature_2m'] as num?)?.toDouble();
    final humidity = (current['relative_humidity_2m'] as num?)?.toInt();
    if (temp == null || humidity == null) {
      throw StateError('Data cuaca tidak lengkap.');
    }
    return WeatherReading(
      temperatureC: temp,
      humidityPercent: humidity,
      timeWib: (current['time'] as String?) ?? '',
    );
  }
}

class WeatherReading {
  final double temperatureC;
  final int humidityPercent;
  final String timeWib;

  const WeatherReading({
    required this.temperatureC,
    required this.humidityPercent,
    required this.timeWib,
  });

  /// "29°C" (1 desimal bila perlu).
  String get temperatureLabel {
    final v = temperatureC;
    final rounded = v.roundToDouble() == v
        ? v.toStringAsFixed(0)
        : v.toStringAsFixed(1);
    return '$rounded°C';
  }

  /// "74%".
  String get humidityLabel => '$humidityPercent%';
}
