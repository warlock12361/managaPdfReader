import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:page_flip/page_flip.dart';
import '../../../core/services/preferences_service.dart';
import 'dart:async';

class ReaderScreen extends StatefulWidget {
  final String filePath;

  const ReaderScreen({super.key, required this.filePath});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final _controller = GlobalKey<PageFlipWidgetState>();
  bool _immersiveMode = false;
  PdfDocument? _document;
  
  // New State
  double _brightness = 1.0; // 1.0 is full brightness, 0.0 is black
  bool _isBookmarked = false;
  int _currentPage = 0;
  int _totalPages = 10; // Default

  Timer? _saveDebounceTimer; // Debouncer
  Timer? _progressTimer;
  int? _initialPage;

  @override
  void initState() {
    super.initState();
    _loadDocumentAndProgress();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      // Poll faster (100ms) for snappy UI updates, but debounce the DB write
      if (mounted && _controller.currentState != null) {
        final newPage = _controller.currentState?.pageNumber ?? 0;
        if (newPage != _currentPage) {
          setState(() {
            _currentPage = newPage;
          });
          
          // Debounce: Cancel previous timer, start new one
          _saveDebounceTimer?.cancel();
          _saveDebounceTimer = Timer(const Duration(seconds: 3), () { // 3s rule
             if (mounted) {
               PreferencesService.saveProgress(widget.filePath, newPage, _totalPages);
               // debugPrint("Saved progress: Page $newPage"); // Uncomment for debugging only
             }
          });
        }
      }
    });
  }

  Future<void> _loadDocumentAndProgress() async {
    try {
      final docLoad = widget.filePath.startsWith('/assets') 
          ? Future.value(null) // Dummy
          : PdfDocument.openFile(widget.filePath);
      
      final prefsLoad = PreferencesService.getLastPage(widget.filePath);

      final results = await Future.wait([
         docLoad,
         prefsLoad
      ]);

      if (mounted) {
        setState(() {
          if (results[0] != null) {
             _document = results[0] as PdfDocument;
             _totalPages = _document!.pages.length;
          } else {
             _totalPages = 10; // Dummy
          }
          
          final saved = results[1] as int;
          _initialPage = (saved >= 0 && saved < _totalPages) ? saved : 0;
          // debugPrint("Reader: Loaded initial page $_initialPage from saved $saved");
          _currentPage = _initialPage!;
        });
      }
    } catch (e) {
      debugPrint("Error loading: $e");
    }
  }

  void _toggleImmersive() {
    setState(() {
      _immersiveMode = !_immersiveMode;
    });
    if (_immersiveMode) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }


  void _showJumpToPageDialog() {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("Jump to Page", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Enter page number (1 - $_totalPages)",
            hintStyle: TextStyle(color: Colors.grey[600]),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).primaryColor)),
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              final page = int.tryParse(controller.text);
              if (page != null && page >= 1 && page <= _totalPages) {
                Navigator.pop(context); // Close dialog FIRST
                // Imperative call. Do not setState.
                _controller.currentState?.goToPage(page - 1);
              } else {
                 ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(content: Text("Invalid page. Enter 1 to $_totalPages"))
                 );
              }
            },
            child: const Text("Go", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showBrightnessControl() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black.withOpacity(0.9),
      builder: (context) {
        return Container(
          height: 150,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text("Brightness", style: TextStyle(color: Colors.white)),
              const SizedBox(height: 10),
              StatefulBuilder(
                builder: (context, setModalState) {
                  return Slider(
                    value: _brightness,
                    min: 0.1,
                    max: 1.0,
                    divisions: 10,
                    activeColor: Colors.white,
                    inactiveColor: Colors.grey,
                    onChanged: (val) {
                      setModalState(() {});
                      setState(() {
                        _brightness = val;
                      });
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _saveDebounceTimer?.cancel(); // Cancel pending saves
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge); // Reset
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Blocking render until data is ready (Bug Fix 1)
    if (_initialPage == null) {
       return const Scaffold(
         backgroundColor: Colors.black,
         body: Center(child: CircularProgressIndicator(color: Colors.white)),
       );
    }
    
    return Scaffold(
      backgroundColor: Colors.black, // Distraction free
      body: Stack(
        children: [
          // 1. Interactive Book Layer
          GestureDetector(
            onTap: _toggleImmersive, // Tap center to toggle
            child: Center(
              child: AspectRatio(
                aspectRatio: 1 / 1.414, // A4ish
                child: Stack(
                  children: [
                     PageFlipWidget(
                        key: _controller, // GlobalKey preserves state
                        initialIndex: _initialPage!, 
                        backgroundColor: Colors.black,
                        children: <Widget>[
                          for (int i = 0; i < _totalPages; i++)
                            _buildPage(i),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
          
          // 2. Brightness Overlay
          IgnorePointer(
            child: Container(
               color: Colors.black.withOpacity(1.0 - _brightness),
            ),
          ),

          // 3. Navigation Overlay (Top)
          AnimatedPositioned(
             duration: const Duration(milliseconds: 300),
             top: _immersiveMode ? -100 : 0,
             left: 0,
             right: 0,
             child: AppBar(
               backgroundColor: Colors.black.withOpacity(0.5),
               foregroundColor: Colors.white,
               elevation: 0,
               leading: IconButton(
                 icon: const Icon(Icons.arrow_back),
                 onPressed: () => Navigator.pop(context),
               ),
               title: Text(widget.filePath.split('/').last),
               actions: [
                  IconButton(
                    icon: const Icon(Icons.format_list_numbered), // Feature 1: Jump
                    tooltip: "Jump to Page",
                    onPressed: _showJumpToPageDialog,
                  ),
                 IconButton(
                   icon: Icon(_brightness < 0.5 ? Icons.brightness_3 : Icons.wb_sunny_outlined), 
                   onPressed: _showBrightnessControl
                 ),
               ],
             ),
           ),

           // 4. Progress Bar Overlay (Bottom)
           AnimatedPositioned(
             duration: const Duration(milliseconds: 300),
             bottom: _immersiveMode ? -150 : 0,
             left: 0,
             right: 0,
             child: Container(
               color: Colors.black.withOpacity(0.5),
               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
               child: SafeArea( // Priority 2: SafeArea
                 top: false,
                 child: Column(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         Text("Page ${_currentPage + 1}", style: const TextStyle(color: Colors.white)),
                         Text("${_totalPages} Pages", style: const TextStyle(color: Colors.white)),
                       ],
                     ),
                     const SizedBox(height: 10),
                     LinearProgressIndicator(
                       value: (_currentPage + 1) / _totalPages,
                       backgroundColor: Colors.grey.withOpacity(0.3),
                       valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                     ),
                   ],
                 ),
               ),
             ),
           ),
        ],
      ),
    );
  }

  Widget _buildPage(int index) {
    return Container(
      color: Colors.white,
      child: _document != null
          ? PdfPageView(
              document: _document!,
              pageNumber: index + 1,
              alignment: Alignment.center,
            )
          : _buildDummyPage(index),
    );
  }

  Widget _buildDummyPage(int index) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Page ${index + 1}",
            style: const TextStyle(fontSize: 24, fontFamily: 'Serif', color: Colors.black),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Text(
              "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
              style: const TextStyle(fontSize: 16, fontFamily: 'Serif', color: Colors.black),
              textAlign: TextAlign.justify,
            ),
          ),
        ],
      ),
    );
  }
}
