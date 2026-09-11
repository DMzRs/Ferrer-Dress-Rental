import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ferrer_rental_shop/core/constants/app_colors.dart';
import 'package:ferrer_rental_shop/core/widgets/top_snackbar.dart';
import 'package:ferrer_rental_shop/core/constants/app_strings.dart';
import 'package:ferrer_rental_shop/core/widgets/common_widgets.dart';
import 'package:ferrer_rental_shop/features/auth/presentation/viewmodels/auth_viewmodel.dart';

class ProfileScreenTab extends StatelessWidget {
  /// Lets menu tiles switch tabs in the owning [UserShell]
  /// (0 = Discover, 1 = Bookings, 2 = Rentals, 3 = Profile).
  final void Function(int tabIndex) onNavigateTo;

  const ProfileScreenTab({super.key, required this.onNavigateTo});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().user;

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.creamGradient),
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 120),
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.brandGradient,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.blush.withValues(alpha: .45),
                          blurRadius: 22,
                          offset: const Offset(0, 9),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      user?.initials ?? '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    (user?.fullName.trim().isNotEmpty ?? false)
                        ? user!.fullName
                        : 'Welcome!',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 3),
                  Text(user?.email ?? '',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            if (user != null && user.fullName.trim().isEmpty) ...[
              const SizedBox(height: 18),
              _CompleteProfileBanner(
                onTap: () => _showEditProfileSheet(context),
              ),
            ],
            const SizedBox(height: 28),
            _menuCard(context, [
              _MenuItem(
                icon: Icons.person_outline_rounded,
                title: 'My Information',
                subtitle: _userSubtitle(user),
                onTap: () => _showEditProfileSheet(context),
              ),
              _MenuItem(
                icon: Icons.local_mall_outlined,
                title: 'Rental History',
                subtitle: 'View your past and active rentals',
                onTap: () => onNavigateTo(2),
              ),
              _MenuItem(
                icon: Icons.favorite_border_rounded,
                title: 'Saved Places',
                subtitle: _savedPlacesSubtitle(user),
                onTap: () => _showSavedPlacesSheet(context),
              ),
              _MenuItem(
                icon: Icons.help_outline_rounded,
                title: 'Help Center',
                subtitle: 'FAQs and how renting works',
                onTap: () => _showHelpCenterSheet(context),
              ),
            ]),
            const SizedBox(height: 18),
            const _LogoutButton(),
            const SizedBox(height: 22),
            const Center(
              child: Text(
                'Ferrer Clothing Rental · v1.1',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: .6,
                  color: AppColors.inkSoft,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _userSubtitle(dynamic user) {
    if (user == null) return 'Not signed in';
    if (user.fullName.trim().isEmpty) return 'Tap to complete your profile';
    return '${user.fullName} · ${user.phone}';
  }

  String _savedPlacesSubtitle(dynamic user) {
    final count = user?.savedPlaces?.length ?? 0;
    if (count == 0) return 'Save addresses for faster checkout';
    return '$count address${count > 1 ? 'es' : ''} saved';
  }

  Widget _menuCard(BuildContext context, List<_MenuItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.champagne),
        boxShadow: [
          BoxShadow(
            color: AppColors.blush.withValues(alpha: .2),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              Divider(height: 1, indent: 58, color: AppColors.champagne.withValues(alpha: .8)),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration:
                    const BoxDecoration(color: AppColors.blushSoft, shape: BoxShape.circle),
                child: Icon(items[i].icon, size: 19, color: AppColors.roseDark),
              ),
              title: Text(items[i].title,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
              subtitle: items[i].subtitle == null
                  ? null
                  : Text(items[i].subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11.5, color: AppColors.inkSoft)),
              trailing:
                  const Icon(Icons.chevron_right_rounded, color: AppColors.champagne),
              onTap: items[i].onTap,
            ),
          ],
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });
}

