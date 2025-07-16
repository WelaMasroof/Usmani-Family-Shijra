import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:graphview/GraphView.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../API/api_service.dart';
import '../models/person.dart';
import '../splash screen/login page.dart';

class FamilyTreeGraph extends StatefulWidget {
  const FamilyTreeGraph({super.key});

  @override
  State<FamilyTreeGraph> createState() => _GraphPageState();
}

class _GraphPageState extends State<FamilyTreeGraph> with TickerProviderStateMixin {
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

      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (ctx) => pw.Center(
          child: pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text('Usmani Family Shijra',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Expanded(child: pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.contain)),
            ],
          ),
        ),
      ));

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

  void _showTooltip(BuildContext ctx, String name, GlobalKey key) {
    final norm = name.trim().toLowerCase();
    final p = personMap[norm];
    if (p == null) return;

    final rb = key.currentContext?.findRenderObject() as RenderBox?;
    if (rb == null) return;

    final pos = rb.localToGlobal(Offset.zero);
    final sz = rb.size;

    // Find grandfather by looking up father's father
    String? grandfatherName;
    if (p.fatherName.isNotEmpty) {
      final fatherNorm = p.fatherName.trim().toLowerCase();
      final father = personMap[fatherNorm];
      if (father != null && father.fatherName.isNotEmpty) {
        grandfatherName = father.fatherName;
      }
    }

    _overlayEntry?.remove();
    _overlayEntry = OverlayEntry(
      builder: (_) => Positioned(
        left: pos.dx + sz.width / 2 - 150, // Increased width
        top: pos.dy - 120, // Increased height
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 300, // Increased width
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.85),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with name
                if (p.name.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      p.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                // ID
                if (p.id.isNotEmpty)
                  _buildInfoRow('ID:', p.id),

                // Father
                if (p.fatherName.isNotEmpty)
                  _buildInfoRow('Father:', p.fatherName),

                // Grandfather
                if (grandfatherName != null && grandfatherName!.isNotEmpty)
                  _buildInfoRow('Grandfather:', grandfatherName!),

                // Mother
                if (p.motherName.isNotEmpty ?? false)
                  _buildInfoRow('Mother:', p.motherName),

                // Instruction
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          size: 16, color: Colors.green),
                      const SizedBox(width: 6),
                      Text(
                        'Long press to trace ancestry to root',
                        style: TextStyle(
                          color: Colors.green.shade300,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
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

// Helper widget for consistent info rows
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Usmani Family Shijra"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadGraph,
            tooltip: 'Refresh Graph',
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(children: [
          const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text('Menu',
                  style: TextStyle(color: Colors.white, fontSize: 24))),
          ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Search Family Member'),
              onTap: () async {
                Navigator.pop(context);
                final res = await showSearch<String?>(
                    context: ctx, delegate: FamilyMemberSearchDelegate(nodeMap));
                if (res != null) _searchAndHighlight(res);
              }),
          ListTile(
              leading: const Icon(Icons.print),
              title: const Text('Export as PDF'),
              onTap: () {
                Navigator.pop(context);
                _exportGraphAsPdf();
              }),

          if (_isAdmin) ...[
            ListTile(
                leading: const Icon(Icons.group_add),
                title: const Text('Add Family Member'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(ctx, '/add');
                }),
            ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete Family Member'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(ctx, '/delete');
                }),
            ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () async {
                  final s = FlutterSecureStorage();
                  await s.delete(key: 'admin_token');
                  Navigator.pushReplacement(
                      ctx, MaterialPageRoute(builder: (_) => const LoginPage()));
                }),
          ],
        ]),
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