import 'package:flutter_riverpod/flutter_riverpod.dart';

class PdfFile {
  final String path;
  final String title;
  final String author;
  final String size;
  final DateTime date;
  final bool isFavorite;

  const PdfFile({
    required this.path,
    required this.title,
    required this.author,
    required this.size,
    required this.date,
    this.isFavorite = false,
  });

  PdfFile copyWith({
    String? path,
    String? title,
    String? author,
    String? size,
    DateTime? date,
    bool? isFavorite,
  }) {
    return PdfFile(
      path: path ?? this.path,
      title: title ?? this.title,
      author: author ?? this.author,
      size: size ?? this.size,
      date: date ?? this.date,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

class FileListNotifier extends AsyncNotifier<List<PdfFile>> {
  @override
  Future<List<PdfFile>> build() async {
    // Simulate delay
    await Future.delayed(const Duration(milliseconds: 800));

    return [
      PdfFile(
        path: '/assets/dummy/design_patterns.pdf',
        title: 'Design Patterns',
        author: 'Gang of Four',
        size: '2.4 MB',
        date: DateTime.now().subtract(const Duration(days: 1)),
        isFavorite: true,
      ),
      PdfFile(
        path: '/assets/dummy/flutter_architecture.pdf',
        title: 'Flutter Architecture',
        author: 'Google',
        size: '5.1 MB',
        date: DateTime.now().subtract(const Duration(days: 5)),
      ),
      PdfFile(
        path: '/assets/dummy/clean_code.pdf',
        title: 'Clean Code',
        author: 'Robert C. Martin',
        size: '1.2 MB',
        date: DateTime.now().subtract(const Duration(hours: 4)),
      ),
      PdfFile(
        path: '/assets/dummy/pragmatic_programmer.pdf',
        title: 'The Pragmatic Programmer',
        author: 'Andrew Hunt',
        size: '3.8 MB',
        date: DateTime.now().subtract(const Duration(days: 12)),
      ),
    ];
  }

  void toggleFavorite(String path) {
    state = state.whenData((files) {
      return files.map((file) {
        if (file.path == path) {
          return file.copyWith(isFavorite: !file.isFavorite);
        }
        return file;
      }).toList();
    });
  }
}

final fileListProvider = AsyncNotifierProvider<FileListNotifier, List<PdfFile>>(() {
  return FileListNotifier();
});
