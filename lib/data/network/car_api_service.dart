import 'package:chopper/chopper.dart';

part 'car_api_service.chopper.dart';

@ChopperApi(baseUrl: '/cars')
abstract class CarApiService extends ChopperService {
  static CarApiService create([ChopperClient? client]) =>
      _$CarApiService(client);

  @GET()
  Future<Response<dynamic>> getCarsByMake(
    @Query('make') String make,
    @Header('X-Api-Key') String apiKey,
  );
}
