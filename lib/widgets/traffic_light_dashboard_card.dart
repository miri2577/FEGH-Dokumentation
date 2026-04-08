import 'package:flutter/material.dart';

class TrafficLightDashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final String status;
  final int redCount;
  final int yellowCount;
  final int greenCount;

  const TrafficLightDashboardCard({
    super.key,
    required this.title,
    required this.value,
    required this.status,
    required this.redCount,
    required this.yellowCount,
    required this.greenCount,
  });

  Color _getStatusColor() {
    switch (status) {
      case 'critical':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  IconData _getStatusIcon() {
    switch (status) {
      case 'critical':
        return Icons.warning_rounded;
      case 'warning':
        return Icons.schedule;
      default:
        return Icons.check_circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  Icons.schedule,
                  color: statusColor,
                  size: 20,
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    _getStatusIcon(),
                    color: statusColor,
                    size: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Flexible(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.7),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildTrafficLight(Colors.red, redCount)),
                const SizedBox(width: 2),
                Expanded(child: _buildTrafficLight(Colors.orange, yellowCount)),
                const SizedBox(width: 2),
                Expanded(child: _buildTrafficLight(Colors.green, greenCount)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrafficLight(Color color, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withValues(alpha:0.3), width: 0.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}