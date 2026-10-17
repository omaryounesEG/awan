part of graphview;

const int DEFAULT_ITERATIONS = 1000;
const double REPULSION_RATE = 0.5;
const double REPULSION_PERCENTAGE = 0.4;
const double ATTRACTION_RATE = 0.15;
const double ATTRACTION_PERCENTAGE = 0.15;
const int CLUSTER_PADDING = 15;
const double EPSILON = 0.0001;

class FruchtermanReingoldAlgorithm implements Algorithm {
  Map<Node, Offset> displacement = {};
  Random rand = Random();
  double graphHeight = 500; //default value, change ahead of time
  double graphWidth = 500;

  /// AWAN SHIM: true once a caller told us the real drawing area, so `run` stops
  /// replacing it with its own node-count heuristic.
  bool _awanDimensionsProvided = false;
  late double tick;

  int iterations = DEFAULT_ITERATIONS;
  double repulsionRate = REPULSION_RATE;
  double attractionRate = ATTRACTION_RATE;
  double repulsionPercentage = REPULSION_PERCENTAGE;
  double attractionPercentage = ATTRACTION_PERCENTAGE;

  @override
  EdgeRenderer? renderer;

  FruchtermanReingoldAlgorithm(
      {this.iterations = DEFAULT_ITERATIONS,
      this.renderer,
      this.repulsionRate = REPULSION_RATE,
      this.attractionRate = ATTRACTION_RATE,
      this.repulsionPercentage = REPULSION_PERCENTAGE,
      this.attractionPercentage = ATTRACTION_PERCENTAGE}) {
    renderer = renderer ?? ArrowEdgeRenderer();
  }

  @override
  void init(Graph? graph) {
    graph!.nodes.forEach((node) {
      displacement[node] = Offset.zero;
      // AWAN SHIM: a node that already carries a position was seeded by the
      // caller (a ring around the focus ayah); keep it and only scatter the
      // nodes that have none. A pre-arranged start converges to a better
      // diagram than a fully random one, and it makes small graphs stable.
      if (node.position == Offset.zero) {
        node.position =
            Offset(rand.nextDouble() * graphWidth, rand.nextDouble() * graphHeight);
      }
    });
  }

  @override
  void step(Graph? graph) {
    displacement = {};
    graph!.nodes.forEach((node) {
      displacement[node] = Offset.zero;
    });
    calculateRepulsion(graph.nodes);
    calculateAttraction(graph.edges);
    moveNodes(graph);
  }

  void moveNodes(Graph graph) {
    graph.nodes.forEach((node) {
      var newPosition = node.position += displacement[node]!;
      // AWAN SHIM: the old constants clamped the top-left corner to a margin of
      // 40 px, so a 44-66 px circle still hung over the edge. Clamp the whole
      // circle instead (and fall back gracefully in a tiny box).
      final double w = node.width;
      final double h = node.height;
      double newDX = min(max(w, graphWidth - w), max(w, newPosition.dx));
      double newDY = min(max(h, graphHeight - h), max(h, newPosition.dy));

      // double newDX = newPosition.dx;
      // double newDY = newPosition.dy;
      node.position = Offset(newDX, newDY);
    });
  }

  void cool(int currentIteration) {
    tick *= 1.0 - currentIteration / iterations;
  }

  /// AWAN SHIM: hold every node inside the drawing area the caller handed us.
  /// `moveNodes` does this on the animated (`step`) path, but the static `run`
  /// loop moves nodes with `limitMaximumDisplacement`, which had no clamp at all
  /// — so a 30-node graph drifted over a 1300 px square and most of it fell off
  /// a phone screen.
  Offset _awanClamp(Node node, Offset position) {
    final double halfW = node.width * 0.5;
    final double halfH = node.height * 0.5;
    return Offset(
      position.dx.clamp(halfW, max(halfW, graphWidth - halfW)),
      position.dy.clamp(halfH, max(halfH, graphHeight - halfH)),
    );
  }

  void _awanClampAll(Graph graph) {
    if (!_awanDimensionsProvided) {
      return;
    }
    for (final Node node in graph.nodes) {
      node.position = _awanClamp(node, node.position);
    }
  }

