import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ferrer_rental_shop/core/constants/app_colors.dart';
import 'package:ferrer_rental_shop/core/widgets/top_snackbar.dart';
import 'package:ferrer_rental_shop/core/utils/formatters.dart';
import 'package:ferrer_rental_shop/features/admin/appointments/presentation/viewmodels/appointments_viewmodel.dart';
import 'package:ferrer_rental_shop/features/booking/domain/entities/appointment_entity.dart';

class AdminAppointmentsScreen extends StatefulWidget {
  const AdminAppointmentsScreen({super.key});

  @override
  State<AdminAppointmentsScreen> createState() =>
      _AdminAppointmentsScreenState();
}

class _AdminAppointmentsScreenState extends State<AdminAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _controller;

  @override
  void initState() {
    super.initState();
    final initial = context.read<AppointmentsViewModel>().tab;
    _controller = TabController(length: 3, vsync: this, initialIndex: initial);
    _controller.addListener(_syncToVm);
  }

  void _syncToVm() {
    if (_controller.indexIsChanging) return;
    final vm = context.read<AppointmentsViewModel>();
    if (_controller.index != vm.tab) vm.setTab(_controller.index);
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
    final vm = context.watch<AppointmentsViewModel>();
    // Deep-links (dashboard) drive the VM tab; mirror it here without
    // clearing the highlight the link just set.
    if (_controller.index != vm.tab) {
      _controller.index = vm.tab;
    }

    return Scaffold(
        appBar: AppBar(
          title: const Text('Appointments'),
          bottom: TabBar(
            controller: _controller,
            labelColor: AppColors.adminPrimary,
            unselectedLabelColor: AppColors.adminMuted,
            indicatorColor: AppColors.adminPrimary,
            dividerColor: AppColors.adminBorder,
            labelStyle:
                const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            tabs: [
              Tab(text: 'Requests (${vm.requests.length})'),
              Tab(text: 'Scheduled (${vm.scheduled.length})'),
              Tab(text: 'Resolved (${vm.resolved.length})'),
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
                  _list(
                    context,
                    vm.requests,
                    emptyText: 'No pending requests right now.',
                  ),
                  _list(
                    context,
                    vm.scheduled,
                    emptyText: 'No confirmed appointments yet.',
                    showStatus: true,
                  ),
                  _list(
                    context,
                    vm.resolved,
                    emptyText: 'Nothing here yet.',
                    showStatus: true,
                  ),
                ],
              ),
      );
  }

  Widget _list(
    BuildContext context,
    List<Appointment> items, {
    required String emptyText,
    bool showStatus = false,
  }) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_rounded, size: 40, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            Text(emptyText,
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
        itemBuilder: (context, index) => _AppointmentTile(
          appointment: items[index],
          showStatus: showStatus,
        ),
      ),
    );
  }
}

class _AppointmentTile extends StatelessWidget {
  final Appointment appointment;
  final bool showStatus;

  const _AppointmentTile({
    required this.appointment,
    required this.showStatus,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = appointment.status == Appointment.statusPending;
    final highlighted =
        context.select<AppointmentsViewModel, bool>((vm) => vm.highlightId == appointment.id);

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 19,
                  backgroundColor: AppColors.adminPrimary.withValues(alpha: .1),
                  child: Text(
                    _initials(appointment.userName),
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
                        appointment.userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                            color: AppColors.adminInk),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        appointment.purpose == 'Measuring'
                            ? 'Measuring appointment'
                            : 'Trying on appointment',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                if (showStatus) _statusChip(appointment),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _meta(Icons.calendar_month_rounded,
                    Formatters.shortDate(appointment.scheduledAt)),
                const SizedBox(width: 10),
                _meta(Icons.schedule_rounded,
                    TimeOfDay.fromDateTime(appointment.scheduledAt).format(context)),
                if (appointment.itemName != null) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: _meta(Icons.checkroom_rounded, appointment.itemName!),
                  ),
                ],
              ],
            ),
            if (appointment.declineReason.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Declined: ${appointment.declineReason}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
              ),
            ],
            if (isPending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.adminRed,
                        side: BorderSide(
                            color: AppColors.adminRed.withValues(alpha: .5)),
                        minimumSize: const Size(0, 40),
                      ),
                      onPressed: () => _showReviewSheet(context),
                      icon: const Icon(Icons.close_rounded, size: 17),
                      label: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.adminPrimary,
                        minimumSize: const Size(0, 40),
                      ),
                      onPressed: () => _showReviewSheet(context),
                      icon: const Icon(Icons.check_rounded, size: 17),
                      label: const Text('Review & Confirm'),
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

  Widget _statusChip(Appointment appointment) {
    final color = appointment.status == Appointment.statusDeclined
        ? AppColors.adminRed
        : appointment.status == Appointment.statusCancelled
            ? AppColors.adminMuted
            : AppColors.adminPrimary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        appointment.statusLabel,
        style: TextStyle(
            fontSize: 10.5,
            letterSpacing: .5,
            fontWeight: FontWeight.w800,
            color: color),
      ),
    );
  }

  Widget _meta(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13.5, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
          ),
        ),
      ],
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  void _showReviewSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: _ReviewSheet(
          appointment: appointment,
          vm: context.read<AppointmentsViewModel>(),
        ),
      ),
    );
  }
}

