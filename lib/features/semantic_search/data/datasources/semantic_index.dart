import 'dart:convert';
import 'dart:typed_data';

/// The precomputed, int8-quantised matrix of verse embeddings.
///
/// 6,236 rows × 384 dimensions as bytes is 2.4 MB — which is the whole point of
/// the quantisation: the same matrix as float32 would be 9.6 MB and would need
/// no dequantisation but would cost four times the install size.
///
/// Search is a linear scan: one dot product per row, int8 × float32, then the
/// row's own scale. On a mid-range phone that is a few milliseconds for the whole
/// Quran, so an HNSW graph would add a dependency and a build step to save
/// nothing at this scale.
class SemanticIndex {
  SemanticIndex({
    required this.dim,
    required this.count,
    required Uint8List vectors,
    required Float32List scales,
    required List<SemanticRow> rows,
  })  : _vectors = vectors,
        _scales = scales,
        _rows = rows;

  static const String assetRoot = 'assets/semantic';

  final int dim;
  final int count;
  final Uint8List _vectors;
  final Float32List _scales;
  final List<SemanticRow> _rows;

  static int _rowBytes(int dim) => dim;

  /// Parses the three files the Python build wrote.
  factory SemanticIndex.fromBytes({
    required Uint8List vectors,
    required Uint8List scales,
    required String manifestJson,
  }) {
    final Map<String, dynamic> manifest =
        jsonDecode(manifestJson) as Map<String, dynamic>;
    final int dim = (manifest['dim'] as num).toInt();
    final int count = (manifest['count'] as num).toInt();
    final List<SemanticRow> rows = <SemanticRow>[
      for (final dynamic raw in manifest['rows'] as List<dynamic>)
        SemanticRow(
          surah: ((raw as Map<String, dynamic>)['s'] as num).toInt(),
          ayah: (raw['a'] as num).toInt(),
        ),
    ];
    if (vectors.length < count * dim) {
      throw StateError(
        'semantic index is short: ${vectors.length} bytes for $count×$dim',
      );
    }
    return SemanticIndex(
      dim: dim,
      count: count,
      vectors: vectors,
      scales: Float32List.view(
        scales.buffer,
        scales.offsetInBytes,
        scales.length ~/ 4,
      ),
      rows: rows,
    );
  }

  SemanticRow row(int index) => _rows[index];

  int get rowCount => _rows.length;

  int _offsetOf(int index) => index * _rowBytes(dim);

  /// The top [limit] rows by cosine similarity to an already-normalised [query].
  ///
  /// Ties are broken by row order, which is mushaf order — two equally good
  /// matches then appear in the order the reader expects to find them.
  List<ScoredRow> search(Float64List query, {int limit = 40}) {
    final int dim = this.dim;
    final List<ScoredRow> best = <ScoredRow>[];
    double worst = double.negativeInfinity;

    for (int index = 0; index < count; index++) {
      final int offset = _offsetOf(index);
      double dot = 0;
      for (int d = 0; d < dim; d++) {
        // int8 → double straight from the byte; the row scale is applied once.
        dot += query[d] * (_vectors[offset + d] >= 128
            ? _vectors[offset + d] - 256
            : _vectors[offset + d]);
      }
      final double score = dot * _scales[index];

      if (best.length < limit) {
        best.add(ScoredRow(index: index, score: score));
        if (best.length == limit) {
          best.sort((ScoredRow a, ScoredRow b) => b.score.compareTo(a.score));
          worst = best.last.score;
        }
      } else if (score > worst) {
        best[best.length - 1] = ScoredRow(index: index, score: score);
        best.sort((ScoredRow a, ScoredRow b) => b.score.compareTo(a.score));
        worst = best.last.score;
      }
    }

    if (best.length < limit) {
      best.sort((ScoredRow a, ScoredRow b) => b.score.compareTo(a.score));
    }
    return best;
  }
}

class SemanticRow {
  const SemanticRow({required this.surah, required this.ayah});

  final int surah;
  final int ayah;
}

class ScoredRow {
  const ScoredRow({required this.index, required this.score});

  final int index;
  final double score;
}
