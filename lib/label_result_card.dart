import 'package:flutter/material.dart';

class LabelResultCard extends StatelessWidget {
  final String label;

  const LabelResultCard({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: const Icon(Icons.label_important_outline),
        title: Text(label),
      ),
    );
  }
}
