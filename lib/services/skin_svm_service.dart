import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'skin_svm_classifier.dart';

/// Hasil lengkap analisis Skin Check berbasis model RBF Kernel SVM.
class SkinCheckSvmPrediction {
  /// Label tipe kulit dalam bahasa Indonesia:
  /// `'Kering'`, `'Normal'`, `'Berminyak'`, atau `'Kombinasi'`.
  final String skinType;

  /// Label asli kelas dataset: `'Dry'`, `'Normal'`, `'Oily'`, `'Combination'`.
  final String rawDatasetLabel;

  /// Tingkat sensitivitas dalam bahasa Indonesia:
  /// `'Non-Sensitif'`, `'Sensitif'`, atau `'Sangat Sensitif'`.
  final String sensitivity;

  /// Risiko jerawat: `'Rentan'` atau `'Tidak Rentan'`.
  final String acneRisk;

  /// Estimasi probabilitas kelas terpilih (0.0 .. 1.0).
  final double confidence;

  /// Distribusi probabilitas untuk seluruh kelas (key bahasa Indonesia).
  final Map<String, double> probabilities;

  /// Skor margin mentah dari hyperplane RBF SVM per kelas (key kelas dataset).
  final Map<String, double> decisionScores;

  const SkinCheckSvmPrediction({
    required this.skinType,
    required this.rawDatasetLabel,
    required this.sensitivity,
    required this.acneRisk,
    required this.confidence,
    required this.probabilities,
    required this.decisionScores,
  });
}

/// Layanan klasifikasi jenis kulit berbasis Support Vector Machine (RBF Kernel)
/// yang dilatih langsung dari dataset `assets/dataset/skin-type.csv`.
class SkinSvmService {
  SkinSvmService._();

  static const String datasetAssetPath = 'assets/dataset/skin-type.csv';

  /// Bobot fitur: 5 fitur kondisi kulit & lingkungan diberi bobot penuh (1.0),
  /// sedangkan Age & Gender diberi bobot ringan (0.1) agar sesuai struktur
  /// 7 kolom dataset tanpa menambah noise jarak RBF.
  static const List<double> featureWeights = [
    0.1, // Age
    0.1, // Gender
    1.0, // Hydration_Level
    1.0, // Oil_Level
    1.0, // Sensitivity
    1.0, // Humidity
    1.0, // Temperature
  ];

  static Future<MultiClassRbfSvm>? _modelFuture;
  static MultiClassRbfSvm? _cachedModel;

  /// Memastikan model SVM sudah terlatih dan tersimpan di cache memori.
  static Future<MultiClassRbfSvm> ensureModel() {
    if (_cachedModel != null && _cachedModel!.isFitted) {
      return Future.value(_cachedModel!);
    }
    return _modelFuture ??= _loadAndTrain();
  }

  /// Reset cache model (untuk pengujian unit).
  @visibleForTesting
  static void resetCache() {
    _cachedModel = null;
    _modelFuture = null;
  }

  /// Melatih model dari string CSV (berguna juga untuk unit test tanpa rootBundle).
  @visibleForTesting
  static MultiClassRbfSvm trainFromCsvString(String csvContent) {
    final parsed = parseDatasetCsv(csvContent);
    final model = MultiClassRbfSvm(
      c: 300.0,
      gamma: 6.0,
      featureWeights: featureWeights,
      seed: 42,
    );
    model.fit(parsed.features, parsed.labels);
    return model;
  }

  static Future<MultiClassRbfSvm> _loadAndTrain() async {
    try {
      final csvContent = await _loadCsvContent();
      final model = trainFromCsvString(csvContent);
      _cachedModel = model;
      return model;
    } catch (e) {
      _modelFuture = null;
      rethrow;
    }
  }

  static Future<String> _loadCsvContent() async {
    if (!kIsWeb) {
      final file = File(datasetAssetPath);
      if (file.existsSync()) {
        return file.readAsStringSync();
      }
    }
    return rootBundle.loadString(datasetAssetPath);
  }

