import '../models/client.dart';
import '../models/mitarbeiter.dart';
import '../models/arbeitszeit.dart';

/// Prueft Aufbewahrungsfristen und meldet abgelaufene Datensaetze.
class RetentionService {
  // Gesetzliche Fristen
  static const int clientRetentionYears = 10;    // SGB IX, AO §147
  static const int workTimeRetentionYears = 2;   // ArbZG §16
  static const int employeeRetentionYears = 3;   // BGB §195

  /// Prueft Klienten deren Aufbewahrungsfrist abgelaufen ist.
  /// Frist: 10 Jahre nach Ende der Kostenuebernahme.
  static List<RetentionWarning> checkClientRetention(List<Client> clients) {
    final warnings = <RetentionWarning>[];
    final now = DateTime.now();

    for (final client in clients) {
      final endDate = client.kostenuebernahmeBis;
      if (endDate == null) continue;

      final retentionEnd = DateTime(
        endDate.year + clientRetentionYears,
        endDate.month,
        endDate.day,
      );

      if (now.isAfter(retentionEnd)) {
        warnings.add(RetentionWarning(
          type: RetentionType.expired,
          entityType: 'Klient',
          entityId: client.id,
          entityName: client.name,
          retentionEnd: retentionEnd,
          message: 'Aufbewahrungsfrist abgelaufen seit ${_formatDate(retentionEnd)}. Loeschung empfohlen.',
        ));
      } else {
        final monthsLeft = _monthsBetween(now, retentionEnd);
        if (monthsLeft <= 6) {
          warnings.add(RetentionWarning(
            type: RetentionType.expiringSoon,
            entityType: 'Klient',
            entityId: client.id,
            entityName: client.name,
            retentionEnd: retentionEnd,
            message: 'Aufbewahrungsfrist endet in $monthsLeft Monaten (${_formatDate(retentionEnd)}).',
          ));
        }
      }
    }
    return warnings;
  }

  /// Prueft Arbeitszeiten die aelter als 2 Jahre sind.
  static List<RetentionWarning> checkWorkTimeRetention(List<Arbeitszeit> records) {
    final warnings = <RetentionWarning>[];
    final now = DateTime.now();
    final cutoff = DateTime(now.year - workTimeRetentionYears, now.month, now.day);

    int expiredCount = 0;
    DateTime? oldestDate;

    for (final record in records) {
      if (record.datum.isBefore(cutoff)) {
        expiredCount++;
        if (oldestDate == null || record.datum.isBefore(oldestDate)) {
          oldestDate = record.datum;
        }
      }
    }

    if (expiredCount > 0) {
      warnings.add(RetentionWarning(
        type: RetentionType.expired,
        entityType: 'Arbeitszeit',
        entityId: 'bulk',
        entityName: '$expiredCount Eintraege',
        retentionEnd: cutoff,
        message: '$expiredCount Arbeitszeit-Eintraege aelter als 2 Jahre (aeltester: ${_formatDate(oldestDate!)}). Loeschung empfohlen.',
      ));
    }
    return warnings;
  }

  /// Prueft inaktive Mitarbeiter deren Frist abgelaufen ist.
  static List<RetentionWarning> checkEmployeeRetention(List<Mitarbeiter> employees) {
    final warnings = <RetentionWarning>[];
    final now = DateTime.now();

    for (final emp in employees) {
      if (emp.isActive) continue;

      final retentionEnd = DateTime(
        emp.createdAt.year + employeeRetentionYears,
        emp.createdAt.month,
        emp.createdAt.day,
      );

      if (now.isAfter(retentionEnd)) {
        warnings.add(RetentionWarning(
          type: RetentionType.expired,
          entityType: 'Mitarbeiter',
          entityId: emp.id,
          entityName: emp.vollstaendigerName,
          retentionEnd: retentionEnd,
          message: 'Personalakte: Aufbewahrungsfrist abgelaufen seit ${_formatDate(retentionEnd)}.',
        ));
      }
    }
    return warnings;
  }

  static String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';

  static int _monthsBetween(DateTime from, DateTime to) {
    return (to.year - from.year) * 12 + to.month - from.month;
  }
}

enum RetentionType { expired, expiringSoon }

class RetentionWarning {
  final RetentionType type;
  final String entityType;
  final String entityId;
  final String entityName;
  final DateTime retentionEnd;
  final String message;

  const RetentionWarning({
    required this.type,
    required this.entityType,
    required this.entityId,
    required this.entityName,
    required this.retentionEnd,
    required this.message,
  });
}
