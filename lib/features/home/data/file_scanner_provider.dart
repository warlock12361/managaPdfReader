import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
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
    // 1. Check Permissions
    if (await Permission.storage.isDenied && await Permission.manageExternalStorage.isDenied) {
       // If absolutely no permission, return empty or dummy (UI handles prompt)
       // But let's try to proceed if we have partial access or if user just granted it.
       // Ideally we wait for the UI to prompt.
       // return []; 
    }

    // 2. Scan Device
    final List<PdfFile> files = [];
    try {
      // Common paths to scan
      final List<String> pathsToScan = [
        '/storage/emulated/0/Download',
        '/storage/emulated/0/Documents',
        '/storage/emulated/0/Books',
        '/storage/emulated/0', // Root scan enabled per user request
      ];

      // Use a Set to avoid duplicates if paths overlap
      final Set<String> processedPaths = {};

      for (final path in pathsToScan) {
        final dir = Directory(path);
        if (await dir.exists()) {
          // Recursive scan
          try {
             await for (final entity in dir.list(recursive: true, followLinks: false)) {
               if (entity is File && entity.path.toLowerCase().endsWith('.pdf')) {
                 if (processedPaths.contains(entity.path)) continue;
                 processedPaths.add(entity.path);

                 final stat = await entity.stat();
                 final sizeMb = (stat.size / (1024 * 1024)).toStringAsFixed(1);
                 
                 files.add(PdfFile(
                   path: entity.path,
                   title: entity.path.split('/').last.replaceAll('.pdf', ''),
                   author: 'Local File', // Metadata extraction is complex, use placeholder
                   size: '$sizeMb MB',
                   date: stat.modified,
                   isFavorite: false, // Could load from local DB if persisted
                 ));
               }
             }
          } catch (e) {
            // Ignore access errors in specific subfolders
          }
        }
      }
    } catch (e) {
      // Error scanning
    }
    
    // Sort by date new to old
    files.sort((a, b) => b.date.compareTo(a.date));

    return files;
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
