import 'dart:math';
import 'dart:typed_data';

/// Min-Max scaler dengan bobot fitur opsional untuk RBF Kernel SVM.
class MinMaxFeatureScaler {
  final Float64List mins;
  final Float64List ranges;
  final Float64List weights;

  MinMaxFeatureScaler({
    required this.mins,
    required this.ranges,
    required this.weights,
  });

  factory MinMaxFeatureScaler.fit(
    List<Float64List> samples, {
    List<double>? featureWeights,
  }) {
    if (samples.isEmpty) {
      throw ArgumentError('Samples cannot be empty.');
    }
    final dims = samples.first.length;
    final mins = Float64List(dims)..fillRange(0, dims, double.infinity);
    final maxs = Float64List(dims)..fillRange(0, dims, double.negativeInfinity);

    for (final row in samples) {
      if (row.length != dims) {
        throw ArgumentError('Inconsistent feature vector length.');
      }
      for (int j = 0; j < dims; j++) {
        if (row[j] < mins[j]) mins[j] = row[j];
        if (row[j] > maxs[j]) maxs[j] = row[j];
      }
    }

    final ranges = Float64List(dims);
    final weights = Float64List(dims);
    for (int j = 0; j < dims; j++) {
      ranges[j] = maxs[j] - mins[j];
      weights[j] = featureWeights != null && j < featureWeights.length
          ? featureWeights[j]
          : 1.0;
    }

    return MinMaxFeatureScaler(
      mins: mins,
      ranges: ranges,
      weights: weights,
    );
  }

  Float64List transform(Float64List raw) {
    final dims = mins.length;
    if (raw.length != dims) {
      throw ArgumentError('Expected $dims features, got ${raw.length}.');
    }
    final out = Float64List(dims);
    for (int j = 0; j < dims; j++) {
      final r = ranges[j];
      final scaled = r == 0 ? 0.0 : (raw[j] - mins[j]) / r;
      out[j] = scaled * weights[j];
    }
    return out;
  }

  List<Float64List> transformAll(List<Float64List> rows) =>
      rows.map(transform).toList(growable: false);
}

/// Binary Support Vector Machine dengan RBF Kernel (Platt SMO + error cache).
class BinaryRbfSvm {
  final double c;
  final double gamma;
  final int maxPasses;
  final double tolerance;
  final int maxIterations;
  final int seed;

  late List<Float64List> _supportVectors;
  late Float64List _supportAlphaY;
  double _bias = 0.0;
  bool _fitted = false;

  BinaryRbfSvm({
    this.c = 300.0,
    this.gamma = 6.0,
    this.maxPasses = 15,
    this.tolerance = 1e-3,
    this.maxIterations = 60000,
    this.seed = 42,
  });

  int get supportVectorCount => _fitted ? _supportVectors.length : 0;
  double get bias => _bias;

  double _rbfKernel(Float64List a, Float64List b) {
    double distSq = 0.0;
    for (int i = 0; i < a.length; i++) {
      final diff = a[i] - b[i];
      distSq += diff * diff;
    }
    return exp(-gamma * distSq);
  }

  /// Melatih classifier biner dengan label +1.0 / -1.0.
  void fit(List<Float64List> features, List<double> labels) {
    final n = features.length;
    if (n == 0 || labels.length != n) {
      throw ArgumentError('Features and labels must be non-empty and equal length.');
    }

    final alphas = Float64List(n);
    _bias = 0.0;
    final rng = Random(seed);

    // Prekomputasi matriks kernel simetris untuk mempercepat SMO.
    final kernelMatrix = List<Float64List>.generate(n, (_) => Float64List(n));
    for (int i = 0; i < n; i++) {
      kernelMatrix[i][i] = 1.0;
      for (int j = i + 1; j < n; j++) {
        final k = _rbfKernel(features[i], features[j]);
        kernelMatrix[i][j] = k;
        kernelMatrix[j][i] = k;
      }
    }

    // Cache error E[i] = f(x_i) - y_i (awal: alpha = 0, b = 0 -> f(x_i) = 0).
    final errors = Float64List(n);
    for (int i = 0; i < n; i++) {
      errors[i] = -labels[i];
    }

    int passes = 0;
    int iter = 0;

    while (passes < maxPasses && iter < maxIterations) {
      int numChanged = 0;

      for (int i = 0; i < n; i++) {
        final ei = errors[i];
        final yi = labels[i];
        final aiOld = alphas[i];

        final violatesKkt =
            (yi * ei < -tolerance && aiOld < c) || (yi * ei > tolerance && aiOld > 0);
        if (!violatesKkt) {
          iter++;
          continue;
        }

        // Heuristik pilihan kedua: maksimalkan |Ei - Ej| dari kandidat acak.
        int j = rng.nextInt(n - 1);
        if (j >= i) j++;
        double maxStep = (ei - errors[j]).abs();
        for (int s = 0; s < 20; s++) {
          final cand = rng.nextInt(n);
          if (cand == i) continue;
          final step = (ei - errors[cand]).abs();
          if (step > maxStep) {
            maxStep = step;
            j = cand;
          }
        }

        final ej = errors[j];
        final yj = labels[j];
        final ajOld = alphas[j];

        double low, high;
        if (yi != yj) {
          low = max(0.0, ajOld - aiOld);
          high = min(c, c + ajOld - aiOld);
        } else {
          low = max(0.0, aiOld + ajOld - c);
          high = min(c, aiOld + ajOld);
        }
        if ((low - high).abs() < 1e-9) {
          iter++;
          continue;
        }

        final kii = kernelMatrix[i][i];
        final kjj = kernelMatrix[j][j];
        final kij = kernelMatrix[i][j];
        final eta = 2.0 * kij - kii - kjj;
        if (eta >= 0.0) {
          iter++;
          continue;
        }

        double ajNew = ajOld - yj * (ei - ej) / eta;
        if (ajNew > high) ajNew = high;
        if (ajNew < low) ajNew = low;
        if ((ajNew - ajOld).abs() < 1e-5) {
          iter++;
          continue;
        }

        final aiNew = aiOld + yi * yj * (ajOld - ajNew);
        final bOld = _bias;
        final b1 = _bias - ei - yi * (aiNew - aiOld) * kii - yj * (ajNew - ajOld) * kij;
        final b2 = _bias - ej - yi * (aiNew - aiOld) * kij - yj * (ajNew - ajOld) * kjj;

        if (aiNew > 0.0 && aiNew < c) {
          _bias = b1;
        } else if (ajNew > 0.0 && ajNew < c) {
          _bias = b2;
        } else {
          _bias = 0.5 * (b1 + b2);
        }

        final dai = yi * (aiNew - aiOld);
        final daj = yj * (ajNew - ajOld);
        final db = _bias - bOld;
        final kiRow = kernelMatrix[i];
        final kjRow = kernelMatrix[j];
        for (int k = 0; k < n; k++) {
          errors[k] += dai * kiRow[k] + daj * kjRow[k] + db;
        }

        alphas[i] = aiNew;
        alphas[j] = ajNew;
        numChanged++;
        iter++;
      }

      if (numChanged == 0) {
        passes++;
      } else {
        passes = 0;
      }
    }

    final svList = <Float64List>[];
    final ayList = <double>[];
    for (int i = 0; i < n; i++) {
      if (alphas[i] > 1e-6) {
        svList.add(features[i]);
        ayList.add(alphas[i] * labels[i]);
      }
    }
    _supportVectors = svList;
    _supportAlphaY = Float64List.fromList(ayList);
    _fitted = true;
  }

