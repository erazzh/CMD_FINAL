import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/firebase_test_drive_repository.dart';
import '../domain/entities/test_drive_entity.dart';
import '../domain/repositories/i_test_drive_repository.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final testDriveRepositoryProvider = Provider<ITestDriveRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return FirebaseTestDriveRepository(firestore);
});

class TestDriveNotifier extends AsyncNotifier<List<TestDriveEntity>> {
  @override
  Future<List<TestDriveEntity>> build() async {

    return _fetchTestDrives();
  }

  Future<List<TestDriveEntity>> _fetchTestDrives() async {
    final repository = ref.read(testDriveRepositoryProvider);
    return repository.getTestDrives();
  }

  Future<void> submitRequest(TestDriveEntity request) async {
    state = const AsyncValue.loading();
    
    try {
      final repository = ref.read(testDriveRepositoryProvider);

      await repository.submitTestDrive(request);
      
      state = AsyncValue.data(await _fetchTestDrives());
    } catch (e, stack) {

      state = AsyncValue.error(e, stack);
    }
  }
}

final testDriveNotifierProvider =
    AsyncNotifierProvider<TestDriveNotifier, List<TestDriveEntity>>(
  () => TestDriveNotifier(),
);