import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/entities/car_entity.dart';

class CompareCarsNotifier extends Notifier<List<CarEntity>> {

  static const int maxCompareLimit = 3;

  @override
  List<CarEntity> build() {

    return [];
  }

  void toggleCarForComparison(CarEntity car) {
    final isAlreadyAdded = state.any((c) => c.id == car.id);

    if (isAlreadyAdded) {

      state = state.where((c) => c.id != car.id).toList();
    } else {

      if (state.length < maxCompareLimit) {
        state = [...state, car];
      } else {
        
        throw Exception('Можно сравнивать не более $maxCompareLimit автомобилей');
      }
    }
  }

  void clearComparison() {
    state = [];
  }
}

final compareCarsProvider =
    NotifierProvider<CompareCarsNotifier, List<CarEntity>>(
  () => CompareCarsNotifier(),
);