class _ReviewSheet extends StatefulWidget {
  final Appointment appointment;
  final AppointmentsViewModel vm;

  const _ReviewSheet({required this.appointment, required this.vm});

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  bool _declining = false;
  bool _busy = false;
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    setState(() => _busy = true);
    final ok = await widget.vm.confirm(widget.appointment);
    if (!mounted) return;
    Navigator.pop(context);
    showTopSnackBar(
      context,
      ok
          ? 'Appointment confirmed.'
          : 'Could not confirm the appointment. Please try again.',
      backgroundColor: ok ? AppColors.adminPrimary : AppColors.adminRed,
    );
  }

  Future<void> _decline() async {
    if (_reasonController.text.trim().isEmpty) {
      showTopSnackBar(
        context,
        'Please write the reason for declining.',
        backgroundColor: AppColors.adminRed,
      );
      return;
    }
    setState(() => _busy = true);
    final ok =
        await widget.vm.decline(widget.appointment, _reasonController.text);
    if (!mounted) return;
    Navigator.pop(context);
    showTopSnackBar(
      context,
      ok
          ? 'Request declined — the customer will see your reason.'
          : 'Could not decline the request. Please try again.',
      backgroundColor: ok ? AppColors.adminPrimary : AppColors.adminRed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.appointment;

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
          Text(
            _declining ? 'Decline Request' : 'Appointment Request',
            style: const TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: AppColors.adminInk),
          ),
          const SizedBox(height: 14),
          _infoRow('Customer', a.userName),
          _infoRow('Purpose', a.purpose),
          _infoRow(
              'Schedule',
              '${Formatters.shortDate(a.scheduledAt)} · '
                  '${TimeOfDay.fromDateTime(a.scheduledAt).format(context)}'),
          if (a.itemName != null) _infoRow('Item', a.itemName!),
          const SizedBox(height: 16),
          if (!_declining) ...[
            Text(
              'Confirming will mark the appointment as scheduled'
              '${a.itemId != null ? ' and set the item to "Scheduled for Appointment".' : '.'}',
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.adminRed,
                      side: BorderSide(
                          color: AppColors.adminRed.withValues(alpha: .5)),
                      minimumSize: const Size(0, 46),
                    ),
                    onPressed: _busy ? null : () => setState(() => _declining = true),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.adminPrimary,
                      minimumSize: const Size(0, 46),
                    ),
                    onPressed: _busy ? null : _confirm,
                    icon: _busy
                        ? const SizedBox(
                            width: 17,
                            height: 17,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Confirm'),
                  ),
                ),
              ],
            ),
          ] else ...[
            TextField(
              controller: _reasonController,
              maxLines: 2,
              minLines: 1,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText:
                    'Tell the customer why this request is declined...',
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.adminMuted,
                      side: BorderSide(
                          color: AppColors.adminBorder.withValues(alpha: .8)),
                      minimumSize: const Size(0, 46),
                    ),
                    onPressed:
                        _busy ? null : () => setState(() => _declining = false),
                    child: const Text('Back'),
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
        ],
      ),
    ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.adminInk),
            ),
          ),
        ],
      ),
    );
  }
}
