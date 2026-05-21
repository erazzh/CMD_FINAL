import 'package:chopper/chopper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/app_database.dart';
import '../data/network/car_api_service.dart';
import '../data/repositories/car_repository_impl.dart';
import '../domain/entities/car_entity.dart';
import '../domain/repositories/i_car_repository.dart';

// ---------------------------------------------------------------------------
// Инфраструктурные провайдеры
// ---------------------------------------------------------------------------

/// Синглтон локальной БД Drift.
/// Riverpod гарантирует единственный экземпляр на всё приложение.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  // Закрываем соединение при уничтожении провайдера (dispose).
  ref.onDispose(db.close);
  return db;
});

/// Chopper-клиент с базовым URL каталога машин.
final chopperClientProvider = Provider<ChopperClient>((ref) {
  final client = ChopperClient(
    baseUrl: Uri.parse('https://freetestapi.com/api/v1'),
    services: [CarApiService.create()],
    interceptors: [HttpLoggingInterceptor()],
  );
  ref.onDispose(client.dispose);
  return client;
});

/// Chopper-сервис для запросов к /cars.
final carApiServiceProvider = Provider<CarApiService>((ref) {
  final client = ref.watch(chopperClientProvider);
  return client.getService<CarApiService>();
});

// ---------------------------------------------------------------------------
// Репозиторий
// ---------------------------------------------------------------------------

/// Провайдер репозитория, объединяющего сеть (Chopper) и БД (Drift).
final carRepositoryProvider = Provider<ICarRepository>((ref) {
  final apiService = ref.watch(carApiServiceProvider);
  final database = ref.watch(appDatabaseProvider);
  return CarRepositoryImpl(
    apiService: apiService,
    database: database,
  );
});

// ---------------------------------------------------------------------------
// UI-провайдеры
// ---------------------------------------------------------------------------

/// Каталог машин из сети.
///
/// Использование в виджете:
/// ```dart
/// final carsAsync = ref.watch(carListProvider);
/// carsAsync.when(data: ..., loading: ..., error: ...);
/// ```
final carListProvider = FutureProvider<List<CarEntity>>((ref) async {
  final repository = ref.watch(carRepositoryProvider);
  return repository.getCars();
});

/// Избранные машины из локальной БД.
final favoriteCarsProvider = FutureProvider<List<CarEntity>>((ref) async {
  final repository = ref.watch(carRepositoryProvider);
  return repository.getFavoriteCars();
});
