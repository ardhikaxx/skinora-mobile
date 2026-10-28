import 'package:flutter_test/flutter_test.dart';
import 'package:skinora_app/services/schedule_service.dart';
import 'package:skinora_app/utils/app_dates.dart';

void main() {
  SlotRecord makeSlot(
    DateTime day,
    String start,
    String end, {
    bool booked = false,
  }) {
    return SlotRecord(
      id: 'slot-1',
      doctorId: 'dokter-1',
      date: AppDates.display(day),
      time: '${AppDates.formatHm(start)} - ${AppDates.formatHm(end)}',
      timeStart: AppDates.formatHm(start),
      timeEnd: AppDates.formatHm(end),
      isBooked: booked,
    );
  }

  group('ScheduleService.availabilityOf', () {
    test('slot besok belum bisa dimulai (upcoming)', () {
      final tomorrow = AppDates.nowWib().add(const Duration(days: 1));
      expect(
        ScheduleService.availabilityOf(makeSlot(tomorrow, '09:00', '09:30')),
        SlotAvailability.upcoming,
      );
    });

    test('slot kemarin sudah berakhir (expired)', () {
      final yesterday = AppDates.nowWib().subtract(const Duration(days: 1));
      expect(
        ScheduleService.availabilityOf(makeSlot(yesterday, '09:00', '09:30')),
        SlotAvailability.expired,
      );
    });

    test('slot hari ini dalam rentang jam bisa dipakai', () {
      final today = AppDates.nowWib();
      expect(
        ScheduleService.availabilityOf(makeSlot(today, '00:00', '23:59')),
        SlotAvailability.available,
      );
    });

    test('slot yang sudah dibooking tidak tersedia', () {
      final today = AppDates.nowWib();
      expect(
        ScheduleService.availabilityOf(
          makeSlot(today, '00:00', '23:59', booked: true),
        ),
        SlotAvailability.booked,
      );
    });

    test('fallback memakai kolom time bila timeStart kosong', () {
      final tomorrow = AppDates.nowWib().add(const Duration(days: 1));
      final slot = SlotRecord(
        id: 'slot-2',
        doctorId: 'dokter-1',
        date: AppDates.display(tomorrow),
        time: '09.00 - 09.30',
      );
      expect(
        ScheduleService.availabilityOf(slot),
        SlotAvailability.upcoming,
      );
    });
  });
}
