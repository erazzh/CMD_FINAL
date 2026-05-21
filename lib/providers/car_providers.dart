import 'package:chopper/chopper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/app_database.dart';
import '../data/network/car_api_service.dart';
import '../data/repositories/car_repository_impl.dart';
import '../domain/entities/car_entity.dart';
import '../domain/repositories/i_car_repository.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final chopperClientProvider = Provider<ChopperClient>((ref) {
  final client = ChopperClient(
    baseUrl: Uri.parse('https://api.api-ninjas.com/v1'),
    services: [CarApiService.create()],
    interceptors: [HttpLoggingInterceptor()],
  );
  ref.onDispose(client.dispose);
  return client;
});

final carApiServiceProvider = Provider<CarApiService>((ref) {
  final client = ref.watch(chopperClientProvider);
  return client.getService<CarApiService>();
});

final carRepositoryProvider = Provider<ICarRepository>((ref) {
  final apiService = ref.watch(carApiServiceProvider);
  final database = ref.watch(appDatabaseProvider);
  return CarRepositoryImpl(
    apiService: apiService,
    database: database,
  );
});

final carListProvider = FutureProvider<List<CarEntity>>((ref) async {
  final repository = ref.watch(carRepositoryProvider);
  return repository.getCars();
});

final favoriteCarsProvider = FutureProvider<List<CarEntity>>((ref) async {
  final repository = ref.watch(carRepositoryProvider);
  return repository.getFavoriteCars();
});
