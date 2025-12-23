// Map screen với markers từ HOAHAI, HOAQUY, KM, MYAN, NHS, TON_GIAO, Y_TE
// Có text labels trên markers (có thể lag nhẹ khi load nhiều markers)

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class AppColors {
  static const primary = Color(0xFFE53935);
  static const chiBoPolygon = Color(0x332196F3);
  static const chiBoStroke = Color(0xFF2196F3);
  static const error = Color(0xFFE53935);
}

class AppConstants {
  static const defaultLatitude = 16.033;
  static const defaultLongitude = 108.241;
  static const defaultZoom = 15.0;
}

class MarkerData {
  final String id;
  final LatLng position;
  final String title;
  final String? subtitle;
  final bool isChiBo;
  final String markerType;
  final MarkerInfo info;

  MarkerData({
    required this.id,
    required this.position,
    required this.title,
    this.subtitle,
    required this.isChiBo,
    required this.markerType,
    required this.info,
  });
}

class MarkerInfo {
  final String? chiBo;
  final String? to;
  final String? canBoPhuTrach;
  final String? canBoPhuTrachPhone;
  final String? biThu;
  final String? biThuPhone;
  final String? toTruong;
  final String? toTruongPhone;
  final Map<String, String> allToTruong;
  final Map<String, String> allToTruongPhones;
  final String rawText;
  final String? name;
  final String? address;

  MarkerInfo({
    this.chiBo,
    this.to,
    this.canBoPhuTrach,
    this.canBoPhuTrachPhone,
    this.biThu,
    this.biThuPhone,
    this.toTruong,
    this.toTruongPhone,
    this.allToTruong = const {},
    this.allToTruongPhones = const {},
    required this.rawText,
    this.name,
    this.address,
  });

  factory MarkerInfo.parse(String text) {
    String? chiBo;
    String? to;
    String? canBoPhuTrach;
    String? canBoPhuTrachPhone;
    String? biThu;
    String? biThuPhone;
    String? toTruong;
    String? toTruongPhone;
    final Map<String, String> allToTruong = {};
    final Map<String, String> allToTruongPhones = {};
    final lines = text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    (String, String?) parseNameAndPhone(String text) {
      final phoneMatch =
          RegExp(r'(.+?)\s*[-–—]\s*([0-9]{10,11})').firstMatch(text);
      if (phoneMatch != null) {
        return (phoneMatch.group(1)!.trim(), phoneMatch.group(2));
      }
      return (text.trim(), null);
    }

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (line.startsWith('Tổ ') && to == null && !line.contains(':')) {
        to = line;
        final match = RegExp(r'Tổ\s+(\d+)').firstMatch(line);
        if (match != null) {
          final toNumber = match.group(1);
          if (allToTruong.containsKey(toNumber)) {
            toTruong = allToTruong[toNumber];
            toTruongPhone = allToTruongPhones[toNumber];
          }
        }
      } else if (line.startsWith('Chi bộ ') && chiBo == null) {
        chiBo = line;
      } else if (line.startsWith('Phụ trách:')) {
        final info = parseNameAndPhone(line.substring('Phụ trách:'.length));
        canBoPhuTrach = info.$1;
        canBoPhuTrachPhone = info.$2;
      } else if (line.startsWith('Bí thư:')) {
        final info = parseNameAndPhone(line.substring('Bí thư:'.length));
        biThu = info.$1;
        biThuPhone = info.$2;
      } else if (line.startsWith('Tổ trưởng:') ||
          line.startsWith('- Tổ trưởng:')) {
        final prefix =
            line.startsWith('- Tổ trưởng:') ? '- Tổ trưởng:' : 'Tổ trưởng:';
        final info = parseNameAndPhone(line.substring(prefix.length));
        toTruong = info.$1;
        toTruongPhone = info.$2;
      } else if (RegExp(r'^Tổ\s+(\d+):\s*Tổ trưởng:').hasMatch(line)) {
        final match =
            RegExp(r'^Tổ\s+(\d+):\s*Tổ trưởng:\s*(.+)$').firstMatch(line);
        if (match != null) {
          final toNumber = match.group(1)!;
          final info = parseNameAndPhone(match.group(2)!);
          allToTruong[toNumber] = info.$1;
          if (info.$2 != null) {
            allToTruongPhones[toNumber] = info.$2!;
          }
        }
      }
    }

