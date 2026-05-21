import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/test_drive_entity.dart';
import '../../domain/repositories/i_test_drive_repository.dart';
import '../models/test_drive_model.dart';

class FirebaseTestDriveRepository implements ITestDriveRepository {
  final FirebaseFirestore _firestore;

  FirebaseTestDriveRepository(this._firestore);

  @override
  Future<void> submitTestDrive(TestDriveEntity request) async {
    try {
      final model = TestDriveModel(
        id: request.id,
        carId: request.carId,
        userName: request.userName,
        contactInfo: request.contactInfo,
        preferredDate: request.preferredDate,
      );

      await _firestore.collection('test_drives').add(model.toMap());
    } catch (e) {

      throw Exception('Error sending request: $e');
    }
  }

  @override
  Future<List<TestDriveEntity>> getTestDrives() async {
    try {
      final snapshot = await _firestore.collection('test_drives').get();
      
      return snapshot.docs
          .map((doc) => TestDriveModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error fetching requests: $e');
    }
  }
}