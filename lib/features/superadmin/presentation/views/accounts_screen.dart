import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ferrer_rental_shop/core/constants/app_colors.dart';
import 'package:ferrer_rental_shop/core/utils/formatters.dart';
import 'package:ferrer_rental_shop/core/utils/validators.dart';
import 'package:ferrer_rental_shop/core/widgets/common_widgets.dart';
import 'package:ferrer_rental_shop/core/widgets/top_snackbar.dart';
import 'package:ferrer_rental_shop/features/auth/domain/entities/app_user.dart';
import 'package:ferrer_rental_shop/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:ferrer_rental_shop/features/superadmin/presentation/viewmodels/accounts_viewmodel.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AccountsViewModel>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout_rounded, size: 21),
            onPressed: () => context.read<AuthViewModel>().signOut(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'register-admin',
        backgroundColor: AppColors.adminPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        icon: const Icon(Icons.person_add_rounded, size: 20),
        label: const Text('Register Admin',
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
        onPressed: () => _showRegisterDialog(context),
      ),
      body: StreamBuilder<List<AppUser>>(
        stream: vm.usersStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                  color: AppColors.adminPrimary),
            );
          }
          // A denied read (e.g. outdated Firestore rules) surfaces here,
          // not as an empty directory.
          if (snapshot.hasError) {
            return const EmptyState(
              icon: Icons.cloud_off_outlined,
              title: 'Couldn\'t load accounts',
              subtitle:
                  'Check your connection and Firestore rules, then try again.',
            );
          }
          final users = snapshot.data ?? const <AppUser>[];
          if (users.isEmpty) {
            return const EmptyState(
              icon: Icons.people_outline_rounded,
              title: 'No accounts yet',
              subtitle: 'Registered accounts will appear here.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
            itemCount: users.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) =>
                _AccountTile(user: users[index]),
          );
        },
      ),
    );
  }

  Future<void> _showRegisterDialog(BuildContext context) {
    final vm = context.read<AccountsViewModel>();
    final name = TextEditingController();
    final email = TextEditingController();
    final phone = TextEditingController();
    final password = TextEditingController();
    final formKey = GlobalKey<FormState>();
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Register Admin'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElegantTextField(
                  controller: name,
                  hint: 'Full name',
                  label: 'FULL NAME',
                  prefixIcon: Icons.person_outline_rounded,
                  validator: Validators.fullName,
                ),
                const SizedBox(height: 12),
                ElegantTextField(
                  controller: email,
                  hint: 'admin@example.com',
                  label: 'EMAIL ADDRESS',
                  prefixIcon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                ),
                const SizedBox(height: 12),
                ElegantTextField(
                  controller: phone,
                  hint: '0917 123 4567',
                  label: 'PHONE NUMBER',
                  prefixIcon: Icons.phone_iphone_rounded,
                  keyboardType: TextInputType.phone,
                  validator: Validators.phone,
                ),
                const SizedBox(height: 12),
                ElegantTextField(
                  controller: password,
                  hint: '••••••••',
                  label: 'PASSWORD',
                  prefixIcon: Icons.lock_rounded,
                  obscureText: true,
                  validator: Validators.password,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!(formKey.currentState?.validate() ?? false)) return;
              final ok = await vm.createAdmin(
                fullName: name.text,
                email: email.text,
                phone: phone.text,
                password: password.text,
              );
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              showAppSnackBar(
                context,
                ok
                    ? 'Admin account created.'
                    : (vm.error ?? 'Could not create admin.'),
                backgroundColor: ok ? AppColors.success : AppColors.danger,
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

  /// Demote always asks first (misclick protection): the dues warning is
  /// included when the account holds outstanding rentals.
  Future<void> _confirmDemote(BuildContext context, AccountsViewModel vm,
      AppUser user, UserRole role) async {
    final dues = await vm.pendingDues(user.uid);
    if (!context.mounted) return;
    final hasDues = dues != null && dues.count > 0;
    final displayName =
        user.fullName.isEmpty ? user.email : user.fullName;
    final proceed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(hasDues
                ? 'Demote with pending rentals?'
                : 'Demote $displayName?'),
            content: Text(
              hasDues
                  ? 'This account has ${Formatters.peso(dues.total)} across '
                      '${dues.count} active rental${dues.count == 1 ? '' : 's'} '
                      'they will no longer see. Proceed?'
                  : '$displayName will lose access to the admin app. Proceed?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Keep Admin'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Demote Anyway'),
              ),
            ],
          ),
        ) ??
        false;
    if (!proceed || !context.mounted) return;
    final ok = await vm.changeRole(user, role);
    if (!ok && context.mounted) {
      showAppSnackBar(
        context,
        vm.error ?? 'Could not change role.',
        backgroundColor: AppColors.danger,
      );
    }
  }

class _AccountTile extends StatelessWidget {
  final AppUser user;

  const _AccountTile({required this.user});

  Color get _roleColor {
    switch (user.role) {
      case UserRole.superadmin:
        return AppColors.adminPrimaryDark;
      case UserRole.admin:
        return AppColors.adminPrimary;
      case UserRole.customer:
        return AppColors.adminMuted;
    }
  }

  String get _roleLabel {
    switch (user.role) {
      case UserRole.superadmin:
        return 'Superadmin';
      case UserRole.admin:
        return 'Admin';
      case UserRole.customer:
        return 'Customer';
    }
  }

  Widget _pill({IconData? trailingIcon, String? tooltip}) {
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _roleColor.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _roleColor.withValues(alpha: .35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _roleLabel,
            style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: _roleColor),
          ),
          if (trailingIcon != null) ...[
            const SizedBox(width: 4),
            Icon(trailingIcon, size: 14, color: _roleColor),
          ],
        ],
      ),
    );
    if (tooltip == null) return pill;
    return Tooltip(message: tooltip, child: pill);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<AccountsViewModel>();
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        leading: CircleAvatar(
          backgroundColor: AppColors.adminPrimarySoft,
          foregroundColor: AppColors.adminPrimary,
          child: Text(user.initials,
              style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
        title: Text(
          user.fullName.isEmpty ? user.email : user.fullName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
              color: AppColors.adminInk),
        ),
        subtitle: Text(
          user.email,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12.5),
        ),
        trailing: switch (user.role) {
          // Superadmins are locked; customers have nowhere to go.
          UserRole.superadmin => _pill(
              trailingIcon: Icons.lock_outline_rounded,
              tooltip: 'Superadmin role cannot be changed here',
            ),
          UserRole.customer => _pill(),
          // Fresh accounts only: promotion happens exclusively through
          // Register Admin, never by converting a customer.
          UserRole.admin => PopupMenuButton<UserRole>(
              tooltip: 'Demote to customer',
              onSelected: (role) =>
                  _confirmDemote(context, vm, user, role),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: UserRole.customer,
                  child: Text('Demote to customer'),
                ),
              ],
              child: _pill(
                  trailingIcon: Icons.keyboard_arrow_down_rounded),
            ),
        },
      ),
    );
  }
}
