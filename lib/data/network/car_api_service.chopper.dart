// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'car_api_service.dart';

// **************************************************************************
// ChopperGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
final class _$CarApiService extends CarApiService {
  _$CarApiService([ChopperClient? client]) {
    if (client == null) return;
    this.client = client;
  }

  @override
  final Type definitionType = CarApiService;

  @override
  Future<Response<dynamic>> getCarsByMake(String make, String apiKey) {
    final Uri $url = Uri.parse('/cars');
    final Map<String, dynamic> $params = <String, dynamic>{
      'make': make,
    };
    final Map<String, String> $headers = <String, String>{'X-Api-Key': apiKey};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      headers: $headers,
    );
    return client.send<dynamic, dynamic>($request);
  }
}
