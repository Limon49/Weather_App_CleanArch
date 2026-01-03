import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import '../../domain/entities/weather_entity.dart';
import '../../domain/usecases/get_current_weather_usecase.dart';
import '../../../../core/errors/failures.dart';

class WeatherController extends GetxController {
  final GetCurrentWeatherUseCase getCurrentWeather;

  WeatherController({required this.getCurrentWeather});

  final Rx<WeatherEntity?> weather = Rx<WeatherEntity?>(null);
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
  }

  Future<void> fetchWeatherForCurrentLocation() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final position = await _determinePosition();
      print('Current Location - Latitude: ${position.latitude}, Longitude: ${position.longitude}');

      final result = await getCurrentWeather(
        GetCurrentWeatherParams(
          latitude: position.latitude,
          longitude: position.longitude,
        ),
      );
      weather.value = result;
    } on LocationFailure catch (f) {
      errorMessage.value = f.message;
    } on Failure catch (f) {
      errorMessage.value = f.message;
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationFailure('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationFailure('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationFailure(
          'Location permissions are permanently denied, enable them in settings.');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 10),
    );
  }
}
