import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:skinora_app/pages/pengguna/riwayat_skin_check_page.dart';
import 'package:skinora_app/pages/pengguna/skin_check_question5_page.dart';
import 'package:skinora_app/pages/pengguna/skin_check_result_page.dart';
import 'package:skinora_app/services/skin_svm_classifier.dart';
import 'package:skinora_app/services/skin_svm_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RBF Kernel SVM (skin-type.csv)', () {
    test('Dataset skin-type.csv terbaca lengkap (2000 baris, 4 kelas seimbang)', () {
      final csvContent = File(SkinSvmService.datasetAssetPath).readAsStringSync();
      final parsed = SkinSvmService.parseDatasetCsv(csvContent);

      expect(parsed.features.length, 2000);
      expect(parsed.labels.length, 2000);
      expect(parsed.features.first.length, 7);

      final counts = <String, int>{};
      for (final label in parsed.labels) {
        counts[label] = (counts[label] ?? 0) + 1;
      }
      expect(counts['Dry'], 500);
      expect(counts['Normal'], 500);
      expect(counts['Oily'], 500);
      expect(counts['Combination'], 500);
    });

    test('Akurasi evaluasi 80/20 pada data uji tak terlihat >= 96%', () {
      final csvContent = File(SkinSvmService.datasetAssetPath).readAsStringSync();
      final parsed = SkinSvmService.parseDatasetCsv(csvContent);

      final indices = List<int>.generate(parsed.features.length, (i) => i);
      indices.shuffle(Random(42));

      final split = (indices.length * 0.8).round();
      final trainIdx = indices.sublist(0, split);
      final testIdx = indices.sublist(split);

      final trainX = [for (final i in trainIdx) parsed.features[i]];
      final trainY = [for (final i in trainIdx) parsed.labels[i]];
      final testX = [for (final i in testIdx) parsed.features[i]];
      final testY = [for (final i in testIdx) parsed.labels[i]];

      final model = MultiClassRbfSvm(
        c: 300.0,
        gamma: 6.0,
        featureWeights: SkinSvmService.featureWeights,
        seed: 42,
      );
      model.fit(trainX, trainY);

      expect(model.isFitted, isTrue);
      expect(model.classes, containsAll(['Dry', 'Normal', 'Oily', 'Combination']));
      expect(model.totalSupportVectors, greaterThan(0));

      int correct = 0;
      for (int i = 0; i < testX.length; i++) {
        final res = model.predict(testX[i]);
        if (res.label == testY[i]) {
          correct++;
        }
      }
      final accuracy = correct / testX.length;
      expect(accuracy, greaterThanOrEqualTo(0.96));
    });

    test('Memprediksi keempat kelas kulit dengan tepat dari input kuesioner Indonesia', () async {
      SkinSvmService.resetCache();

      // 1. Kering (Dry): Low hydration, Low oil, High sensitivity, Hum 32%, Temp 16°C
      final dryPred = await SkinSvmService.predict(
        age: '28',
        gender: 'Perempuan',
        conditionAfterWash: 'Terasa sangat kering/kencang',
        oilCondition: 'Wajah terasa kering dan hampir tidak berminyak',
        sensitivity: 'Sering mengalami kemerahan, perih, gatal, atau iritasi',
        humidity: '32%',
        temperature: '16°C',
      );
      expect(dryPred.skinType, 'Kering');
      expect(dryPred.rawDatasetLabel, 'Dry');
      expect(dryPred.sensitivity, 'Sangat Sensitif');
      expect(dryPred.confidence, greaterThan(0.5));

      // 2. Normal: Medium/High hydration, Medium oil, Low sensitivity, Hum 52%, Temp 21°C
      final normalPred = await SkinSvmService.predict(
        age: '25',
        gender: 'Laki-laki',
        conditionAfterWash: 'Terasa cukup nyaman',
        oilCondition: 'Sedikit berminyak, terutama di area tertentu',
        sensitivity: 'Jarang mengalami kemerahan, perih, atau iritasi',
        humidity: '52%',
        temperature: '21°C',
      );
      expect(normalPred.skinType, 'Normal');
      expect(normalPred.rawDatasetLabel, 'Normal');
      expect(normalPred.sensitivity, 'Non-Sensitif');
      expect(normalPred.acneRisk, 'Tidak Rentan');

      // 3. Berminyak (Oily): Low/Medium hydration, High oil, Medium sensitivity, Hum 65%, Temp 25°C
      final oilyPred = await SkinSvmService.predict(
        age: '24',
        gender: 'Laki-laki',
        conditionAfterWash: 'Terasa cukup nyaman',
        oilCondition: 'Wajah terlihat mengkilap dan banyak minyak',
        sensitivity: 'Kadang mengalami kemerahan atau iritasi',
        humidity: '65%',
        temperature: '25°C',
      );
      expect(oilyPred.skinType, 'Berminyak');
      expect(oilyPred.rawDatasetLabel, 'Oily');
      expect(oilyPred.sensitivity, 'Sensitif');
      expect(oilyPred.acneRisk, 'Rentan');

      // 4. Kombinasi (Combination): High hydration, High oil, High sensitivity, Hum 74%, Temp 32°C
      final comboPred = await SkinSvmService.predict(
        age: '30',
        gender: 'Perempuan',
        conditionAfterWash: 'Terasa sangat lembap/kenyal',
        oilCondition: 'Wajah terlihat mengkilap dan banyak minyak',
        sensitivity: 'Sering mengalami kemerahan, perih, gatal, atau iritasi',
        humidity: '74%',
        temperature: '32°C',
      );
      expect(comboPred.skinType, 'Kombinasi');
      expect(comboPred.rawDatasetLabel, 'Combination');
      expect(comboPred.sensitivity, 'Sangat Sensitif');
      expect(comboPred.acneRisk, 'Rentan');
    });

    test('Parser angka dan encoder input menangani format koma, simbol, dan nilai kosong', () {
      expect(
        SkinSvmService.parseNumericInput('74,5%', fallback: 50, minVal: 0, maxVal: 100),
        74.5,
      );
      expect(
        SkinSvmService.parseNumericInput('31.2°C', fallback: 25, minVal: -10, maxVal: 60),
        31.2,
      );
      expect(
        SkinSvmService.parseNumericInput('invalid', fallback: 25, minVal: -10, maxVal: 60),
        25,
      );
      expect(SkinSvmService.encodeGender('Perempuan'), 1.0);
      expect(SkinSvmService.encodeGender('Laki-laki'), 0.0);
    });

    testWidgets('SkinCheckQuestion5Page menampilkan hasil RBF-SVM dan badge keyakinan di SkinCheckResultPage', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SkinCheckQuestion5Page(
            age: '26',
            gender: 'Perempuan',
            conditionAfterWash: 'Terasa sangat kering/kencang',
            oilCondition: 'Wajah terasa kering dan hampir tidak berminyak',
            sensitivity: 'Sering mengalami kemerahan, perih, gatal, atau iritasi',
            humidity: '32%',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, '32°C'), '16°C');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lihat Hasil'));
      await tester.pumpAndSettle();

      expect(find.byType(SkinCheckResultPage), findsOneWidget);
      expect(find.text('Kering'), findsOneWidget);
      expect(find.text('Sangat Sensitif'), findsOneWidget);
      expect(find.textContaining('Model RBF-SVM • Keyakinan'), findsOneWidget);
      expect(find.textContaining('ceramide'), findsOneWidget);
    });

    testWidgets('RiwayatSkinCheckPage mempertahankan label Sangat Sensitif & confidence saat dibuka', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RiwayatSkinCheckPage(
            initialHistory: [
              SkinCheckHistoryModel(
                id: 'svm-1',
                date: '26 Nov 2026, 19.00 WIB',
                skinType: 'Kering',
                subtitle: 'Sangat Sensitif - Tidak Rentan',
                icon: LucideIcons.shield,
                tags: const ['Kering', 'Sangat Sensitif', 'Tidak Rentan'],
                neutralTags: const ['Tidak Rentan'],
                confidence: 0.91,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kering').first);
      await tester.pumpAndSettle();

      expect(find.byType(SkinCheckResultPage), findsOneWidget);
      expect(find.text('Sangat Sensitif'), findsOneWidget);
      expect(find.text('Model RBF-SVM • Keyakinan 91%'), findsOneWidget);
    });
  });
}
