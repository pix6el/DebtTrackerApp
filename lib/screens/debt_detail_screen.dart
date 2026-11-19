import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/db_helper.dart';
import '../models/debt_model.dart';
import '../utils/formatters.dart';
import '../utils/notification_service.dart';

class DebtDetailScreen extends StatefulWidget {
  final int debtId;

  const DebtDetailScreen({super.key, required this.debtId});

  @override
  State<DebtDetailScreen> createState() => _DebtDetailScreenState();
}

class _DebtDetailScreenState extends State<DebtDetailScreen> {
  Debt? _debt;
  List<DebtPayment> _payments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final debt = await DbHelper.instance.getDebtById(widget.debtId);
    final payments = await DbHelper.instance.getPaymentsForDebt(widget.debtId);
    if (!mounted) return;
    setState(() {
      _debt = debt;
      _payments = payments;
      _isLoading = false;
    });
  }

  void _openAddPaymentSheet() {
    if (_debt == null || _debt!.isSettled) return;
    final formKey = GlobalKey<FormState>();
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final remaining = _debt!.remainingAmount;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.withAlpha(100),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    'Record Payment',
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Remaining balance: ${Formatters.myr(remaining)}',
                    style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}'),
                      ),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Payment Amount (MYR)',
                      prefixText: 'RM ',
                      prefixIcon: const Icon(Icons.payments_outlined),
                      border: const OutlineInputBorder(),
                      suffixIcon: TextButton(
                        onPressed: () {
                          amountCtrl.text = remaining.toStringAsFixed(2);
                        },
                        child: const Text('Full'),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a payment amount';
                      }
                      final parsed = double.tryParse(value.trim());
                      if (parsed == null || parsed <= 0) {
                        return 'Enter a valid amount greater than 0';
                      }
                      if (parsed > remaining + 0.009) {
                        return 'Cannot exceed ${Formatters.myr(remaining)}';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: noteCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Note (Optional)',
                      prefixIcon: Icon(Icons.notes_rounded),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final entered = double.parse(amountCtrl.text.trim());
                      final paymentAmount =
                          entered > remaining ? remaining : entered;
                      final payment = DebtPayment(
                        debtId: _debt!.id!,
                        amount: paymentAmount,
                        paidAt: DateTime.now(),
                        note: noteCtrl.text.trim(),
                      );
                      await DbHelper.instance.addPayment(payment);
                      final refreshed =
                          await DbHelper.instance.getDebtById(widget.debtId);
                      if (refreshed != null) {
                        await NotificationService.instance
                            .syncDebtReminder(refreshed);
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                      _loadDetails();
                    },
                    child: const Text(
                      'Save Payment',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).whenComplete(() {
      amountCtrl.dispose();
      noteCtrl.dispose();
    });
  }

  Future<void> _confirmUndoPayment(DebtPayment payment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Undo Payment?'),
        content: Text(
          'This will remove the ${Formatters.myr(payment.amount)} payment and restore it to the remaining balance.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Undo'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DbHelper.instance.deletePayment(payment);
      final refreshed = await DbHelper.instance.getDebtById(widget.debtId);
      if (refreshed != null) {
        await NotificationService.instance.syncDebtReminder(refreshed);
      }
      _loadDetails();
    }
  }

  void _openEditDebtSheet() {
    final current = _debt;
    if (current == null) return;

    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: current.personName);
    final amountCtrl = TextEditingController(
      text: current.totalAmount.toStringAsFixed(2),
    );
    final noteCtrl = TextEditingController(text: current.note);
    DebtType selectedType = current.type;
    DateTime? selectedDueDate = current.dueDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey.withAlpha(100),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Text(
                        'Edit Debt Record',
                        style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      SegmentedButton<DebtType>(
                        segments: const [
                          ButtonSegment(
                            value: DebtType.owe,
                            label: Text('I Owe'),
                            icon: Icon(Icons.arrow_upward_rounded),
                          ),
                          ButtonSegment(
                            value: DebtType.owed,
                            label: Text('Owed to Me'),
                            icon: Icon(Icons.arrow_downward_rounded),
                          ),
                        ],
                        selected: {selectedType},
                        onSelectionChanged: (selection) {
                          setModalState(() => selectedType = selection.first);
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: nameCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Person Name',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}'),
                          ),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Total Amount (MYR)',
                          helperText: current.paidAmount > 0
                              ? 'Already paid: ${Formatters.myr(current.paidAmount)} (Max RM 100,000.00)'
                              : 'Max RM 100,000.00',
                          prefixText: 'RM ',
                          prefixIcon: const Icon(Icons.payments_outlined),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter an amount';
                          }
                          final parsed = double.tryParse(value.trim());
                          if (parsed == null || parsed <= 0) {
                            return 'Enter a valid amount greater than 0';
                          }
                          if (parsed > 100000) {
                            return 'Maximum amount is RM 100,000.00';
                          }
                          if (parsed + 0.009 < current.paidAmount) {
                            return 'Cannot be less than paid (${Formatters.myr(current.paidAmount)})';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: ctx,
                                  initialDate: selectedDueDate ??
                                      DateTime.now().add(
                                        const Duration(days: 7),
                                      ),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  setModalState(
                                    () => selectedDueDate = picked,
                                  );
                                }
                              },
                              icon: const Icon(
                                Icons.calendar_today_rounded,
                                size: 18,
                              ),
                              label: Text(
                                selectedDueDate == null
                                    ? 'Add Due Date (Optional)'
                                    : 'Due: ${Formatters.date(selectedDueDate!)}',
                              ),
                            ),
                          ),
                          if (selectedDueDate != null) ...[
                            const SizedBox(width: 8),
                            IconButton.outlined(
                              tooltip: 'Clear Due Date',
                              onPressed: () {
                                setModalState(() => selectedDueDate = null);
                              },
                              icon: const Icon(Icons.close_rounded, size: 18),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: noteCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Note (Optional)',
                          prefixIcon: Icon(Icons.notes_rounded),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          final updated = current.copyWith(
                            personName: nameCtrl.text.trim(),
                            type: selectedType,
                            totalAmount: double.parse(amountCtrl.text.trim()),
                            dueDate: selectedDueDate,
                            clearDueDate: selectedDueDate == null,
                            note: noteCtrl.text.trim(),
                          );
                          await DbHelper.instance.updateDebt(updated);
                          await NotificationService.instance
                              .syncDebtReminder(updated);
                          if (ctx.mounted) Navigator.pop(ctx);
                          _loadDetails();
                        },
                        child: const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      nameCtrl.dispose();
      amountCtrl.dispose();
      noteCtrl.dispose();
    });
  }

  Future<void> _confirmDeleteDebt() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Record?'),
        content: const Text(
          'This will permanently delete this debt and all its payment history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && _debt?.id != null) {
      await NotificationService.instance.cancelDebtReminders(_debt!.id!);
      await DbHelper.instance.deleteDebt(_debt!.id!);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_debt == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Record not found')),
      );
    }

    final debt = _debt!;
    final isOwe = debt.type == DebtType.owe;
    final accentColor = debt.isSettled
        ? Colors.grey
        : (isOwe ? const Color(0xFFD94848) : const Color(0xFF1F9D68));
    final colorScheme = Theme.of(context).colorScheme;
    final progressPercent = (debt.progress * 100).round();

    return Scaffold(
      appBar: AppBar(
        title: Text(debt.personName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Record',
            onPressed: _openEditDebtSheet,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Delete Record',
            onPressed: _confirmDeleteDebt,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDetails,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: colorScheme.outlineVariant.withAlpha(140),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withAlpha(30),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            debt.isSettled
                                ? 'Settled'
                                : (isOwe ? 'You Owe' : 'Owed to Me'),
                            style: TextStyle(
                              color: accentColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Text(
                          '$progressPercent% paid',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Remaining Balance',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Formatters.myr(debt.remainingAmount),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: debt.progress,
                        minHeight: 8,
                        backgroundColor: accentColor.withAlpha(30),
                        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Paid: ${Formatters.myr(debt.paidAmount)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          'Total: ${Formatters.myr(debt.totalAmount)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 28),
                    _buildMetaRow(
                      icon: Icons.schedule_rounded,
                      label: 'Created',
                      value: Formatters.dateTime(debt.createdAt),
                    ),
                    if (debt.dueDate != null) ...[
                      const SizedBox(height: 8),
                      _buildMetaRow(
                        icon: Icons.calendar_today_rounded,
                        label: 'Due Date',
                        value: debt.isOverdue
                            ? '${Formatters.date(debt.dueDate!)} (Overdue)'
                            : Formatters.date(debt.dueDate!),
                        valueColor:
                            debt.isOverdue ? const Color(0xFFD94848) : null,
                      ),
                    ],
                    if (debt.note.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildMetaRow(
                        icon: Icons.notes_rounded,
                        label: 'Note',
                        value: debt.note,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Payment History',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 10),
            if (_payments.isEmpty)
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: colorScheme.outlineVariant.withAlpha(140),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 40,
                        color: colorScheme.outline.withAlpha(140),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No payments recorded yet',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._payments.map(
                (payment) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: colorScheme.outlineVariant.withAlpha(140),
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: CircleAvatar(
                        backgroundColor:
                            colorScheme.primaryContainer.withAlpha(160),
                        child: Icon(
                          Icons.check_rounded,
                          color: colorScheme.primary,
                        ),
                      ),
                      title: Text(
                        Formatters.myr(payment.amount),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(Formatters.dateTime(payment.paidAt)),
                          if (payment.note.isNotEmpty)
                            Text(
                              payment.note,
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.undo_rounded),
                        tooltip: 'Undo payment',
                        onPressed: () => _confirmUndoPayment(payment),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: debt.isSettled
          ? null
          : FloatingActionButton.extended(
              onPressed: _openAddPaymentSheet,
              icon: const Icon(Icons.add_card_rounded),
              label: const Text('Record Payment'),
            ),
    );
  }

  Widget _buildMetaRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}
