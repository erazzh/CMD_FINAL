// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

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
  Future<Response<dynamic>> getCars() {
    final Uri $url = Uri.parse('/cars');
    final Request $request = Request('GET', $url, client.baseUrl);
    return client.send<dynamic, dynamic>($request);
  }
}
