import '../entities/car_entity.dart';

/// Контракт репозитория машин.
/// Реализации живут в data/repositories/.
abstract class ICarRepository {
  /// Получить каталог машин из сети.
  Future<List<CarEntity>> getCars();

  /// Получить список избранных машин из локальной БД.
  Future<List<CarEntity>> getFavoriteCars();

  /// Добавить машину в избранное.
  Future<void> addToFavorites(CarEntity car);

  /// Удалить машину из избранного по [carId].
  Future<void> removeFromFavorites(String carId);
}
