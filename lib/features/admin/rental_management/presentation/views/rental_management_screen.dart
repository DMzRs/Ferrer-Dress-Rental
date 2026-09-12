import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ferrer_rental_shop/core/constants/app_colors.dart';
import 'package:ferrer_rental_shop/core/widgets/top_snackbar.dart';
import 'package:ferrer_rental_shop/core/utils/formatters.dart';
import 'package:ferrer_rental_shop/features/admin/rental_management/presentation/viewmodels/rental_management_viewmodel.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/entities/rental_entity.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/usecases/process_return_usecase.dart';

class RentalManagementScreen extends StatefulWidget {
  const RentalManagementScreen({super.key});

  @override
  State<RentalManagementScreen> createState() => _RentalManagementScreenState();
}

class _RentalManagementScreenState extends State<RentalManagementScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _controller;

  @override
  void initState() {
    super.initState();
    final initial = context.read<RentalManagementViewModel>().tab.index;
    _controller = TabController(length: 5, vsync: this, initialIndex: initial);
    _controller.addListener(_syncToVm);
  }

  void _syncToVm() {
    if (_controller.indexIsChanging) return;
    final vm = context.read<RentalManagementViewModel>();
    final tab = RentalTab.values[_controller.index];
    if (tab != vm.tab) vm.setTab(tab);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_syncToVm)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RentalManagementViewModel>();
    // Deep-links (dashboard) drive the VM tab; mirror it here without
    // clearing the highlight the link just set.
    if (_controller.index != vm.tab.index) {
      _controller.index = vm.tab.index;
    }

    return Scaffold(
        appBar: AppBar(
          title: const Text('Rental Management'),
          bottom: TabBar(
            controller: _controller,
            isScrollable: true,
            labelColor: AppColors.adminPrimary,
            unselectedLabelColor: AppColors.adminMuted,
            indicatorColor: AppColors.adminPrimary,
            dividerColor: AppColors.adminBorder,
            labelStyle:
                const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            tabs: [
              Tab(text: 'Requests (${vm.pendingCount})'),
              Tab(text: 'Rejected (${vm.rejectedCount})'),
              Tab(text: 'Active (${vm.activeCount})'),
              Tab(text: 'Overdue (${vm.overdueCount})'),
              Tab(text: 'Completed (${vm.completedCount})'),
            ],
          ),
        ),
        body: vm.isLoading
            ? const Center(
                child:
                    CircularProgressIndicator(color: AppColors.adminPrimary))
            : TabBarView(
                controller: _controller,
                children: [
                  _list(context, vm, RentalTab.requests),
                  _list(context, vm, RentalTab.rejected),
                  _list(context, vm, RentalTab.active),
                  _list(context, vm, RentalTab.overdue),
                  _list(context, vm, RentalTab.completed),
                ],
              ),
      );
  }

  Widget _list(BuildContext context, RentalManagementViewModel vm, RentalTab tab) {
    final items = switch (tab) {
      RentalTab.requests =>
        vm.allRentals.where((r) => r.isPending).toList(),
      RentalTab.overdue =>
        vm.allRentals.where((r) => r.isOverdue).toList(),
      RentalTab.completed =>
        vm.allRentals.where((r) => r.isCompleted).toList(),
      RentalTab.rejected =>
        vm.allRentals.where((r) => r.isDeclined || r.isCancelled).toList(),
      RentalTab.active =>
        vm.allRentals.where((r) => r.status == 'active').toList(),
    };

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 40, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            Text(
                tab == RentalTab.requests
                    ? 'No pending rental requests'
                    : 'Nothing in this tab',
                style: TextStyle(fontSize: 13.5, color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.adminPrimary,
      onRefresh: () async {},
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) => _RentalRow(
                          rental: items[index],
                          showReturnButton: tab == RentalTab.active ||
                              tab == RentalTab.overdue,
                          showDecisionButtons: tab == RentalTab.requests,
                        ),
      ),
    );
  }
}

class _RentalRow extends StatelessWidget {
  final Rental rental;
  final bool showReturnButton;
  final bool showDecisionButtons;

  const _RentalRow({
    required this.rental,
    required this.showReturnButton,
    this.showDecisionButtons = false,
  });