class _CompleteProfileBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _CompleteProfileBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.champagne.withValues(alpha: .5),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.goldSoft),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 18, color: AppColors.gold),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Your profile is almost empty — add your name and details.',
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _showEditProfileSheet(BuildContext context) async {
  final vm = context.read<AuthViewModel>();
  final user = vm.user;
  if (user == null) return;

  final nameController = TextEditingController(text: user.fullName);
  final phoneController = TextEditingController(text: user.phone);
  final addressController = TextEditingController(text: user.address);

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      var busy = false;
      return StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
              16, 8, 16, MediaQuery.of(sheetContext).viewInsets.bottom + 24),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.champagne,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('My Information',
                    style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink)),
                const SizedBox(height: 4),
                const Text('This is how the shop identifies and reaches you.',
                    style:
                        TextStyle(fontSize: 12.5, color: AppColors.inkSoft)),
                const SizedBox(height: 18),
                ElegantTextField(
                  controller: nameController,
                  hint: 'Maria Santos',
                  label: 'FULL NAME',
                  prefixIcon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 14),
                ElegantTextField(
                  controller: phoneController,
                  hint: '0917 123 4567',
                  label: 'PHONE NUMBER',
                  prefixIcon: Icons.phone_iphone_rounded,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 14),
                ElegantTextField(
                  controller: addressController,
                  hint: 'House #, Street, Barangay, City',
                  label: 'DEFAULT ADDRESS',
                  prefixIcon: Icons.home_outlined,
                ),
                const SizedBox(height: 20),
                GradientButton(
                  label: 'Save Changes',
                  busy: busy,
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) {
                      showTopSnackBar(
                          context, 'Please enter your full name.');
                      return;
                    }
                    setSheetState(() => busy = true);
                    final ok = await vm.updateProfile(
                      fullName: nameController.text,
                      phone: phoneController.text,
                      address: addressController.text,
                    );
                    if (!sheetContext.mounted) return;
                    setSheetState(() => busy = false);
                    Navigator.pop(sheetContext);
                    showTopSnackBar(
                      context,
                      ok
                          ? 'Profile updated.'
                          : (vm.error ?? 'Could not save your profile.'),
                      backgroundColor:
                          ok ? AppColors.success : AppColors.danger,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Future<void> _showSavedPlacesSheet(BuildContext context) async {
  final vm = context.read<AuthViewModel>();
  final user = vm.user;
  if (user == null) return;

  final newPlaceController = TextEditingController();

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      var places = [...user.savedPlaces];
      var busy = false;
      return StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
              16, 8, 16, MediaQuery.of(sheetContext).viewInsets.bottom + 24),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.champagne,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Saved Places',
                    style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink)),
                const SizedBox(height: 4),
                const Text(
                    'Addresses you rent to often — tap one at checkout to fill '
                    'the delivery address instantly.',
                    style: TextStyle(fontSize: 12.5, color: AppColors.inkSoft)),
                const SizedBox(height: 16),
                if (places.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text('No saved places yet.',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.inkSoft)),
                  ),
                for (var i = 0; i < places.length; i++)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.champagne),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.place_outlined,
                            size: 17, color: AppColors.roseDark),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            places[i],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.ink),
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.close_rounded,
                              size: 18, color: AppColors.inkSoft),
                          onPressed: () async {
                            final updated = [...places]..removeAt(i);
                            setSheetState(() => busy = true);
                            final ok =
                                await vm.updateProfile(savedPlaces: updated);
                            if (!sheetContext.mounted) return;
                            setSheetState(() {
                              if (ok) places = updated;
                              busy = false;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElegantTextField(
                        controller: newPlaceController,
                        hint: 'Add a new address',
                        prefixIcon: Icons.add_location_alt_outlined,
                        textInputAction: TextInputAction.done,
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 52,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: busy
                            ? null
                            : () async {
                                final value = newPlaceController.text.trim();
                                if (value.isEmpty || places.contains(value)) {
                                  return;
                                }
                                final updated = [...places, value];
                                setSheetState(() => busy = true);
                                final ok = await vm.updateProfile(
                                    savedPlaces: updated);
                                if (!sheetContext.mounted) return;
                                setSheetState(() {
                                  if (ok) {
                                    places = updated;
                                    newPlaceController.clear();
                                  }
                                  busy = false;
                                });
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.roseDark,
                          disabledBackgroundColor:
                              AppColors.roseDark.withValues(alpha: .5),
                          shape: const CircleBorder(),
                          padding: EdgeInsets.zero,
                        ),
                        child: busy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.2, color: Colors.white),
                              )
                            : const Icon(Icons.add_rounded,
                                color: Colors.white, size: 24),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Future<void> _showHelpCenterSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(sheetContext).size.height * .8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.champagne,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Help Center',
                  style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink)),
              const SizedBox(height: 8),
              const Text(AppStrings.helpCenterIntro,
                  style: TextStyle(
                      fontSize: 13, height: 1.55, color: AppColors.inkSoft)),
              const SizedBox(height: 16),
              for (final (question, answer) in AppStrings.helpCenterFaqs) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.champagne),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(question,
                          style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink)),
                      const SizedBox(height: 5),
                      Text(answer,
                          style: const TextStyle(
                              fontSize: 12.5,
                              height: 1.5,
                              color: AppColors.inkSoft)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      );
    },
  );
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.danger,
          side: BorderSide(color: AppColors.danger.withValues(alpha: .45)),
          backgroundColor: Colors.white.withValues(alpha: .7),
        ),
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: const Text('Sign Out'),
        onPressed: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text('Sign out?',
                  style: TextStyle(fontFamily: 'serif', fontWeight: FontWeight.w700)),
              content: const Text('You will be missed. See you soon!',
                  style: TextStyle(fontSize: 13.5)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Stay', style: TextStyle(color: AppColors.inkSoft)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Sign Out',
                      style: TextStyle(
                          color: AppColors.danger, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          );
          if (confirmed == true && context.mounted) {
            await context.read<AuthViewModel>().signOut();
          }
        },
      ),
    );
  }
}