  /// Mem-parsing dataset `skin-type.csv` menjadi vektor fitur 7D dan label kelas.
  static ({List<Float64List> features, List<String> labels}) parseDatasetCsv(
    String csvContent,
  ) {
    final lines = csvContent.split(RegExp(r'\r?\n'));
    final features = <Float64List>[];
    final labels = <String>[];

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      final cols = line.split(',');
      if (cols.length < 8) continue;

      final age = double.tryParse(cols[0].trim());
      final gender = encodeGender(cols[1]);
      final hydration = encodeHydrationLevel(cols[2]);
      final oil = encodeOilLevel(cols[3]);
      final sensitivity = encodeSensitivityLevel(cols[4]);
      final humidity = double.tryParse(cols[5].trim());
      final temperature = double.tryParse(cols[6].trim());
      final label = cols[7].trim();

      if (age == null || humidity == null || temperature == null || label.isEmpty) {
        continue;
      }

      features.add(
        Float64List.fromList([
          age,
          gender,
          hydration,
          oil,
          sensitivity,
          humidity,
          temperature,
        ]),
      );
      labels.add(label);
    }

    if (features.isEmpty) {
      throw StateError('Dataset CSV kosong atau format tidak valid.');
    }

    return (features: features, labels: labels);
  }

  /// Prediksi tipe kulit, sensitivitas, dan risiko jerawat dari input kuesioner.
  static Future<SkinCheckSvmPrediction> predict({
    required String age,
    required String gender,
    required String conditionAfterWash,
    required String oilCondition,
    required String sensitivity,
    required String humidity,
    required String temperature,
  }) async {
    final model = await ensureModel();
    return predictWithModel(
      model: model,
      age: age,
      gender: gender,
      conditionAfterWash: conditionAfterWash,
      oilCondition: oilCondition,
      sensitivity: sensitivity,
      humidity: humidity,
      temperature: temperature,
    );
  }

  /// Prediksi sinkron menggunakan instance model yang sudah dilatih.
  static SkinCheckSvmPrediction predictWithModel({
    required MultiClassRbfSvm model,
    required String age,
    required String gender,
    required String conditionAfterWash,
    required String oilCondition,
    required String sensitivity,
    required String humidity,
    required String temperature,
  }) {
    final ageVal = parseNumericInput(age, fallback: 25.0, minVal: 1.0, maxVal: 100.0);
    final genderVal = encodeGender(gender);
    final hydrationVal = encodeHydrationLevel(conditionAfterWash);
    final oilVal = encodeOilLevel(oilCondition);
    final sensitivityVal = encodeSensitivityLevel(sensitivity);
    final humidityVal =
        parseNumericInput(humidity, fallback: 50.0, minVal: 0.0, maxVal: 100.0);
    final tempVal =
        parseNumericInput(temperature, fallback: 25.0, minVal: -10.0, maxVal: 60.0);

    final vector = Float64List.fromList([
      ageVal,
      genderVal,
      hydrationVal,
      oilVal,
      sensitivityVal,
      humidityVal,
      tempVal,
    ]);

    final result = model.predict(vector);
    final skinTypeId = mapDatasetLabelToIndonesian(result.label);
    final sensitivityLabel = deriveSensitivityLabel(sensitivityVal);
    final acneRiskLabel = deriveAcneRisk(
      skinType: skinTypeId,
      oilLevel: oilVal,
      hydrationLevel: hydrationVal,
      sensitivityLevel: sensitivityVal,
    );

    final localizedProbs = <String, double>{
      for (final e in result.probabilities.entries)
        mapDatasetLabelToIndonesian(e.key): e.value,
    };

    return SkinCheckSvmPrediction(
      skinType: skinTypeId,
      rawDatasetLabel: result.label,
      sensitivity: sensitivityLabel,
      acneRisk: acneRiskLabel,
      confidence: result.confidence,
      probabilities: localizedProbs,
      decisionScores: result.decisionScores,
    );
  }

  /// Encode gender dari input UI Indonesia maupun dataset (`Female` = 1.0, `Male` = 0.0).
  static double encodeGender(String raw) {
    final g = raw.trim().toLowerCase();
    if (g == 'female' ||
        g == 'perempuan' ||
        g == 'wanita' ||
        g == 'p' ||
        g == 'f') {
      return 1.0;
    }
    return 0.0;
  }

  /// Encode Q1 (`Hydration_Level`): Low = 0.0, Medium = 0.5, High = 1.0.
  static double encodeHydrationLevel(String raw) {
    final v = raw.trim().toLowerCase();
    if (v == 'low' ||
        v.contains('sangat kering') ||
        v.contains('kencang') ||
        (v.contains('kering') && !v.contains('lembap'))) {
      return 0.0;
    }
    if (v == 'high' || v.contains('sangat lembap') || v.contains('kenyal')) {
      return 1.0;
    }
    return 0.5;
  }

  /// Encode Q2 (`Oil_Level`): Low = 0.0, Medium = 0.5, High = 1.0.
  static double encodeOilLevel(String raw) {
    final v = raw.trim().toLowerCase();
    if (v == 'low' ||
        v.contains('kering') ||
        v.contains('tidak berminyak')) {
      return 0.0;
    }
    if (v == 'high' ||
        v.contains('mengkilap') ||
        v.contains('banyak minyak')) {
      return 1.0;
    }
    return 0.5;
  }

  /// Encode Q3 (`Sensitivity`): Low = 0.0, Medium = 0.5, High = 1.0.
  static double encodeSensitivityLevel(String raw) {
    final v = raw.trim().toLowerCase();
    if (v == 'low' || v.contains('jarang')) {
      return 0.0;
    }
    if (v == 'high' || v.contains('sering')) {
      return 1.0;
    }
    return 0.5;
  }

  static double parseNumericInput(
    String raw, {
    required double fallback,
    required double minVal,
    required double maxVal,
  }) {
    final normalized = raw.replaceAll(',', '.');
    final match = RegExp(r'-?\d+(?:\.\d+)?').firstMatch(normalized);
    if (match == null) return fallback;
    final parsed = double.tryParse(match.group(0)!);
    if (parsed == null || parsed.isNaN || parsed.isInfinite) return fallback;
    if (parsed < minVal) return minVal;
    if (parsed > maxVal) return maxVal;
    return parsed;
  }

  static String mapDatasetLabelToIndonesian(String label) {
    switch (label.trim().toLowerCase()) {
      case 'dry':
        return 'Kering';
      case 'normal':
        return 'Normal';
      case 'oily':
        return 'Berminyak';
      case 'combination':
        return 'Kombinasi';
      default:
        return label;
    }
  }

  static String deriveSensitivityLabel(double sensitivityLevel) {
    if (sensitivityLevel >= 0.9) return 'Sangat Sensitif';
    if (sensitivityLevel >= 0.4) return 'Sensitif';
    return 'Non-Sensitif';
  }

  static String deriveAcneRisk({
    required String skinType,
    required double oilLevel,
    required double hydrationLevel,
    required double sensitivityLevel,
  }) {
    var riskScore = 0;
    if (skinType == 'Berminyak') riskScore += 2;
    if (skinType == 'Kombinasi') riskScore += 1;
    if (oilLevel >= 0.9) riskScore += 2;
    if (oilLevel >= 0.4 && oilLevel < 0.9) riskScore += 1;
    if (hydrationLevel <= 0.1 && oilLevel >= 0.4) riskScore += 1;
    if (sensitivityLevel >= 0.9) riskScore += 1;
    return riskScore >= 3 ? 'Rentan' : 'Tidak Rentan';
  }
}
