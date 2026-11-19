import 'package:flutter/material.dart';
import '../models/debt_model.dart';
import '../utils/formatters.dart';
import '../widgets/donut_chart.dart';
import 'debt_detail_screen.dart';

enum MonthlyPeriod { thisMonth, nextMonth, incoming }

class MonthlyPlanScreen extends StatefulWidget {
  final List<Debt> debts;
  final Future<void> Function() onRefresh;

  const MonthlyPlanScreen({
    super.key,
    required this.debts,
    required this.onRefresh,
  });

  @override
  State<MonthlyPlanScreen> createState() => _MonthlyPlanScreenState();
}

class _MonthlyPlanScreenState extends State<MonthlyPlanScreen> {
  MonthlyPeriod _selectedPeriod = MonthlyPeriod.thisMonth;

  DateTime _monthStart(DateTime base, int offsetMonths) {
    return DateTime(base.year, base.month + offsetMonths, 1);
  }

  bool _isSameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  List<Debt> get _unpaidOweDebts => widget.debts
      .where((d) => d.type == DebtType.owe && !d.isSettled)
      .toList();

  List<Debt> _debtsForMonth(DateTime targetMonth) {
    final list = _unpaidOweDebts
        .where(
          (d) => d.dueDate != null && _isSameMonth(d.dueDate!, targetMonth),
        )
        .toList();
    list.sort((a, b) => b.remainingAmount.compareTo(a.remainingAmount));
    return list;
  }

  List<Debt> _incomingDebts(DateTime incomingStart) {
    final list = _unpaidOweDebts
        .where(
          (d) => d.dueDate != null && !d.dueDate!.isBefore(incomingStart),
        )
        .toList();
    list.sort((a, b) => b.remainingAmount.compareTo(a.remainingAmount));
    return list;
  }

  List<Debt> _overdueFromPastMonths(DateTime thisMonthStart) {
    return _unpaidOweDebts
        .where(
          (d) => d.dueDate != null && d.dueDate!.isBefore(thisMonthStart),
        )
        .toList();
  }

  List<Debt> get _noDueDateDebts =>
      _unpaidOweDebts.where((d) => d.dueDate == null).toList();

  double _sumRemaining(List<Debt> items) =>
      items.fold(0.0, (sum, d) => sum + d.remainingAmount);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final thisMonth = _monthStart(now, 0);
    final nextMonth = _monthStart(now, 1);
    final monthPlus2 = _monthStart(now, 2);
    final monthPlus3 = _monthStart(now, 3);
    final laterStart = _monthStart(now, 4);

    final thisMonthDebts = _debtsForMonth(thisMonth);
    final nextMonthDebts = _debtsForMonth(nextMonth);
    final incomingDebts = _incomingDebts(monthPlus2);
    final overduePastDebts = _overdueFromPastMonths(thisMonth);
    final noDueDateDebts = _noDueDateDebts;

    final List<Debt> activeDebts;
    final String activeTitle;
    final String activeSubtitle;

    switch (_selectedPeriod) {
      case MonthlyPeriod.thisMonth:
        activeDebts = thisMonthDebts;
        activeTitle = Formatters.monthYear(thisMonth);
        activeSubtitle = 'Due this month';
      case MonthlyPeriod.nextMonth:
        activeDebts = nextMonthDebts;
        activeTitle = Formatters.monthYear(nextMonth);
        activeSubtitle = 'Due next month';
      case MonthlyPeriod.incoming:
        activeDebts = incomingDebts;
        activeTitle = '${Formatters.monthYear(monthPlus2)}+';
        activeSubtitle = 'Incoming months';
    }

    final activeTotal = _sumRemaining(activeDebts);
    final slices = <DonutSlice>[
      for (int i = 0; i < activeDebts.length; i++)
        DonutSlice(
          label: activeDebts[i].personName,
          value: activeDebts[i].remainingAmount,
          color: DonutChart.colorForIndex(i),
        ),
    ];

    // Forecast data for bar graph
    final forecastBuckets = <_ForecastBucket>[
      _ForecastBucket(
        label: Formatters.shortMonth(thisMonth),
        sublabel: 'This mo',
        total: _sumRemaining(thisMonthDebts),
        count: thisMonthDebts.length,
        period: MonthlyPeriod.thisMonth,
      ),
      _ForecastBucket(
        label: Formatters.shortMonth(nextMonth),
        sublabel: 'Next mo',
        total: _sumRemaining(nextMonthDebts),
        count: nextMonthDebts.length,
        period: MonthlyPeriod.nextMonth,
      ),
      _ForecastBucket(
        label: Formatters.shortMonth(monthPlus2),
        sublabel: '${monthPlus2.year}',
        total: _sumRemaining(_debtsForMonth(monthPlus2)),
        count: _debtsForMonth(monthPlus2).length,
        period: MonthlyPeriod.incoming,
      ),
      _ForecastBucket(
        label: Formatters.shortMonth(monthPlus3),
        sublabel: '${monthPlus3.year}',
        total: _sumRemaining(_debtsForMonth(monthPlus3)),
        count: _debtsForMonth(monthPlus3).length,
        period: MonthlyPeriod.incoming,
      ),
    ];

