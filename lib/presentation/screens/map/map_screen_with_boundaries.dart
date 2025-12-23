import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

// Color constants
const _primaryColor = Color(0xFFE53935);

// Map constants
const _defaultLatitude = 16.033;
const _defaultLongitude = 108.241;
const _defaultZoom = 15.0;

/// Map screen with boundaries (polygons) for each Tổ Dân Phố
class MapScreenWithBoundaries extends StatefulWidget {
  const MapScreenWithBoundaries({super.key});

  @override
  State<MapScreenWithBoundaries> createState() =>
      _MapScreenWithBoundariesState();
}

class _MapScreenWithBoundariesState extends State<MapScreenWithBoundaries> {
  GoogleMapController? _mapController;
  Set<Polygon> _polygons = {};
  Set<Marker> _markers = {}; // Center markers for each tổ
  bool _isLoading = false;
  LatLngBounds? _currentBounds;

  String? _selectedToDanPho;
  String? _selectedChiBo; // Selected Chi bộ for filtering
  List<String> _availableChiBo = []; // List of all Chi bộ
  final Map<String, List<String>> _chiBoToToDanPho =
      {}; // Map ChiBo -> List of ToDP

  // Search
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  final Map<String, List<LatLng>> _toDanPhoPolygons = {};
  final Map<String, String> _toDanPhoToChiBo = {}; // Map ToDP -> ChiBo
  final Map<String, Color> _toDanPhoColors = {}; // Map ToDP -> Color
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) async {
    _mapController = controller;
    debugPrint('🗺️ Map created, loading Phường 260');
    await _loadAreaBoundaries();
  }

  /// Group LineStrings by ToDanPho and create polygons
  Future<void> _loadAreaBoundaries() async {
    setState(() {
      _isLoading = true;
      _toDanPhoPolygons.clear();
      _toDanPhoToChiBo.clear();
      _chiBoToToDanPho.clear();
      _availableChiBo.clear();
      _searchController.clear();
      _isSearching = false;
    });

    try {
      // Load 260to.geojson (Phường 260)
      const filename = 'assets/maps/260to.geojson';
      final geojson = await DefaultAssetBundle.of(context).loadString(filename);
      debugPrint('📂 Loaded file: $filename');

      final Map<String, dynamic> data =
          Map<String, dynamic>.from(jsonDecode(geojson));
      final List features = (data['features'] as List?) ?? [];

      // Group line segments by ToDanPho
      final Map<String, List<List<LatLng>>> linesByTo = {};
      double? minLat, maxLat, minLng, maxLng;

      void extendBounds(LatLng p) {
        minLat = (minLat == null) ? p.latitude : math.min(minLat!, p.latitude);
        maxLat = (maxLat == null) ? p.latitude : math.max(maxLat!, p.latitude);
        minLng =
            (minLng == null) ? p.longitude : math.min(minLng!, p.longitude);
        maxLng =
            (maxLng == null) ? p.longitude : math.max(maxLng!, p.longitude);
      }

      for (final f in features) {
        final fm = f as Map;
        final geom = fm['geometry'] as Map?;
        if (geom == null) continue;
        final props = (fm['properties'] as Map?) ?? {};

        // Read ToDP and ChiBo from properties
        String toDanPho =
            (props['ToDP'] ?? props['To'] ?? '').toString().trim();
        String chiBo = (props['ChiBo'] ?? '').toString().trim();

        // Convert "To 1" -> "Tổ 1", "To 10" -> "Tổ 10"
        if (toDanPho.toLowerCase().startsWith('to ')) {
          toDanPho = 'Tổ${toDanPho.substring(2)}';
        }

        if (toDanPho.isEmpty) continue; // Store ChiBo mapping
        if (chiBo.isNotEmpty) {
          _toDanPhoToChiBo[toDanPho] = chiBo;

          // Build ChiBo -> ToDanPho mapping
          _chiBoToToDanPho.putIfAbsent(chiBo, () => []);
          if (!_chiBoToToDanPho[chiBo]!.contains(toDanPho)) {
            _chiBoToToDanPho[chiBo]!.add(toDanPho);
          }
        }

        if (geom['type'] == 'LineString') {
          final coords = geom['coordinates'] as List?;
          if (coords == null || coords.length < 2) continue;
          final linePoints = <LatLng>[];
          for (final c in coords) {
            if (c is List && c.length >= 2) {
              final lng = (c[0] as num).toDouble();
              final lat = (c[1] as num).toDouble();

              // File is already in WGS84 format, no conversion needed
              final point = LatLng(lat, lng);

              // Validate coordinates (Đà Nẵng area)
              if (lat < 15.5 || lat > 16.5 || lng < 107.5 || lng > 109.0) {
                debugPrint('⚠️ Point rejected: ($lat, $lng)');
                continue;
              }

              linePoints.add(point);
              extendBounds(point);
            }
          }

          if (linePoints.isNotEmpty) {
            linesByTo.putIfAbsent(toDanPho, () => []);
            linesByTo[toDanPho]!.add(linePoints);
          }
        }
      } // Create polygons from line segments
      final polygons = <Polygon>{};
      final markers = <Marker>{};
      int polygonIndex = 0;
      int skippedCount = 0; // Track skipped polygons
      final List<String> skippedToNames = []; // Track which tổ are skipped

      // Sort tổ names for consistent colors
      final sortedToNames = linesByTo.keys.toList()..sort();

      debugPrint('📊 Total linesByTo entries: ${linesByTo.length}');
      debugPrint('📊 All tổ names: ${sortedToNames.join(", ")}');

      for (final toDanPho in sortedToNames) {
        final lines = linesByTo[toDanPho]!;

        debugPrint('🔍 Processing: $toDanPho (${lines.length} line segments)');

        // Collect all unique points from all line segments
        final allPoints = <LatLng>[];
        for (final line in lines) {
          allPoints.addAll(line);
        }

        debugPrint('   → Total points before connecting: ${allPoints.length}');

        if (allPoints.length < 3) {
          debugPrint('⚠️ Skipped $toDanPho: only ${allPoints.length} points');
          skippedCount++;
          skippedToNames.add(toDanPho);
          continue; // Need at least 3 points for polygon
        }

        // Try to create a polygon by connecting line segments
        // For simplicity, we'll use all points as-is
        // In production, you might want to sort/order them properly
        final polygonPoints = _connectLineSegments(lines);

        debugPrint('   → Points after connecting: ${polygonPoints.length}');

        if (polygonPoints.length < 3) {
          debugPrint(
              '⚠️ Skipped $toDanPho: polygon only has ${polygonPoints.length} points after connecting');
          skippedCount++;
          skippedToNames.add(toDanPho);
          continue;
        }

        _toDanPhoPolygons[toDanPho] =
            polygonPoints; // Generate color based on tổ index
        final color = _generateColorForTo(polygonIndex, sortedToNames.length);
        _toDanPhoColors[toDanPho] = color; // Store color for later use

        polygons.add(
          Polygon(
            polygonId: PolygonId('260_polygon_$toDanPho'),
            points: polygonPoints,
            strokeColor: color.withOpacity(1.0), // Viền màu đậm 100%
            strokeWidth: 4, // Viền to hơn (tăng từ 2 lên 4)
            fillColor: color
                .withOpacity(0.25), // Màu nền đậm hơn (tăng từ 0.15 lên 0.25)
            consumeTapEvents: true,
            onTap: () {
              setState(() {
                _selectedToDanPho = toDanPho;
              });
              _showToInfo(toDanPho, polygonPoints);
            },
          ),
        );

        // Create center marker with label
        final center = _calculatePolygonCenter(polygonPoints);
        final markerIcon = await _createMarkerLabel(toDanPho);

        markers.add(
          Marker(
            markerId: MarkerId('260_marker_$toDanPho'),
            position: center,
            icon: markerIcon,
            anchor: const Offset(0.5, 0.5),
            onTap: () {
              setState(() {
                _selectedToDanPho = toDanPho;
              });
              _showToInfo(toDanPho, polygonPoints);
            },
          ),
        );

        polygonIndex++;
      }
      setState(() {
        _polygons = polygons;
        _markers = markers;
        _availableChiBo = _chiBoToToDanPho.keys.toList()..sort();
      });
      debugPrint('✅ Loaded ${_toDanPhoPolygons.length} tổ');
      if (skippedCount > 0) {
        debugPrint('⚠️ Skipped $skippedCount tổ due to insufficient points');
        debugPrint('⚠️ Skipped tổ names: ${skippedToNames.join(", ")}');
      }
      debugPrint('📋 Chi bộ: ${_availableChiBo.length} chi bộ');
      debugPrint('📋 Chi bộ mapping: ${_toDanPhoToChiBo.length} entries');
      debugPrint('📋 Expected tổ count: ${linesByTo.length}');
      debugPrint('📋 Actual polygon count: ${_toDanPhoPolygons.length}');
      debugPrint(
          '📋 Difference: ${linesByTo.length - _toDanPhoPolygons.length} tổ not displayed');

      if (minLat != null &&
          maxLat != null &&
          minLng != null &&
          maxLng != null) {
        const paddingDegrees = 0.002;
        _currentBounds = LatLngBounds(
          southwest: LatLng(minLat! - paddingDegrees, minLng! - paddingDegrees),
          northeast: LatLng(maxLat! + paddingDegrees, maxLng! + paddingDegrees),
        );

        if (_mapController != null) {
          await _fitCameraToBounds();
        }
      }
    } catch (e, stack) {
      debugPrint('❌ Load GeoJSON error: $e');
      debugPrint('Stack: $stack');
      setState(() => _polygons = {});
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Connect line segments to form a closed polygon
  /// This is a simple implementation - may need refinement for complex shapes
  List<LatLng> _connectLineSegments(List<List<LatLng>> lines) {
    if (lines.isEmpty) return [];
    if (lines.length == 1) return lines[0];

    final allPoints = <LatLng>[];
    final usedLines = <int>{};

    // Start with first line
    allPoints.addAll(lines[0]);
    usedLines.add(0);

    // Try to connect remaining lines
    while (usedLines.length < lines.length) {
      final lastPoint = allPoints.last;
      bool foundConnection = false;

      for (int i = 0; i < lines.length; i++) {
        if (usedLines.contains(i)) continue;

        final line = lines[i];
        final firstPoint = line.first;
        final lastLinePoint = line.last;

        // Check if this line connects to our current chain
        final distToFirst = _distance(lastPoint, firstPoint);
        final distToLast = _distance(lastPoint, lastLinePoint);

        if (distToFirst < 0.0001) {
          // Connect forward
          allPoints.addAll(line.skip(1));
          usedLines.add(i);
          foundConnection = true;
          break;
        } else if (distToLast < 0.0001) {
          // Connect backward
          allPoints.addAll(line.reversed.skip(1));
          usedLines.add(i);
          foundConnection = true;
          break;
        }
      }

      if (!foundConnection) break;
    }

    // Remove duplicate consecutive points
    final cleaned = <LatLng>[];
    for (int i = 0; i < allPoints.length; i++) {
      if (i == 0 || _distance(allPoints[i], allPoints[i - 1]) > 0.00001) {
        cleaned.add(allPoints[i]);
      }
    }

    return cleaned;
  }

  /// Calculate distance between two LatLng points
  double _distance(LatLng p1, LatLng p2) {
    final lat = p1.latitude - p2.latitude;
    final lng = p1.longitude - p2.longitude;
    return math.sqrt(lat * lat + lng * lng);
  }

  /// Calculate center of polygon
  LatLng _calculatePolygonCenter(List<LatLng> points) {
    if (points.isEmpty) {
      return const LatLng(_defaultLatitude, _defaultLongitude);
    }

    double sumLat = 0;
    double sumLng = 0;

    for (final point in points) {
      sumLat += point.latitude;
      sumLng += point.longitude;
    }

    return LatLng(sumLat / points.length, sumLng / points.length);
  }

  /// Generate distinct color for each tổ
  Color _generateColorForTo(int index, int total) {
    // Danh sách màu cố định để đảm bảo mỗi tổ có màu khác biệt rõ ràng
    final predefinedColors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.lime,
      Colors.amber,
      Colors.cyan,
      Colors.deepOrange,
      Colors.lightGreen,
      Colors.deepPurple,
      Colors.brown,
      Colors.blueGrey,
      Colors.yellow,
      Colors.lightBlue,
      Colors.pinkAccent,
      Colors.greenAccent,
    ];

    // Nếu có ít tổ, dùng màu cố định
    if (index < predefinedColors.length) {
      return predefinedColors[index];
    }

    // Nếu có nhiều tổ hơn, tạo màu bằng thuật toán Golden Ratio
    // Đảm bảo các màu phân bố đều và khác biệt rõ ràng
    const goldenRatioConjugate = 0.618033988749895;
    final hue = ((index * goldenRatioConjugate) % 1.0) * 360;

    // Thay đổi độ sáng và độ bão hòa theo nhóm để tăng sự khác biệt
    final saturation = 0.6 + (index % 3) * 0.15;
    final lightness = 0.45 + (index % 2) * 0.1;

    return HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor();
  }

  /// Create custom marker label
  Future<BitmapDescriptor> _createMarkerLabel(String text) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final pixelRatio = View.of(context).devicePixelRatio;
    final scaleFactor = pixelRatio.clamp(1.5, 3.0);

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white,
          fontSize: 12 * scaleFactor,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.7),
              offset: const Offset(1, 1),
              blurRadius: 3,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final bgWidth = textPainter.width + 16 * scaleFactor;
    final bgHeight = textPainter.height + 12 * scaleFactor;

    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, bgWidth, bgHeight),
      Radius.circular(6 * scaleFactor),
    );

    // Background
    canvas.drawRRect(
      bgRect,
      Paint()
        ..color = Colors.black.withOpacity(0.6)
        ..style = PaintingStyle.fill,
    );

    // Border
    canvas.drawRRect(
      bgRect,
      Paint()
        ..color = Colors.white.withOpacity(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 * scaleFactor,
    );

    // Text
    textPainter.paint(
      canvas,
      Offset(8 * scaleFactor, 6 * scaleFactor),
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(bgWidth.toInt(), bgHeight.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final buffer = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(buffer);
  }

  Future<void> _fitCameraToBounds() async {
    if (_currentBounds == null || _mapController == null) return;

    try {
      await _mapController!
          .animateCamera(CameraUpdate.newLatLngBounds(_currentBounds!, 100));
    } catch (e) {
      final center = LatLng(
        (_currentBounds!.southwest.latitude +
                _currentBounds!.northeast.latitude) /
            2,
        (_currentBounds!.southwest.longitude +
                _currentBounds!.northeast.longitude) /
            2,
      );
      await _mapController!.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(target: center, zoom: 15)));
    }
  }

  void _searchTo(String query) {
    if (query.isEmpty) {
      setState(() => _isSearching = false);
      return;
    }

    setState(() => _isSearching = true);

    final lowerQuery = query.toLowerCase().trim();

    // First, try to find matching Chi bộ
    String? matchingChiBo;
    for (final chiBo in _availableChiBo) {
      if (chiBo.toLowerCase().contains(lowerQuery)) {
        matchingChiBo = chiBo;
        break;
      }
    }

    if (matchingChiBo != null) {
      // Found Chi bộ - select it and zoom to it
      setState(() {
        _selectedChiBo = matchingChiBo;
      });
      _filterByChiBo(matchingChiBo);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã tìm thấy: $matchingChiBo'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }

    // If not Chi bộ, search for Tổ
    // Support searching: "1" -> "Tổ 1", "tổ 1" -> "Tổ 1", "to 1" -> "Tổ 1"
    final matchingTo = _toDanPhoPolygons.keys.firstWhere(
      (name) {
        final lowerName = name.toLowerCase();

        // Direct match
        if (lowerName.contains(lowerQuery)) return true;

        // Match number only: "1" matches "Tổ 1"
        if (RegExp(r'^\d+$').hasMatch(lowerQuery)) {
          return lowerName.contains('tổ $lowerQuery') ||
              lowerName.contains('to $lowerQuery');
        }

        // Match "to X" -> "Tổ X"
        if (lowerQuery.startsWith('to ')) {
          final num = lowerQuery.substring(3);
          return lowerName.contains('tổ $num');
        }

        return false;
      },
      orElse: () => '',
    );

    if (matchingTo.isNotEmpty) {
      final points = _toDanPhoPolygons[matchingTo]!;
      final center = _calculatePolygonCenter(points);

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(center, 17),
      );

      setState(() {
        _selectedToDanPho = matchingTo;
      });

      _showToInfo(matchingTo, points);
    } else {
      // Show snackbar if not found
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không tìm thấy "$query"'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _showToInfo(String toDanPho, List<LatLng> points) {
    final chiBo = _toDanPhoToChiBo[toDanPho] ?? 'Không có thông tin';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.green,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        toDanPho,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        chiBo,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            _infoRow(Icons.group, 'Chi bộ', chiBo),
            const SizedBox(height: 8),
            _infoRow(Icons.map, 'Số điểm ranh giới', '${points.length} điểm'),
            const SizedBox(height: 8),
            _infoRow(Icons.square_foot, 'Diện tích',
                '~${_calculateArea(points).toStringAsFixed(2)} ha'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Đóng'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Calculate approximate area in hectares
  double _calculateArea(List<LatLng> points) {
    if (points.length < 3) return 0;

    // Shoelace formula
    double area = 0;
    for (int i = 0; i < points.length; i++) {
      final j = (i + 1) % points.length;
      area += points[i].longitude * points[j].latitude;
      area -= points[j].longitude * points[i].latitude;
    }
    area = area.abs() / 2;

    // Convert to hectares (very rough approximation)
    // 1 degree ≈ 111 km, so 1 square degree ≈ 12321 km² ≈ 1232100 ha
    return area * 1232100;
  }

  /// Filter polygons and markers by Chi bộ
  void _filterByChiBo(String? chiBo) {
    if (chiBo == null) {
      // Show all tổ
      final polygons = <Polygon>{};
      final markers = <Marker>{};

      for (final entry in _toDanPhoPolygons.entries) {
        final toDanPho = entry.key;
        final points = entry.value;
        final color = _toDanPhoColors[toDanPho] ?? Colors.blue;

        polygons.add(
          Polygon(
            polygonId: PolygonId('260_polygon_$toDanPho'),
            points: points,
            strokeColor: color.withOpacity(1.0),
            strokeWidth: 4,
            fillColor: color.withOpacity(0.25),
            consumeTapEvents: true,
            onTap: () {
              setState(() {
                _selectedToDanPho = toDanPho;
              });
              _showToInfo(toDanPho, points);
            },
          ),
        );

        final center = _calculatePolygonCenter(points);
        _createMarkerLabel(toDanPho).then((markerIcon) {
          markers.add(
            Marker(
              markerId: MarkerId('260_marker_$toDanPho'),
              position: center,
              icon: markerIcon,
              anchor: const Offset(0.5, 0.5),
              onTap: () {
                setState(() {
                  _selectedToDanPho = toDanPho;
                });
                _showToInfo(toDanPho, points);
              },
            ),
          );
          if (mounted) {
            setState(() {
              _markers = markers;
            });
          }
        });
      }

      setState(() {
        _polygons = polygons;
      });
    } else {
      // Filter by selected Chi bộ
      final toListInChiBo = _chiBoToToDanPho[chiBo] ?? [];
      final polygons = <Polygon>{};
      final markers = <Marker>{};

      for (final entry in _toDanPhoPolygons.entries) {
        final toDanPho = entry.key;
        final points = entry.value;
        final color = _toDanPhoColors[toDanPho] ?? Colors.blue;

        final isInSelectedChiBo = toListInChiBo.contains(toDanPho);

        polygons.add(
          Polygon(
            polygonId: PolygonId('260_polygon_$toDanPho'),
            points: points,
            strokeColor: isInSelectedChiBo
                ? color.withOpacity(1.0)
                : color.withOpacity(0.3),
            strokeWidth: isInSelectedChiBo ? 6 : 2, // Viền to hơn nếu được chọn
            fillColor: isInSelectedChiBo
                ? color.withOpacity(0.4) // Màu đậm hơn nếu được chọn
                : color.withOpacity(0.05), // Màu nhạt nếu không được chọn
            consumeTapEvents: true,
            onTap: () {
              setState(() {
                _selectedToDanPho = toDanPho;
              });
              _showToInfo(toDanPho, points);
            },
          ),
        );

        if (isInSelectedChiBo) {
          final center = _calculatePolygonCenter(points);
          _createMarkerLabel(toDanPho).then((markerIcon) {
            markers.add(
              Marker(
                markerId: MarkerId('260_marker_$toDanPho'),
                position: center,
                icon: markerIcon,
                anchor: const Offset(0.5, 0.5),
                onTap: () {
                  setState(() {
                    _selectedToDanPho = toDanPho;
                  });
                  _showToInfo(toDanPho, points);
                },
              ),
            );
            if (mounted) {
              setState(() {
                _markers = markers;
              });
            }
          });
        }
      }

      setState(() {
        _polygons = polygons;
      });

      // Zoom to selected Chi bộ
      if (toListInChiBo.isNotEmpty) {
        double? minLat, maxLat, minLng, maxLng;

        for (final toDanPho in toListInChiBo) {
          final points = _toDanPhoPolygons[toDanPho];
          if (points != null) {
            for (final point in points) {
              minLat = (minLat == null)
                  ? point.latitude
                  : math.min(minLat, point.latitude);
              maxLat = (maxLat == null)
                  ? point.latitude
                  : math.max(maxLat, point.latitude);
              minLng = (minLng == null)
                  ? point.longitude
                  : math.min(minLng, point.longitude);
              maxLng = (maxLng == null)
                  ? point.longitude
                  : math.max(maxLng, point.longitude);
            }
          }
        }

        if (minLat != null &&
            maxLat != null &&
            minLng != null &&
            maxLng != null) {
          const paddingDegrees = 0.005;
          final bounds = LatLngBounds(
            southwest: LatLng(minLat - paddingDegrees, minLng - paddingDegrees),
            northeast: LatLng(maxLat + paddingDegrees, maxLng + paddingDegrees),
          );

          _mapController?.animateCamera(
            CameraUpdate.newLatLngBounds(bounds, 50),
          );
        }
      }
    }
  }

  Future<void> _goToMyLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dịch vụ định vị chưa bật'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      LocationPermission p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) {
        p = await Geolocator.requestPermission();
      }
      if (p == LocationPermission.deniedForever ||
          p == LocationPermission.denied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Từ chối quyền vị trí'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final pos = await Geolocator.getCurrentPosition();
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(pos.latitude, pos.longitude),
            zoom: 16,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi vị trí: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Show Chi bộ selector bottom sheet
  void _showChiBoSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    Icons.filter_list,
                    color: _primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chọn Chi bộ',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Lọc tổ dân phố theo chi bộ',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            // List of Chi bộ
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: ListView(
                children: [
                  // "Tất cả" option
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _selectedChiBo == null
                            ? _primaryColor.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.select_all,
                        color: _selectedChiBo == null
                            ? _primaryColor
                            : Colors.grey,
                      ),
                    ),
                    title: const Text(
                      'Tất cả Chi bộ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('${_toDanPhoPolygons.length} tổ'),
                    trailing: _selectedChiBo == null
                        ? Icon(Icons.check_circle, color: _primaryColor)
                        : null,
                    selected: _selectedChiBo == null,
                    selectedTileColor: _primaryColor.withOpacity(0.05),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onTap: () {
                      setState(() {
                        _selectedChiBo = null;
                      });
                      _filterByChiBo(null);
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 8),
                  // Individual Chi bộ options
                  ..._availableChiBo.map((chiBo) {
                    final toCount = _chiBoToToDanPho[chiBo]?.length ?? 0;
                    final isSelected = _selectedChiBo == chiBo;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _primaryColor.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.group,
                            color: isSelected ? _primaryColor : Colors.grey,
                          ),
                        ),
                        title: Text(
                          chiBo,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text('$toCount tổ dân phố'),
                        trailing: isSelected
                            ? Icon(Icons.check_circle, color: _primaryColor)
                            : null,
                        selected: isSelected,
                        selectedTileColor: _primaryColor.withOpacity(0.05),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onTap: () {
                          setState(() {
                            _selectedChiBo = chiBo;
                          });
                          _filterByChiBo(chiBo);
                          Navigator.pop(context);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bản đồ Ranh giới - Phường 260'),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        actions: [
          // Chi bộ filter button
          if (_availableChiBo.isNotEmpty)
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  tooltip: 'Lọc theo Chi bộ',
                  onPressed: _showChiBoSelector,
                ),
                if (_selectedChiBo != null)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: LatLng(
                _defaultLatitude,
                _defaultLongitude,
              ),
              zoom: _defaultZoom,
            ),
            polygons: _polygons,
            markers: _markers,
            mapType: MapType.normal,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),
          // Search bar
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText:
                        'Tìm tổ hoặc chi bộ... (VD: 1, An Thượng, Đa Mặn)',
                    prefixIcon: Icon(Icons.search, color: _primaryColor),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _isSearching = false);
                            },
                          ),
                        IconButton(
                          icon: Icon(Icons.search, color: _primaryColor),
                          onPressed: () => _searchTo(_searchController.text),
                        ),
                      ],
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  onSubmitted: _searchTo,
                ),
              ),
            ),
          ), // Legend
          Positioned(
            top: 80,
            left: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Chú thích',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.3),
                            border: Border.all(color: Colors.blue, width: 2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('Ranh giới tổ'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tổng: ${_toDanPhoPolygons.length} tổ',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                    // Show selected Chi bộ chip
                    if (_selectedChiBo != null) ...[
                      const SizedBox(height: 8),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.filter_list,
                            size: 14,
                            color: _primaryColor,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Lọc: $_selectedChiBo',
                              style: TextStyle(
                                fontSize: 11,
                                color: _primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedChiBo = null;
                          });
                          _filterByChiBo(null);
                        },
                        icon: const Icon(Icons.clear, size: 14),
                        label: const Text(
                          'Xóa lọc',
                          style: TextStyle(fontSize: 11),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: _primaryColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          // Floating buttons
          Positioned(
            right: 16,
            bottom: 80,
            child: FloatingActionButton(
              heroTag: 'myLocation',
              mini: true,
              backgroundColor: Colors.white,
              elevation: 4,
              onPressed: _goToMyLocation,
              child: Icon(Icons.my_location, color: _primaryColor),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 130,
            child: FloatingActionButton(
              heroTag: 'fitBounds',
              mini: true,
              backgroundColor: Colors.white,
              elevation: 4,
              onPressed: _fitCameraToBounds,
              child: Icon(
                Icons.center_focus_strong,
                color: _primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
