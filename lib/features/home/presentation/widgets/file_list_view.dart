import 'package:flutter/material.dart';
import 'dart:ui'; // For BackdropFilter
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/file_scanner_provider.dart';
import '../../../../core/services/preferences_service.dart';
import '../dashboard_screen.dart';

class FileListView extends ConsumerWidget {
  final FileFilter filter;
  final String searchQuery;

  const FileListView({super.key, required this.filter, this.searchQuery = ""});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileListAsync = ref.watch(fileListProvider);

    return fileListAsync.when(
      data: (allFiles) {
        var files = allFiles;
        if (filter == FileFilter.favorites) {
          files = files.where((f) => f.isFavorite).toList();
        }
        
        if (searchQuery.isNotEmpty) {
          files = files.where((f) => f.title.toLowerCase().contains(searchQuery.toLowerCase())).toList();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: files.length,
          itemBuilder: (context, index) {
            final file = files[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: _FileListItem(file: file),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text("Error: $err")),
    );
  }
}

class _FileListItem extends ConsumerWidget {
  final PdfFile file;

  const _FileListItem({required this.file});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Generate a color based on title hash for the placeholder thumbnail
    // Using high saturation gradients as requested
    final color = Colors.primaries[file.title.hashCode % Colors.primaries.length];
    
    // Gradient for the icon (Cyan to Teal or Blue to Violet) example
    final gradient = LinearGradient(
      colors: [
         Colors.cyanAccent,
         Colors.tealAccent,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return InkWell(
      onTap: () async {
        await context.push('/reader', extra: file.path);
        // FORCE refresh of data (and progress) when user returns
        ref.refresh(fileListProvider); 
      },
      borderRadius: BorderRadius.circular(20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Glassmorphism Background
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                height: 135,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1), // Semi-transparent dark grey
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1), // Faint white border
                    width: 1,
                  ),
                ),
              ),
            ),
            
            // Content
            Container(
              height: 135,
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Thumbnail Hero with Gradient
                  Hero(
                    tag: file.path,
                    child: Container(
                      width: 70,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                           colors: [
                             color.withOpacity(0.3),
                             color.withOpacity(0.1),
                           ],
                           begin: Alignment.topLeft,
                           end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color.withOpacity(0.3)),
                      ),
                      child: Center(
                         child: ShaderMask(
                            shaderCallback: (bounds) => gradient.createShader(bounds),
                            child: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 32),
                         ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Metadata
                    Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          file.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white, // High contrast
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Progress Text (Feature 2)
                        FutureBuilder<List<int>>(
                          future: Future.wait([
                            PreferencesService.getLastPage(file.path),
                            PreferencesService.getTotalPages(file.path)
                          ]),
                          builder: (context, snapshot) {
                             if (snapshot.hasData) {
                                final page = snapshot.data![0];
                                final total = snapshot.data![1];

                                if (page >= 0 && total > 0) {
                                  final percentage = ((page + 1) / total * 100).toStringAsFixed(0);
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 4.0),
                                    child: Text(
                                      "${page + 1} / $total ($percentage%)",
                                      style: TextStyle(
                                        color: Colors.grey[400], 
                                        fontSize: 12, // Small caption text
                                        fontWeight: FontWeight.w500
                                      ),
                                    ),
                                  );
                                } else if (page > 0) {
                                   return Padding(
                                    padding: const EdgeInsets.only(bottom: 4.0),
                                    child: Text(
                                      "Page ${page + 1}",
                                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                    ),
                                  );
                                }
                             }
                             return const SizedBox.shrink();
                          },
                        ),
                        Text(
                          file.author,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[400], // Muted text
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              file.size,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey[500]),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '•  ${DateFormat.yMMMd().format(file.date)}',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Action
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          file.isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: file.isFavorite ? Colors.redAccent : Colors.grey[600],
                        ),
                        onPressed: () {
                           ref.read(fileListProvider.notifier).toggleFavorite(file.path);
                        },
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
