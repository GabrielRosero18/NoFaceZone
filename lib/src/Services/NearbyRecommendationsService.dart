import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class NearbyPlace {
  final String name;
  final String address;
  final double lat;
  final double lng;
  final String category;
  final double distanceMeters;
  final double relevanceScore;
  final double? rating;

  const NearbyPlace({
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.category,
    required this.distanceMeters,
    required this.relevanceScore,
    this.rating,
  });
}

class NearbyRecommendationsResult {
  final bool hasPermission;
  final bool isPermissionDeniedForever;
  final bool isLocationServiceDisabled;
  final List<NearbyPlace> places;
  final String? errorMessage;

  const NearbyRecommendationsResult({
    required this.hasPermission,
    this.isPermissionDeniedForever = false,
    this.isLocationServiceDisabled = false,
    required this.places,
    this.errorMessage,
  });
}

class NearbyRecommendationsService {
  static const _radiusMeters = 2200;
  static const _overpassUrl = 'https://overpass-api.de/api/interpreter';
  static const _cacheTtl = Duration(minutes: 20);
  static DateTime? _lastCacheAt;
  static Position? _lastCachePosition;
  static List<NearbyPlace> _lastCachedPlaces = <NearbyPlace>[];

  static Future<NearbyRecommendationsResult> fetchNearbyWellbeingPlaces({
    bool forceRefresh = false,
  }) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const NearbyRecommendationsResult(
        hasPermission: false,
        isLocationServiceDisabled: true,
        places: [],
        errorMessage: 'Activa la ubicación para sugerencias cercanas.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return NearbyRecommendationsResult(
        hasPermission: false,
        isPermissionDeniedForever: permission == LocationPermission.deniedForever,
        places: [],
        errorMessage: permission == LocationPermission.deniedForever
            ? 'Permiso de ubicación bloqueado permanentemente.'
            : 'Permiso de ubicación no concedido.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
    );

    final cached = forceRefresh ? <NearbyPlace>[] : _tryReadCache(position);
    if (cached.isNotEmpty) {
      return NearbyRecommendationsResult(
        hasPermission: true,
        places: cached,
      );
    }

    final query = '''
[out:json][timeout:25];
(
  node(around:$_radiusMeters,${position.latitude},${position.longitude})[leisure=park];
  way(around:$_radiusMeters,${position.latitude},${position.longitude})[leisure=park];
  relation(around:$_radiusMeters,${position.latitude},${position.longitude})[leisure=park];

  node(around:$_radiusMeters,${position.latitude},${position.longitude})[amenity=library];
  way(around:$_radiusMeters,${position.latitude},${position.longitude})[amenity=library];
  relation(around:$_radiusMeters,${position.latitude},${position.longitude})[amenity=library];
  node(around:$_radiusMeters,${position.latitude},${position.longitude})[amenity=public_bookcase];
  way(around:$_radiusMeters,${position.latitude},${position.longitude})[amenity=public_bookcase];
  relation(around:$_radiusMeters,${position.latitude},${position.longitude})[amenity=public_bookcase];

  node(around:$_radiusMeters,${position.latitude},${position.longitude})[leisure=fitness_centre];
  way(around:$_radiusMeters,${position.latitude},${position.longitude})[leisure=fitness_centre];
  relation(around:$_radiusMeters,${position.latitude},${position.longitude})[leisure=fitness_centre];
  node(around:$_radiusMeters,${position.latitude},${position.longitude})[leisure=sports_centre];
  way(around:$_radiusMeters,${position.latitude},${position.longitude})[leisure=sports_centre];
  relation(around:$_radiusMeters,${position.latitude},${position.longitude})[leisure=sports_centre];
  node(around:$_radiusMeters,${position.latitude},${position.longitude})[sport];
  way(around:$_radiusMeters,${position.latitude},${position.longitude})[sport];
  relation(around:$_radiusMeters,${position.latitude},${position.longitude})[sport];
);
out center 40;
''';

