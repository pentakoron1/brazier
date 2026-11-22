import 'package:brazier/services/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UnreviewedReminderFrequency tests', () {
    test('fromCode maps valid codes correctly', () {
      expect(
        UnreviewedReminderFrequency.fromCode('max_once_per_day'),
        UnreviewedReminderFrequency.maxOncePerDay,
      );
      expect(
        UnreviewedReminderFrequency.fromCode('max_once_per_week'),
        UnreviewedReminderFrequency.maxOncePerWeek,
      );
      expect(
        UnreviewedReminderFrequency.fromCode('max_once_per_month'),
        UnreviewedReminderFrequency.maxOncePerMonth,
      );
    });

    test('fromCode returns default fallback for unknown code', () {
      expect(
        UnreviewedReminderFrequency.fromCode('invalid'),
        UnreviewedReminderFrequency.maxOncePerWeek,
      );
      expect(
        UnreviewedReminderFrequency.fromCode(null),
        UnreviewedReminderFrequency.maxOncePerWeek,
      );
    });

    test('label and code properties match expected strings', () {
      expect(UnreviewedReminderFrequency.maxOncePerDay.code, 'max_once_per_day');
      expect(UnreviewedReminderFrequency.maxOncePerDay.label, 'Max once per day');

      expect(UnreviewedReminderFrequency.maxOncePerWeek.code, 'max_once_per_week');
      expect(UnreviewedReminderFrequency.maxOncePerWeek.label, 'Max once per week');

      expect(UnreviewedReminderFrequency.maxOncePerMonth.code, 'max_once_per_month');
      expect(UnreviewedReminderFrequency.maxOncePerMonth.label, 'Max once per month');
    });
  });
}
