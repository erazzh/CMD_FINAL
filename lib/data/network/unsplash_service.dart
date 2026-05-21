import 'dart:convert';
import 'package:http/http.dart' as http;

/// Сервис для получения изображений машин через Unsplash API.
///
/// Кеширует результаты по бренду, чтобы не превышать лимит 50 запросов/час.
class UnsplashService {
  static const _accessKey = 'bxOlPyfTf-e2LhbgP0X2l0lVvf6ydb6eU2PCwEQVmPU';
  static const _baseUrl = 'https://api.unsplash.com';

  // Кеш: brand → imageUrl
  final Map<String, String> _cache = {};

  /// Возвращает URL фото для бренда.
  /// Если бренд уже запрашивался — возвращает из кеша (экономим лимит).
  Future<String> getCarImageUrl(String brand, String model) async {
    final key = brand.toLowerCase();

    if (_cache.containsKey(key)) {
      return _cache[key]!;
    }

    try {
      final query = Uri.encodeComponent('$brand $model car');
      final uri = Uri.parse(
        '$_baseUrl/search/photos?query=$query&per_page=1&orientation=landscape',
      );

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Client-ID $_accessKey'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final results = data['results'] as List<dynamic>;

        if (results.isNotEmpty) {
          final url = (results[0] as Map<String, dynamic>)['urls']
              ['regular'] as String;
          _cache[key] = url;
          return url;
        }
      }
    } catch (_) {
      // При ошибке возвращаем пустую строку — UI покажет иконку
    }

    _cache[key] = '';
    return '';
  }
}
