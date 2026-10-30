import 'package:flutter/material.dart';

@immutable
class PlanSection {
  const PlanSection({
    required this.title,
    required this.summary,
    required this.description,
    required this.icon,
  });

  final String title;
  final String summary;
  final String description;
  final IconData icon;
}
