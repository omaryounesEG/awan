
import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

import 'package:awan/features/knowledge_graph/domain/entities/mutashabih_entities.dart';
import 'package:awan/features/knowledge_graph/presentation/widgets/mutashabih_node_views.dart';
import 'package:awan/features/knowledge_graph/presentation/widgets/ring_layout_algorithm.dart';


/// The similarity diagram for one ayah: the ayah in the middle, its similar
/// ayat on a ring around it, an arrow per similarity.
///
/// * The `Graph` and the layout live in this widget's `State`, not in `build`,
///   and the layout (`RingLayoutAlgorithm`) is a pure function of the graph —
///   so a rebuild, a tap or a rotation rearranges nothing.
/// * Node **sizes** are set here rather than left to measurement: graphview
///   uses them to keep circles apart and to clamp the ring inside the canvas.
/// * The package draws the canvas, the edges and the arrowheads; the placement
///   is ours, because the force-directed layout it ships cannot know how much
///   room it has (see `docs/STEP_10_knowledge_graph.md`).

class MutashabihGraph extends StatefulWidget {
  const MutashabihGraph({
    super.key,
    required this.node,
    required this.labelFor,
    required this.onTargetTap,

    this.highlightedTargetIndex,
    this.edgeColor,
  });

  final MutashabihNodeEntry node;

  /// `(surah, ayah)` → the label drawn inside a node.
  final String Function(int surah, int ayah) labelFor;

  /// Index into `node.targets`.
  final void Function(int targetIndex) onTargetTap;

  /// The target whose sheet is currently open, if any.
  final int? highlightedTargetIndex;

  final Color? edgeColor;

  @override
  State<MutashabihGraph> createState() => _MutashabihGraphState();
}

class _MutashabihGraphState extends State<MutashabihGraph> {
  static const String _sourceKey = 'src';

  late Graph _graph;
  late RingLayoutAlgorithm _algorithm;

  @override
  void initState() {
    super.initState();
    _build();
  }

  @override
  void didUpdateWidget(covariant MutashabihGraph oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new ayah *or* a new display level: the second case keeps the same source
    // and only shortens the target list, and it must re-lay-out the whole
    // diagram — leaving the old edges behind draws arrows to circles that are no
    // longer there.
    if (oldWidget.node.sourceAbsoluteId != widget.node.sourceAbsoluteId ||
        oldWidget.node.targets.length != widget.node.targets.length) {
      _build();
    }
  }

  /// The circle diameter for a graph with [targetCount] targets — shared with
  /// the node view so the layout and the painted circle agree.
  static double diameterFor(int targetCount) =>
      targetCount > 20 ? 44 : (targetCount > 12 ? 54 : 66);

  static const double _sourceDiameter = 96;

  void _build() {
    _graph = Graph();
    _algorithm = RingLayoutAlgorithm();

    final Node source = Node.Id(_sourceKey);
    // Sizes are what graphview uses to keep circles apart and to clamp them
    // inside the canvas, so they are set here rather than left to measurement.
    const double sourceDiameter = _sourceDiameter;
    source.size = const Size(sourceDiameter, sourceDiameter);

    final int count = widget.node.targets.length;
    final double diameter = diameterFor(count);
    for (int i = 0; i < count; i++) {
      final Node target = Node.Id('t$i');
      target.size = Size(diameter, diameter);
      _graph.addEdge(
        source,
        target,
        paint: Paint()
          ..strokeWidth = 1.2
          ..color = widget.edgeColor ?? const Color(0x552B2B24),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // The key is what actually re-creates the package's render object when the
    // source or the level changes; without it graphview keeps the graph it was
    // handed first.
    return GraphView(
      key: ValueKey<String>(
        '${widget.node.sourceAbsoluteId}/${widget.node.targets.length}',
      ),
      graph: _graph,
      algorithm: _algorithm,
      animated: true,
      builder: _nodeBuilder,
    );
  }

  Widget _nodeBuilder(Node node) {
    final String key = (node.key?.value ?? '').toString();

    if (key == _sourceKey) {
      return MutashabihSourceNodeView(
        label: widget.labelFor(
          widget.node.sourceSurahNumber,
          widget.node.sourceAyahNumber,
        ),
      );
    }

    final int index = int.tryParse(key.length > 1 ? key.substring(1) : '') ?? -1;
    if (index < 0 || index >= widget.node.targets.length) {
      return const SizedBox.shrink();
    }

    final MutashabihTargetEntry target = widget.node.targets[index];
    return MutashabihTargetNodeView(
      label: widget.labelFor(target.targetSurahNumber, target.targetAyahNumber),
      // A 30-target graph has to fit one screen: the circles shrink with the
      // fan-out so the layout has room to separate them.
      diameter: diameterFor(widget.node.targetCount),
      highlighted: widget.highlightedTargetIndex == index,
      onTap: () => widget.onTargetTap(index),
    );
  }
}