    return MarkerInfo(
      rawText: text,
      chiBo: chiBo,
      to: to,
      canBoPhuTrach: canBoPhuTrach,
      canBoPhuTrachPhone: canBoPhuTrachPhone,
      biThu: biThu,
      biThuPhone: biThuPhone,
      toTruong: toTruong,
      toTruongPhone: toTruongPhone,
      allToTruong: allToTruong,
      allToTruongPhones: allToTruongPhones,
    );
  }
  String get displayTitle {
    // Prioritize name for special markers (Y tế, Công viên, Giáo dục, Tôn giáo)
    if (name != null && name!.isNotEmpty) return name!;
    if (chiBo != null) return chiBo!;
    if (to != null) return to!;
    return rawText.split('\n').first;
  }

  String? get displaySubtitle {
    // Show address for special markers
    if (name != null &&
        name!.isNotEmpty &&
        address != null &&
        address!.isNotEmpty) {
      return address;
    }
    if (chiBo != null && biThu != null) {
      return 'Bí thư: $biThu';
    }
    if (to != null && toTruong != null) {
      return 'Tổ trưởng: $toTruong';
    }
    if (chiBo != null && canBoPhuTrach != null) {
      return 'Phụ trách: $canBoPhuTrach';
    }
    return null;
  }

  bool get hasDetailedInfo =>
      canBoPhuTrach != null ||
      biThu != null ||
      toTruong != null ||
      allToTruong.isNotEmpty;
  bool get isChiBo => chiBo != null;
  bool get isToDanPho => to != null && chiBo == null;
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  final List<String> _areas = ['TẤT CẢ', 'HOAHAI', 'HOAQUY', 'KM', 'MYAN'];
  String _selectedArea = 'TẤT CẢ';

  // Marker data storage
  final List<MarkerData> _allMarkerData = [];
  Set<Marker> _visibleMarkers = {};
  bool _isLoading = false;

  // Icon cache - KEY OPTIMIZATION!
  final Map<String, BitmapDescriptor> _iconCache = {};

  // Viewport filtering
  LatLngBounds? _currentViewport;
  Timer? _updateMarkersTimer;
  // Search
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  final List<MarkerData> _searchResults = [];
  // Filter - Ban đầu rỗng, người dùng tự chọn
  final Set<String> _selectedMarkerTypes = {};
  final List<String> _markerTypes = [
    'SHCĐ',
    'Chi bộ',
    'Tổ dân phố',
    'Nhà văn hóa',
    'Tôn giáo',
    'Y tế',
    'Công viên',
    'Giáo dục'
  ];

  MarkerInfo? _selectedMarkerInfo;
  LatLng? _selectedMarkerPosition;
  bool _isBottomSheetExpanded = false;

  /// Create marker icon with emoji/icon for each type
  /// 🎨 EASY TO SEE icons on phone with distinct colors
  Future<BitmapDescriptor> _createMarkerIcon(String markerType) async {
    // Check cache first
    if (_iconCache.containsKey(markerType)) {
      return _iconCache[markerType]!;
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = 72.0; // Tăng từ 48 lên 72 cho dễ nhìn trên mobile

    // Get color and emoji for each type
    final config = _getMarkerConfig(markerType);

    // Draw circle background
    final paint = Paint()
      ..color = config.color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2 - 2, paint);

    // Draw white border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4; // Tăng border từ 3 lên 4
    canvas.drawCircle(
        const Offset(size / 2, size / 2), size / 2 - 2, borderPaint);

    // Draw icon/emoji in center
    final textPainter = TextPainter(
      text: TextSpan(
        text: config.emoji,
        style: const TextStyle(
          fontSize: 36, // Tăng từ 24 lên 36
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size - textPainter.width) / 2,
        (size - textPainter.height) / 2,
      ),
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final icon = BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());

    // Cache it
    _iconCache[markerType] = icon;

    return icon;
  }

  /// Get marker configuration (color + emoji) for each type
  ({Color color, String emoji}) _getMarkerConfig(String markerType) {
    switch (markerType) {
      case 'Y tế':
        return (color: const Color(0xFF4CAF50), emoji: '🏥'); // Green
      case 'Tôn giáo':
        return (color: const Color(0xFF9C27B0), emoji: '⛪'); // Purple
      case 'SHCĐ':
        return (color: const Color(0xFFF44336), emoji: '🏛️'); // Red
      case 'Nhà văn hóa':
        return (color: const Color(0xFF2196F3), emoji: '🏛️'); // Blue
      case 'Chi bộ':
        return (color: const Color(0xFFFF9800), emoji: '🚩'); // Orange
      case 'Tổ dân phố':
        return (color: const Color(0xFF00BCD4), emoji: '🏘️'); // Cyan
      case 'Công viên':
        return (color: const Color(0xFF8BC34A), emoji: '🌳'); // Light Green
      case 'Giáo dục':
        return (color: const Color(0xFFFFEB3B), emoji: '🎓'); // Yellow
      default:
        return (color: const Color(0xFF9E9E9E), emoji: '📍'); // Grey
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _searchController.dispose();
    _updateMarkersTimer?.cancel();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) async {
    _mapController = controller;
    await _loadAreaData(_selectedArea);
  }

  Future<void> _loadAreaData(String area) async {
    setState(() {
      _isLoading = true;
      _allMarkerData.clear();
      _visibleMarkers.clear();
      _searchController.clear();
      _isSearching = false;
    });
    try {
      final List<String> areasToLoad = area == 'TẤT CẢ'
          ? [
              'HOAHAI',
              'HOAQUY',
              'KM',
              'MYAN',
              'NHS',
              'TON_GIAO',
              'Y_TE',
              'CONG_VIEN',
              'GIAO_DUC'
            ]
          : [area];

      double? minLat, maxLat, minLng, maxLng;

      void extendBounds(LatLng p) {
        minLat = (minLat == null) ? p.latitude : math.min(minLat!, p.latitude);
        maxLat = (maxLat == null) ? p.latitude : math.max(maxLat!, p.latitude);
        minLng =
            (minLng == null) ? p.longitude : math.min(minLng!, p.longitude);
        maxLng =
            (maxLng == null) ? p.longitude : math.max(maxLng!, p.longitude);
      }

      int markerIndex = 0;
      for (final currentArea in areasToLoad) {
        String filename;
        if (currentArea == 'NHS') {
          filename = 'nha_sinh_hoat';
        } else if (currentArea == 'TON_GIAO') {
          filename = 'ton_giao';
        } else if (currentArea == 'Y_TE') {
          filename = 'y_te';
        } else if (currentArea == 'CONG_VIEN') {
          filename = 'cong_vien';
        } else if (currentArea == 'GIAO_DUC') {
          filename = 'giao_duc';
        } else {
          filename = currentArea;
        }

        final pointGeojson = await DefaultAssetBundle.of(context)
            .loadString('assets/maps/$filename.geojson');
        final Map<String, dynamic> pointData =
            Map<String, dynamic>.from(jsonDecode(pointGeojson));
        final List features = (pointData['features'] as List?) ?? [];

        for (final f in features) {
          final fm = f as Map;
          final geom = fm['geometry'] as Map?;
          if (geom == null) continue;

          final props = (fm['properties'] as Map?) ?? {};

          if (geom['type'] == 'Point') {
            final c = geom['coordinates'];
            if (c is List && c.length >= 2) {
              final lng = (c[0] as num).toDouble();
              final lat = (c[1] as num).toDouble();
              final p = LatLng(lat, lng);

              if (p.latitude < 15.5 ||
                  p.latitude > 16.5 ||
                  p.longitude < 107.5 ||
                  p.longitude > 109.0) {
                continue;
              }
              extendBounds(p);

              final textUtf8 =
                  (props['Text_utf8'] ?? props['Text'] ?? '').toString();
              final name = (props['name'] ?? '').toString();
              final address = (props['address'] ?? '').toString();
              final displayText = name.isNotEmpty ? name : textUtf8;

              if (displayText.isEmpty) continue;
              final isSpecialArea = (currentArea == 'NHS' ||
                      currentArea == 'TON_GIAO' ||
                      currentArea == 'Y_TE' ||
                      currentArea == 'CONG_VIEN' ||
                      currentArea == 'GIAO_DUC') &&
                  name.isNotEmpty;

              final markerInfo = isSpecialArea
                  ? MarkerInfo(
                      rawText: displayText,
                      name: name,
                      address: address.isNotEmpty ? address : null,
                    )
                  : MarkerInfo.parse(displayText);

              final layer = (props['Layer'] ?? '').toString().toLowerCase();
              final isToDanPho = layer == 'todanpho' ||
                  layer == 'tổ mới 2017' ||
                  layer.contains('tổ dân phố') ||
                  layer.contains('to dan pho') ||
                  layer == '0' ||
                  layer.contains('tên đường') ||
                  layer.contains('ten duong') ||
                  (layer != 'chibo' &&
                      displayText.toLowerCase().startsWith('tổ '));

              String markerType = 'Chi bộ';
              if (currentArea == 'NHS') {
                final nameLower = displayText.toLowerCase();
                if (nameLower.contains('nhà shcđ') ||
                    nameLower.contains('shcđ')) {
                  markerType = 'SHCĐ';
                } else if (nameLower.contains('nhà văn hóa') ||
                    nameLower.contains('văn hóa')) {
                  markerType = 'Nhà văn hóa';
                } else if (nameLower.contains('chi bộ')) {
                  markerType = 'Chi bộ';
                }
              } else if (currentArea == 'TON_GIAO') {
                markerType = 'Tôn giáo';
              } else if (currentArea == 'Y_TE') {
                markerType = 'Y tế';
              } else if (currentArea == 'CONG_VIEN') {
                markerType = 'Công viên';
              } else if (currentArea == 'GIAO_DUC') {
                markerType = 'Giáo dục';
              } else {
                markerType = isToDanPho ? 'Tổ dân phố' : 'Chi bộ';
              }

              if (!_selectedMarkerTypes.contains(markerType)) {
                continue;
              }
              final isSpecialMarker = currentArea == 'NHS' ||
                  currentArea == 'TON_GIAO' ||
                  currentArea == 'Y_TE' ||
                  currentArea == 'CONG_VIEN' ||
                  currentArea == 'GIAO_DUC';
              final isChiBo = isSpecialMarker || !isToDanPho;

              if (!isToDanPho &&
                  !markerInfo.hasDetailedInfo &&
                  !isSpecialMarker) {
                continue;
              }

              String infoTitle = displayText;
              String? infoSnippet;

              if (!isToDanPho && markerInfo.hasDetailedInfo) {
                infoTitle = markerInfo.displayTitle;
                if (markerInfo.isChiBo && markerInfo.biThu != null) {
                  infoSnippet = 'BT: ${markerInfo.biThu}';
                  if (markerInfo.biThuPhone != null) {
                    infoSnippet += ' - ${markerInfo.biThuPhone}';
                  }
                } else if (markerInfo.toTruong != null) {
                  infoSnippet = 'TT: ${markerInfo.toTruong}';
                  if (markerInfo.toTruongPhone != null) {
                    infoSnippet += ' - ${markerInfo.toTruongPhone}';
                  }
                }
              } else if (address.isNotEmpty) {
                infoSnippet = address;
              }

              final markerId = '${currentArea}_marker_$markerIndex';

              // Store marker data for lazy rendering
              _allMarkerData.add(MarkerData(
                id: markerId,
                position: p,
                title: infoTitle,
                subtitle: infoSnippet,
                isChiBo: isChiBo,
                markerType: markerType,
                info: markerInfo,
              ));

              markerIndex++;
            }
          }
        }
      }

      // Initial render - chỉ hiển thị markers trong viewport
      _updateVisibleMarkers();

      if (minLat != null &&
          maxLat != null &&
          minLng != null &&
          maxLng != null) {
        const paddingDegrees = 0.002;
        final bounds = LatLngBounds(
          southwest: LatLng(minLat! - paddingDegrees, minLng! - paddingDegrees),
          northeast: LatLng(maxLat! + paddingDegrees, maxLng! + paddingDegrees),
        );

        if (_mapController != null) {
          await _mapController!.animateCamera(
            CameraUpdate.newLatLngBounds(bounds, 50),
          );
        }
      }
    } catch (e) {
      debugPrint('Error loading area data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // KEY OPTIMIZATION: Only show markers in viewport
  void _updateVisibleMarkers() async {
    if (_mapController == null) return;

    try {
      final bounds = await _mapController!.getVisibleRegion();
      _currentViewport = bounds;

      final visibleData = _allMarkerData.where((data) {
        return _isInBounds(data.position, bounds);
      }).toList();

      // Limit markers based on zoom level
      final zoom = await _mapController!.getZoomLevel();
      final maxMarkers = _getMaxMarkersForZoom(zoom);

      if (visibleData.length > maxMarkers) {
        // Sample markers evenly
        final step = visibleData.length / maxMarkers;
        final sampled = <MarkerData>[];
        for (var i = 0; i < maxMarkers; i++) {
          sampled.add(visibleData[(i * step).floor()]);
        }
        visibleData.clear();
        visibleData.addAll(sampled);
      }
      final newMarkers = <Marker>{};
      for (final data in visibleData) {
        // Create icon based on marker type (Y tế, Tôn giáo, SHCĐ, etc.)
        final icon = await _createMarkerIcon(data.markerType);
        newMarkers.add(
          Marker(
            markerId: MarkerId(data.id),
            position: data.position,
            icon: icon,
            anchor: const Offset(0.5, 0.5),
            infoWindow: InfoWindow(
              title: data.title,
              snippet: data.subtitle,
            ),
            onTap: () {
              debugPrint('🎯 Marker tapped: ${data.title}');
              debugPrint(
                  '📍 Position: ${data.position.latitude}, ${data.position.longitude}');
              debugPrint('🏷️ Type: ${data.markerType}');
              setState(() {
                _selectedMarkerInfo = data.info;
                _selectedMarkerPosition = data.position;
                _isBottomSheetExpanded = false;
              });
            },
          ),
        );
      }

      setState(() {
        _visibleMarkers = newMarkers;
      });
    } catch (e) {
      debugPrint('Error updating visible markers: $e');
    }
  }

  bool _isInBounds(LatLng position, LatLngBounds bounds) {
    return position.latitude >= bounds.southwest.latitude &&
        position.latitude <= bounds.northeast.latitude &&
        position.longitude >= bounds.southwest.longitude &&
        position.longitude <= bounds.northeast.longitude;
  }

  int _getMaxMarkersForZoom(double zoom) {
    if (zoom < 12) return 50;
    if (zoom < 14) return 100;
    if (zoom < 16) return 200;
    return 500;
  }

  void _onCameraMove(CameraPosition position) {
    // Không update markers khi đang search - giữ nguyên search results
    if (_isSearching) {
      return;
    }

    // Debounce: delay update để tránh render liên tục khi pan/zoom
    _updateMarkersTimer?.cancel();
    _updateMarkersTimer = Timer(const Duration(milliseconds: 500), () {
      _updateVisibleMarkers();
    });
  }

  void _searchMarkers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults.clear();
      });
      // Reload normal markers when search is cleared
      _updateVisibleMarkers();
      return;
    }

    final lowerQuery = query.toLowerCase();
    final results = _allMarkerData.where((data) {
      return data.title.toLowerCase().contains(lowerQuery) ||
          (data.subtitle?.toLowerCase().contains(lowerQuery) ?? false) ||
          data.info.rawText.toLowerCase().contains(lowerQuery);
    }).toList();

    setState(() {
      _isSearching = true;
      _searchResults.clear();
      _searchResults.addAll(results);
    });

    // Show ALL search results as markers (không giới hạn viewport)
    final searchMarkers = <Marker>{};
    for (final data in results) {
      // Use correct icon based on marker type
      final icon = await _createMarkerIcon(data.markerType);
      searchMarkers.add(
        Marker(
          markerId: MarkerId(data.id),
          position: data.position,
          icon: icon,
          infoWindow: InfoWindow(
            title: data.title,
            snippet: data.subtitle,
          ),
          onTap: () {
            debugPrint('🔍 Search result tapped: ${data.title}');
            debugPrint(
                '📍 Position: ${data.position.latitude}, ${data.position.longitude}');
            debugPrint('🏷️ Type: ${data.markerType}');
            setState(() {
              _selectedMarkerInfo = data.info;
              _selectedMarkerPosition = data.position;
            });
            _mapController?.animateCamera(
              CameraUpdate.newLatLngZoom(data.position, 17),
            );
          },
        ),
      );
    }

    setState(() {
      _visibleMarkers = searchMarkers;
    });
  }

  /// Show filter bottom sheet
  void _showFilterBottomSheet() {
    // Tạo bản sao tạm thời để người dùng có thể thay đổi trước khi áp dụng
    final tempSelectedTypes = Set<String>.from(_selectedMarkerTypes);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.filter_list,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Lọc loại điểm',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Quick action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setModalState(() {
                            tempSelectedTypes.clear();
                            tempSelectedTypes.addAll(_markerTypes);
                          });
                        },
                        icon: const Icon(Icons.check_circle, size: 18),
                        label: const Text('Chọn tất cả'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setModalState(() {
                            tempSelectedTypes.clear();
                          });
                        },
                        icon: const Icon(Icons.cancel, size: 18),
                        label: const Text('Bỏ chọn'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[700],
                          side: BorderSide(color: Colors.grey[400]!),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 4),
                // List of checkboxes
                ..._markerTypes.map((type) {
                  final config = _getMarkerConfig(type);
                  final isSelected = tempSelectedTypes.contains(type);
                  return CheckboxListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                    visualDensity: VisualDensity.compact,
                    secondary: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: config.color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          config.emoji,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                    title: Text(type),
                    value: isSelected,
                    activeColor: AppColors.primary,
                    onChanged: (bool? value) {
                      setModalState(() {
                        if (value == true) {
                          tempSelectedTypes.add(type);
                        } else {
                          tempSelectedTypes.remove(type);
                        }
                      });
                    },
                  );
                }),
                const SizedBox(height: 16),
                // Apply button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedMarkerTypes.clear();
                        _selectedMarkerTypes.addAll(tempSelectedTypes);
                      });
                      Navigator.pop(context);
                      _loadAreaData(_selectedArea);
                    },
                    icon: const Icon(Icons.check),
                    label: Text('Áp dụng (${tempSelectedTypes.length})'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMarkerInfoSheet() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isBottomSheetExpanded = !_isBottomSheetExpanded;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: _isBottomSheetExpanded ? 400 : 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.location_on,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedMarkerInfo!.displayTitle,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_selectedMarkerInfo!.displaySubtitle != null)
                                Text(
                                  _selectedMarkerInfo!.displaySubtitle!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              _selectedMarkerInfo = null;
                              _selectedMarkerPosition = null;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16), // Details
                    // Show name if available (for Y tế, Công viên, Giáo dục, etc.)
                    if (_selectedMarkerInfo!.name != null &&
                        _selectedMarkerInfo!.name!.isNotEmpty) ...[
                      _buildInfoRow(Icons.business, 'Tên cơ sở',
                          _selectedMarkerInfo!.name!),
                      const SizedBox(height: 12),
                    ],
                    if (_selectedMarkerInfo!.address != null &&
                        _selectedMarkerInfo!.address!.isNotEmpty) ...[
                      _buildInfoRow(Icons.location_city, 'Địa chỉ',
                          _selectedMarkerInfo!.address!),
                      const SizedBox(height: 12),
                    ],
                    // Chi bộ info
                    if (_selectedMarkerInfo!.chiBo != null) ...[
                      _buildInfoRow(
                          Icons.group, 'Chi bộ', _selectedMarkerInfo!.chiBo!),
                      const SizedBox(height: 12),
                    ],
                    if (_selectedMarkerInfo!.biThu != null) ...[
                      _buildInfoRow(
                          Icons.person, 'Bí thư', _selectedMarkerInfo!.biThu!),
                      if (_selectedMarkerInfo!.biThuPhone != null)
                        _buildInfoRow(Icons.phone, 'SĐT',
                            _selectedMarkerInfo!.biThuPhone!),
                      const SizedBox(height: 12),
                    ],
                    if (_selectedMarkerInfo!.toTruong != null) ...[
                      _buildInfoRow(Icons.person_outline, 'Tổ trưởng',
                          _selectedMarkerInfo!.toTruong!),
                      if (_selectedMarkerInfo!.toTruongPhone != null)
                        _buildInfoRow(Icons.phone, 'SĐT',
                            _selectedMarkerInfo!.toTruongPhone!),
                      const SizedBox(height: 12),
                    ],

                    // Direction button
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _openGoogleMapsDirections,
                        icon: const Icon(Icons.directions),
                        label: const Text('Chỉ đường'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 2),
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

  void _openGoogleMapsDirections() async {
    if (_selectedMarkerPosition == null) return;

    final lat = _selectedMarkerPosition!.latitude;
    final lng = _selectedMarkerPosition!.longitude;

    // Debug log to verify coordinates
    debugPrint(
        '🗺️ Opening directions to: ${_selectedMarkerInfo?.displayTitle}');
    debugPrint('📍 Coordinates: $lat, $lng');

    final url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể mở Google Maps'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Bản đồ', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                value: _selectedArea,
                dropdownColor: AppColors.primary,
                underline: const SizedBox(),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                items: _areas.map((String area) {
                  return DropdownMenuItem<String>(
                    value: area,
                    child: Text(area),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    _selectedArea = v;
                    _selectedMarkerInfo = null;
                    _selectedMarkerPosition = null;
                  });
                  _loadAreaData(v);
                },
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: LatLng(
                  AppConstants.defaultLatitude, AppConstants.defaultLongitude),
              zoom: AppConstants.defaultZoom,
            ),
            markers: _visibleMarkers,
            mapType: MapType.normal,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onCameraMove: _onCameraMove, // KEY: Update markers on pan/zoom
            onTap: (_) {
              setState(() {
                _selectedMarkerInfo = null;
                _selectedMarkerPosition = null;
              });
            },
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
                  decoration: InputDecoration(
                    hintText: 'Tìm chi bộ, tổ, tên người...',
                    prefixIcon:
                        const Icon(Icons.search, color: AppColors.primary),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              _searchMarkers('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  onChanged: _searchMarkers,
                ),
              ),
            ),
          ), // Legend - Chú thích dạng cột dọc
          Positioned(
            top: 80,
            left: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 160),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Chú thích',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 11)),
                    const SizedBox(height: 6),
                    // Hiển thị các icon đang được chọn theo dạng cột
                    ..._selectedMarkerTypes.map((type) {
                      final config = _getMarkerConfig(type);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: config.color,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 1),
                              ),
                              child: Center(
                                child: Text(config.emoji,
                                    style: const TextStyle(fontSize: 8)),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(type,
                                  style: const TextStyle(fontSize: 10),
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),

          // Filter button - nút lọc nổi
          Positioned(
            top: 80,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              elevation: 4,
              onPressed: _showFilterBottomSheet,
              child: const Icon(Icons.filter_list),
            ),
          ), // Stats badge
          Positioned(
            bottom: 16,
            left: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(
                  'Hiển thị: ${_visibleMarkers.length}/${_allMarkerData.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          // Bottom sheet for selected marker
          if (_selectedMarkerInfo != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildMarkerInfoSheet(),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () async {
          try {
            final position = await Geolocator.getCurrentPosition();
            _mapController?.animateCamera(
              CameraUpdate.newLatLngZoom(
                LatLng(position.latitude, position.longitude),
                16,
              ),
            );
          } catch (e) {
            debugPrint('Error getting location: $e');
          }
        },
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
