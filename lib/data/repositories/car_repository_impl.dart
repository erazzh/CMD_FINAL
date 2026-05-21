import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;

import '../../domain/entities/car_entity.dart';
import '../../domain/repositories/i_car_repository.dart';
import '../local/app_database.dart';
import '../models/car_model.dart';
import '../network/car_api_service.dart';
import '../network/unsplash_service.dart';

class CarRepositoryImpl implements ICarRepository {
  final CarApiService _apiService;
  final AppDatabase _database;
  final UnsplashService _unsplash = UnsplashService();

  static const _apiKey = 'h60dC6cvpQq8sGqGf84xtc0eSn2LgLt2N7tXbjjf';

  // Популярные бренды — по 3 машины каждый = ~24 машины
  static const _brands = [
    'toyota', 'bmw', 'mercedes-benz',
    'audi', 'honda', 'ford',
    'porsche', 'lexus',
  ];

  CarRepositoryImpl({
    required CarApiService apiService,
    required AppDatabase database,
  })  : _apiService = apiService,
        _database = database;

  @override
  Future<List<CarEntity>> getCars() async {
    try {
      // Запрашиваем каждый бренд параллельно
      final results = await Future.wait(
        _brands.map((brand) => _fetchBrand(brand)),
      );

      final allCars = results.expand((list) => list).toList();

      // Загружаем фото параллельно (UnsplashService кеширует по бренду)
      final enriched = await Future.wait(
        allCars.map((car) async {
          final imageUrl = await _unsplash.getCarImageUrl(car.brand, car.model);
          return CarModel(
            id: car.id,
            brand: car.brand,
            model: car.model,
            year: car.year,
            price: car.price,
            imageUrl: imageUrl,
          );
        }),
      );

      return enriched;
    } catch (e) {
      throw Exception('Ошибка сети: $e');
    }
  }

  Future<List<CarModel>> _fetchBrand(String brand) async {
    try {
      final response = await _apiService.getCarsByMake(brand, _apiKey);
      if (!response.isSuccessful) {
        final rawBody = (response.base as http.Response).body;
        // ignore: avoid_print
        print('[$brand] HTTP ${response.statusCode}: $rawBody');
        return [];
      }
      final rawBody = (response.base as http.Response).body;
      final body = jsonDecode(rawBody) as List<dynamic>;
      // ignore: avoid_print
      print('[$brand] loaded ${body.length} cars');
      return body
          .map((item) => CarModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // ignore: avoid_print
      print('[$brand] error: $e');
      return [];
    }
  }

  @override
  Future<List<CarEntity>> getFavoriteCars() async {
    final rows = await _database.select(_database.favoriteCars).get();
    return rows
        .map((row) => CarModel(
              id: row.id,
              brand: row.brand,
              model: row.model,
              year: row.year,
              price: row.price,
              imageUrl: row.imageUrl,
            ))
        .toList();
  }

  @override
  Future<void> addToFavorites(CarEntity car) async {
    await _database.into(_database.favoriteCars).insertOnConflictUpdate(
          FavoriteCarsCompanion(
            id: Value(car.id),
            brand: Value(car.brand),
            model: Value(car.model),
            year: Value(car.year),
            price: Value(car.price),
            imageUrl: Value(car.imageUrl),
          ),
        );
  }

  @override
  Future<void> removeFromFavorites(String carId) async {
    await (_database.delete(_database.favoriteCars)
          ..where((tbl) => tbl.id.equals(carId)))
        .go();
  }
}
