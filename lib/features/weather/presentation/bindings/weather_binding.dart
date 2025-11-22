import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../../core/networks/api_client.dart';
import '../../data/datasources/weather_remote_data_source.dart';
import '../../data/repositories/weather_repository_impl.dart';
import '../../domain/repositories/weather_repository.dart';
import '../../domain/usecases/get_current_weather_usecase.dart';
import '../controllers/weather_controller.dart';

class WeatherBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => http.Client());
    Get.lazyPut(() => ApiClient(Get.find()));

    Get.lazyPut<WeatherRemoteDataSource>(
      () => WeatherRemoteDataSourceImpl(Get.find()),
    );
    Get.lazyPut<WeatherRepository>(() => WeatherRepositoryImpl(Get.find()));

    // usecase
    Get.lazyPut(() => GetCurrentWeatherUseCase(Get.find()));

    Get.lazyPut(() => WeatherController(getCurrentWeather: Get.find()));
  }
}
