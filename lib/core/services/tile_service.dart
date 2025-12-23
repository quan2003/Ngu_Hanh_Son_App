import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Service để load GeoJSON tiles on-demand theo zoom level và viewport
class TileService {
  final Map<String, Map<String, dynamic>> _tileCache = {};
  Map<String, dynamic>? _tileIndex;
  
  /// Load tile index từ assets
  Future<void> loadTileIndex() async {
    if (_tileIndex != null) return;
    
    try {
      final indexStr = await rootBundle.loadString('assets/maps/tiles/index.json');
      _tileIndex = json.decode(indexStr);
      print('📚 Loaded tile index with ${_tileIndex!.length} tiles');
    } catch (e) {
      print('❌ Error loading tile index: $e');
    }
  }
    /// Tính tile coordinates từ lat/lng và zoom level
  /// Theo Web Mercator projection
  _TileCoordinate _latLngToTile(double lat, double lng, int zoom) {
    final scale = 1 << zoom;
    final x = ((lng + 180.0) / 360.0 * scale).floor();
    final latRad = lat * math.pi / 180.0;
    final y = ((1.0 - (math.log(math.tan(latRad) + (1 / math.cos(latRad))) / math.pi)) / 2.0 * scale).floor();
    return _TileCoordinate(zoom, x, y);
  }
    /// Get tiles cần thiết cho viewport hiện tại
  List<String> getTilesForViewport(
    LatLngBounds bounds,
    double zoom,
  ) {
    if (_tileIndex == null) return [];
    
    // Chọn zoom level phù hợp (làm tròn xuống)
    final tileZoom = zoom.floor().clamp(12, 16);
    
    // Tính tile coordinates cho góc viewport
    final topLeft = _latLngToTile(bounds.northeast.latitude, bounds.southwest.longitude, tileZoom);
    final bottomRight = _latLngToTile(bounds.southwest.latitude, bounds.northeast.longitude, tileZoom);
    
    // Debug: print viewport info
    print('🔍 Viewport: lat ${bounds.southwest.latitude}-${bounds.northeast.latitude}, lng ${bounds.southwest.longitude}-${bounds.northeast.longitude}');
    print('🔍 Tile range: (${ topLeft.x},${topLeft.y}) to (${bottomRight.x},${bottomRight.y}) at zoom $tileZoom');
    
    // Collect tất cả tiles trong viewport từ index
    final tiles = <String>[];
    for (final tileKey in _tileIndex!.keys) {
      // Parse tile key: "zoom/x/y"
      final parts = tileKey.split('/');
      if (parts.length != 3) continue;
      
      final z = int.tryParse(parts[0]);
      final x = int.tryParse(parts[1]);
      final y = int.tryParse(parts[2]);
      
      if (z == null || x == null || y == null) continue;
      if (z != tileZoom) continue;
      
      // Check if tile is in viewport
      if (x >= topLeft.x && x <= bottomRight.x &&
          y >= topLeft.y && y <= bottomRight.y) {
        tiles.add(tileKey);
      }
    }
    
    print('🔍 Found ${tiles.length} tiles in index for viewport');
    return tiles;
  }
  
  /// Load một tile từ assets
  Future<Map<String, dynamic>?> loadTile(String tileKey) async {
    // Check cache
    if (_tileCache.containsKey(tileKey)) {
      return _tileCache[tileKey];
    }
    
    try {
      final tilePath = 'assets/maps/tiles/$tileKey.json';
      final tileStr = await rootBundle.loadString(tilePath);
      final tileData = json.decode(tileStr);
      
      // Cache tile
      _tileCache[tileKey] = tileData;
      
      print('📦 Loaded tile $tileKey with ${tileData['features']?.length ?? 0} features');
      return tileData;
    } catch (e) {
      print('⚠️ Error loading tile $tileKey: $e');
      return null;
    }
  }
  
  /// Load tất cả tiles cho viewport (parallel)
  Future<List<Map<String, dynamic>>> loadTilesForViewport(
    LatLngBounds bounds,
    double zoom,
  ) async {
    if (_tileIndex == null) {
      await loadTileIndex();
    }
    
    final tileKeys = getTilesForViewport(bounds, zoom);
    print('🗺️ Loading ${tileKeys.length} tiles for zoom ${zoom.floor()}');
    
    final futures = tileKeys.map((key) => loadTile(key));
    final tiles = await Future.wait(futures);
    
    return tiles.whereType<Map<String, dynamic>>().toList();
  }
  
  /// Clear cache để free memory
  void clearCache() {
    _tileCache.clear();
    print('🧹 Cleared tile cache');
  }
  
  /// Get thông tin về tile index
  Map<String, dynamic>? getTileInfo(String tileKey) {
    return _tileIndex?[tileKey];
  }
}

class _TileCoordinate {
  final int zoom;
  final int x;
  final int y;
  
  _TileCoordinate(this.zoom, this.x, this.y);
  
  @override
  String toString() => '$zoom/$x/$y';
}
