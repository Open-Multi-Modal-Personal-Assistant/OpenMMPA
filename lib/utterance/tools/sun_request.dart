import 'package:dart_helper_utils/dart_helper_utils.dart';

class SunRequest {
  SunRequest(this.latitude, this.longitude, this.date);

  SunRequest.fromJson(Map<String, Object?> jsonObject) {
    latitude = 0.0;
    longitude = 0.0;
    date = DateTime.now();
    switch (jsonObject) {
      case {'latitude': final double lat}:
        latitude = lat;
      case {'longitude': final double lon}:
        longitude = lon;
      case {'date': final String dateString}:
        final parsedDate = dateString.tryToDateAutoFormat();
        if (parsedDate != null) {
          date = parsedDate;
        }
      default:
        throw FormatException('Unhandled SunRequest format', jsonObject);
    }
  }

  late final double latitude;
  late final double longitude;
  late final DateTime date;

  @override
  String toString() => {
        'latitude': latitude,
        'longitude': longitude,
        'date': date.toIso8601String(),
      }.toString();
}
