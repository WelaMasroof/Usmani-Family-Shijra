import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_force_directed_graph/flutter_force_directed_graph.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../API/api_service.dart';
import '../models/person.dart';
import 'package:pdf/pdf.dart';

class FamilyTreeGraph extends StatefulWidget {
  const FamilyTreeGraph({super.key});

  @override
  State<FamilyTreeGraph> createState() => _FamilyTreeGraphState();
}

class _FamilyTreeGraphState extends State<FamilyTreeGraph> {
  late final ForceDirectedGraphController<String> _controller;
  final GlobalKey _graphKey = GlobalKey();
  final Map<String, Person> _personMap = {};
  final Set<String> _addedNodes = {};
  final Set<String> _highlightedNodes = {}; // ✅ FIX: declare this!
  bool _loading = true;

  final List<Color> generationColors = [
    Colors.green,
    Colors.blue,
    Colors.purple,
    Colors.orange,
    Colors.teal,
    Colors.red,
    Colors.brown,
    Colors.pink,
    Colors.indigo,
  ];

  @override
  void initState() {
    super.initState();
    _controller = ForceDirectedGraphController<String>();
    _loadFamilyTree();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadFamilyTree() async {
    try {
      final persons = await ApiService.fetchPersons();

      for (final person in persons) {
        _personMap[person.name] = person;
        if (!_addedNodes.contains(person.name)) {
          _controller.addNode(person.name);
          _addedNodes.add(person.name);
        }
      }

      for (final person in persons) {
        final father = person.fatherName.trim();
        if (father.isNotEmpty && _addedNodes.contains(father)) {
          _controller.addEdgeByData(father, person.name);
        }
      }

      setState(() => _loading = false);
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading family tree: $e')),
      );
    }
  }

  int _calculateGeneration(String name) {
    int generation = 0;
    String? currentName = name;

    while (currentName != null &&
        _personMap[currentName]?.fatherName.trim().isNotEmpty == true) {
      generation++;
      currentName = _personMap[currentName]?.fatherName.trim();
    }

    return generation;
  }

  String _getShortName(String fullName) {
    final parts = fullName.split(' ');
    if (parts.length > 2) {
      return '${parts[0]} ${parts[1][0]}.';
    }
    return fullName;
  }

  Widget _nodeBuilder(BuildContext context, String name) {
    final generation = _calculateGeneration(name);
    final color = generation < generationColors.length
        ? generationColors[generation]
        : Colors.grey;
    final isRoot = generation == 0;
    final isHighlighted = _highlightedNodes.contains(name);

    return GestureDetector(
      onTap: () => _showPersonDetails(context, _personMap[name]!),
      child: Tooltip(
        message: name,
        child: Container(
          width: isRoot ? 80 : 60,
          height: isRoot ? 80 : 60,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: isHighlighted ? Colors.yellow : Colors.white,
              width: isHighlighted ? 4 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: isHighlighted
                    ? Colors.yellow.withOpacity(0.6)
                    : Colors.black.withOpacity(0.2),
                blurRadius: isHighlighted ? 10 : 5,
                spreadRadius: isHighlighted ? 2 : 1,
              )
            ],
          ),
          child: Center(
            child: Text(
              _getShortName(name),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: isRoot ? 14 : 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showPersonDetails(BuildContext context, Person person) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(person.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${person.id}'),
            const SizedBox(height: 8),
            Text('Father: ${person.fatherName.trim().isEmpty ? 'Root Member' : person.fatherName}'),
            const SizedBox(height: 8),
            Text('Generation: ${_calculateGeneration(person.name) + 1}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportGraphAsPdf() async {
    try {
      RenderRepaintBoundary boundary =
      _graphKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final doc = pw.Document();
      final imagePdf = pw.MemoryImage(pngBytes);

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          build: (pw.Context context) {
            return pw.Center(child: pw.Image(imagePdf));
          },
        ),
      );

      await Printing.layoutPdf(onLayout: (format) async => doc.save());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usmani Family Tree'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              final result = await showSearch(
                context: context,
                delegate: FamilyMemberSearchDelegate(_personMap.keys.toList()),
              );
              if (result != null && _addedNodes.contains(result)) {
                _highlightedNodes.clear();
                _highlightedNodes.add(result);
                setState(() {});
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _exportGraphAsPdf,
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Color Guide'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(generationColors.length, (index) {
                    final label = index == 0
                        ? 'Generation ${index + 1} (Root)'
                        : 'Generation ${index + 1}';
                    return _buildColorLegend(label, generationColors[index]);
                  }),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RepaintBoundary(
        key: _graphKey,
        child: ForceDirectedGraphWidget<String>(
          controller: _controller,
          nodesBuilder: _nodeBuilder,
          edgesBuilder: (ctx, a, b, distance) => Container(
            width: distance,
            height: 1.5,
            color: Colors.grey.withOpacity(0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildColorLegend(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white),
            ),
          ),
          const SizedBox(width: 10),
          Text(text),
        ],
      ),
    );
  }
}

class FamilyMemberSearchDelegate extends SearchDelegate<String> {
  final List<String> names;

  FamilyMemberSearchDelegate(this.names);

  @override
  List<Widget> buildActions(BuildContext context) => [
    IconButton(
      icon: const Icon(Icons.clear),
      onPressed: () => query = '',
    )
  ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, ''),
  );

  @override
  Widget buildResults(BuildContext context) {
    final results = names
        .where((name) => name.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final name = results[index];
        return ListTile(
          title: Text(name),
          onTap: () => close(context, name),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = names
        .where((name) => name.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final name = suggestions[index];
        return ListTile(
          title: Text(name),
          onTap: () => close(context, name),
        );
      },
    );
  }
}
