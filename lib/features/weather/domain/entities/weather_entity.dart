class WeatherEntity {
  final String cityName;
  final double temperature;
  final String condition;
  final String iconCode;
  final double minTemp;
  final double maxTemp;

  const WeatherEntity({
    required this.cityName,
    required this.temperature,
    required this.condition,
    required this.iconCode,
    required this.minTemp,
    required this.maxTemp,
  });
}
