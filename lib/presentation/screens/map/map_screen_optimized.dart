// OPTIMIZED VERSION - Reduced lag by:
// 1. Caching marker icons (không tạo lại mỗi lần)
// 2. Simplified marker rendering (icon đơn giản hơn)
// 3. Viewport-based filtering (chỉ hiển thị markers trong view)
// 4. Debounced updates (giảm render khi zoom/pan)

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

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
    if (chiBo != null) return chiBo!;
    if (to != null) return to!;
    return rawText.split('\n').first;
  }

  String? get displaySubtitle {
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

class MapScreenOptimized extends StatefulWidget {
  const MapScreenOptimized({super.key});

  @override
  State<MapScreenOptimized> createState() => _MapScreenOptimizedState();
}

class _MapScreenOptimizedState extends State<MapScreenOptimized> {
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

  // Filter
  final Set<String> _selectedMarkerTypes = {
    'SHCĐ',
    'Chi bộ',
    'Tổ dân phố',
    'Nhà văn hóa',
    'Tôn giáo',
    'Y tế'
  };
  final List<String> _markerTypes = [
    'SHCĐ',
    'Chi bộ',
    'Tổ dân phố',
    'Nhà văn hóa',
    'Tôn giáo',
    'Y tế'
  ];

  MarkerInfo? _selectedMarkerInfo;
  LatLng? _selectedMarkerPosition;
  bool _isBottomSheetExpanded = false;

  // Simplify: chỉ có 2 loại icon (chi bộ và tổ dân phố)
  Future<void> _initializeIcons() async {
    if (_iconCache.isNotEmpty) return;

    // Tạo 2 icon đơn giản thay vì custom với text
    _iconCache['chibo'] = await _createSimpleMarkerIcon(
      const Color(0xFFEA4335), // Red
    );
    _iconCache['todanpho'] = await _createSimpleMarkerIcon(
      const Color(0xFF34A853), // Green
    );
  }

  Future<BitmapDescriptor> _createSimpleMarkerIcon(Color color) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final size = 48.0;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Simple pin shape
    canvas.drawCircle(Offset(size / 2, size / 2), size / 3, paint);

    // Triangle pointer
    final path = Path();
    path.moveTo(size / 2 - size / 6, size / 2 + size / 6);
    path.lineTo(size / 2, size);
    path.lineTo(size / 2 + size / 6, size / 2 + size / 6);
    path.close();
    canvas.drawPath(path, paint);

    // White center
    final centerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 8, centerPaint);

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), (size * 1.2).toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  @override
  void initState() {
    super.initState();
    _initializeIcons();
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
      await _initializeIcons(); // Ensure icons are ready

      final List<String> areasToLoad = area == 'TẤT CẢ'
          ? ['HOAHAI', 'HOAQUY', 'KM', 'MYAN', 'NHS', 'TON_GIAO', 'Y_TE']
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
                      currentArea == 'Y_TE') &&
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
              } else {
                markerType = isToDanPho ? 'Tổ dân phố' : 'Chi bộ';
              }

              if (!_selectedMarkerTypes.contains(markerType)) {
                continue;
              }

              final isSpecialMarker = currentArea == 'NHS' ||
                  currentArea == 'TON_GIAO' ||
                  currentArea == 'Y_TE';
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
        final iconKey = data.isChiBo ? 'chibo' : 'todanpho';
        final icon = _iconCache[iconKey] ?? BitmapDescriptor.defaultMarker;

        newMarkers.add(
          Marker(
            markerId: MarkerId(data.id),
            position: data.position,
            icon: icon,
            infoWindow: InfoWindow(
              title: data.title,
              snippet: data.subtitle,
            ),
            onTap: () {
              setState(() {
                _selectedMarkerInfo = data.info;
                _selectedMarkerPosition = data.position;
                _isBottomSheetExpanded = false;
              });
              _mapController?.animateCamera(
                CameraUpdate.newLatLngZoom(data.position, 17),
              );
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
    // Debounce: delay update để tránh render liên tục khi pan/zoom
    _updateMarkersTimer?.cancel();
    _updateMarkersTimer = Timer(const Duration(milliseconds: 500), () {
      _updateVisibleMarkers();
    });
  }

  void _searchMarkers(String query) {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults.clear();
      });
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

    // Show search results as markers
    final searchMarkers = <Marker>{};
    for (final data in results) {
      final iconKey = data.isChiBo ? 'chibo' : 'todanpho';
      final icon = _iconCache[iconKey] ?? BitmapDescriptor.defaultMarker;

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

  Widget _buildFilterCheckbox(String type) {
    return CheckboxListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      title: Text(type, style: const TextStyle(fontSize: 12)),
      value: _selectedMarkerTypes.contains(type),
      onChanged: (bool? value) {
        setState(() {
          if (value == true) {
            _selectedMarkerTypes.add(type);
          } else {
            _selectedMarkerTypes.remove(type);
          }
        });
        _loadAreaData(_selectedArea);
      },
      activeColor: AppColors.primary,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bản đồ (Tối ưu)',
            style: TextStyle(fontWeight: FontWeight.bold)),
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
          ),
          // Legend and Filter card
          Positioned(
            top: 80,
            left: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 200),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.filter_list,
                            size: 18, color: AppColors.primary),
                        const SizedBox(width: 6),
                        const Text('Lọc loại điểm',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ..._markerTypes.map((type) => _buildFilterCheckbox(type)),
                  ],
                ),
              ),
            ),
          ),
          // Stats badge
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
