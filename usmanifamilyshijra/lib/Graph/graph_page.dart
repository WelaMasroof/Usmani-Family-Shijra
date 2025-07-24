import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import '../API/api_service.dart';
import '../models/person.dart';

class GraphPage extends StatefulWidget {
  const GraphPage({super.key});

  @override
  State<GraphPage> createState() => _GraphPageState();
}

class _GraphPageState extends State<GraphPage> with TickerProviderStateMixin {
  final Graph graph = Graph()..isTree = true;
  final BuchheimWalkerConfiguration builder = BuchheimWalkerConfiguration();

  Map<String, Node> nodeMap = {};
  Map<String, Person> personMap = {};
  final Map<String, AnimationController> _animationControllers = {};
  OverlayEntry? _overlayEntry;

  bool loading = true;
  String? highlightedName;

  final TransformationController _transformationController = TransformationController();
  final GlobalKey _graphKey = GlobalKey();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadGraph();
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _transformationController.dispose();
    _searchController.dispose();
    for (var controller in _animationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> loadGraph() async {
    try {
      final persons = await ApiService.fetchPersons();
      final Map<String, List<String>> treeMap = {};
      String normalize(String value) => value.trim().toLowerCase();

      for (var person in persons) {
        final child = normalize(person.name);
        final father = normalize(person.fatherName);

        if (father.isNotEmpty) {
          treeMap[father] ??= [];
          treeMap[father]!.add(child);
        }

        personMap[child] = person;
      }

      for (var person in persons) {
        final normalizedName = normalize(person.name);
        nodeMap[normalizedName] = Node.Id(person.name);
        _animationControllers[normalizedName] = AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 300),
          lowerBound: 0.9,
          upperBound: 1.1,
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            _animationControllers[normalizedName]!.reverse();
          }
        });
      }

      for (var entry in treeMap.entries) {
        final fatherNode = nodeMap[entry.key];
        for (var childKey in entry.value) {
          final childNode = nodeMap[childKey];
          if (fatherNode != null && childNode != null) {
            graph.addEdge(fatherNode, childNode);
          }
        }
      }

      setState(() => loading = false);
    } catch (e) {
      debugPrint('Error loading graph: $e');
      setState(() => loading = false);
    }
  }

  void _showTooltip(BuildContext context, String name, GlobalKey key) {
    final normalizedName = name.trim().toLowerCase();
    final person = personMap[normalizedName];
    if (person == null) return;

    final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _overlayEntry?.remove();
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx + size.width / 2 - 100,
        top: position.dy - 70,
        child: Material(
          color: Colors.transparent,
          child: AnimatedOpacity(
            opacity: 1,
            duration: const Duration(milliseconds: 300),
            child: Container(
              width: 200,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.85),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Name: ${person.name}', style: const TextStyle(color: Colors.white)),
                  Text('Father: ${person.fatherName}', style: const TextStyle(color: Colors.white)),
                  Text('ID: ${person.id}', style: const TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);

    Future.delayed(const Duration(seconds: 5), () {
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
  }

  Widget _nodeWidget(String name) {
    final normalizedName = name.trim().toLowerCase();
    final key = GlobalKey();

    return GestureDetector(
      onTap: () {
        final controller = _animationControllers[normalizedName];
        controller?.forward();
        _showTooltip(context, name, key);
        setState(() {
          highlightedName = normalizedName;
        });
      },
      child: AnimatedBuilder(
        animation: _animationControllers[normalizedName]!,
        builder: (context, child) {
          return Transform.scale(
            scale: _animationControllers[normalizedName]!.value,
            child: child,
          );
        },
        child: Container(
          key: key,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.amberAccent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: normalizedName == highlightedName ? Colors.red : Colors.transparent,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: 4,
                color: Colors.grey.shade300,
              ),
            ],
          ),
          child: SizedBox(
            width: 160,
            child: Text(
              name,
              textAlign: TextAlign.center,
              softWrap: true,
              overflow: TextOverflow.visible,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _searchAndHighlight(String searchTerm) {
    String normalized = searchTerm.trim().toLowerCase();
    if (nodeMap.containsKey(normalized)) {
      setState(() {
        highlightedName = normalized;
      });

      // Optional: you could scroll here by modifying the transformation controller.
      // Currently, InteractiveViewer doesn't support jumping to child offset easily.
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Person "$searchTerm" not found')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    builder
      ..siblingSeparation = 25
      ..levelSeparation = 60
      ..subtreeSeparation = 25
      ..orientation = BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Usmani Family Shijra"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search by name...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                fillColor: Colors.white,
                filled: true,
              ),
              onSubmitted: _searchAndHighlight,
            ),
          ),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : InteractiveViewer(
        key: _graphKey,
        transformationController: _transformationController,
        constrained: false,
        boundaryMargin: const EdgeInsets.all(100),
        minScale: 0.1,
        maxScale: 10,
        panEnabled: true,
        scaleEnabled: true,
        child: GraphView(
          graph: graph,
          algorithm: BuchheimWalkerAlgorithm(builder, TreeEdgeRenderer(builder)),
          builder: (Node node) {
            final key = node.key;
            if (key == null || key.value == null) {
              return const Text('Unknown');
            }
            return _nodeWidget(key.value.toString());
          },
        ),
      ),
    );
  }
}
