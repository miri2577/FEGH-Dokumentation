import 'dart:convert';
import 'package:http/http.dart' as http;

class GeocodingResult {
  final String label;
  final String? street;
  final String? housenumber;
  final String? postalcode;
  final String? locality;
  final double lat;
  final double lng;

  const GeocodingResult({
    required this.label,
    this.street,
    this.housenumber,
    this.postalcode,
    this.locality,
    required this.lat,
    required this.lng,
  });

  /// z.B. "Hauptstraße 1"
  String get addressLine {
    if (street != null && housenumber != null) return '$street $housenumber';
    if (street != null) return street!;
    return label.split(',').first.trim();
  }

  /// z.B. "10827 Berlin"
  String get plzOrt {
    if (postalcode != null && locality != null) return '$postalcode $locality';
    if (locality != null) return locality!;
    if (postalcode != null) return postalcode!;
    final parts = label.split(',');
    return parts.length > 1 ? parts.sublist(1).join(',').trim() : '';
  }
}

class DistanceService {
  // Nominatim (OSM Geocoding) - kostenlos, kein API-Key
  static const _nominatimUrl = 'https://nominatim.openstreetmap.org';
  // OSRM (OSM Routing) - kostenlos, kein API-Key
  static const _osrmUrl = 'https://router.project-osrm.org';

  static const _userAgent = 'FEGH-Dokumentation/1.0';

  // Optionaler ORS API-Key (Fallback, nicht mehr zwingend nötig)
  String _apiKey = '';

  DistanceService({String? apiKey}) {
    if (apiKey != null && apiKey.isNotEmpty) {
      _apiKey = apiKey;
    }
  }

  bool get hasApiKey => _apiKey.isNotEmpty;

  void setApiKey(String key) {
    _apiKey = key;
  }

  /// Berechnet Fahrdistanz zwischen zwei Adressen.
  /// Adressen werden NUR für die Berechnung verwendet, NICHT gespeichert.
  Future<double?> calculateDistance(String startAdresse, String zielAdresse) async {
    try {
      final startCoords = await geocode(startAdresse);
      if (startCoords == null) return null;

      final zielCoords = await geocode(zielAdresse);
      if (zielCoords == null) return null;

      return await getRouteDistance(startCoords, zielCoords);
    } catch (e) {
      return null;
    }
  }

  /// Berechnet Fahrdistanz zwischen zwei Koordinaten-Paaren.
  Future<double?> calculateDistanceFromCoords(
    double startLat, double startLng,
    double zielLat, double zielLng,
  ) async {
    return getRouteDistance(
      GeocodingResult(label: '', lat: startLat, lng: startLng),
      GeocodingResult(label: '', lat: zielLat, lng: zielLng),
    );
  }

  /// Adress-Suche mit Nominatim (OSM Geocoder).
  /// Gibt bis zu [maxResults] Vorschläge mit PLZ und Ort zurück.
  Future<List<GeocodingResult>> searchAddresses(String query, {int maxResults = 5}) async {
    if (query.trim().length < 3) return [];

    try {
      final uri = Uri.parse('$_nominatimUrl/search').replace(
        queryParameters: {
          'q': query,
          'format': 'json',
          'addressdetails': '1',
          'limit': maxResults.toString(),
          'countrycodes': 'de',
        },
      );

      final response = await http.get(uri, headers: {
        'User-Agent': _userAgent,
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return [];

      final data = json.decode(response.body) as List;
      if (data.isEmpty) return [];

      return data.map((item) {
        final address = item['address'] as Map<String, dynamic>? ?? {};
        final displayName = item['display_name'] as String? ?? '';
        final street = address['road'] as String?;
        final housenumber = address['house_number'] as String?;
        final postalcode = address['postcode'] as String?;
        // Stadt/Ort: city > town > village > suburb
        final locality = address['city'] as String?
            ?? address['town'] as String?
            ?? address['village'] as String?;

        return GeocodingResult(
          label: displayName,
          street: street,
          housenumber: housenumber,
          postalcode: postalcode,
          locality: locality,
          lat: double.tryParse(item['lat']?.toString() ?? '') ?? 0,
          lng: double.tryParse(item['lon']?.toString() ?? '') ?? 0,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Geocoding: Adresse → erstes Ergebnis
  Future<GeocodingResult?> geocode(String adresse) async {
    try {
      final results = await searchAddresses(adresse, maxResults: 1);
      return results.isNotEmpty ? results.first : null;
    } catch (e) {
      return null;
    }
  }

  /// Routing mit OSRM (OpenStreetMap).
  /// Berechnet die Fahrdistanz (Auto) zwischen zwei Koordinaten.
  Future<double?> getRouteDistance(GeocodingResult start, GeocodingResult ziel) async {
    try {
      // OSRM Format: /route/v1/driving/lng1,lat1;lng2,lat2
      final uri = Uri.parse(
        '$_osrmUrl/route/v1/driving/${start.lng},${start.lat};${ziel.lng},${ziel.lat}?overview=false',
      );

      final response = await http.get(uri, headers: {
        'User-Agent': _userAgent,
      }).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) return null;

      final data = json.decode(response.body) as Map<String, dynamic>;
      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) return null;

      final distanceMeters = routes[0]['distance'] as num?;
      if (distanceMeters == null) return null;

      // Meter → Kilometer, auf 1 Dezimalstelle gerundet
      return (distanceMeters.toDouble() / 1000.0 * 10).roundToDouble() / 10;
    } catch (e) {
      return null;
    }
  }
}
