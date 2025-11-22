import '../../../../core/errors/failures.dart';
import '../../domain/entities/weather_entity.dart';
import '../../domain/repositories/weather_repository.dart';
import '../datasources/weather_remote_data_source.dart';

class WeatherRepositoryImpl implements WeatherRepository {
  final WeatherRemoteDataSource remoteDataSource;

  WeatherRepositoryImpl(this.remoteDataSource);

  @override
  Future<WeatherEntity> getCurrentWeather({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final model = await remoteDataSource.getCurrentWeather(
        latitude: latitude,
        longitude: longitude,
      );
      return model;
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
