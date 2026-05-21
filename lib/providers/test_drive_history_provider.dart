import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/entities/car_entity.dart';
import '../domain/entities/test_drive_entity.dart';
import 'test_drive_providers.dart';

class TestDriveHistoryItem {
  final TestDriveEntity request;
  final CarEntity? car;

  TestDriveHistoryItem({required this.request, this.car});
}

final testDriveHistoryProvider = FutureProvider<List<TestDriveHistoryItem>>((ref) async {

  final testDrivesState = ref.watch(testDriveNotifierProvider);
  
  final testDrives = testDrivesState.value ?? [];

  
  final List<CarEntity> cars = [];

  return testDrives.map((drive) {
    final matchingCar = cars.where((c) => c.id == drive.carId).firstOrNull;
    return TestDriveHistoryItem(
      request: drive,
      car: matchingCar,
    );
  }).toList();
});