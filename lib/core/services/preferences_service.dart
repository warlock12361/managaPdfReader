import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _progressPrefix = 'pdf_progress_';

  // Save the current page number and total pages for a given file path
  static Future<void> saveProgress(String filePath, int page, int totalPages) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_progressPrefix$filePath', page);
    await prefs.setInt('${_progressPrefix}total_$filePath', totalPages);
  }

  // Get the last read page number for a given file path. Defaults to 0.
  static Future<int> getLastPage(String filePath) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_progressPrefix$filePath') ?? 0;
  }

  // Get total pages. Defaults to 0.
  static Future<int> getTotalPages(String filePath) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('${_progressPrefix}total_$filePath') ?? 0;
  }
}
