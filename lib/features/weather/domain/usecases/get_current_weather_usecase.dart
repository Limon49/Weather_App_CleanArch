import '../../../../core/usecases/usecase.dart';
import '../entities/weather_entity.dart';
import '../repositories/weather_repository.dart';

class GetCurrentWeatherParams {
  final double latitude;
  final double longitude;

  GetCurrentWeatherParams({required this.latitude, required this.longitude});
}

class GetCurrentWeatherUseCase
    implements UseCase<WeatherEntity, GetCurrentWeatherParams> {
  final WeatherRepository repository;

  GetCurrentWeatherUseCase(this.repository);

  @override
  Future<WeatherEntity> call(GetCurrentWeatherParams params) {
    return repository.getCurrentWeather(
      latitude: params.latitude,
      longitude: params.longitude,
    );
  }
}