  void limitMaximumDisplacement(List<Node> nodes) {
    nodes.forEach((node) {
      if (node != focusedNode) {
        var dispLength = max(EPSILON, displacement[node]!.distance);
        var next =
            node.position + displacement[node]! / dispLength * min(dispLength, tick);
        if (_awanDimensionsProvided) {
          next = _awanClamp(node, next);
        }
        node.position = next;
      } else {
        displacement[node] = Offset.zero;
      }
    });
  }

  void calculateAttraction(List<Edge> edges) {
    edges.forEach((edge) {
      var source = edge.source;
      var destination = edge.destination;
      var delta = source.position - destination.position;
      var deltaDistance = max(EPSILON, delta.distance);
      var maxAttractionDistance = min(graphWidth * attractionPercentage, graphHeight * attractionPercentage);
      var attractionForce = min(0, (maxAttractionDistance - deltaDistance)).abs() / (maxAttractionDistance * 2);
      var attractionVector = delta * attractionForce * attractionRate;

      displacement[source] = displacement[source]! - attractionVector;
      displacement[destination] = displacement[destination]! + attractionVector;
    });
  }

  void calculateRepulsion(List<Node> nodes) {
    nodes.forEach((nodeA) {
      nodes.forEach((nodeB) {
        if (nodeA != nodeB) {
          var delta = nodeA.position - nodeB.position;
          var deltaDistance = max(EPSILON, delta.distance); //protect for 0
          var maxRepulsionDistance = min(graphWidth * repulsionPercentage, graphHeight * repulsionPercentage);
          var repulsionForce = max(0, maxRepulsionDistance - deltaDistance) / maxRepulsionDistance; //value between 0-1
          var repulsionVector = delta * repulsionForce * repulsionRate;

          displacement[nodeA] = displacement[nodeA]! + repulsionVector;
        }
      });
    });

    nodes.forEach((nodeA) {
      displacement[nodeA] = displacement[nodeA]! / nodes.length.toDouble();
    });
  }

  var focusedNode;

  @override
  Size run(Graph? graph, double shiftX, double shiftY) {
    var size = findBiggestSize(graph!) * graph.nodeCount();
    // AWAN SHIM: prefer the viewport the render box passed in. The node-count
    // heuristic below is fine for a desktop canvas but puts a 30-node graph in a
    // 1300x1300 box, i.e. mostly off a phone screen. `moveNodes` clamps every
    // node into graphWidth x graphHeight, so the viewport is the right area.
    if (!_awanDimensionsProvided) {
      graphWidth = size;
      graphHeight = size;
    }

    var nodes = graph.nodes;
    var edges = graph.edges;

    tick = 0.1 * sqrt(graphWidth / 2 * graphHeight / 2);

    init(graph);

    for (var i = 0; i < iterations; i++) {
      calculateRepulsion(nodes);
      calculateAttraction(edges);
      limitMaximumDisplacement(nodes);

      cool(i);

      if (done()) {
        break;
      }
    }

    if (focusedNode == null) {
      positionNodes(graph);
    }

    shiftCoordinates(graph, shiftX, shiftY);

    // AWAN SHIM: `positionNodes` re-clusters and can move nodes again, so clamp
    // once more before reporting the size.
    _awanClampAll(graph);

    return calculateGraphSize(graph);
  }

  void shiftCoordinates(Graph graph, double shiftX, double shiftY) {
    graph.nodes.forEach((node) {
      node.position = Offset(node.x + shiftX, node.y + shiftY);
    });
  }

  void positionNodes(Graph graph) {
    var offset = getOffset(graph);
    var x = offset.dx;
    var y = offset.dy;
    var nodesVisited = <Node>[];
    var nodeClusters = <NodeCluster>[];
    graph.nodes.forEach((node) {
      node.position = Offset(node.x - x, node.y - y);
    });

    graph.nodes.forEach((node) {
      if (!nodesVisited.contains(node)) {
        nodesVisited.add(node);
        var cluster = findClusterOf(nodeClusters, node);
        if (cluster == null) {
          cluster = NodeCluster();
          cluster.add(node);
          nodeClusters.add(cluster);
        }

        followEdges(graph, cluster, node, nodesVisited);
      }
    });

    positionCluster(nodeClusters);
  }

