import 'package:flutter/material.dart';
import 'skin_check_question4_page.dart';

/// Halaman wrapper kompatibilitas rute lama (dialihkan ke Pertanyaan 4/5).
class SkinCheckQuestion6Page extends StatelessWidget {
  final String age;
  final String gender;
  final String conditionAfterWash;
  final String oilCondition;
  final String sensitivity;
  final String? initialHumidity;
  final ValueChanged<int>? onNavigateTab;

  const SkinCheckQuestion6Page({
    super.key,
    required this.age,
    required this.gender,
    required this.conditionAfterWash,
    required this.oilCondition,
    required this.sensitivity,
    this.initialHumidity,
    this.onNavigateTab,
  });

  @override
  Widget build(BuildContext context) {
    return SkinCheckQuestion4Page(
      age: age,
      gender: gender,
      conditionAfterWash: conditionAfterWash,
      oilCondition: oilCondition,
      sensitivity: sensitivity,
      initialHumidity: initialHumidity,
      onNavigateTab: onNavigateTab,
    );
  }
}
