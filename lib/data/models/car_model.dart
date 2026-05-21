import '../../domain/entities/car_entity.dart';

/// DTO-модель данных машины под API Ninjas.
///
/// API: https://api.api-ninjas.com/v1/cars
/// Поля ответа:
///   json["make"]         → [CarEntity.brand]
///   json["model"]        → [CarEntity.model]
///   json["year"]         → [CarEntity.year]
///   json["fuel_type"]    → используется для расчёта цены
///   json["cylinders"]    → используется для расчёта цены
///   json["city_mpg"]     → хранится в imageUrl временно (нет фото в API)
///
/// Цена генерируется на основе цилиндров и года выпуска.
/// Фото отсутствует в API — UI показывает иконку машины.
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
    final make = json['make'] as String? ?? '';
    final model = json['model'] as String? ?? '';
    final year = json['year'] as int? ?? 2000;
    final cylinders = (json['cylinders'] as num?)?.toInt() ?? 4;
    final fuelType = json['fuel_type'] as String? ?? 'gas';

    return CarModel(
      id: '${make}_${model}_$year'.replaceAll(' ', '_').toLowerCase(),
      brand: make,
      model: model,
      year: year,
      price: _estimatePrice(cylinders: cylinders, year: year, fuelType: fuelType, make: make),
      imageUrl: '', // API Ninjas не предоставляет фото
    );
  }

  /// Генерирует приблизительную цену на основе характеристик.
  static double _estimatePrice({
    required int cylinders,
    required int year,
    required String fuelType,
    required String make,
  }) {
    // Базовая цена по количеству цилиндров
    double base;
    switch (cylinders) {
      case 3:
        base = 18000;
      case 4:
        base = 28000;
      case 6:
        base = 45000;
      case 8:
        base = 65000;
      case 10:
        base = 90000;
      case 12:
        base = 130000;
      default:
        base = 35000;
    }

    // Надбавка за год выпуска
    final yearBonus = ((year - 2000).clamp(0, 25)) * 800.0;

    // Надбавка за гибрид/электро
    double fuelBonus = 0;
    if (fuelType == 'electricity') fuelBonus = 15000;
    if (fuelType == 'hybrid') fuelBonus = 8000;

    // Небольшая вариация по бренду (детерминированная)
    final makeHash = make.codeUnits.fold(0, (a, b) => a + b) % 10;
    final brandVariation = makeHash * 1500.0;

    return (base + yearBonus + fuelBonus + brandVariation).roundToDouble();
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
