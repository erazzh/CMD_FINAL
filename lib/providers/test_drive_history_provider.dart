import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/car_entity.dart';
import '../domain/entities/test_drive_entity.dart';
import 'car_providers.dart';
import 'test_drive_providers.dart';

class TestDriveHistoryItem {
  final TestDriveEntity request;
  final CarEntity? car;

  TestDriveHistoryItem({required this.request, this.car});
}

final testDriveHistoryProvider = FutureProvider<List<TestDriveHistoryItem>>((ref) async {
  final testDrivesAsync = ref.watch(testDriveNotifierProvider);
  final carsAsync = ref.watch(carListProvider);

  
  final testDrives = testDrivesAsync.value ?? [];
  final cars = carsAsync.value ?? [];

  return testDrives.map((drive) {
    final matchingCar = cars.where((c) => c.id == drive.carId).firstOrNull;
    return TestDriveHistoryItem(
      request: drive,
      car: matchingCar,
    );
  }).toList();
});