import 'package:latlong2/latlong.dart';

void main() {
  // Test the coordinate transformation

  // Control Point 1: Chi bộ Mỹ Đa Đông 2
  final geojson1 = [111.4991748, 16.0456582];
  final expected1 = [108.2420212, 16.0418518]; // [lng, lat]

  // Control Point 2: Chi bộ Mỹ Đa Đông 1
  final geojson2 = [111.498627, 16.0437836];
  final expected2 = [108.2426413, 16.0421305]; // [lng, lat]

  // Offsets
  const lngOffset = 3.256569650000003;
  const latOffset = 0.0027297500000003083;

  print('=== Testing Coordinate Transformation ===\n');

  // Test point 1
  final transformed1 = LatLng(
    geojson1[1] - latOffset, // lat
    geojson1[0] - lngOffset, // lng
  );

  final error1Lat = (transformed1.latitude - expected1[1]).abs();
  final error1Lng = (transformed1.longitude - expected1[0]).abs();

  print('Point 1: Chi bộ Mỹ Đa Đông 2');
  print('  Input (GeoJSON):  [${geojson1[0]}, ${geojson1[1]}]');
  print('  Expected (WGS84): [${expected1[0]}, ${expected1[1]}]');
  print(
      '  Result:           [${transformed1.longitude}, ${transformed1.latitude}]');
  print('  Error (degrees):  [$error1Lng, $error1Lat]');
  print(
      '  Error (meters):   [${(error1Lng * 111000).toStringAsFixed(2)}m, ${(error1Lat * 111000).toStringAsFixed(2)}m]');

  // Test point 2
  final transformed2 = LatLng(
    geojson2[1] - latOffset, // lat
    geojson2[0] - lngOffset, // lng
  );

  final error2Lat = (transformed2.latitude - expected2[1]).abs();
  final error2Lng = (transformed2.longitude - expected2[0]).abs();

  print('\nPoint 2: Chi bộ Mỹ Đa Đông 1');
  print('  Input (GeoJSON):  [${geojson2[0]}, ${geojson2[1]}]');
  print('  Expected (WGS84): [${expected2[0]}, ${expected2[1]}]');
  print(
      '  Result:           [${transformed2.longitude}, ${transformed2.latitude}]');
  print('  Error (degrees):  [$error2Lng, $error2Lat]');
  print(
      '  Error (meters):   [${(error2Lng * 111000).toStringAsFixed(2)}m, ${(error2Lat * 111000).toStringAsFixed(2)}m]');

  // Test a typical point to see where it will be displayed
  final testPoint = [111.4983329, 16.0452023]; // Tổ 76
  final testTransformed = LatLng(
    testPoint[1] - latOffset,
    testPoint[0] - lngOffset,
  );

  print('\n=== Sample Point (Tổ 76) ===');
  print('  Input (GeoJSON): [${testPoint[0]}, ${testPoint[1]}]');
  print(
      '  Result (WGS84):  [${testTransformed.longitude}, ${testTransformed.latitude}]');
  print(
      '  Google Maps: https://www.google.com/maps?q=${testTransformed.latitude},${testTransformed.longitude}');
}
