import 'package:hive_flutter/hive_flutter.dart';

class StorageService {
  static const String favoritesBoxName = 'favorites';
  static const String metadataBoxName = 'file_metadata';

  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(favoritesBoxName);
    await Hive.openBox(metadataBoxName);
  }

  Box get favoritesBox => Hive.box(favoritesBoxName);
  Box get metadataBox => Hive.box(metadataBoxName);
  
  // Basic API for Favorites
  bool isFavorite(String path) {
    return favoritesBox.get(path, defaultValue: false);
  }

  Future<void> toggleFavorite(String path) async {
    final current = isFavorite(path);
    await favoritesBox.put(path, !current);
  }
}

final storageService = StorageService();
