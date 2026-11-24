import 'package:flutter/material.dart';
import 'skin_check_question5_page.dart';

/// Halaman wrapper kompatibilitas rute lama (dialihkan ke Pertanyaan 5/5).
class SkinCheckQuestion7Page extends StatelessWidget {
  final String age;
  final String gender;
  final String conditionAfterWash;
  final String oilCondition;
  final String sensitivity;
  final String humidity;
  final String? initialTemperature;
  final ValueChanged<int>? onNavigateTab;

  const SkinCheckQuestion7Page({
    super.key,
    required this.age,
    required this.gender,
    required this.conditionAfterWash,
    required this.oilCondition,
    required this.sensitivity,
    required this.humidity,
    this.initialTemperature,
    this.onNavigateTab,
  });

  @override
  Widget build(BuildContext context) {
    return SkinCheckQuestion5Page(
      age: age,
      gender: gender,
      conditionAfterWash: conditionAfterWash,
      oilCondition: oilCondition,
      sensitivity: sensitivity,
      humidity: humidity,
      initialTemperature: initialTemperature,
      onNavigateTab: onNavigateTab,
    );
  }
}
