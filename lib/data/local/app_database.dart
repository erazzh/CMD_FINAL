import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// Таблица избранных машин.
///
/// Поля строго соответствуют [CarEntity]:
///   id, brand, model, year, price, imageUrl.
/// Первичный ключ — [id] (строка, приходит из API).
class FavoriteCars extends Table {
  TextColumn get id => text()();

  TextColumn get brand => text()();

  TextColumn get model => text()();

  IntColumn get year => integer()();

  RealColumn get price => real()();

  TextColumn get imageUrl => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Локальная SQLite-база данных (Drift).
///
/// Содержит одну таблицу: [FavoriteCars].
///
/// Кодогенерация запускается командой:
///   flutter pub run build_runner build --delete-conflicting-outputs
@DriftDatabase(tables: [FavoriteCars])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

/// Открывает соединение с файлом базы данных на устройстве.
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'cars.db'));
    return NativeDatabase.createInBackground(file);
  });
}
