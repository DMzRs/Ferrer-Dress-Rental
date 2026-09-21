import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ferrer_rental_shop/core/constants/app_colors.dart';
import 'package:ferrer_rental_shop/features/auth/domain/repositories/auth_repository.dart';
import 'package:ferrer_rental_shop/features/booking/domain/repositories/appointment_repository.dart';
import 'package:ferrer_rental_shop/features/booking/presentation/viewmodels/my_appointments_viewmodel.dart';
import 'package:ferrer_rental_shop/features/booking/presentation/views/my_appointments_screen.dart';
import 'package:ferrer_rental_shop/features/home/presentation/viewmodels/home_viewmodel.dart';
import 'package:ferrer_rental_shop/features/home/presentation/views/home_screen.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/entities/chat_message.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/entities/conversation.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/repositories/message_repository.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/usecases/mark_seen_usecase.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/usecases/send_message_usecase.dart';
import 'package:ferrer_rental_shop/features/messaging/presentation/viewmodels/thread_viewmodel.dart';
import 'package:ferrer_rental_shop/features/messaging/presentation/views/customer_thread_screen.dart';
import 'package:ferrer_rental_shop/features/notifications/domain/notifications_builder.dart';
import 'package:ferrer_rental_shop/features/notifications/presentation/views/notifications_screen.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/repositories/rental_repository.dart';
import 'package:ferrer_rental_shop/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:ferrer_rental_shop/features/rentals/presentation/viewmodels/my_rentals_viewmodel.dart';
import 'package:ferrer_rental_shop/features/rentals/presentation/views/my_rentals_screen.dart';
import 'profile_screen_tab.dart';

class UserShell extends StatelessWidget {
  /// Tab to open first (0 = Discover, 2 = Rentals). Deep links like the
  /// post-checkout "View My Rentals" route land directly on Rentals.
  final int initialTab;

  /// Rental id to flash-highlight once it appears in the list (post-checkout).
  final String? highlightRentalId;

  const UserShell({super.key, this.initialTab = 0, this.highlightRentalId});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<HomeViewModel>(
          create: (_) => HomeViewModel(
            context.read<InventoryRepository>(),
          ),
        ),
        ChangeNotifierProvider<MyRentalsViewModel>(
          create: (_) => MyRentalsViewModel(
            context.read<RentalRepository>(),
            context.read<AuthRepository>(),
          ),
        ),
        ChangeNotifierProvider<MyAppointmentsViewModel>(
          create: (_) => MyAppointmentsViewModel(
            context.read<AppointmentRepository>(),
            context.read<AuthRepository>(),
          ),
        ),
        ChangeNotifierProvider<ThreadViewModel>(
          create: (_) => ThreadViewModel(
            messages: context.read<MessageRepository>(),
            sender: context.read<SendMessageUseCase>(),
            seen: context.read<MarkSeenUseCase>(),
            auth: context.read<AuthRepository>(),
          ),
        ),
      ],
      child: _UserShellView(
        initialTab: initialTab,
        highlightRentalId: highlightRentalId,
      ),
    );
  }
}

class _UserShellView extends StatefulWidget {
  final int initialTab;
  final String? highlightRentalId;

  const _UserShellView({this.initialTab = 0, this.highlightRentalId});

  @override
  State<_UserShellView> createState() => _UserShellViewState();
}

