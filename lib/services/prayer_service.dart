import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'notification_service.dart';

/// Prayer Times Service using Aladhan API
/// Includes network resilience and caching
class PrayerService {
  static final PrayerService _instance = PrayerService._internal();
  factory PrayerService() => _instance;
  PrayerService._internal();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.aladhanApiBase,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));
  
  // Cache key
  static const String _cacheKey = 'cached_prayer_times';

  /// Get current location with fallback
  Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('📍 Location service disabled, using default');
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
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      debugPrint('📍 Location error: $e');
      return null;
    }
  }

  /// Get prayer times with network resilience and caching
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
        final times = PrayerTimes.fromJson(response.data['data']['timings']);
        // Cache the successful response
        await _cachePrayerTimes(times);
        debugPrint('🕌 Prayer times fetched successfully');
        return times;
      }
      
      // If API returns unexpected response, use cache
      return await _getCachedPrayerTimes();
    } on DioException catch (e) {
      debugPrint('🌐 Network error: ${e.type} - ${e.message}');
      // Network failure - use cached times
      return await _getCachedPrayerTimes();
    } catch (e) {
      debugPrint('⚠️ Prayer times error: $e');
      return await _getCachedPrayerTimes();
    }
  }

  /// Cache prayer times locally
  Future<void> _cachePrayerTimes(PrayerTimes times) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, 
        '${times.fajr}|${times.sunrise}|${times.dhuhr}|${times.asr}|${times.maghrib}|${times.isha}');
    } catch (e) {
      debugPrint('Cache write error: $e');
    }
  }

  /// Get cached prayer times (fallback for offline)
  Future<PrayerTimes?> _getCachedPrayerTimes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cacheKey);
      if (cached != null) {
        final parts = cached.split('|');
        if (parts.length == 6) {
          debugPrint('📦 Using cached prayer times');
          return PrayerTimes(
            fajr: parts[0],
            sunrise: parts[1],
            dhuhr: parts[2],
            asr: parts[3],
            maghrib: parts[4],
            isha: parts[5],
          );
        }
      }
    } catch (e) {
      debugPrint('Cache read error: $e');
    }
    
    // Last resort: hardcoded defaults for Dhaka timezone
    debugPrint('⚠️ Using hardcoded prayer times');
    return PrayerTimes(
      fajr: '05:00',
      sunrise: '06:15',
      dhuhr: '12:00',
      asr: '15:30',
      maghrib: '17:45',
      isha: '19:00',
    );
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

  /// Schedule notifications for all prayers (AGGRESSIVE)
  Future<void> schedulePrayerNotifications(PrayerTimes times, {bool notificationsEnabled = true}) async {
    if (!notificationsEnabled) {
      await NotificationService().cancelAll();
      return;
    }

    final prayerNames = {
      1: 'Fajr',
      2: 'Dhuhr',
      3: 'Asr',
      4: 'Maghrib',
      5: 'Isha',
    };

    final timeMap = {
      1: times.fajr,
      2: times.dhuhr,
      3: times.asr,
      4: times.maghrib,
      5: times.isha,
    };

    final service = NotificationService();
    
    for (final entry in prayerNames.entries) {
      final id = entry.key;
      final name = entry.value;
      final timeStr = timeMap[id]!;
      
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      await service.schedulePrayerNotification(
        id: id,
        prayerName: name,
        time: TimeOfDay(hour: hour, minute: minute),
      );
    }
    
    debugPrint('🔔 All 5 prayer notifications scheduled aggressively');
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
