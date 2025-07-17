import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:graphview/GraphView.dart';
import 'package:pdf/widgets.dart' as pw;
import '../splash screen/About page.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../API/api_service.dart';
import '../models/person.dart';
import '../splash screen/login page.dart';

class GraphPage extends StatefulWidget {
  const GraphPage({super.key});

  @override
  State<GraphPage> createState() => _GraphPageState();
}

class _GraphPageState extends State<GraphPage> with TickerProviderStateMixin {
  final Graph graph = Graph();
  late BuchheimWalkerConfiguration builder;
  final GlobalKey _previewContainer = GlobalKey();

  Map<String, Node> nodeMap = {};
  Map<String, Person> personMap = {};
  Map<String, AnimationController> _animationControllers = {};
  OverlayEntry? _overlayEntry;

  bool loading = true;
  String? highlightedName;
  Set<String> highlightedChildren = {};
  Set<String> pathToRoot = {};
  Map<String, List<String>> _treeMap = {};
  final TransformationController _transformationController = TransformationController();
  final TextEditingController _searchController = TextEditingController();
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    builder = BuchheimWalkerConfiguration()
      ..siblingSeparation = 25
      ..levelSeparation = 60
      ..subtreeSeparation = 25
      ..orientation = BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM;

    _transformationController.value = Matrix4.identity()..scale(0.7);
    _checkIfAdmin().then((_) => loadGraph());
  }

  Future<void> _checkIfAdmin() async {
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'admin_token');
    if (token != null) {
      setState(() {
        _isAdmin = true;
      });
    }
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _transformationController.dispose();
    _searchController.dispose();
    for (var c in _animationControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> loadGraph() async {
    setState(() {
      loading = true;
      graph.edges.clear();
      graph.nodes.clear();
      nodeMap.clear();
      personMap.clear();
      _treeMap.clear();
      _animationControllers.clear();
      pathToRoot.clear();
    });

    try {
      final persons = await ApiService.fetchPersons();
      Map<String, List<String>> treeMap = {};
      String normalize(String s) => s.trim().toLowerCase();

      for (var p in persons) {
        final child = normalize(p.name);
        final father = normalize(p.fatherName);
        if (father.isNotEmpty) {
          treeMap[father] ??= [];
          treeMap[father]!.add(child);
        }
        personMap[child] = p;
      }

      _treeMap = treeMap;

      for (var p in persons) {
        final nameKey = normalize(p.name);
        nodeMap[nameKey] = Node.Id(p.name);
        _animationControllers[nameKey] = AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 300),
          lowerBound: 0.9,
          upperBound: 1.1,
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            _animationControllers[nameKey]?.reverse();
          }
        });
      }

      for (var entry in treeMap.entries) {
        final fatherNode = nodeMap[entry.key];
        for (var c in entry.value) {
          final childNode = nodeMap[c];
          if (fatherNode != null && childNode != null) {
            graph.addEdge(fatherNode, childNode);
          }
        }
      }

      setState(() {
        loading = false;
      });
    } catch (e) {
      debugPrint("Error loading graph: $e");
      setState(() {
        loading = false;
      });
    }
  }

  void _highlightPathToRoot(String nodeName) {
    final norm = nodeName.trim().toLowerCase();
    pathToRoot.clear();

    String current = norm;
    bool foundRoot = false;

    // Trace upwards until we can't find a parent
    while (!foundRoot) {
      pathToRoot.add(current);

      // Find parent of current node
      String? parent;
      for (var entry in _treeMap.entries) {
        if (entry.value.contains(current)) {
          parent = entry.key;
          break;
        }
      }

      if (parent == null) {
        foundRoot = true; // Reached the root
      } else {
        current = parent;
      }
    }

    setState(() {});
  }

  Widget _nodeWidget(String name, {bool isChild = false}) {
    final key = GlobalKey();
    final norm = name.trim().toLowerCase();
    final controller = _animationControllers[norm];

    return GestureDetector(
      onLongPress: () {
        // Long press to show path to root
        _highlightPathToRoot(norm);
        setState(() {
          highlightedName = norm;
          highlightedChildren.clear();
        });
      },
      onTap: () {
        controller?.forward();
        _showTooltip(context, name, key);
        setState(() {
          highlightedName = norm;
          highlightedChildren.clear();
          pathToRoot.clear();
          _highlightChildren(norm);
        });
      },
      child: AnimatedBuilder(
        animation: controller ?? AnimationController(vsync: this),
        builder: (ctx, child) => Transform.scale(
          scale: controller?.value ?? 1.0,
          child: child,
        ),
        child: Container(
          key: key,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: pathToRoot.contains(norm)
                ? Colors.green.shade300
                : isChild
                ? Colors.lightBlue.shade100
                : Colors.yellow.shade300,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: norm == highlightedName ? Colors.red : Colors.transparent,
              width: 2,
            ),
            boxShadow: [BoxShadow(blurRadius: 3, color: Colors.grey.shade400)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person, size: 24, color: Colors.black87),
              const SizedBox(height: 4),
              SizedBox(
                width: 140,
                child: Text(name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _highlightChildren(String parent) {
    if (_treeMap.containsKey(parent)) {
      for (var c in _treeMap[parent]!) {
        highlightedChildren.add(c);
        _highlightChildren(c);
      }
    }
  }

  void _showTooltip(BuildContext ctx, String name, GlobalKey key) {
    final norm = name.trim().toLowerCase();
    final p = personMap[norm];
    if (p == null) return;

    final rb = key.currentContext?.findRenderObject() as RenderBox?;
    if (rb == null) return;

    final pos = rb.localToGlobal(Offset.zero);
    final sz = rb.size;
    final screenSize = MediaQuery.of(ctx).size;

    const double tooltipWidth = 200;
    const double tooltipHeight = 100;

    double left = pos.dx + sz.width / 2 - tooltipWidth / 2;
    double top = pos.dy - tooltipHeight;

    // 🛑 Clamp the position inside screen boundaries
    if (left < 10) left = 10;
    if (left + tooltipWidth > screenSize.width) left = screenSize.width - tooltipWidth - 10;
    if (top < 10) top = pos.dy + sz.height + 10; // Show below the node if there's no space above

    _overlayEntry?.remove();
    _overlayEntry = OverlayEntry(
      builder: (_) => Positioned(
        left: left,
        top: top,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: tooltipWidth,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.85),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (p.name.isNotEmpty)
                  Text('Name: ${p.name}', style: const TextStyle(color: Colors.white)),
                if (p.fatherName.isNotEmpty)
                  Text('Father: ${p.fatherName}', style: const TextStyle(color: Colors.white)),
                if (p.id.isNotEmpty)
                  Text('ID: ${p.id}', style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 8),
                Text('Long press to trace to root',
                    style: TextStyle(color: Colors.green.shade300, fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(ctx)?.insert(_overlayEntry!);
    Future.delayed(const Duration(seconds: 5), () {
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
  }


  void _searchAndHighlight(String term) {
    final n = term.trim().toLowerCase();
    if (nodeMap.containsKey(n)) {
      setState(() {
        highlightedName = n;
        highlightedChildren.clear();
        pathToRoot.clear();
        _highlightChildren(n);
      });
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Person "$term" not found')));
    }
  }

  Future<Uint8List> _captureFullGraph() async {
    RenderRepaintBoundary boundary = _previewContainer.currentContext?.findRenderObject() as RenderRepaintBoundary;
    if (boundary.debugNeedsPaint) {
      await Future.delayed(const Duration(milliseconds: 300));
    }

    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<void> _exportGraphAsPdf() async {
    try {
      setState(() {
        loading = true;
      });

      final bytes = await _captureFullGraph();
      final pdf = pw.Document();
      final now = DateTime.now();
      final formattedDate = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          build: (ctx) => pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // 🔝 Title and Date at the top
                pw.Text(
                  'Usmani Family Shijra',
                  style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'Generated on: $formattedDate',
                  style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                ),
                pw.SizedBox(height: 20),

                // 📊 Graph Image in Center
                pw.Expanded(
                  child: pw.Center(
                    child: pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.contain),
                  ),
                ),

                pw.SizedBox(height: 20),
                pw.Divider(),

                // 👨‍💻 Developer Info at bottom
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Developed by:',
                          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                      pw.Text('• Umar Farooq', style: pw.TextStyle(fontSize: 12)),
                      pw.Text('Contact: uummeerr0786@gmail.com',
                          style: pw.TextStyle(fontSize: 12)),
                      pw.Text('Portfolio: https://umerfarooq003.web.app/',
                          style: pw.TextStyle(fontSize: 12, color: PdfColors.blue)),
                      pw.Text('• Muhammad Faaez Usmani', style: pw.TextStyle(fontSize: 12)),
                      pw.Text('Contact: faeezusmani2002@gmail.com',
                          style: pw.TextStyle(fontSize: 12)),
                      pw.Text('Phone Number: https://umerfarooq003.web.app/',
                          style: pw.TextStyle(fontSize: 12, color: PdfColors.blue)),
                      pw.SizedBox(height: 6),
                      pw.Text('App: Usmani Family Shijra App (v1.0) - Android',
                          style: pw.TextStyle(fontSize: 12)),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        'Note: This shijra is auto-generated. Please verify details manually if required.',
                        style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await Printing.layoutPdf(onLayout: (fmt) => pdf.save());
    } catch (e) {
      debugPrint("Error exporting PDF: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to export PDF')));
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: Colors.teal,
          centerTitle: true,
          title: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text(
                'Usmani Family Shajra',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                'For Addition in Shajra: Faaez Usmani - 0306-1234567',
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: loadGraph,
              tooltip: 'refresh graph',
            ),
          ],
        ),
      ),

      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.blue),
              margin: EdgeInsets.zero,
              padding: EdgeInsets.zero,
              child: Container(
                alignment: Alignment.topLeft,
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Menu',
                        style: TextStyle(color: Colors.white, fontSize: 24)),
                    SizedBox(height: 5),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                    leading: const Icon(Icons.search),
                    title: const Text('Search Family Member'),
                    onTap: () async {
                      Navigator.pop(context);
                      final res = await showSearch<String?>(
                          context: ctx,
                          delegate: FamilyMemberSearchDelegate(nodeMap));
                      if (res != null) _searchAndHighlight(res);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.print),
                    title: const Text('Export as PDF'),
                    onTap: () {
                      Navigator.pop(context);
                      _exportGraphAsPdf();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.login_outlined),
                    title: const Text('Login'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/login');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: const Text('About'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AboutPage()),
                      );
                    },
                  ),
                ],
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: const [
                  Text('Developed by',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Umar Farooq'),
                  Text('Muhammad Faaez Usmani')
                ],
              ),
            ),
          ],
        ),
      ),


      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
        Expanded(
          child: InteractiveViewer(
            transformationController: _transformationController,
            constrained: false,
            boundaryMargin: const EdgeInsets.all(100),
            minScale: 0.1,
            maxScale: 10,
            scaleEnabled: false,
            child: RepaintBoundary(
              key: _previewContainer,
              child: graph.nodes.isEmpty
                  ? const Center(child: Text("No family data available"))
                  : GraphView(
                graph: graph,
                algorithm: BuchheimWalkerAlgorithm(builder, TreeEdgeRenderer(builder)),
                builder: (node) {
                  final name = node.key?.value.toString() ?? '';
                  return _nodeWidget(
                    name,
                    isChild: highlightedChildren.contains(name.trim().toLowerCase()),
                  );
                },
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey, // 👈 Set your background color here
              borderRadius: BorderRadius.circular(12), // Optional: rounded corners
            ),
            padding: const EdgeInsets.all(8.0), // Optional: internal padding
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton(
                  heroTag: 'zoomIn',
                  mini: true,
                  onPressed: () {
                    setState(() {
                      _transformationController.value =
                      _transformationController.value.clone()..scale(1.2);
                    });
                  },
                  child: const Icon(Icons.zoom_in),
                ),
                const SizedBox(width: 20),
                FloatingActionButton(
                  heroTag: 'zoomOut',
                  mini: true,
                  onPressed: () {
                    setState(() {
                      _transformationController.value =
                      _transformationController.value.clone()..scale(0.8);
                    });
                  },
                  child: const Icon(Icons.zoom_out),
                ),
                const SizedBox(width: 20),
                FloatingActionButton(
                  heroTag: 'resetZoom',
                  mini: true,
                  onPressed: () {
                    setState(() {
                      _transformationController.value = Matrix4.identity()..scale(0.7);
                    });
                  },
                  child: const Icon(Icons.refresh),
                ),
                const SizedBox(width: 20),
                FloatingActionButton(
                  heroTag: 'clearPath',
                  mini: true,
                  onPressed: () {
                    setState(() {
                      pathToRoot.clear();
                    });
                  },
                  child: const Icon(Icons.clear_all),
                ),
              ],
            ),
          ),
        ),


      ]),
    );
  }
}

class FamilyMemberSearchDelegate extends SearchDelegate<String?> {
  final Map<String, Node> nodeMap;
  FamilyMemberSearchDelegate(this.nodeMap);

  @override
  Widget buildLeading(BuildContext ctx) =>
      IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(ctx, null));

  @override
  List<Widget> buildActions(BuildContext ctx) =>
      [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];

  @override
  Widget buildSuggestions(BuildContext ctx) => _buildList();

  @override
  Widget buildResults(BuildContext ctx) => _buildList();

  Widget _buildList() {
    final hits = nodeMap.keys
        .where((n) => n.contains(query.toLowerCase()))
        .toList();

    if (hits.isEmpty) {
      return const Center(child: Text('No matching results found.'));
    }
    return ListView.builder(
        itemCount: hits.length,
        itemBuilder: (ctx, i) => ListTile(
          title: Text(hits[i]),
          onTap: () => close(ctx, hits[i]),
        ));
  }
}