class _UserShellViewState extends State<_UserShellView> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    final notificationsCount = attentionCount(buildNotifications(
      context.watch<MyRentalsViewModel>().allRentalsForNotifications,
      context.watch<MyAppointmentsViewModel>().allAppointmentsForNotifications,
    ));
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(onAvatarTap: () => setState(() => _index = 5)),
          const MyAppointmentsScreen(),
          MyRentalsScreen(highlightRentalId: widget.highlightRentalId),
          const CustomerThreadScreen(),
          NotificationsScreen(
            onNavigateTo: (tab) => setState(() => _index = tab),
          ),
          ProfileScreenTab(
            onNavigateTo: (tab) => setState(() => _index = tab),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .97),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppColors.goldSoft.withValues(alpha: .6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .07),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            indicatorColor: AppColors.blushSoft,
            height: 64,
            labelTextStyle: WidgetStateProperty.all(
              TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.inkSoft.withValues(alpha: .9),
              ),
            ),
            iconTheme: WidgetStateProperty.resolveWith(
              (states) => IconThemeData(
                size: 23,
                color: states.contains(WidgetState.selected)
                    ? AppColors.roseDark
                    : AppColors.inkSoft.withValues(alpha: .65),
              ),
            ),
          ),
          child: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) {
              setState(() => _index = i);
              // Entering the Messages tab marks the thread read.
              if (i == 3) context.read<ThreadViewModel>().markRead();
            },
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore_rounded),
                label: 'Discover',
              ),
              const NavigationDestination(
                icon: Icon(Icons.event_note_outlined),
                selectedIcon: Icon(Icons.event_note_rounded),
                label: 'Bookings',
              ),
              const NavigationDestination(
                icon: Icon(Icons.local_mall_outlined),
                selectedIcon: Icon(Icons.local_mall_rounded),
                label: 'Rentals',
              ),
              NavigationDestination(
                icon: const _MessagesBadge(
                  icon: Icons.forum_outlined,
                  selectedIcon: Icons.forum_rounded,
                ),
                selectedIcon: const _MessagesBadge(
                  icon: Icons.forum_outlined,
                  selectedIcon: Icons.forum_rounded,
                  selected: true,
                ),
                label: 'Messages',
              ),
              NavigationDestination(
                icon: _NavIcon(
                  icon: Icons.notifications_outlined,
                  selectedIcon: Icons.notifications_rounded,
                  badgeCount: notificationsCount,
                ),
                selectedIcon: _NavIcon(
                  icon: Icons.notifications_outlined,
                  selectedIcon: Icons.notifications_rounded,
                  badgeCount: notificationsCount,
                  selected: true,
                ),
                label: 'Notifications',
              ),
              const NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Nav icon with an attention-count bubble. Plain icon when zero.
class _NavIcon extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final int badgeCount;
  final bool selected;

  const _NavIcon({
    required this.icon,
    required this.selectedIcon,
    required this.badgeCount,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconWidget =
        Icon(selected ? selectedIcon : icon);
    if (badgeCount <= 0) return iconWidget;
    return Badge(
      backgroundColor: AppColors.roseDark,
      textColor: Colors.white,
      label: Text(badgeCount > 9 ? '9+' : '$badgeCount'),
      child: iconWidget,
    );
  }
}

/// Messages tab icon: bubble counts the shop's messages newer than the
/// customer's last open. Plain icon when zero.
class _MessagesBadge extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;

  const _MessagesBadge({
    required this.icon,
    required this.selectedIcon,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthViewModel>().user?.uid;
    if (uid == null) {
      return Icon(selected ? selectedIcon : icon);
    }
    return StreamBuilder<Conversation?>(
      stream: context.read<MessageRepository>().watchThread(uid),
      builder: (context, threadSnap) {
        return StreamBuilder<List<ChatMessage>>(
          stream: context.read<MessageRepository>().watchMessages(uid),
          builder: (context, msgSnap) {
            final seen = threadSnap.data?.lastSeenCustomer;
            final count = (msgSnap.data ?? const <ChatMessage>[]).where((m) {
              if (m.senderRole != 'admin') return false;
              if (m.createdAt == null) return false;
              if (seen == null) return true;
              return m.createdAt!.isAfter(seen);
            }).length;
            final iconWidget = Icon(selected ? selectedIcon : icon);
            if (count <= 0) return iconWidget;
            return Badge(
              backgroundColor: AppColors.roseDark,
              textColor: Colors.white,
              label: Text(count > 9 ? '9+' : '$count'),
              child: iconWidget,
            );
          },
        );
      },
    );
  }
}
