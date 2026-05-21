import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/test_drive_entity.dart';

class TestDriveModel extends TestDriveEntity {
  TestDriveModel({
    required super.id,
    required super.carId,
    required super.userName,
    required super.contactInfo,
    required super.preferredDate,
  });

  // данные из Firestore в наш объект
  factory TestDriveModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TestDriveModel(
      id: doc.id,
      carId: data['carId'] ?? '',
      userName: data['userName'] ?? '',
      contactInfo: data['contactInfo'] ?? '',
      preferredDate: (data['preferredDate'] as Timestamp).toDate(),
    );
  }

  // наш объект в формат для отправки в Firestore
  Map<String, dynamic> toMap() {
    return {
      'carId': carId,
      'userName': userName,
      'contactInfo': contactInfo,
      'preferredDate': Timestamp.fromDate(preferredDate),
    };
  }
}