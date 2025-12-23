import 'dart:convert';
import 'dart:io';
import 'package:nhs_dangbo_app/core/services/geojson_service.dart';

/// Script để convert GeoJSON từ local coordinate system sang WGS84
/// Sử dụng manual calibration với control points đã xác minh
/// Chạy: dart run tools/convert_geojson.dart
void main() async {
  print('🔧 Converting GeoJSON from Local Coordinates to WGS84...');

  final inputPath = 'assets/maps/nhs.geojson';
  final outputPath = 'assets/maps/nhs_wgs84.geojson';

  try {
    // Load and convert using GeoJsonService (proven to work!)
    print('📂 Loading $inputPath...');
    final features = await GeoJsonService.loadGeoJson(
      inputPath,
      maxFeatures: null, // Load ALL features
      simplifyTolerance: 1, // No simplification
    );

    print('✅ Converted ${features.length} features');

    // Build GeoJSON FeatureCollection
    final featureCollection = {
      'type': 'FeatureCollection',
      'features': features
          .map((f) => {
                'type': 'Feature',
                'geometry': {
                  'type': f.type,
                  'coordinates': f.coordinates,
                },
                'properties': f.properties,
              })
          .toList(),
    };

    // Write to file
    print('💾 Writing to $outputPath...');
    final file = File(outputPath);
    await file.writeAsString(
      json.encode(featureCollection),
      flush: true,
    );

    final sizeInMB = await file.length() / (1024 * 1024);
    print('✅ Conversion complete!');
    print('   Output: $outputPath');
    print('   Features: ${features.length}');
    print('   Size: ${sizeInMB.toStringAsFixed(2)} MB');
    print('\n🎉 Now run: python tools/geojson_tiler.py');
  } catch (e, stackTrace) {
    print('❌ Error: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}
