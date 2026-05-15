import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RouteResult {
  final List<LatLng> points;
  final double distanceMeters;

  const RouteResult({required this.points, required this.distanceMeters});
}

class RoutingService {
  static const _osrmBase = 'https://router.project-osrm.org';

  /// Retorna geometría por carretera + distancia real vía OSRM.
  /// Retorna null si falla la red o no hay ruta.
  static Future<RouteResult?> getRoute(List<LatLng> waypoints) async {
    if (waypoints.length < 2) return null;

    final coords = waypoints
        .map((p) => '${p.longitude},${p.latitude}')
        .join(';');

    final uri = Uri.parse(
      '$_osrmBase/route/v1/driving/$coords'
      '?overview=full&geometries=geojson',
    );

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) return null;

      final route = routes[0] as Map<String, dynamic>;
      final distanceMeters = (route['distance'] as num?)?.toDouble() ?? 0.0;

      final geometry = route['geometry'] as Map<String, dynamic>?;
      final coordinates = geometry?['coordinates'] as List?;
      if (coordinates == null) return null;

      final all = coordinates
          .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
          .toList();

      // Decimar a máx 200 puntos para rendimiento
      final points = all.length <= 200 ? all : _decimate(all, 200);

      return RouteResult(points: points, distanceMeters: distanceMeters);
    } catch (_) {
      return null;
    }
  }

  static List<LatLng> _decimate(List<LatLng> pts, int max) {
    final step = pts.length / max;
    final result = <LatLng>[];
    for (int i = 0; i < max; i++) {
      result.add(pts[(i * step).round().clamp(0, pts.length - 1)]);
    }
    result.add(pts.last);
    return result;
  }

  /// Distancia haversine entre dos puntos (metros) — fallback sin red.
  static double haversineMeters(LatLng a, LatLng b) {
    const r = 6371000.0;
    final lat1 = a.latitude * math.pi / 180;
    final lat2 = b.latitude * math.pi / 180;
    final dLat = (b.latitude - a.latitude) * math.pi / 180;
    final dLng = (b.longitude - a.longitude) * math.pi / 180;
    final x = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) *
            math.sin(dLng / 2) * math.sin(dLng / 2);
    return r * 2 * math.atan2(math.sqrt(x), math.sqrt(1 - x));
  }
}
