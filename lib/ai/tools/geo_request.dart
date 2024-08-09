import 'package:dart_helper_utils/dart_helper_utils.dart';

class GeoRequest {
  GeoRequest(this.latitude, this.longitude, this.date);

  GeoRequest.fromJson(Map<String, Object?> jsonObject) {
    for (final mapEntry in jsonObject.entries) {
      switch (mapEntry.key) {
        case 'latitude':
          final lat = mapEntry.value as double?;
          if (lat != null) {
            latitude = lat;
          }
        case 'longitude':
          final lon = mapEntry.value as double?;
          if (lon != null) {
            longitude = lon;
          }
        case 'date':
          final dateString = mapEntry.value as String?;
          final parsedDate = dateString.tryToDateAutoFormat();
          if (parsedDate != null) {
            date = parsedDate;
          }
        default:
          throw FormatException('Unhandled SunRequest format', jsonObject);
      }
    }
  }

  double latitude = 0;
  double longitude = 0;
  DateTime date = DateTime.now();

  @override
  String toString() => {
        'latitude': latitude,
        'longitude': longitude,
        'date': date.toIso8601String(),
      }.toString();
}
