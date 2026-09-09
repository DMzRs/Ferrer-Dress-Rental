import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/config/app_config.dart';
import 'core/router/app_router.dart';
import 'core/services/firebase_service.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/auth_gate.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'features/booking/data/repositories/appointment_repository_impl.dart';
import 'features/booking/domain/repositories/appointment_repository.dart';
import 'features/booking/presentation/viewmodels/booking_viewmodel.dart';
import 'features/inventory/data/datasources/mock_item_data_source.dart';
import 'features/inventory/data/repositories/inventory_repository_impl.dart';
import 'features/inventory/domain/repositories/inventory_repository.dart';
import 'features/rentals/data/datasources/item_status_hooks.dart';
import 'features/rentals/data/repositories/rental_repository_impl.dart';
import 'features/rentals/domain/repositories/rental_repository.dart';
import 'features/rentals/domain/usecases/cancel_rental_usecase.dart';
import 'features/rentals/domain/usecases/confirm_rental_usecase.dart';
import 'features/rentals/domain/usecases/create_rental_usecase.dart';
import 'features/rentals/domain/usecases/decline_rental_usecase.dart';
import 'features/rentals/domain/usecases/process_return_usecase.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.initialize();

  final authRepository = AuthRepositoryImpl(AuthRepositoryImpl.defaultDataSource());

  final itemSource = InventoryRepositoryImpl.defaultDataSource();
  final inventoryRepository = InventoryRepositoryImpl(itemSource);

  ItemStatusHook? hook;
  if (!AppConfig.firebaseEnabled && itemSource is MockItemDataSource) {
    hook = itemSource.updateStatus;
  }

  final rentalRepository =
      RentalRepositoryImpl(RentalRepositoryImpl.defaultDataSource(hook));
  final appointmentRepository =
      AppointmentRepositoryImpl(AppointmentRepositoryImpl.defaultDataSource());

  runApp(MultiProvider(
    providers: [
      Provider<AuthRepository>.value(value: authRepository),
      Provider<InventoryRepository>.value(value: inventoryRepository),
      Provider<RentalRepository>.value(value: rentalRepository),
      Provider<AppointmentRepository>.value(value: appointmentRepository),
      ChangeNotifierProvider<AuthViewModel>(
        create: (_) => AuthViewModel(authRepository),
      ),
      Provider<CreateRentalUseCase>(
        create: (_) => CreateRentalUseCase(rentalRepository, inventoryRepository),
      ),
      Provider<ProcessReturnUseCase>(
        create: (_) =>
            ProcessReturnUseCase(rentalRepository, inventoryRepository),
      ),
      Provider<CancelRentalUseCase>(
        create: (_) =>
            CancelRentalUseCase(rentalRepository, inventoryRepository),
      ),
      Provider<ConfirmRentalUseCase>(
        create: (_) => ConfirmRentalUseCase(rentalRepository),
      ),
      Provider<DeclineRentalUseCase>(
        create: (_) =>
            DeclineRentalUseCase(rentalRepository, inventoryRepository),
      ),
      ChangeNotifierProvider<BookingViewModel>(
        create: (_) => BookingViewModel(appointmentRepository),
      ),
    ],
    child: const FerrerApp(),
  ));
}

class FerrerApp extends StatelessWidget {
  const FerrerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepository = context.read<AuthRepository>();
    return MaterialApp(
      title: 'Ferrer Clothing Rental',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      onGenerateRoute: onGenerateRoute,
      home: AuthGate(authRepository: authRepository),
    );
  }
}
