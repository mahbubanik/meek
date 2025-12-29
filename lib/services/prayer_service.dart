import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import '../config/api_config.dart';

/// Prayer Times Service using Aladhan API
class PrayerService {
  static final PrayerService _instance = PrayerService._internal();
  factory PrayerService() => _instance;
  PrayerService._internal();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.aladhanApiBase,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  /// Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get prayer times for current location
  Future<PrayerTimes?> getPrayerTimes() async {
    try {
      final position = await getCurrentLocation();
      
      // Default to Dhaka if location unavailable
      final lat = position?.latitude ?? 23.8103;
      final lon = position?.longitude ?? 90.4125;
      
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      final response = await _dio.get(
        '${ApiConfig.prayerTimesEndpoint}/$timestamp',
        queryParameters: {
          'latitude': lat,
          'longitude': lon,
          'method': 1, // University of Islamic Sciences, Karachi
        },
      );

      if (response.statusCode == 200 && response.data['code'] == 200) {
        return PrayerTimes.fromJson(response.data['data']['timings']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get current prayer info
  PrayerInfo? getCurrentPrayer(PrayerTimes times) {
    final now = DateTime.now();
    final currentTime = now.hour * 60 + now.minute;

    final prayers = [
      PrayerInfo('Fajr', times.fajr, times.sunrise),
      PrayerInfo('Dhuhr', times.dhuhr, times.asr),
      PrayerInfo('Asr', times.asr, times.maghrib),
      PrayerInfo('Maghrib', times.maghrib, times.isha),
      PrayerInfo('Isha', times.isha, '23:59'),
    ];

    for (final prayer in prayers) {
      final startMinutes = _timeToMinutes(prayer.startTime);
      final endMinutes = _timeToMinutes(prayer.endTime);
      
      if (currentTime >= startMinutes && currentTime < endMinutes) {
        prayer.minutesRemaining = endMinutes - currentTime;
        return prayer;
      }
    }

    return null;
  }

  /// Get next prayer
  PrayerInfo? getNextPrayer(PrayerTimes times) {
    final now = DateTime.now();
    final currentTime = now.hour * 60 + now.minute;

    final prayers = [
      PrayerInfo('Fajr', times.fajr, times.sunrise),
      PrayerInfo('Dhuhr', times.dhuhr, times.asr),
      PrayerInfo('Asr', times.asr, times.maghrib),
      PrayerInfo('Maghrib', times.maghrib, times.isha),
      PrayerInfo('Isha', times.isha, '23:59'),
    ];

    for (final prayer in prayers) {
      final startMinutes = _timeToMinutes(prayer.startTime);
      if (currentTime < startMinutes) {
        prayer.minutesRemaining = startMinutes - currentTime;
        return prayer;
      }
    }

    // Next is Fajr tomorrow
    final fajrMinutes = _timeToMinutes(times.fajr);
    final minutesUntilMidnight = (24 * 60) - currentTime;
    prayers.first.minutesRemaining = minutesUntilMidnight + fajrMinutes;
    return prayers.first;
  }

  int _timeToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  String formatTimeRemaining(int minutes) {
    if (minutes < 60) {
      return '${minutes}min';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return mins > 0 ? '${hours}h ${mins}min' : '${hours}h';
  }
}

/// Prayer times model
class PrayerTimes {
  final String fajr;
  final String sunrise;
  final String dhuhr;
  final String asr;
  final String maghrib;
  final String isha;

  PrayerTimes({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });

  factory PrayerTimes.fromJson(Map<String, dynamic> json) {
    return PrayerTimes(
      fajr: json['Fajr'] ?? '05:00',
      sunrise: json['Sunrise'] ?? '06:00',
      dhuhr: json['Dhuhr'] ?? '12:00',
      asr: json['Asr'] ?? '15:30',
      maghrib: json['Maghrib'] ?? '18:00',
      isha: json['Isha'] ?? '19:30',
    );
  }
}

/// Prayer info model
class PrayerInfo {
  final String name;
  final String startTime;
  final String endTime;
  int minutesRemaining;

  PrayerInfo(this.name, this.startTime, this.endTime, [this.minutesRemaining = 0]);
}
