import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class GeocodingSuggestion {
  final String address;
  final LatLng latLng;

  const GeocodingSuggestion({required this.address, required this.latLng});
}

class GeocodingRepository {
  static const _base = 'https://nominatim.openstreetmap.org';

  Future<List<GeocodingSuggestion>> searchVietnam(
    String query, {
    int limit = 5,
  }) async {
    if (query.trim().isEmpty) return const [];
    final uri = Uri.parse('$_base/search').replace(queryParameters: {
      'q': query,
      'format': 'jsonv2',
      'addressdetails': '1',
      'countrycodes': 'vn',
      'limit': '$limit',
      'accept-language': 'vi',
    });
    final res = await http.get(uri, headers: {'User-Agent': 'EcoCollect/1.0'});
    if (res.statusCode != 200) return const [];
    final data = jsonDecode(res.body);
    if (data is! List) return const [];
    return data
        .map((e) {
          final lat = double.tryParse('${e['lat'] ?? ''}');
          final lon = double.tryParse('${e['lon'] ?? ''}');
          final display = '${e['display_name'] ?? ''}'.trim();
          if (lat == null || lon == null || display.isEmpty) return null;
          return GeocodingSuggestion(
            address: display,
            latLng: LatLng(lat, lon),
          );
        })
        .whereType<GeocodingSuggestion>()
        .toList();
  }

  Future<String?> reverseVietnam(LatLng latLng) async {
    final uri = Uri.parse('$_base/reverse').replace(queryParameters: {
      'lat': '${latLng.latitude}',
      'lon': '${latLng.longitude}',
      'format': 'jsonv2',
      'accept-language': 'vi',
    });
    final res = await http.get(uri, headers: {'User-Agent': 'EcoCollect/1.0'});
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body);
    if (data is! Map<String, dynamic>) return null;
    final address = '${data['display_name'] ?? ''}'.trim();
    if (address.isEmpty) return null;
    return address;
  }
}
