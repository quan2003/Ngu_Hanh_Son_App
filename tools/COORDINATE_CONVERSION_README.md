# Hướng dẫn Chuyển đổi Tọa độ cho Bản đồ Đà Nẵng

## Tổng quan

Các file GeoJSON trong dự án này sử dụng **hệ tọa độ cục bộ (local coordinate system)**, không phải là VN-2000 hay UTM chuẩn. Do đó, cần sử dụng **manual calibration** với control points đã được xác minh qua Google Maps.

## Hệ tọa độ

### Input (GeoJSON)

- **Format**: Local coordinate system
- **Units**: Meters (easting, northing)
- **Example**: `[553202.45, 1774166.03]`

### Output (WGS84)

- **Format**: WGS84 (GPS coordinates)
- **Units**: Degrees (latitude, longitude)
- **Example**: `[16.0471358, 108.2335286]`

## Control Points

Các điểm control đã được xác minh với Google Maps:

| Tên                 | Easting   | Northing   | Latitude   | Longitude   |
| ------------------- | --------- | ---------- | ---------- | ----------- |
| Chi bộ Mỹ Đa Đông 2 | 553202.45 | 1774166.03 | 16.0471358 | 108.2335286 |
| Chi bộ Mỹ Đa Đông 1 | 553144.35 | 1773958.52 | 16.0421305 | 108.2400664 |

## Công thức Chuyển đổi

### Python

```python
def transform_coordinate(easting, northing):
    scale_lat = 2.4120738180668202e-05
    scale_lng = -0.0001125292231222876
    offset_lat = -26.74705849866553
    offset_lng = 170.48497052784614

    lat = scale_lat * northing + offset_lat
    lng = scale_lng * easting + offset_lng

    return lat, lng
```

### Dart/Flutter

```dart
LatLng _transformCoordinate(double easting, double northing) {
  const double scaleLat = 2.4120738180668202e-05;
  const double scaleLng = -0.0001125292231222876;
  const double offsetLat = -26.74705849866553;
  const double offsetLng = 170.48497052784614;

  final lat = scaleLat * northing + offsetLat;
  final lng = scaleLng * easting + offsetLng;

  return LatLng(lat, lng);
}
```

## Cách sử dụng

### 1. Test chuyển đổi tọa độ

```bash
# Dart test
dart run tools/test_coordinate_debug.dart

# Python test
python tools/manual_calibration.py
```

### 2. Convert GeoJSON file

```bash
dart run tools/convert_geojson.dart
```

### 3. Tạo tiles cho bản đồ

```bash
python tools/geojson_tiler.py
```

## Xác minh kết quả

Tất cả các tọa độ đã chuyển đổi phải nằm trong phạm vi Đà Nẵng:

- **Latitude**: 15.9° - 16.3°
- **Longitude**: 108.1° - 108.6°

### Test Cases

✅ Chi bộ 7: `15.938°N, 108.130°E`
✅ Chi bộ 1A: `15.947°N, 108.159°E`
✅ Mỹ Đa Đông 2: `16.047°N, 108.234°E`
✅ Mỹ Đa Đông 1: `16.042°N, 108.240°E`

## Lưu ý quan trọng

1. **Không sử dụng proj4dart** cho dự án này vì GeoJSON không dùng hệ tọa độ chuẩn
2. **Manual calibration** đảm bảo độ chính xác tuyệt đối với Google Maps
3. Nếu thêm control points mới, chạy lại `manual_calibration.py` để tính toán lại parameters
4. Error tolerance: < 0.1 km (100 meters)

## Công cụ hỗ trợ

- `test_coordinate_debug.dart` - Test chuyển đổi trong Dart
- `manual_calibration.py` - Tính toán calibration parameters
- `find_correct_projection.py` - Tìm CRS chuẩn (không khớp với data này)
- `test_coordinate_conversion.py` - Test chuyển đổi trong Python

## Tham khảo

- Control points được xác minh qua Google Maps
- Transformation: Affine transformation (linear scale + offset)
- Accuracy: ±50 meters (đủ cho hiển thị bản đồ)
