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
  
  // State
  double _brightness = 1.0;
  int _currentPage = 0;
  int _totalPages = 10;

  Timer? _saveDebounceTimer;
  Timer? _progressTimer;
  
  // CRITICAL: Store future once to prevent multiple loads
  late Future<Map<String, dynamic>> _loadFuture;
  
  // Flag to ensure we only navigate once
  bool _hasNavigatedToInitial = false;
  int _targetInitialPage = 0;

  @override
  void initState() {
    super.initState();
    
    // Initialize the future ONCE in initState
    _loadFuture = _loadDocumentAndProgress();
    
    // Start polling for page changes
    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted && _controller.currentState != null) {
        final newPage = _controller.currentState?.pageNumber ?? 0;
        if (newPage != _currentPage) {
          setState(() {
            _currentPage = newPage;
          });
          HapticFeedback.selectionClick();
          
          _saveDebounceTimer?.cancel();
          _saveDebounceTimer = Timer(const Duration(seconds: 1), () {
             if (mounted) {
               PreferencesService.saveProgress(widget.filePath, newPage, _totalPages);
             }
          });
        }
      }
    });
  }

  Future<Map<String, dynamic>> _loadDocumentAndProgress() async {
    debugPrint("Reader: Loading ${widget.filePath}...");
    
    // Load PDF document
    final PdfDocument? document = widget.filePath.startsWith('/assets') 
        ? null
        : await PdfDocument.openFile(widget.filePath);
    
    final int totalPages = document?.pages.length ?? 10;
    
    // Load saved progress
    final int savedPage = await PreferencesService.getLastPage(widget.filePath);
    final int initialPage = (savedPage >= 0 && savedPage < totalPages) ? savedPage : 0;
    
    debugPrint("Reader: Loaded initial page $initialPage from saved $savedPage");
    
    return {
      'document': document,
      'totalPages': totalPages,
      'initialPage': initialPage,
    };
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
                Navigator.pop(context);
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

  Future<bool> _onWillPop() async {
    debugPrint("Reader: Closing... Forced Save at Page $_currentPage");
    await PreferencesService.saveProgress(widget.filePath, _currentPage, _totalPages);
    return true;
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _saveDebounceTimer?.cancel();
    PreferencesService.saveProgress(widget.filePath, _currentPage, _totalPages);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadFuture, // Use stored future to prevent multiple calls
      builder: (context, snapshot) {
        // Show loading spinner until data is ready
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }

        final data = snapshot.data!;
        final PdfDocument? document = data['document'];
        final int totalPages = data['totalPages'];
        final int initialPage = data['initialPage'];

        // Update state variables once (without causing rebuild)
        if (_totalPages != totalPages) {
          _totalPages = totalPages;
          _currentPage = initialPage;
          _targetInitialPage = initialPage;
        }
        
        // CRITICAL FIX: page_flip package ignores initialIndex
        // Must use goToPage() after widget is built
        if (!_hasNavigatedToInitial && _targetInitialPage > 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _controller.currentState != null) {
              debugPrint("Reader: Forcing navigation to page $_targetInitialPage");
              _controller.currentState?.goToPage(_targetInitialPage);
              _hasNavigatedToInitial = true;
            }
          });
        }

        return WillPopScope(
          onWillPop: _onWillPop,
          child: Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              children: [
                // PDF Viewer with Page Flip
                GestureDetector(
                  onTap: _toggleImmersive,
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1 / 1.414,
                      child: PageFlipWidget(
                        key: _controller,
                        initialIndex: initialPage,
                        backgroundColor: Colors.black,
                        children: <Widget>[
                          for (int i = 0; i < totalPages; i++)
                            _buildPage(document, i),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Brightness Overlay
                IgnorePointer(
                  child: Container(
                     color: Colors.black.withOpacity(1.0 - _brightness),
                  ),
                ),

                // AppBar
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
                       onPressed: () => Navigator.maybePop(context),
                     ),
                     title: Text(widget.filePath.split('/').last),
                     actions: [
                        IconButton(
                          icon: const Icon(Icons.format_list_numbered),
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

                 // Progress Bar
                 AnimatedPositioned(
                   duration: const Duration(milliseconds: 300),
                   bottom: _immersiveMode ? -150 : 0,
                   left: 0,
                   right: 0,
                   child: Container(
                     color: Colors.black.withOpacity(0.5),
                     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                     child: SafeArea(
                       top: false,
                       child: Column(
                         mainAxisSize: MainAxisSize.min,
                         children: [
                           Row(
                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
                             children: [
                               Text("Page ${_currentPage + 1}", style: const TextStyle(color: Colors.white)),
                               Text("$_totalPages Pages", style: const TextStyle(color: Colors.white)),
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
          ),
        );
      },
    );
  }

  Widget _buildPage(PdfDocument? document, int index) {
    return Container(
      color: Colors.white,
      child: document != null
          ? PdfPageView(
              document: document,
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
