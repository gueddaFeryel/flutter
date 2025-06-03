import 'package:flutter/material.dart';
import '../models/intervention.dart';
import 'medical_badge.dart';

class InterventionCard extends StatelessWidget {
  final Intervention intervention;
  final VoidCallback onTap;

  const InterventionCard({
    required this.intervention,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    intervention.type.replaceAll('_', ' '),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  MedicalBadge(
                    label: intervention.status.toLowerCase(),
                    color: _getStatusColor(intervention.status),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildRoomInfo(context),
              if (intervention.startTime != null)
                Text(
                  'Horaire: ${_formatTime(intervention.startTime!)}'
                  '${intervention.endTime != null ? ' - ${_formatTime(intervention.endTime!)}' : ''}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerRight,
                child: Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoomInfo(BuildContext context) {
    if (intervention.room != null) {
      return Text(
        'Salle: ${intervention.room!.name}',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'demande':
        return Colors.orange;
      case 'confirmée':
        return Colors.green;
      case 'annulée':
        return Colors.red;
      case 'terminée':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}