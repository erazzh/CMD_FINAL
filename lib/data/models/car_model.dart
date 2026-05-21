import '../../domain/entities/car_entity.dart';

/// DTO-модель данных машины.
///
/// Отвечает за:
/// - парсинг JSON из сетевого ответа [fromJson]
/// - сериализацию в JSON [toJson]
///
/// Следует паттерну [TestDriveModel]: расширяет Entity, чтобы
/// слой данных оставался совместимым с Domain без лишних конвертеров.
///
/// API: https://freetestapi.com/api/v1/cars
/// Маппинг полей:
///   json["id"]    → int → toString() → [CarEntity.id]
///   json["make"]  → [CarEntity.brand]
///   json["model"] → [CarEntity.model]
///   json["year"]  → [CarEntity.year]
///   json["price"] → num → toDouble() → [CarEntity.price]
///   json["image"] → [CarEntity.imageUrl]
class CarModel extends CarEntity {
  CarModel({
    required super.id,
    required super.brand,
    required super.model,
    required super.year,
    required super.price,
    required super.imageUrl,
  });

  factory CarModel.fromJson(Map<String, dynamic> json) {
    return CarModel(
      id: (json['id'] as int? ?? 0).toString(),
      brand: json['make'] as String? ?? '',
      model: json['model'] as String? ?? '',
      year: json['year'] as int? ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['image'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'make': brand,
      'model': model,
      'year': year,
      'price': price,
      'image': imageUrl,
    };
  }
}
