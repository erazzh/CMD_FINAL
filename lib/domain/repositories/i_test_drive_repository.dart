import '../entities/test_drive_entity.dart';

abstract class ITestDriveRepository {

  Future<void> submitTestDrive(TestDriveEntity request);
  
  Future<List<TestDriveEntity>> getTestDrives();
}