  /// Menghitung margin keputusan f(x) = sum(alpha_i * y_i * K(sv_i, x)) + b.
  double decisionFunction(Float64List x) {
    if (!_fitted) {
      throw StateError('BinaryRbfSvm has not been fitted yet.');
    }
    double sum = _bias;
    for (int i = 0; i < _supportVectors.length; i++) {
      sum += _supportAlphaY[i] * _rbfKernel(_supportVectors[i], x);
    }
    return sum;
  }
}

/// Hasil prediksi multi-kelas SVM beserta skor margin dan probabilitas softmax.
class SvmClassificationResult {
  final String label;
  final Map<String, double> decisionScores;
  final Map<String, double> probabilities;

  const SvmClassificationResult({
    required this.label,
    required this.decisionScores,
    required this.probabilities,
  });

  double get confidence => probabilities[label] ?? 0.0;
}

/// Multi-class RBF Kernel SVM menggunakan strategi One-vs-Rest (OvR).
class MultiClassRbfSvm {
  final double c;
  final double gamma;
  final List<double>? featureWeights;
  final int seed;

  late MinMaxFeatureScaler _scaler;
  late List<String> _classes;
  final Map<String, BinaryRbfSvm> _classifiers = {};
  bool _fitted = false;

  MultiClassRbfSvm({
    this.c = 300.0,
    this.gamma = 6.0,
    this.featureWeights,
    this.seed = 42,
  });

  bool get isFitted => _fitted;
  List<String> get classes => _fitted ? List.unmodifiable(_classes) : const [];

  int get totalSupportVectors => _classifiers.values
      .fold<int>(0, (sum, clf) => sum + clf.supportVectorCount);

  void fit(List<Float64List> rawFeatures, List<String> labels) {
    if (rawFeatures.isEmpty || rawFeatures.length != labels.length) {
      throw ArgumentError('Features and labels must be non-empty and equal length.');
    }

    _scaler = MinMaxFeatureScaler.fit(
      rawFeatures,
      featureWeights: featureWeights,
    );
    final scaled = _scaler.transformAll(rawFeatures);
    _classes = labels.toSet().toList()..sort();
    _classifiers.clear();

    for (final cls in _classes) {
      final binaryLabels = labels
          .map((l) => l == cls ? 1.0 : -1.0)
          .toList(growable: false);
      final clf = BinaryRbfSvm(c: c, gamma: gamma, seed: seed);
      clf.fit(scaled, binaryLabels);
      _classifiers[cls] = clf;
    }
    _fitted = true;
  }

  SvmClassificationResult predict(Float64List rawFeatures) {
    if (!_fitted) {
      throw StateError('MultiClassRbfSvm has not been fitted yet.');
    }
    final scaled = _scaler.transform(rawFeatures);
    final scores = <String, double>{};
    String bestLabel = _classes.first;
    double bestScore = double.negativeInfinity;

    for (final cls in _classes) {
      final score = _classifiers[cls]!.decisionFunction(scaled);
      scores[cls] = score;
      if (score > bestScore) {
        bestScore = score;
        bestLabel = cls;
      }
    }

    // Softmax stabil secara numerik atas margin SVM sebagai estimasi confidence.
    double sumExp = 0.0;
    final expScores = <String, double>{};
    for (final entry in scores.entries) {
      final e = exp(entry.value - bestScore);
      expScores[entry.key] = e;
      sumExp += e;
    }
    final probs = <String, double>{
      for (final entry in expScores.entries)
        entry.key: sumExp == 0 ? 0.0 : entry.value / sumExp,
    };

    return SvmClassificationResult(
      label: bestLabel,
      decisionScores: scores,
      probabilities: probs,
    );
  }
}