    final response = await http.post(
      Uri.parse(_overpassUrl),
      headers: const {
        'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
        'User-Agent': 'NoFaceZoneSchoolProject/1.0',
      },
      body: {'data': query},
    );

    if (response.statusCode != 200) {
      return NearbyRecommendationsResult(
        hasPermission: true,
        places: _fallbackPlacesFromCurrentPosition(position),
        errorMessage: 'No se pudo consultar OpenStreetMap ahora.',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final elements = (decoded['elements'] as List?) ?? <dynamic>[];
    final List<NearbyPlace> places = <NearbyPlace>[];
    final seen = <String>{};

    for (final e in elements) {
      final map = e as Map<String, dynamic>;
      final tags = (map['tags'] as Map?)?.map((k, v) => MapEntry(k.toString(), v.toString())) ?? {};
      final center = map['center'] as Map<String, dynamic>?;
      final lat = (map['lat'] as num?)?.toDouble() ?? (center?['lat'] as num?)?.toDouble();
      final lng = (map['lon'] as num?)?.toDouble() ?? (center?['lon'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;

      final distanceMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        lat,
        lng,
      );
      final category = _resolveCategory(tags);
      final name = _resolvePlaceName(tags, category, distanceMeters);
      final address = _resolvePlaceAddress(tags, distanceMeters);
      final relevanceScore = _computeRelevanceScore(
        category: category,
        distanceMeters: distanceMeters,
      );
      final dedupeKey = '$name|$category|${lat.toStringAsFixed(4)}|${lng.toStringAsFixed(4)}';
      if (seen.contains(dedupeKey)) continue;
      seen.add(dedupeKey);

      places.add(
        NearbyPlace(
          name: name,
          address: address,
          lat: lat,
          lng: lng,
          category: category,
          distanceMeters: distanceMeters,
          relevanceScore: relevanceScore,
          rating: null,
        ),
      );
    }

    places.sort((a, b) {
      return b.relevanceScore.compareTo(a.relevanceScore);
    });

    if (places.isEmpty) {
      return NearbyRecommendationsResult(
        hasPermission: true,
        places: _fallbackPlacesFromCurrentPosition(position),
        errorMessage: 'No se encontraron lugares cercanos en este momento.',
      );
    }

    _writeCache(position, places.take(24).toList());
    return NearbyRecommendationsResult(
      hasPermission: true,
      places: places.take(24).toList(),
    );
  }

  static List<NearbyPlace> _tryReadCache(Position currentPosition) {
    if (_lastCacheAt == null || _lastCachePosition == null || _lastCachedPlaces.isEmpty) {
      return <NearbyPlace>[];
    }
    final isExpired = DateTime.now().difference(_lastCacheAt!) > _cacheTtl;
    if (isExpired) return <NearbyPlace>[];

    final movedMeters = Geolocator.distanceBetween(
      currentPosition.latitude,
      currentPosition.longitude,
      _lastCachePosition!.latitude,
      _lastCachePosition!.longitude,
    );
    if (movedMeters > 350) return <NearbyPlace>[];
    return List<NearbyPlace>.from(_lastCachedPlaces);
  }

  static void _writeCache(Position position, List<NearbyPlace> places) {
    _lastCacheAt = DateTime.now();
    _lastCachePosition = position;
    _lastCachedPlaces = List<NearbyPlace>.from(places);
  }

  static double _computeRelevanceScore({
    required String category,
    required double distanceMeters,
  }) {
    final now = DateTime.now();
    final hour = now.hour;
    final distancePenalty = (distanceMeters / 1000) * 12.0;
    var score = 100.0 - distancePenalty;

    // Ranking contextual por hora
    if (hour >= 6 && hour <= 10) {
      if (category == 'park') score += 12;
      if (category == 'library') score += 4;
    } else if (hour >= 11 && hour <= 17) {
      if (category == 'library') score += 10;
      if (category == 'park') score += 5;
    } else {
      if (category == 'gym') score += 9;
      if (category == 'park') score += 3;
    }

    return score.clamp(0, 130);
  }

  static String _resolveCategory(Map<String, String> tags) {
    if (tags['leisure'] == 'park') return 'park';
    if (tags['amenity'] == 'library' || tags['amenity'] == 'public_bookcase') return 'library';
    if (tags['leisure'] == 'fitness_centre' || tags['leisure'] == 'sports_centre' || tags.containsKey('sport')) {
      return 'gym';
    }
    return 'other';
  }

  static String _resolvePlaceName(
    Map<String, String> tags,
    String category,
    double distanceMeters,
  ) {
    final candidates = <String?>[
      tags['name:es'],
      tags['name'],
      tags['official_name'],
      tags['short_name'],
      tags['brand'],
      tags['operator'],
    ];
    for (final candidate in candidates) {
      final value = (candidate ?? '').trim();
      if (value.isNotEmpty) return value;
    }

    final nearLabel = _distanceLabel(distanceMeters);
    switch (category) {
      case 'park':
        return 'Parque cercano ($nearLabel)';
      case 'library':
        return 'Biblioteca cercana ($nearLabel)';
      case 'gym':
        return 'Centro deportivo ($nearLabel)';
      default:
        return 'Lugar recomendado ($nearLabel)';
    }
  }

  static String _resolvePlaceAddress(Map<String, String> tags, double distanceMeters) {
    final street = tags['addr:street'];
    final number = tags['addr:housenumber'];
    if (street != null && street.trim().isNotEmpty) {
      final num = (number ?? '').trim();
      if (num.isNotEmpty) return '$street $num';
      return street;
    }

    final fullAddress = tags['addr:full'];
    if (fullAddress != null && fullAddress.trim().isNotEmpty) {
      return fullAddress;
    }

    final zone = tags['addr:suburb'] ??
        tags['addr:neighbourhood'] ??
        tags['addr:district'] ??
        tags['addr:city'] ??
        tags['is_in:city'] ??
        tags['is_in:state'];
    if (zone != null && zone.trim().isNotEmpty) {
      return '$zone • ${_distanceLabel(distanceMeters)}';
    }

    return 'A ${_distanceLabel(distanceMeters)} de tu ubicación';
  }

  static String categoryLabel(String category) {
    switch (category) {
      case 'park':
        return 'Parque';
      case 'library':
        return 'Biblioteca';
      case 'gym':
        return 'Deporte';
      default:
        return 'Bienestar';
    }
  }

  static String _distanceLabel(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  static String distanceLabel(double meters) => _distanceLabel(meters);

  static List<NearbyPlace> _fallbackPlacesFromCurrentPosition(Position position) {
    const offsets = <({double lat, double lng, String title, String category})>[
      (lat: 0.0042, lng: 0.0031, title: 'Parque recomendado', category: 'park'),
      (lat: -0.0036, lng: 0.0018, title: 'Biblioteca cercana', category: 'library'),
      (lat: 0.0021, lng: -0.0027, title: 'Zona de caminata', category: 'gym'),
    ];

    return offsets
        .map(
          (o) => NearbyPlace(
            name: o.title,
            address: 'Sugerencia estimada cerca de tu zona',
            lat: position.latitude + o.lat,
            lng: position.longitude + o.lng,
            category: o.category,
            distanceMeters: Geolocator.distanceBetween(
              position.latitude,
              position.longitude,
              position.latitude + o.lat,
              position.longitude + o.lng,
            ),
            relevanceScore: 40,
          ),
        )
        .toList();
  }

  static IconData iconForCategory(String category) {
    switch (category) {
      case 'park':
        return Icons.park;
      case 'library':
        return Icons.local_library;
      case 'gym':
        return Icons.fitness_center;
      default:
        return Icons.place;
    }
  }
}
