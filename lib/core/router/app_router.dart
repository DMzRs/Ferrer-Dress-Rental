import 'package:flutter/material.dart';

import 'package:ferrer_rental_shop/features/booking/presentation/views/booking_screen.dart';
import 'package:ferrer_rental_shop/features/checkout/presentation/views/checkout_screen.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/entities/catalog_item.dart';
import 'package:ferrer_rental_shop/features/item_details/presentation/views/item_details_screen.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/entities/rental_entity.dart';
import 'package:ferrer_rental_shop/features/rentals/presentation/views/rental_details_screen.dart';
import 'package:ferrer_rental_shop/features/shell/presentation/views/user_shell.dart';

/// Named route paths.
class AppRoutes {
  AppRoutes._();

  /// Item details route.
  static const itemDetails = '/item-details';
  /// Checkout route.
  static const checkout = '/checkout';
  /// Fitting booking route.
  static const booking = '/booking';
  /// Rentals list route.
  static const myRentals = '/my-rentals';
  /// Rental details route.
  static const rentalDetails = '/rental-details';
}

/// Navigation helpers on [BuildContext].
extension AppNavigator on BuildContext {
  /// Pushes a named route with optional arguments.
  void pushNamed(String route, {Object? arguments}) {
    Navigator.of(this).pushNamed(route, arguments: arguments);
  }

  /// Replaces the current route with a named route.
  void pushReplacementNamed(String route, {Object? arguments}) {
    Navigator.of(this).pushReplacementNamed(route, arguments: arguments);
  }
}

/// Builds routes for named navigation.
Route<dynamic>? onGenerateRoute(RouteSettings settings) {
  switch (settings.name) {
    case AppRoutes.itemDetails:
      final item = settings.arguments as CatalogItem;
      return MaterialPageRoute(builder: (_) => ItemDetailsScreen(item: item));
    case AppRoutes.checkout:
      final item = settings.arguments as CatalogItem;
      return MaterialPageRoute(builder: (_) => CheckoutScreen(item: item));
    case AppRoutes.booking:
      final args = settings.arguments as BookingScreenArgs?;
      return MaterialPageRoute(
        builder: (_) => BookingScreen(args: args ?? const BookingScreenArgs()),
      );
    case AppRoutes.myRentals:
      // Lands on the shell's Rentals tab (keeps the bottom nav bar) and
      // optionally flashes the just-created rental. Arguments: rental id?
      final highlightId = settings.arguments as String?;
      return MaterialPageRoute(
        builder: (_) => UserShell(
          initialTab: 2,
          highlightRentalId: highlightId,
        ),
      );
    case AppRoutes.rentalDetails:
      final rental = settings.arguments as Rental;
      return MaterialPageRoute(builder: (_) => RentalDetailsScreen(rental: rental));
    default:
      return null;
  }
}