    final laterDebts = _incomingDebts(laterStart);
    if (laterDebts.isNotEmpty) {
      forecastBuckets.add(
        _ForecastBucket(
          label: 'Later',
          sublabel: '${Formatters.shortMonth(laterStart)}+',
          total: _sumRemaining(laterDebts),
          count: laterDebts.length,
          period: MonthlyPeriod.incoming,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          SegmentedButton<MonthlyPeriod>(
            segments: [
              ButtonSegment(
                value: MonthlyPeriod.thisMonth,
                label: Text('This (${Formatters.shortMonth(thisMonth)})'),
              ),
              ButtonSegment(
                value: MonthlyPeriod.nextMonth,
                label: Text('Next (${Formatters.shortMonth(nextMonth)})'),
              ),
              const ButtonSegment(
                value: MonthlyPeriod.incoming,
                label: Text('Incoming'),
              ),
            ],
            selected: {_selectedPeriod},
            onSelectionChanged: (selection) {
              setState(() => _selectedPeriod = selection.first);
            },
          ),
          const SizedBox(height: 16),

          // Donut Chart Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: BorderSide(
                color: colorScheme.outlineVariant.withAlpha(140),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activeTitle,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            activeSubtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withAlpha(160),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${activeDebts.length} ${activeDebts.length == 1 ? 'debt' : 'debts'}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  DonutChart(
                    slices: slices,
                    size: 210,
                    strokeWidth: 26,
                    center: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'To Pay',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            Formatters.myr(activeTotal),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (activeDebts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'No unpaid debts due in this period.',
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  else ...[
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    for (int i = 0; i < activeDebts.length; i++)
                      _buildBreakdownRow(
                        context: context,
                        debt: activeDebts[i],
                        color: DonutChart.colorForIndex(i),
                        total: activeTotal,
                      ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Monthly Forecast Bar Graph Card
          _buildForecastCard(context, forecastBuckets),

          // Overdue & Undated notice cards (so nothing is missed)
          if (overduePastDebts.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildNoticeCard(
              context: context,
              icon: Icons.warning_amber_rounded,
              iconColor: const Color(0xFFD94848),
              title:
                  '${overduePastDebts.length} overdue from earlier ${overduePastDebts.length == 1 ? 'month' : 'months'}',
              amount: _sumRemaining(overduePastDebts),
            ),
          ],
          if (noDueDateDebts.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildNoticeCard(
              context: context,
              icon: Icons.event_busy_rounded,
              iconColor: colorScheme.onSurfaceVariant,
              title:
                  '${noDueDateDebts.length} unpaid ${noDueDateDebts.length == 1 ? 'debt' : 'debts'} without a due date',
              amount: _sumRemaining(noDueDateDebts),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBreakdownRow({
    required BuildContext context,
    required Debt debt,
    required Color color,
    required double total,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final percent = total > 0 ? ((debt.remainingAmount / total) * 100) : 0.0;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DebtDetailScreen(debtId: debt.id!),
          ),
        );
        await widget.onRefresh();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
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
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (debt.dueDate != null)
                    Text(
                      debt.isOverdue
                          ? 'Overdue • ${Formatters.date(debt.dueDate!)}'
                          : 'Due ${Formatters.date(debt.dueDate!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: debt.isOverdue
                            ? const Color(0xFFD94848)
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Formatters.myr(debt.remainingAmount),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${percent.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 11,
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

  Widget _buildForecastCard(
    BuildContext context,
    List<_ForecastBucket> buckets,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final maxAmount = buckets.fold<double>(
      0.0,
      (maxVal, b) => b.total > maxVal ? b.total : maxVal,
    );

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: colorScheme.outlineVariant.withAlpha(140),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Outlook',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              'Tap a month to view its donut breakdown',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            for (final bucket in buckets)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    setState(() => _selectedPeriod = bucket.period);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 2,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  bucket.label,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: _selectedPeriod == bucket.period
                                        ? colorScheme.primary
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${bucket.sublabel} • ${bucket.count} ${bucket.count == 1 ? 'debt' : 'debts'}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              Formatters.myr(bucket.total),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: bucket.total > 0
                                    ? colorScheme.onSurface
                                    : colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: maxAmount > 0 ? bucket.total / maxAmount : 0,
                            minHeight: 8,
                            backgroundColor: colorScheme.surfaceContainerHighest
                                .withAlpha(180),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _selectedPeriod == bucket.period
                                  ? colorScheme.primary
                                  : colorScheme.primary.withAlpha(140),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoticeCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required double amount,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withAlpha(140),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              Formatters.myr(amount),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ForecastBucket {
  final String label;
  final String sublabel;
  final double total;
  final int count;
  final MonthlyPeriod period;

  const _ForecastBucket({
    required this.label,
    required this.sublabel,
    required this.total,
    required this.count,
    required this.period,
  });
}
