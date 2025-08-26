import 'package:flutter/material.dart';

/// A data model for an alert. Using a class instead of a Map provides
/// type-safety and better autocompletion.
class Alert {
  final String numberPlate;
  final String date;
  final String time;
  final String status;
  final String notice;

  const Alert({
    required this.numberPlate,
    required this.date,
    required this.time,
    required this.status,
    required this.notice,
  });

  /// Derives the status color from the theme.
  Color getStatusColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (status) {
      case 'STOP':
        return colorScheme.error;
      case 'IDLE':
        return colorScheme.primary;
      default:
        return colorScheme.onSurface.withOpacity(0.6);
    }
  }

  /// Provides the appropriate icon for the status.
  IconData get statusIcon {
    switch (status) {
      case 'STOP':
        return Icons.warning_amber_rounded;
      case 'IDLE':
        return Icons.pause_circle_filled_rounded;
      default:
        return Icons.info_outline;
    }
  }
}

class AlertPage extends StatelessWidget {
  /// The list of alerts now uses the type-safe [Alert] model.
  final List<Alert> alerts = const [
    Alert(
        numberPlate: "TN 12 W 1397",
        date: "Jan 23, 2025",
        time: "6:19 PM",
        status: "STOP",
        notice: "Exceeds 0min Limit"),
    Alert(
        numberPlate: "TN12AJ1108",
        date: "Jan 23, 2025",
        time: "6:17 PM",
        status: "IDLE",
        notice: "Exceeds 0min Limit"),
    Alert(
        numberPlate: "TN 12 R 0974",
        date: "Jan 23, 2025",
        time: "6:16 PM",
        status: "STOP",
        notice: "Exceeds 0min Limit"),
    Alert(
        numberPlate: "TN12AJ1199",
        date: "Jan 23, 2025",
        time: "6:15 PM",
        status: "STOP",
        notice: "Exceeds 0min Limit"),
    Alert(
        numberPlate: "TN 12 AC 9041",
        date: "Jan 23, 2025",
        time: "6:15 PM",
        status: "STOP",
        notice: "Exceeds 0min Limit"),
  ];

  const AlertPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get theme for consistent access
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface, // Use theme surface color
      appBar: AppBar(
        title: Text(
          "Vehicle Alerts",
          style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onPrimary), // Use theme text style and color
        ),
        centerTitle: true,
        elevation: 0, // Cleaner look with no elevation
        backgroundColor: colorScheme.primary, // Use theme primary color
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20))),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16), // Consistent padding
        itemCount: alerts.length,
        separatorBuilder: (_, __) =>
            const SizedBox(height: 14), // Consistent spacing
        itemBuilder: (context, index) {
          // By extracting the list item, the main build method is cleaner.
          return AlertListItem(alert: alerts[index]);
        },
      ),
    );
  }
}

/// A widget that represents a single item in the alerts list.
/// Extracting this makes the code more modular and reusable.
class AlertListItem extends StatelessWidget {
  const AlertListItem({super.key, required this.alert});

  final Alert alert;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColor = alert.getStatusColor(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              alert.statusIcon,
              color: statusColor,
              size: 36,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.numberPlate,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6.0,
                    runSpacing: 4.0,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 16,
                          color: colorScheme.onSurface.withOpacity(0.7)),
                      Text(alert.date,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.7),
                          )),
                      const SizedBox(width: 14),
                      Icon(Icons.access_time,
                          size: 16,
                          color: colorScheme.onSurface.withOpacity(0.7)),
                      Text(alert.time,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.7),
                          )),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: 120,
            height: 80,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: statusColor.withOpacity(0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    alert.status,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    alert.notice,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onPrimary.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
