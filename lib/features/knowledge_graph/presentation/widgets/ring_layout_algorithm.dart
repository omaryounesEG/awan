import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

/// A deterministic layout for a one-to-many similarity graph: the ayah being
/// read sits in the middle and its similar ayat sit on a ring around it.
///
/// Why not Fruchterman-Reingold, which is what a force-directed graph normally
/// wants? Three reasons, all observed on the device rather than assumed:
///
/// * **It fits by construction.** A force-directed pass has no idea how much
///   room it has, so a 30-target graph spread over a square wider than the
///   screen and only one node stayed visible. Here the radius is derived from
///   the canvas the render box reports, so every node is on screen by
///   definition.
/// * **It is stable.** The layout is a pure function of the graph, so a
///   relayout (a tap, an orientation change) cannot teleport the diagram.
/// * **It is readable.** For this shape — one centre, N spokes — a ring reads
///   better than a hairball: the eye can count the spokes and trace an edge
///   without crossing others.
///
/// The graphview package still draws the canvas, the edges and the arrows; only
/// the placement is ours.
class RingLayoutAlgorithm implements Algorithm {
  RingLayoutAlgorithm({this.padding = 10});

  /// Space kept between a node and the edge of the canvas.
  final double padding;

  @override
  EdgeRenderer? renderer = ArrowEdgeRenderer();

  double _width = 360;
  double _height = 520;

  @override
  void setDimensions(double width, double height) {
    if (width.isFinite && width > 0) {
      _width = width;
    }
    if (height.isFinite && height > 0) {
      _height = height;
    }
  }

  @override
  void init(Graph? graph) {}

  @override
  void step(Graph? graph) {}

  @override
  void setFocusedNode(Node node) {}

  @override
  Size run(Graph? graph, double shiftX, double shiftY) {
    if (graph == null || graph.nodes.isEmpty) {
      return Size(_width, _height);
    }

    final List<Node> nodes = graph.nodes;
    final Node source = nodes.first;
    final List<Node> targets = nodes.skip(1).toList();

    double biggest = 0;
    for (final Node node in nodes) {
      biggest = math.max(biggest, math.max(node.width, node.height));
    }
    final double half = biggest / 2;

    final double centreX = _width / 2;
    final double centreY = _height / 2;
    source.position = Offset(centreX, centreY);

    if (targets.isEmpty) {
      return Size(_width, _height);
    }

    // A ring tight enough to leave the padding, and never so small that the
    // nodes sit on top of each other.
    final double room = math.min(_width, _height) / 2 - half - padding;
    final double minimum = targets.length <= 1 ? 0 : half * 1.4;
    final double radius = math.max(minimum, room);

    for (int i = 0; i < targets.length; i++) {
      final Node target = targets[i];
      final double angle = (2 * math.pi * i) / targets.length - math.pi / 2;
      final double x = centreX + radius * math.cos(angle);
      final double y = centreY + radius * math.sin(angle);
      // Keep the whole circle inside the canvas even if the radius had to be
      // clamped for a single-target graph.
      target.position = Offset(
        x.clamp(half, math.max(half, _width - half)),
        y.clamp(half, math.max(half, _height - half)),
      );
    }

    return Size(_width, _height);
  }
}
