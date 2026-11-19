import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/db_helper.dart';
import '../models/debt_model.dart';
import '../utils/formatters.dart';
import '../utils/notification_service.dart';
import 'about_screen.dart';
import 'debt_detail_screen.dart';
import 'monthly_plan_screen.dart';
import 'settings_screen.dart';

enum DebtFilter { all, owe, owed, settled }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Debt> _debts = [];
  DebtFilter _filter = DebtFilter.all;
  bool _isLoading = true;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _loadDebts();
  }

  Future<void> _loadDebts() async {
    final data = await DbHelper.instance.getAllDebts();
    if (!mounted) return;
    setState(() {
      _debts = data;
      _isLoading = false;
    });
  }

  double get _totalOwe => _debts
      .where((d) => d.type == DebtType.owe && !d.isSettled)
      .fold(0.0, (sum, d) => sum + d.remainingAmount);

  double get _totalOwed => _debts
      .where((d) => d.type == DebtType.owed && !d.isSettled)
      .fold(0.0, (sum, d) => sum + d.remainingAmount);

  List<Debt> get _filteredDebts {
    switch (_filter) {
      case DebtFilter.owe:
        return _debts
            .where((d) => d.type == DebtType.owe && !d.isSettled)
            .toList();
      case DebtFilter.owed:
        return _debts
            .where((d) => d.type == DebtType.owed && !d.isSettled)
            .toList();
      case DebtFilter.settled:
        return _debts.where((d) => d.isSettled).toList();
      case DebtFilter.all:
        return _debts;
    }
  }

  void _openAddDebtSheet() {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    DebtType selectedType = DebtType.owe;
    DateTime? selectedDueDate;

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
                        'New Debt Record',
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
                        decoration: const InputDecoration(
                          labelText: 'Total Amount (MYR)',
                          helperText: 'Max RM 100,000.00',
                          prefixText: 'RM ',
                          prefixIcon: Icon(Icons.payments_outlined),
                          border: OutlineInputBorder(),
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
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: selectedDueDate ??
                                DateTime.now().add(const Duration(days: 7)),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setModalState(() => selectedDueDate = picked);
                          }
                        },
                        icon: const Icon(Icons.calendar_today_rounded, size: 18),
                        label: Text(
                          selectedDueDate == null
                              ? 'Add Due Date (Optional)'
                              : 'Due: ${Formatters.date(selectedDueDate!)}',
                        ),
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
                          final debt = Debt(
                            personName: nameCtrl.text.trim(),
                            type: selectedType,
                            totalAmount: double.parse(amountCtrl.text.trim()),
                            dueDate: selectedDueDate,
                            note: noteCtrl.text.trim(),
                            createdAt: DateTime.now(),
                          );
                          final insertedId =
                              await DbHelper.instance.insertDebt(debt);
                          await NotificationService.instance.syncDebtReminder(
                            debt.copyWith(id: insertedId),
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                          _loadDebts();
                        },
                        child: const Text(
                          'Save Record',
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final netBalance = _totalOwed - _totalOwe;

    return Scaffold(
      drawer: _buildSidebar(colorScheme),
      appBar: AppBar(
        title: Text(
          _selectedTab == 0 ? 'Debt Tracker' : 'Monthly Plan',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _selectedTab == 0
              ? _buildDebtsBody(colorScheme, netBalance)
              : MonthlyPlanScreen(
                  debts: _debts,
                  onRefresh: _loadDebts,
                ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (index) {
          setState(() => _selectedTab = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Debts',
          ),
          NavigationDestination(
            icon: Icon(Icons.donut_large_outlined),
            selectedIcon: Icon(Icons.donut_large_rounded),
            label: 'Monthly',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddDebtSheet,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Debt'),
      ),
    );
  }

  Widget _buildDebtsBody(ColorScheme colorScheme, double netBalance) {
    return RefreshIndicator(
      onRefresh: _loadDebts,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: _buildSummaryCard(colorScheme, netBalance),
            ),
          ),
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),
              child: Row(
                children: [
                  _buildFilterChip('All', DebtFilter.all),
                  const SizedBox(width: 8),
                  _buildFilterChip('I Owe', DebtFilter.owe),
                  const SizedBox(width: 8),
                  _buildFilterChip('Owed to Me', DebtFilter.owed),
                  const SizedBox(width: 8),
                  _buildFilterChip('Settled', DebtFilter.settled),
                ],
              ),
            ),
          ),
          if (_filteredDebts.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 64,
                      color: colorScheme.outline.withAlpha(130),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No debt records found',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap + Add Debt to create a new entry',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.outline,
                          ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              sliver: SliverList.separated(
                itemCount: _filteredDebts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) =>
                    _buildDebtCard(_filteredDebts[index]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(ColorScheme colorScheme, double netBalance) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.primaryContainer.withAlpha(220),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withAlpha(45),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Net Position',
            style: TextStyle(
              color: colorScheme.onPrimary.withAlpha(210),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${netBalance >= 0 ? '+' : '-'}${Formatters.myr(netBalance.abs())}',
            style: TextStyle(
              color: colorScheme.onPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _buildStatPill(
                  label: 'You Owe',
                  amount: Formatters.myr(_totalOwe),
                  icon: Icons.arrow_upward_rounded,
                  iconColor: Colors.redAccent.shade100,
                  textColor: colorScheme.onPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatPill(
                  label: 'Owed to Me',
                  amount: Formatters.myr(_totalOwed),
                  icon: Icons.arrow_downward_rounded,
                  iconColor: Colors.greenAccent.shade100,
                  textColor: colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill({
    required String label,
    required String amount,
    required IconData icon,
    required Color iconColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(35),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: textColor.withAlpha(190),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  amount,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, DebtFilter value) {
    final isSelected = _filter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _filter = value),
      showCheckmark: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _buildDebtCard(Debt debt) {
    final isOwe = debt.type == DebtType.owe;
    final accentColor = debt.isSettled
        ? Colors.grey
        : (isOwe ? const Color(0xFFD94848) : const Color(0xFF1F9D68));
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: colorScheme.outlineVariant.withAlpha(140),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DebtDetailScreen(debtId: debt.id!),
            ),
          );
          _loadDebts();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: accentColor.withAlpha(30),
                    child: Icon(
                      isOwe
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      color: accentColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          debt.personName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              isOwe ? 'You owe' : 'Owes you',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (debt.dueDate != null) ...[
                              Text(
                                ' • ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                debt.isOverdue
                                    ? 'Overdue (${Formatters.date(debt.dueDate!)})'
                                    : 'Due ${Formatters.date(debt.dueDate!)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: debt.isOverdue
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: debt.isOverdue
                                      ? const Color(0xFFD94848)
                                      : colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        debt.isSettled
                            ? 'Settled'
                            : Formatters.myr(debt.remainingAmount),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'of ${Formatters.myr(debt.totalAmount)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: debt.progress,
                  minHeight: 6,
                  backgroundColor: accentColor.withAlpha(30),
                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                ),
              ),
              if (debt.note.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  debt.note,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _openAboutScreen(int initialTab) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AboutScreen(initialTab: initialTab),
      ),
    );
  }

  void _openSettingsScreen() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SettingsScreen(),
      ),
    );
  }

  Widget _buildSidebar(ColorScheme colorScheme) {
    final textTheme = Theme.of(context).textTheme;

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              margin: const EdgeInsets.all(14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary,
                    colorScheme.primaryContainer.withAlpha(220),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      'assets/icon/app_icon.png',
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MYR Debt Tracker',
                          style: textTheme.titleMedium?.copyWith(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Offline Ringgit Manager',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onPrimary.withAlpha(215),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _buildDrawerTile(
                    icon: Icons.account_balance_wallet_outlined,
                    selectedIcon: Icons.account_balance_wallet_rounded,
                    label: 'Debts',
                    selected: _selectedTab == 0,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _selectedTab = 0);
                    },
                  ),
                  const SizedBox(height: 4),
                  _buildDrawerTile(
                    icon: Icons.donut_large_outlined,
                    selectedIcon: Icons.donut_large_rounded,
                    label: 'Monthly Plan',
                    selected: _selectedTab == 1,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _selectedTab = 1);
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    child: Divider(height: 1),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: Text(
                      'SETTINGS & INFO',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  _buildDrawerTile(
                    icon: Icons.settings_outlined,
                    selectedIcon: Icons.settings_rounded,
                    label: 'Settings',
                    selected: false,
                    onTap: _openSettingsScreen,
                  ),
                  const SizedBox(height: 4),
                  _buildDrawerTile(
                    icon: Icons.menu_book_outlined,
                    selectedIcon: Icons.menu_book_rounded,
                    label: 'How to Use',
                    selected: false,
                    onTap: () => _openAboutScreen(0),
                  ),
                  const SizedBox(height: 4),
                  _buildDrawerTile(
                    icon: Icons.info_outline_rounded,
                    selectedIcon: Icons.info_rounded,
                    label: 'About App',
                    selected: false,
                    onTap: () => _openAboutScreen(1),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    Icons.offline_pin_outlined,
                    size: 16,
                    color: colorScheme.outline,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Version 1.0.0 • 100% Offline',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerTile({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      selected: selected,
      selectedTileColor: colorScheme.secondaryContainer,
      selectedColor: colorScheme.onSecondaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      leading: Icon(selected ? selectedIcon : icon),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}
