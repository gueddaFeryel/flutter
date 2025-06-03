import 'package:flutter/material.dart';

class MedicalBadge extends StatelessWidget {
  final String label;
  final Color color;
  
  const MedicalBadge({
    required this.label,
    required this.color,
    Key? key,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        label,
        style: TextStyle(color: Colors.white),
      ),
      backgroundColor: color,
    );
  }
}