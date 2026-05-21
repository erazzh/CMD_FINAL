import 'package:chopper/chopper.dart';

part 'car_api_service.chopper.dart';

/// Chopper-клиент для каталога машин.
///
/// Базовый URL задаётся при создании [ChopperClient] в провайдере.
/// Пример: https://freetestapi.com/api/v1
///
/// После изменений запусти кодогенерацию:
///   flutter pub run build_runner build --delete-conflicting-outputs
@ChopperApi(baseUrl: '/cars')
abstract class CarApiService extends ChopperService {
  /// Фабричный метод для внедрения в [ChopperClient].
  static CarApiService create([ChopperClient? client]) =>
      _$CarApiService(client);

  /// GET /cars — возвращает список машин.
  @Get()
  Future<Response<dynamic>> getCars();
}
