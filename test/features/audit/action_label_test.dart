import 'package:ferrer_rental_shop/features/audit/domain/action_label.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('known actions have professional labels', () {
    expect('user.signup'.actionLabel, 'Signed up');
    expect('account.created'.actionLabel, 'Admin account created');
    expect('account.role_changed'.actionLabel, 'Role changed');
    expect('rental.requested'.actionLabel, 'Rental requested');
    expect('rental.confirmed'.actionLabel, 'Rental confirmed');
    expect('rental.declined'.actionLabel, 'Rental declined');
    expect('rental.returned'.actionLabel, 'Rental returned');
    expect('rental.cancelled'.actionLabel, 'Rental cancelled');
    expect('appointment.requested'.actionLabel, 'Appointment requested');
    expect('appointment.confirmed'.actionLabel, 'Appointment confirmed');
    expect('appointment.declined'.actionLabel, 'Appointment declined');
    expect('appointment.completed'.actionLabel, 'Appointment completed');
    expect('appointment.no_show'.actionLabel, 'No-show recorded');
    expect('appointment.cancelled'.actionLabel, 'Appointment cancelled');
    expect('item.created'.actionLabel, 'Item added');
    expect('item.updated'.actionLabel, 'Item updated');
    expect('item.status_changed'.actionLabel, 'Item status changed');
  });

  test('unknown actions fall back to a readable label', () {
    expect('custom.thing_happened'.actionLabel, 'Thing happened');
    expect('mystery'.actionLabel, 'Mystery');
  });
}
