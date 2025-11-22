import '../../domain/entities/weather_entity.dart';

class WeatherModel extends WeatherEntity {
  const WeatherModel({
    required super.cityName,
    required super.temperature,
    required super.condition,
    required super.iconCode,
    required super.minTemp,
    required super.maxTemp,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    try {
      return WeatherModel(
        cityName: json['name']?.toString() ?? 'Unknown',
        temperature: (json['main']?['temp'] as num?)?.toDouble() ?? 0.0,
        condition: json['weather']?[0]?['main']?.toString() ?? 'Unknown',
        iconCode: json['weather']?[0]?['icon']?.toString() ?? '01d',
        minTemp: (json['main']?['temp_min'] as num?)?.toDouble() ?? 0.0,
        maxTemp: (json['main']?['temp_max'] as num?)?.toDouble() ?? 0.0,
      );
    } catch (e) {
      throw Exception('Failed to parse weather data: $e');
    }
  }
}
