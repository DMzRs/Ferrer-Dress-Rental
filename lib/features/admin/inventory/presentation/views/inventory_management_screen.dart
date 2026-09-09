import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ferrer_rental_shop/core/constants/app_colors.dart';
import 'package:ferrer_rental_shop/core/utils/formatters.dart';
import 'package:ferrer_rental_shop/core/widgets/common_widgets.dart';
import 'package:ferrer_rental_shop/features/admin/inventory/presentation/viewmodels/inventory_viewmodel.dart';
import 'package:ferrer_rental_shop/features/admin/inventory/presentation/widgets/add_item_sheet.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/entities/catalog_item.dart';

class InventoryManagementScreen extends StatelessWidget {
  const InventoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<InventoryViewModel>();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-item',
        backgroundColor: AppColors.adminPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        extendedPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.add_rounded, size: 21),
        label: const Text('Add New Item',
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
        onPressed: () => AddItemSheet.show(
          context,
          onSave: vm.addItem,
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: vm.search,
                    decoration: InputDecoration(
                      hintText: 'Search inventory...',
                      prefixIcon: Icon(Icons.search_rounded,
                          size: 20, color: Colors.grey.shade500),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _CountPill(label: '${vm.availableCount} available', color: AppColors.adminPrimary),
                  _CountPill(label: '${vm.scheduledCount} scheduled', color: AppColors.adminViolet),
                  _CountPill(label: '${vm.rentedCount} rented', color: AppColors.adminAmber),
                  _CountPill(label: '${vm.maintenanceCount} maintenance', color: AppColors.adminRed),
                ],
              ),
            ),
          const SizedBox(height: 6),
          Expanded(
            child: vm.isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.adminPrimary))
                : RefreshIndicator(
                    color: AppColors.adminPrimary,
                    onRefresh: () async {},
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                      itemCount: vm.items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = vm.items[index];
                        return _InventoryTile(
                          item: item,
                          onEdit: (item) async {
                            final vm =
                                context.read<InventoryViewModel>();
                            final photos = await vm.itemPhotos(item.id);
                            if (!context.mounted) return;
                            AddItemSheet.show(
                              context,
                              onSave: vm.addItem,
                              onUpdate: vm.updateItem,
                              item: item,
                              initialPhotos: photos,
                            );
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
        ),
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  final String label;
  final Color color;

  const _CountPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11.5, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _InventoryTile extends StatelessWidget {
  final CatalogItem item;
  final ValueChanged<CatalogItem> onEdit;

  const _InventoryTile({required this.item, required this.onEdit});

  Color get _statusColor {
    switch (item.status) {
      case 'rented':
        return AppColors.adminAmber;
      case 'scheduled_for_appointment':
        return AppColors.adminViolet;
      case 'maintenance':
        return AppColors.adminRed;
      default:
        return AppColors.adminPrimary;
    }
  }

  String get _statusLabel {
    switch (item.status) {
      case 'rented':
        return 'Rented';
      case 'scheduled_for_appointment':
        return 'Scheduled for Appointment';
      case 'maintenance':
        return 'Maintenance';
      default:
        return 'Available';
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradients = AppColors.itemPlaceholderGradients;
    final colors = gradients[item.id.hashCode % gradients.length];

    return Card(
      child: ListTile(
        onTap: () => onEdit(item),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: item.thumbnail.isNotEmpty
              ? SizedBox(
                  width: 52,
                  height: 62,
                  child: itemImage(item.thumbnail, fit: BoxFit.cover),
                )
              : Container(
                  width: 52,
                  height: 62,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: colors),
                  ),
                  child: Icon(Icons.checkroom_rounded,
                      size: 22, color: Colors.white.withValues(alpha: .85)),
                ),
        ),
        title: Text(
          item.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
              color: AppColors.adminInk),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            '${item.categoryLabel} · ${Formatters.peso(item.basePrice)}/day · Deposit ${Formatters.peso(item.securityDeposit)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
          ),
        ),
        isThreeLine: false,
        dense: false,
        trailing: PopupMenuButton<String>(
          initialValue: item.status,
          tooltip: 'Quick edit status',
          onSelected: (value) =>
              context.read<InventoryViewModel>().changeStatus(item, value),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          offset: const Offset(0, 42),
          itemBuilder: (_) => [
            _menuItem('available', 'Available',
                item.isAvailable ? Icons.check_rounded : null),
            _menuItem('scheduled_for_appointment', 'Scheduled for Appointment',
                item.status == 'scheduled_for_appointment'
                    ? Icons.check_rounded
                    : null),
            _menuItem('rented', 'Rented',
                item.status == 'rented' ? Icons.check_rounded : null),
            _menuItem('maintenance', 'Maintenance',
                item.status == 'maintenance' ? Icons.check_rounded : null),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: _statusColor.withValues(alpha: .35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _statusLabel,
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: _statusColor),
                ),
                Icon(Icons.keyboard_arrow_down_rounded,
                    size: 15, color: _statusColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String value, String label, IconData? icon) {
    return PopupMenuItem<String>(
      value: value,
      height: 40,
      child: Row(
        children: [
          Icon(icon ?? Icons.circle_outlined,
              size: icon != null ? 17 : 8,
              color: icon != null
                  ? AppColors.adminPrimary
                  : Colors.grey.shade400),
          const SizedBox(width: 9),
          Text(label,
              style: const TextStyle(fontSize: 13, color: AppColors.adminInk)),
        ],
      ),
    );
  }
}



