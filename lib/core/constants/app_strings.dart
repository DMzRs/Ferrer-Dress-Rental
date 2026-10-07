/// Centralized user-facing copy strings.
class AppStrings {
  AppStrings._();

  /// Login screen headline.
  static const String welcomeBack = 'Welcome Back';
  /// Login screen subheadline.
  static const String loginSubtitle = 'Sign in to continue';
  /// Signup screen headline.
  static const String createAccountTitle = 'Create Account';
  /// Signup screen subheadline.
  static const String signupSubtitle = 'Join Ferrer and find your perfect look';

  /// Deposit explainer headline.
  static const String depositInfoTitle = 'Refundable Security Deposit';
  /// Deposit explainer body copy.
  static const String depositInfoBody =
      'A refundable security deposit is collected with every rental. '
      'It will be returned in full once the item is returned on time '
      'and in its original condition.';

  /// Help center intro copy.
  static const String helpCenterIntro =
      'Ferrer Clothing Rental rents premium adult dresses and kiddie '
      'costumes for weddings, debuts, birthdays, and school events. '
      'Reserve online, visit us for a fitting, and enjoy your event.';
  /// Help center question-and-answer pairs.
  static const List<(String, String)> helpCenterFaqs = [
    (
      'How do I rent an item?',
      'Choose a dress or costume, select your rental dates at checkout, and '
      'pay. The shop reviews and confirms your rental — you can track its '
      'status anytime under My Rentals.'
    ),
    (
      'Why book a fitting appointment?',
      'A fitting makes sure the size sits perfectly before your event. '
      'Book one from any item page.'
    ),
    (
      'When is my deposit refunded?',
      'In full when the item is returned on time and undamaged. Late '
      'returns deduct 50% of the deposit as a late fee.'
    ),
    (
      'How is delivery arranged?',
      'Provide your delivery address at checkout. Message our official '
      'Facebook page or call the shop to arrange the details.'
    ),
  ];
}
