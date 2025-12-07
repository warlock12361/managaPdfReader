import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glassmorphism_ui/glassmorphism_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/file_scanner_provider.dart';
import 'widgets/file_list_view.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // Reduced to 2
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
    // Check permissions after build
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPermissions());
  }

  Future<void> _checkPermissions() async {
    // For Android 11+ (API 30+)
    if (await Permission.manageExternalStorage.request().isGranted) {
      return; 
    }
    
    // Fallback or older Android
    var status = await Permission.storage.request();
    if (status.isDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Storage permission is required to read PDFs")),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true, // For glass effect overlap
      body: Stack(
        children: [
          // Background gradient or solid color
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark 
                  ? [Color(0xFF1C1C1E), Color(0xFF000000)] 
                  : [Color(0xFFF5F5F7), Color(0xFFE1E1E1)],
              ),
            ),
          ),
          
          SafeArea(
            bottom: false,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverAppBar(
                  title: _isSearching 
                      ? TextField(
                          controller: _searchController,
                          autofocus: true,
                          style: Theme.of(context).textTheme.titleLarge,
                          decoration: const InputDecoration(
                            hintText: "Search PDF...",
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: Colors.grey),
                          ),
                        )
                      : Text("Library", style: Theme.of(context).textTheme.displayLarge),
                  floating: true,
                  snap: true,
                  pinned: false, // Hide on scroll for immersion
                  actions: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _isSearching = !_isSearching;
                          if (!_isSearching) {
                            _searchQuery = "";
                            _searchController.clear();
                          }
                        });
                      },
                      icon: Icon(_isSearching ? Icons.close : Icons.search, size: 28),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'About') {
                           showModalBottomSheet(
                            context: context, 
                            backgroundColor: Theme.of(context).cardColor,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                            ),
                            builder: (context) => Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text("Manga Premium PDF Reader", style: Theme.of(context).textTheme.headlineSmall),
                                  const SizedBox(height: 16),
                                  const Text("Crafted with ❤️ by Sonu Verma"),
                                  const SizedBox(height: 24),
                                  ListTile(
                                    leading: const Icon(Icons.email_outlined, color: Colors.blueAccent),
                                    title: const Text("Contact Developer"),
                                    subtitle: const Text("sonuverma12361@gmail.com"),
                                    onTap: () async {
                                      final Uri emailLaunchUri = Uri(
                                        scheme: 'mailto',
                                        path: 'sonuverma12361@gmail.com',
                                      );
                                      if (!await launchUrl(emailLaunchUri)) {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not open email app")));
                                      }
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.coffee, color: Colors.brown),
                                    title: const Text("Buy me a Coffee"),
                                    subtitle: const Text("Support via UPI"),
                                    onTap: () async {
                                       // upi://pay?pa=7004164962@slc&pn=Sonu%20Verma&am=50&cu=INR
                                       final Uri upiUri = Uri.parse("upi://pay?pa=7004164962@slc&pn=Sonu%20Verma&am=50&cu=INR");
                                       if (!await launchUrl(upiUri, mode: LaunchMode.externalApplication)) {
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not open UPI app")));
                                       }
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          );
                        } else {
                           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$value clicked")));
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'Sort', child: Text("Sort by Date")),
                        const PopupMenuItem(value: 'About', child: Text("About")),
                      ],
                      child: const Icon(Icons.more_vert, size: 28),
                    ),
                    const SizedBox(width: 16),
                  ],
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(60),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Container(
                        height: 45,
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicator: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          dividerColor: Colors.transparent, // Remove line
                          labelColor: Theme.of(context).colorScheme.onPrimary,
                          unselectedLabelColor: Theme.of(context).textTheme.bodyMedium?.color,
                          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
                          overlayColor: MaterialStateProperty.all(Colors.transparent), // Remove splash/oval
                          tabs: const [
                            Tab(text: "All PDFs"),
                            Tab(text: "Favorites"),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              body: TabBarView(
                controller: _tabController,
                physics: const BouncingScrollPhysics(), // iOS style bounce
                children: [
                   // Pass query if searching (Note: FileListView needs update to accept query, or we filter in Provider. For now simpler to filter in view or assume ListView handles it. 
                   // Plan said "Wrap FileListView". I will update FileListView next to accept 'searchQuery'.)
                  FileListView(filter: FileFilter.all, searchQuery: _searchQuery),
                  FileListView(filter: FileFilter.favorites, searchQuery: _searchQuery),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Open file picker for PDF
          final result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['pdf'],
          );
          
          if (result != null && result.files.isNotEmpty) {
            // Refresh the library to pick up the file
            ref.refresh(fileListProvider);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Added: ${result.files.first.name}")),
              );
            }
          }
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

enum FileFilter { all, favorites, folders }
