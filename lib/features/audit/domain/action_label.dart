/// Human-readable titles for audit actions. The stored `group.name`
/// keys stay stable for filtering; only this mapping faces the user.
extension ActionLabel on String {
  String get actionLabel {
    const known = {
      'user.signup': 'Signed up',
      'account.created': 'Admin account created',
      'account.role_changed': 'Role changed',
      'rental.requested': 'Rental requested',
      'rental.confirmed': 'Rental confirmed',
      'rental.declined': 'Rental declined',
      'rental.returned': 'Rental returned',
      'rental.cancelled': 'Rental cancelled',
      'appointment.requested': 'Appointment requested',
      'appointment.confirmed': 'Appointment confirmed',
      'appointment.declined': 'Appointment declined',
      'appointment.completed': 'Appointment completed',
      'appointment.no_show': 'No-show recorded',
      'appointment.cancelled': 'Appointment cancelled',
      'item.created': 'Item added',
      'item.updated': 'Item updated',
      'item.status_changed': 'Item status changed',
    };
    final hit = known[this];
    if (hit != null) return hit;
    // Fallback: last segment, underscores to spaces, capitalized.
    final last = split('.').last.replaceAll('_', ' ').trim();
    if (last.isEmpty) return this;
    return last[0].toUpperCase() + last.substring(1);
  }
}
