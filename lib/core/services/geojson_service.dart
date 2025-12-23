import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

class GeoJsonService {
  // Coordinate transformation offsets
  // The GeoJSON files use a local coordinate system that needs to be converted to WGS84
  // Derived from control points:
  //   - Chi bộ Mỹ Đa Đông 2: GeoJSON [111.4991748, 16.0456582] → WGS84 [108.2420212, 16.0418518]
  //   - Chi bộ Mỹ Đa Đông 1: GeoJSON [111.498627, 16.0437836] → WGS84 [108.2426413, 16.0421305]
  static const double _lngOffset = 3.256569650000003;
  static const double _latOffset = 0.0027297500000003083;

  /// Transform local coordinate system to WGS84 (latitude, longitude)
  static LatLng _transformCoordinate(double lng, double lat) {
    // Simple offset transformation: WGS84 = Local - Offset
    final wgs84Lng = lng - _lngOffset;
    final wgs84Lat = lat - _latOffset;
    return LatLng(wgs84Lat, wgs84Lng);
  }

  static Future<List<GeoJsonFeature>> loadGeoJson(String assetPath,
      {int? maxFeatures, int simplifyTolerance = 10}) async {
    try {
      print('Loading GeoJSON from $assetPath...');
      final String jsonString = await rootBundle.loadString(assetPath);
      print('GeoJSON loaded, size: ${jsonString.length} bytes');

      print('Parsing JSON...');
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      final List<GeoJsonFeature> features = [];

      if (jsonData['type'] == 'FeatureCollection') {
        final List<dynamic> featuresJson = jsonData['features'] ?? [];
        print('Found ${featuresJson.length} features');

        // Limit features if specified
        final featuresToProcess = maxFeatures != null
            ? featuresJson.take(maxFeatures).toList()
            : featuresJson;

        int count = 0;
        for (var featureJson in featuresToProcess) {
          final feature = _parseFeature(featureJson, simplifyTolerance);
          if (feature != null) {
            features.add(feature);
            count++;

            // Log progress every 1000 features
            if (count % 1000 == 0) {
              print('Processed $count features...');
            }
          }
        }

        print('Successfully parsed ${features.length} features');
      }

      return features;
    } catch (e, stackTrace) {
      print('Error loading GeoJSON: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  static GeoJsonFeature? _parseFeature(Map<String, dynamic> featureJson,
      [int simplifyTolerance = 10]) {
    try {
      final geometry = featureJson['geometry'];
      final properties =
          featureJson['properties'] as Map<String, dynamic>? ?? {};

      if (geometry == null) return null;

      final geometryType = geometry['type'] as String?;
      final coordinates = geometry['coordinates'];

      if (geometryType == null || coordinates == null) return null;

      return GeoJsonFeature(
        type: geometryType,
        coordinates: coordinates,
        properties: properties,
      );
    } catch (e) {
      print('Error parsing feature: $e');
      return null;
    }
  }

  static List<LatLng> parseCoordinates(dynamic coordinates,
      {int simplifyEveryN = 1}) {
    final List<LatLng> points = [];

    if (coordinates is List) {
      int index = 0;
      for (var coord in coordinates) {
        // Skip points for simplification (take every Nth point)
        if (index % simplifyEveryN != 0 &&
            index != 0 &&
            index != coordinates.length - 1) {
          index++;
          continue;
        }
        if (coord is List && coord.length >= 2) {
          try {
            // GeoJSON format: [longitude, latitude]
            final lng = (coord[0] as num).toDouble();
            final lat = (coord[1] as num).toDouble();

            // Transform from local coordinate system to WGS84
            final wgs84Point = _transformCoordinate(lng, lat);
            points.add(wgs84Point);
          } catch (e) {
            // Skip invalid coordinates
            print('Error converting coordinate: $e');
          }
        }
        index++;
      }
    }

    return points;
  }

  static List<List<LatLng>> parsePolygonCoordinates(dynamic coordinates,
      {int simplifyEveryN = 1}) {
    final List<List<LatLng>> polygons = [];

    if (coordinates is List) {
      for (var ring in coordinates) {
        if (ring is List) {
          final points = parseCoordinates(ring, simplifyEveryN: simplifyEveryN);
          if (points.isNotEmpty) {
            polygons.add(points);
          }
        }
      }
    }

    return polygons;
  }

  static List<List<List<LatLng>>> parseMultiPolygonCoordinates(
      dynamic coordinates,
      {int simplifyEveryN = 1}) {
    final List<List<List<LatLng>>> multiPolygons = [];

    if (coordinates is List) {
      for (var polygon in coordinates) {
        if (polygon is List) {
          final polygonRings =
              parsePolygonCoordinates(polygon, simplifyEveryN: simplifyEveryN);
          if (polygonRings.isNotEmpty) {
            multiPolygons.add(polygonRings);
          }
        }
      }
    }

    return multiPolygons;
  }

  // Calculate the bounding box center from a list of features
  static LatLng? calculateCenter(List<GeoJsonFeature> features) {
    if (features.isEmpty) return null;

    double minLat = double.infinity;
    double maxLat = double.negativeInfinity;
    double minLng = double.infinity;
    double maxLng = double.negativeInfinity;

    // Use heavy simplification for center calculation to speed up
    const simplify = 20;

    for (var feature in features) {
      List<LatLng> points = [];

      switch (feature.type) {
        case 'Point':
          points = parseCoordinates([feature.coordinates]);
          break;
        case 'LineString':
          points =
              parseCoordinates(feature.coordinates, simplifyEveryN: simplify);
          break;
        case 'Polygon':
          final rings = parsePolygonCoordinates(feature.coordinates,
              simplifyEveryN: simplify);
          if (rings.isNotEmpty) points = rings[0];
          break;
        case 'MultiLineString':
          for (var line in feature.coordinates) {
            points.addAll(parseCoordinates(line, simplifyEveryN: simplify));
          }
          break;
        case 'MultiPolygon':
          final multiPolygons = parseMultiPolygonCoordinates(
              feature.coordinates,
              simplifyEveryN: simplify);
          for (var polygon in multiPolygons) {
            if (polygon.isNotEmpty) points.addAll(polygon[0]);
          }
          break;
      }

      for (var point in points) {
        if (point.latitude < minLat) minLat = point.latitude;
        if (point.latitude > maxLat) maxLat = point.latitude;
        if (point.longitude < minLng) minLng = point.longitude;
        if (point.longitude > maxLng) maxLng = point.longitude;
      }
    }

    if (minLat == double.infinity) return null;

    return LatLng(
      (minLat + maxLat) / 2,
      (minLng + maxLng) / 2,
    );
  }
}

class GeoJsonFeature {
  final String type;
  final dynamic coordinates;
  final Map<String, dynamic> properties;

  GeoJsonFeature({
    required this.type,
    required this.coordinates,
    required this.properties,
  });

  /// Create from JSON (used by TileService)
  factory GeoJsonFeature.fromJson(Map<String, dynamic> json) {
    return GeoJsonFeature(
      type: json['type'] as String,
      coordinates: json['coordinates'],
      properties: json['properties'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Convert to JSON (used by Python tiler)
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'coordinates': coordinates,
      'properties': properties,
    };
  }

  String? get name => properties['name'] as String?;
  String? get description => properties['description'] as String?;

  @override
  String toString() {
    return 'GeoJsonFeature(type: $type, properties: $properties)';
  }
}
