import 'package:ferrer_rental_shop/features/booking/data/datasources/firebase_appointment_data_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dayDocId formats a stable per-day document id', () {
    expect(
      FirebaseAppointmentDataSource.dayDocId(DateTime(2026, 9, 5, 14, 30)),
      '2026-09-05',
    );
    expect(
      FirebaseAppointmentDataSource.dayDocId(DateTime(2026, 9, 5, 9, 0)),
      '2026-09-05',
    );
  });
}
