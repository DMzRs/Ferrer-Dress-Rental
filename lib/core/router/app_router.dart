import 'package:flutter/material.dart';

import 'package:ferrer_rental_shop/features/booking/presentation/views/booking_screen.dart';
import 'package:ferrer_rental_shop/features/checkout/presentation/views/checkout_screen.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/entities/catalog_item.dart';
import 'package:ferrer_rental_shop/features/item_details/presentation/views/item_details_screen.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/entities/rental_entity.dart';
import 'package:ferrer_rental_shop/features/rentals/presentation/views/my_rentals_screen.dart';
import 'package:ferrer_rental_shop/features/rentals/presentation/views/rental_details_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const itemDetails = '/item-details';
  static const checkout = '/checkout';
  static const booking = '/booking';
  static const myRentals = '/my-rentals';
  static const rentalDetails = '/rental-details';
}

extension AppNavigator on BuildContext {
  void pushNamed(String route, {Object? arguments}) {
    Navigator.of(this).pushNamed(route, arguments: arguments);
  }

  void pushReplacementNamed(String route, {Object? arguments}) {
    Navigator.of(this).pushReplacementNamed(route, arguments: arguments);
  }
}

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
      return MaterialPageRoute(builder: (_) => const MyRentalsScreen());
    case AppRoutes.rentalDetails:
      final rental = settings.arguments as Rental;
      return MaterialPageRoute(builder: (_) => RentalDetailsScreen(rental: rental));
    default:
      return null;
  }
}

