import 'package:flutter/material.dart';
import '../models/debt_model.dart';
import '../utils/formatters.dart';
import 'debt_detail_screen.dart';

enum PersonFilter { all, owe, owed, settled }

class PeopleSummaryScreen extends StatefulWidget {
  final List<Debt> debts;
  final Future<void> Function() onRefresh;

  const PeopleSummaryScreen({
    super.key,
    required this.debts,
    required this.onRefresh,
  });

  @override
  State<PeopleSummaryScreen> createState() => _PeopleSummaryScreenState();
}

class _PeopleSummaryScreenState extends State<PeopleSummaryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  PersonFilter _filter = PersonFilter.all;
  final Set<String> _expandedKeys = {};

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  int _debtSortRank(Debt d) {
    if (d.isSettled) return 2;
    if (d.dueDate != null) return 0;
    return 1;
  }

  int _compareGroupDebts(Debt a, Debt b) {
    final rankCmp = _debtSortRank(a).compareTo(_debtSortRank(b));
    if (rankCmp != 0) return rankCmp;
    if (!a.isSettled && a.dueDate != null && b.dueDate != null) {
      final dueCmp = a.dueDate!.compareTo(b.dueDate!);
      if (dueCmp != 0) return dueCmp;
      final remCmp = b.remainingAmount.compareTo(a.remainingAmount);
      if (remCmp != 0) return remCmp;
    }
    return b.createdAt.compareTo(a.createdAt);
  }

  List<_PersonGroup> _buildGroups() {
    final buckets = <String, List<Debt>>{};
    final displayNames = <String, String>{};

    for (final debt in widget.debts) {
      final trimmed = debt.personName.trim();
      final key = trimmed.toLowerCase();
      buckets.putIfAbsent(key, () => []).add(debt);
      displayNames.putIfAbsent(
        key,
        () => trimmed.isNotEmpty ? trimmed : 'Unnamed',
      );
    }

    final groups = <_PersonGroup>[];
    for (final entry in buckets.entries) {
      final list = List<Debt>.from(entry.value)..sort(_compareGroupDebts);

      var oweRemaining = 0.0;
      var owedRemaining = 0.0;
      var totalOriginal = 0.0;
      var totalPaid = 0.0;
      var activeCount = 0;
      var overdueCount = 0;
      DateTime? nextDueDate;

      for (final d in list) {
        totalOriginal += d.totalAmount;
        totalPaid += d.paidAmount;
        if (!d.isSettled) {
          activeCount++;
          if (d.type == DebtType.owe) {
            oweRemaining += d.remainingAmount;
          } else {
            owedRemaining += d.remainingAmount;
          }
          if (d.isOverdue) {
            overdueCount++;
          }
          if (d.dueDate != null &&
              (nextDueDate == null || d.dueDate!.isBefore(nextDueDate))) {
            nextDueDate = d.dueDate;
          }
        }
      }

      groups.add(
        _PersonGroup(
          key: entry.key,
          displayName: displayNames[entry.key]!,
          debts: list,
          oweRemaining: oweRemaining,
          owedRemaining: owedRemaining,
          totalOriginal: totalOriginal,
          totalPaid: totalPaid,
          activeCount: activeCount,
          overdueCount: overdueCount,
          nextDueDate: nextDueDate,
        ),
      );
    }

    groups.sort((a, b) {
      if (a.isAllSettled != b.isAllSettled) {
        return a.isAllSettled ? 1 : -1;
      }
      final netCmp = b.netBalance.abs().compareTo(a.netBalance.abs());
      if (netCmp != 0) return netCmp;
      final grossCmp = (b.oweRemaining + b.owedRemaining)
          .compareTo(a.oweRemaining + a.owedRemaining);
      if (grossCmp != 0) return grossCmp;
      return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
    });

    return groups;
  }

  List<_PersonGroup> _applyFilters(List<_PersonGroup> groups) {
    Iterable<_PersonGroup> items;
    switch (_filter) {
      case PersonFilter.owe:
        items = groups.where((g) => !g.isAllSettled && g.netBalance < -0.009);
      case PersonFilter.owed:
        items = groups.where((g) => !g.isAllSettled && g.netBalance > 0.009);
      case PersonFilter.settled:
        items = groups.where((g) => g.isAllSettled);
      case PersonFilter.all:
        items = groups;
    }

    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      items = items.where(
        (g) =>
            g.displayName.toLowerCase().contains(query) ||
            g.debts.any(
              (d) =>
                  d.note.toLowerCase().contains(query) ||
                  d.category.label.toLowerCase().contains(query),
            ),
      );
    }
    return items.toList();
  }

  void _resetFilters() {
    _searchCtrl.clear();
    setState(() {
      _searchQuery = '';
      _filter = PersonFilter.all;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final allGroups = _buildGroups();
    final filteredGroups = _applyFilters(allGroups);
    final activePeople = allGroups.where((g) => !g.isAllSettled).length;
    final settledPeople = allGroups.length - activePeople;

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: _buildOverviewCard(
                colorScheme: colorScheme,
                totalPeople: allGroups.length,
                activePeople: activePeople,
                settledPeople: settledPeople,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildSearchBox(colorScheme),
          ),
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
              child: Row(
                children: [
                  _buildFilterChip('All', PersonFilter.all),
                  const SizedBox(width: 8),
                  _buildFilterChip('You Owe', PersonFilter.owe),
                  const SizedBox(width: 8),
                  _buildFilterChip('Owed to Me', PersonFilter.owed),
                  const SizedBox(width: 8),
                  _buildFilterChip('Settled', PersonFilter.settled),
                ],
              ),
            ),
          ),
          if (filteredGroups.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        allGroups.isNotEmpty
                            ? Icons.person_search_rounded
                            : Icons.people_outline_rounded,
                        size: 64,
                        color: colorScheme.outline.withAlpha(130),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        allGroups.isNotEmpty
                            ? 'No matching people'
                            : 'No people to group yet',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        allGroups.isNotEmpty
                            ? 'Try another search or clear your filter'
                            : 'Debts with the same person name are grouped here automatically',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.outline,
                            ),
                      ),
                      if (allGroups.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: _resetFilters,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Reset Filter'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
              sliver: SliverList.separated(
                itemCount: filteredGroups.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) => _buildPersonCard(
                  filteredGroups[index],
                  colorScheme,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard({
    required ColorScheme colorScheme,
    required int totalPeople,
    required int activePeople,
    required int settledPeople,
  }) {
    return Card(
      elevation: 0,
      color: colorScheme.primaryContainer.withAlpha(110),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outlineVariant.withAlpha(120),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          children: [
            _buildStatColumn(
              colorScheme: colorScheme,
              label: 'People',
              value: '$totalPeople',
              icon: Icons.people_outline_rounded,
              iconColor: colorScheme.primary,
            ),
            _buildStatDivider(colorScheme),
            _buildStatColumn(
              colorScheme: colorScheme,
              label: 'Active',
              value: '$activePeople',
              icon: Icons.pending_actions_rounded,
              iconColor: const Color(0xFFD97706),
            ),
            _buildStatDivider(colorScheme),
            _buildStatColumn(
              colorScheme: colorScheme,
              label: 'Settled',
              value: '$settledPeople',
              icon: Icons.check_circle_outline_rounded,
              iconColor: const Color(0xFF1F9D68),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatDivider(ColorScheme colorScheme) {
    return Container(
      width: 1,
      height: 34,
      color: colorScheme.outlineVariant.withAlpha(140),
    );
  }

  Widget _buildStatColumn({
    required ColorScheme colorScheme,
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: iconColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox(ColorScheme colorScheme) {
    final borderSide = BorderSide(
      color: colorScheme.outlineVariant.withAlpha(140),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: TextField(
        controller: _searchCtrl,
        textInputAction: TextInputAction.search,
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search person...',
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  tooltip: 'Clear search',
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          isDense: true,
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest.withAlpha(110),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: borderSide,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: borderSide,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, PersonFilter value) {
    return FilterChip(
      label: Text(label),
      selected: _filter == value,
      onSelected: (_) => setState(() => _filter = value),
      showCheckmark: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _buildPersonCard(_PersonGroup group, ColorScheme colorScheme) {
    final isExpanded = _expandedKeys.contains(group.key);
    final accentColor = group.isAllSettled
        ? Colors.grey
        : (group.isEven
            ? colorScheme.primary
            : (group.netBalance < 0
                ? const Color(0xFFD94848)
                : const Color(0xFF1F9D68)));

    final statusLabel = group.isAllSettled
        ? 'Settled'
        : (group.isEven
            ? 'Even'
            : (group.netBalance < 0 ? 'You owe' : 'Owes you'));

    final initial =
        group.displayName.isNotEmpty ? group.displayName[0].toUpperCase() : '?';
    final recordCountText =
        '${group.debts.length} ${group.debts.length == 1 ? 'record' : 'records'}';
    final statusDetailText = group.isAllSettled
        ? '$recordCountText • All settled'
        : '$recordCountText • ${group.activeCount} active';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: colorScheme.outlineVariant.withAlpha(140),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedKeys.remove(group.key);
                } else {
                  _expandedKeys.add(group.key);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 21,
                        backgroundColor: accentColor.withAlpha(30),
                        child: Text(
                          initial,
                          style: TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              statusDetailText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (group.overdueCount > 0 ||
                                group.nextDueDate != null) ...[
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  if (group.overdueCount > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFD94848)
                                            .withAlpha(28),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${group.overdueCount} overdue',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFFD94848),
                                        ),
                                      ),
                                    ),
                                  if (group.nextDueDate != null)
                                    Text(
                                      'Next due ${Formatters.date(group.nextDueDate!)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: accentColor,
                            ),
                          ),
                          if (!group.isAllSettled && !group.isEven) ...[
                            const SizedBox(height: 1),
                            Text(
                              Formatters.myr(group.netBalance.abs()),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: accentColor,
                              ),
                            ),
                          ],
                          const SizedBox(height: 2),
                          Icon(
                            isExpanded
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                            size: 20,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (group.hasBothSides) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest
                            .withAlpha(110),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'You owe ${Formatters.myr(group.oweRemaining)} • Owes you ${Formatters.myr(group.owedRemaining)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: group.progress,
                      minHeight: 6,
                      backgroundColor: accentColor.withAlpha(30),
                      valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1),
            for (int i = 0; i < group.debts.length; i++) ...[
              if (i > 0) const Divider(height: 1, indent: 48),
              _buildDebtRow(group.debts[i], colorScheme),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildDebtRow(Debt debt, ColorScheme colorScheme) {
    final isOwe = debt.type == DebtType.owe;
    final rowAccent = debt.isSettled
        ? Colors.grey
        : (isOwe ? const Color(0xFFD94848) : const Color(0xFF1F9D68));

    return InkWell(
      onTap: () async {
        if (debt.id == null) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DebtDetailScreen(debtId: debt.id!),
          ),
        );
        await widget.onRefresh();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            Icon(
              isOwe
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              size: 18,
              color: rowAccent,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: debt.category.color.withAlpha(26),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          debt.category.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: debt.category.color,
                          ),
                        ),
                      ),
                      if (debt.isInstallment)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer.withAlpha(180),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            debt.installmentLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      if (debt.dueDate != null)
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
                        )
                      else
                        Text(
                          isOwe ? 'You owe' : 'Owes you',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                  if (debt.note.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      debt.note,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
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
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: rowAccent,
                  ),
                ),
                Text(
                  'of ${Formatters.myr(debt.totalAmount)}',
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: colorScheme.outline,
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonGroup {
  final String key;
  final String displayName;
  final List<Debt> debts;
  final double oweRemaining;
  final double owedRemaining;
  final double totalOriginal;
  final double totalPaid;
  final int activeCount;
  final int overdueCount;
  final DateTime? nextDueDate;

  const _PersonGroup({
    required this.key,
    required this.displayName,
    required this.debts,
    required this.oweRemaining,
    required this.owedRemaining,
    required this.totalOriginal,
    required this.totalPaid,
    required this.activeCount,
    required this.overdueCount,
    required this.nextDueDate,
  });

  double get netBalance => owedRemaining - oweRemaining;

  bool get isAllSettled => activeCount == 0;

  bool get hasBothSides => oweRemaining > 0.009 && owedRemaining > 0.009;

  bool get isEven => !isAllSettled && netBalance.abs() <= 0.009;

  double get progress =>
      totalOriginal == 0 ? 1.0 : (totalPaid / totalOriginal).clamp(0.0, 1.0);
}
