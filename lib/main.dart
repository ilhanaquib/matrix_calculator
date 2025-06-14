import 'package:flutter/material.dart';
import 'package:project_phase_2/home.dart';

void main() {
  runApp(const NutrientSolverApp());
}

class NutrientSolverApp extends StatelessWidget {
  const NutrientSolverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: NutrientSolverHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}