  void positionCluster(List<NodeCluster> nodeClusters) {
    combineSingleNodeCluster(nodeClusters);

    var cluster = nodeClusters[0];
    // move first cluster to 0,0
    cluster.offset(-cluster.rect!.left, -cluster.rect!.top);

    for (var i = 1; i < nodeClusters.length; i++) {
      var nextCluster = nodeClusters[i];
      var xDiff = nextCluster.rect!.left - cluster.rect!.right - CLUSTER_PADDING;
      var yDiff = nextCluster.rect!.top - cluster.rect!.top;
      nextCluster.offset(-xDiff, -yDiff);
      cluster = nextCluster;
    }
  }

  void combineSingleNodeCluster(List<NodeCluster> nodeClusters) {
    NodeCluster? firstSingleNodeCluster;

    nodeClusters.forEach((cluster) {
      if (cluster.size() == 1) {
        if (firstSingleNodeCluster == null) {
          firstSingleNodeCluster = cluster;
        } else {
          firstSingleNodeCluster!.concat(cluster);
        }
      }
    });

    nodeClusters.removeWhere((element) => element.size() == 1);
  }

  void followEdges(Graph graph, NodeCluster cluster, Node node, List nodesVisited) {
    graph.successorsOf(node).forEach((successor) {
      if (!nodesVisited.contains(successor)) {
        nodesVisited.add(successor);
        cluster.add(successor);

        followEdges(graph, cluster, successor, nodesVisited);
      }
    });

    graph.predecessorsOf(node).forEach((predecessor) {
      if (!nodesVisited.contains(predecessor)) {
        nodesVisited.add(predecessor);
        cluster.add(predecessor);

        followEdges(graph, cluster, predecessor, nodesVisited);
      }
    });
  }

  NodeCluster? findClusterOf(List<NodeCluster> clusters, Node node) {
    return clusters.firstWhereOrNull((element) => element.contains(node));
  }

  double findBiggestSize(Graph graph) {
    return graph.nodes.map((it) => max(it.height, it.width)).reduce(max);
  }

  Offset getOffset(Graph graph) {
    var offsetX = double.infinity;
    var offsetY = double.infinity;

    graph.nodes.forEach((node) {
      offsetX = min(offsetX, node.x);
      offsetY = min(offsetY, node.y);
    });

    return Offset(offsetX, offsetY);
  }

  bool done() {
    return tick < 1.0 / max(graphHeight, graphWidth);
  }

  void drawEdges(Canvas canvas, Graph graph, Paint linePaint) {}

  Size calculateGraphSize(Graph graph) {
    var left = double.infinity;
    var top = double.infinity;
    var right = double.negativeInfinity;
    var bottom = double.negativeInfinity;

    graph.nodes.forEach((node) {
      left = min(left, node.x);
      top = min(top, node.y);
      right = max(right, node.x + node.width);
      bottom = max(bottom, node.y + node.height);
    });

    return Size(right - left, bottom - top);
  }

  @override
  void setFocusedNode(Node node) {}

  @override
  void setDimensions(double width, double height) {
    graphWidth = width;
    graphHeight = height;
    _awanDimensionsProvided = true;
  }
}

class NodeCluster {
  List<Node>? nodes;

  Rect? rect;

  List<Node>? getNodes() {
    return nodes;
  }

  Rect? getRect() {
    return rect;
  }

  void setRect(Rect rect) {
    rect = rect;
  }

  void add(Node node) {
    nodes!.add(node);

    if (nodes!.length == 1) {
      rect = Rect.fromLTRB(node.x, node.y, node.x + node.width, node.y + node.height);
    } else {
      rect = Rect.fromLTRB(min(rect!.left, node.x), min(rect!.top, node.y), max(rect!.right, node.x + node.width),
          max(rect!.bottom, node.y + node.height));
    }
  }

  bool contains(Node node) {
    return nodes!.contains(node);
  }

  int size() {
    return nodes!.length;
  }

  void concat(NodeCluster cluster) {
    cluster.nodes!.forEach((node) {
      node.position = (Offset(rect!.right + CLUSTER_PADDING, rect!.top));
      add(node);
    });
  }

  void offset(double xDiff, double yDiff) {
    nodes!.forEach((node) {
      node.position = (node.position + Offset(xDiff, yDiff));
    });

    rect = rect!.translate(xDiff, yDiff);
  }

  NodeCluster() {
    nodes = [];
    rect = Rect.zero;
  }
}
