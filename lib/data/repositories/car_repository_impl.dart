import 'package:drift/drift.dart';

import '../../domain/entities/car_entity.dart';
import '../../domain/repositories/i_car_repository.dart';
import '../local/app_database.dart';
import '../models/car_model.dart';
import '../network/car_api_service.dart';

/// Реализация [ICarRepository].
///
/// Источники данных:
///   - Сеть: [CarApiService] (Chopper) — для [getCars].
///   - Локальная БД: [AppDatabase] (Drift) — для избранного.
class CarRepositoryImpl implements ICarRepository {
  final CarApiService _apiService;
  final AppDatabase _database;

  const CarRepositoryImpl({
    required CarApiService apiService,
    required AppDatabase database,
  })  : _apiService = apiService,
        _database = database;

  @override
  Future<List<CarEntity>> getCars() async {
    try {
      final response = await _apiService.getCars();

      if (!response.isSuccessful || response.body == null) {
        throw Exception('Ошибка получения каталога: ${response.statusCode}');
      }

      final body = response.body as List<dynamic>;

      return body
          .map((item) => CarModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Ошибка сети: $e');
    }
  }

  @override
  Future<List<CarEntity>> getFavoriteCars() async {
    final rows = await _database.select(_database.favoriteCars).get();

    return rows
        .map(
          (row) => CarModel(
            id: row.id,
            brand: row.brand,
            model: row.model,
            year: row.year,
            price: row.price,
            imageUrl: row.imageUrl,
          ),
        )
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