  @override
  Widget build(BuildContext context) {
    final overdue = rental.isOverdue;
    final vm = showDecisionButtons ? context.watch<RentalManagementViewModel>() : null;
    final busy = vm?.isProcessing ?? false;
    final processingThis = vm?.processingRentalId == rental.id && busy;
    final highlighted =
        context.select<RentalManagementViewModel, bool>((m) => m.highlightId == rental.id);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: highlighted
              ? AppColors.adminPrimary
              : AppColors.adminBorder,
          width: highlighted ? 1.8 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 19,
                  backgroundColor:
                      AppColors.adminPrimary.withValues(alpha: .1),
                  child: Text(
                    _initials(rental.userName),
                    style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.adminPrimary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rental.userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                            color: AppColors.adminInk),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        rental.itemName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      rental.isPending
                          ? 'Requested ${Formatters.shortDate(rental.createdAt)}'
                          : 'Due ${Formatters.shortDate(rental.endDate)}',
                      style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: (overdue ||
                                  rental.isDeclined ||
                                  rental.isCancelled)
                              ? AppColors.adminRed
                              : AppColors.adminMuted),
                    ),
                    if (rental.isPending)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.adminAmber.withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text('PENDING',
                              style: TextStyle(
                                  fontSize: 9.5,
                                  letterSpacing: .6,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.adminAmber)),
                        ),
                      )
                    else if (overdue)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                AppColors.adminRed.withValues(alpha: .09),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text('OVERDUE',
                              style: TextStyle(
                                  fontSize: 9.5,
                                  letterSpacing: .6,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.adminRed)),
                        ),
                      )
                    else if (rental.isDeclined || rental.isCancelled)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                AppColors.adminRed.withValues(alpha: .09),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                              rental.isDeclined ? 'DECLINED' : 'CANCELLED',
                              style: const TextStyle(
                                  fontSize: 9.5,
                                  letterSpacing: .6,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.adminRed)),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _meta(Icons.calendar_month_rounded,
                    '${Formatters.shortDate(rental.startDate)} → ${Formatters.shortDate(rental.endDate)}'),
                const SizedBox(width: 14),
                _meta(Icons.payments_rounded,
                    Formatters.peso(rental.total)),
                const Spacer(),
                if (showDecisionButtons) ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.adminPrimary,
                      minimumSize: const Size(0, 38),
                    ),
                    onPressed:
                        busy ? null : () => _showDecisionModal(context, decline: false),
                    icon: processingThis
                        ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_rounded, size: 17),
                    label: const Text('Confirm'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.adminRed,
                      side: BorderSide(
                          color: AppColors.adminRed.withValues(alpha: .5)),
                      minimumSize: const Size(0, 38),
                    ),
                    onPressed:
                        busy ? null : () => _showDecisionModal(context, decline: true),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Decline'),
                  ),
                ] else if (showReturnButton)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: overdue
                          ? AppColors.adminRed
                          : AppColors.adminPrimary,
                      minimumSize: const Size(0, 38),
                    ),
                    onPressed: () => _showReturnModal(context),
                    icon: const Icon(Icons.assignment_return_rounded,
                        size: 17),
                    label: const Text('Process Return'),
                  ),
              ],
            ),
            if (rental.deliveryAddress.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.home_outlined,
                      size: 13.5, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      rental.deliveryAddress,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 11.5, color: Colors.grey.shade600),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _meta(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13.5, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Text(text,
            style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
      ],
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Future<void> _showReturnModal(BuildContext context) async {
    final vm = context.read<RentalManagementViewModel>();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: _ReturnConfirmationSheet(rental: rental, vm: vm),
        ),
      ),
    );
  }

  Future<void> _showDecisionModal(BuildContext context,
      {required bool decline}) async {
    final vm = context.read<RentalManagementViewModel>();
    if (!decline) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Confirm this rental?'),
          content: Text(
            '${rental.userName} will be notified that "${rental.itemName}" '
            '(${Formatters.shortDate(rental.startDate)} → ${Formatters.shortDate(rental.endDate)}) '
            'is confirmed for their rental dates.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Go Back'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Confirm',
                  style: TextStyle(
                      color: AppColors.adminPrimary,
                      fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      final error = await vm.confirmRental(rental);
      if (error == null) return;
      if (context.mounted) {
        showTopSnackBar(context, error, backgroundColor: AppColors.adminRed);
      }
      return;
    }

    // Decline requires a reason (mirrors the appointment flow) so the
    // customer sees WHY in My Rentals. Keyboard-aware bottom sheet.
    // The sheet owns its TextEditingController (created/disposed in its own
    // State) so disposal always happens at unmount — never while the pop
    // animation can still touch the field.
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: _DeclineRentalSheet(
          rental: rental,
          vm: context.read<RentalManagementViewModel>(),
          pageContext: context,
        ),
      ),
    );
  }
}

class _DeclineRentalSheet extends StatefulWidget {
  final Rental rental;
  final RentalManagementViewModel vm;

  /// Context of the page underneath, for post-pop feedback.
  final BuildContext pageContext;

  const _DeclineRentalSheet({
    required this.rental,
    required this.vm,
    required this.pageContext,
  });

  @override
  State<_DeclineRentalSheet> createState() => _DeclineRentalSheetState();
}

class _DeclineRentalSheetState extends State<_DeclineRentalSheet> {
  final _reasonController = TextEditingController();
  bool _busy = false;
  String? _fieldError;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _decline() async {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      setState(() => _fieldError = 'Please write the reason for declining.');
      return;
    }
    setState(() {
      _busy = true;
      _fieldError = null;
    });
    final error =
        await widget.vm.declineRental(widget.rental, reason);
    if (!mounted) return;
    Navigator.pop(context);
    if (error != null && widget.pageContext.mounted) {
      showTopSnackBar(
        widget.pageContext,
        error,
        backgroundColor: AppColors.adminRed,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.adminCard,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Decline this rental?',
                style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.adminInk)),
            const SizedBox(height: 8),
            Text(
              '${widget.rental.userName} requested "${widget.rental.itemName}" '
              '(${Formatters.shortDate(widget.rental.startDate)} → ${Formatters.shortDate(widget.rental.endDate)}). '
              'They will see your reason and get a full refund.',
              style: TextStyle(
                  fontSize: 12.5, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              minLines: 1,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText:
                    'Tell the customer why this request is declined...',
                errorText: _fieldError,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.adminMuted,
                      side: const BorderSide(
                          color: AppColors.adminBorder),
                      minimumSize: const Size(0, 46),
                    ),
                    onPressed: _busy
                        ? null
                        : () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.adminRed,
                      minimumSize: const Size(0, 46),
                    ),
                    onPressed: _busy ? null : _decline,
                    icon: _busy
                        ? const SizedBox(
                            width: 17,
                            height: 17,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_rounded, size: 18),
                    label: const Text('Decline & Notify'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReturnConfirmationSheet extends StatefulWidget {
  final Rental rental;
  final RentalManagementViewModel vm;

  const _ReturnConfirmationSheet({required this.rental, required this.vm});

  @override
  State<_ReturnConfirmationSheet> createState() =>
      _ReturnConfirmationSheetState();
}

class _ReturnConfirmationSheetState extends State<_ReturnConfirmationSheet> {
  bool _processing = true;
  ProcessReturnResult? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    setState(() {
      _processing = true;
      _error = null;
    });
    final result = await widget.vm.processReturn(widget.rental);
    if (!mounted) return;
    setState(() {
      _result = result;
      _processing = false;
      if (result == null) _error = 'Could not process this return.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final deposit = widget.rental.securityDeposit;
    final refundAmount =
        _result?.depositRefunded ?? (widget.rental.isOverdue ? deposit * .5 : deposit);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.adminCard,
        borderRadius: BorderRadius.circular(22),
      ),
      child: _processing ? _progress() : (_error != null ? _failure() : _success(refundAmount)),
    );
  }

  Widget _progress() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(color: AppColors.adminPrimary),
        const SizedBox(height: 18),
        Text('Processing return for ${widget.rental.itemName}...',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _failure() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline_rounded, size: 42, color: AppColors.adminRed),
        const SizedBox(height: 14),
        Text(_error ?? 'Something went wrong',
            style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 18),
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _success(double refundAmount) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.adminPrimary.withValues(alpha: .1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  size: 26, color: AppColors.adminPrimary),
            ),
            const SizedBox(width: 13),
            const Expanded(
              child: Text(
                'Return Processed',
                style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.adminInk),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${widget.rental.itemName} · ${widget.rental.userName}',
          style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppColors.adminSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.adminBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SECURITY DEPOSIT REFUND',
                        style: TextStyle(
                            fontSize: 9.5,
                            letterSpacing: 1.1,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade500)),
                    const SizedBox(height: 5),
                    Text(
                      Formatters.peso(refundAmount),
                      style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          color: AppColors.adminInk),
                    ),
                    if (_result?.wasOverdue ?? false)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '50% late deduction applied',
                          style: TextStyle(
                              fontSize: 11.5, color: Colors.grey.shade600),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('Full refund — on time',
                            style: TextStyle(
                                fontSize: 11.5, color: Colors.grey.shade600)),
                      ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: (_result?.wasOverdue ?? false)
                      ? AppColors.adminAmber.withValues(alpha: .12)
                      : AppColors.adminPrimary.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  (_result?.wasOverdue ?? false) ? 'PARTIAL' : 'FULL',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .5,
                      color: (_result?.wasOverdue ?? false)
                          ? AppColors.adminAmber
                          : AppColors.adminPrimary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 46,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.done_all_rounded, size: 18),
            label: const Text('Done'),
          ),
        ),
      ],
    );
  }
}



