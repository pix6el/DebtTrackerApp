import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  final int initialTab;

  const AboutScreen({
    super.key,
    this.initialTab = 0,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: initialTab,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'About & Guide',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.menu_book_rounded),
                text: 'How to Use',
              ),
              Tab(
                icon: Icon(Icons.info_outline_rounded),
                text: 'About App',
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _InstructionsTab(),
            _AboutTab(),
          ],
        ),
      ),
    );
  }
}

class _InstructionsTab extends StatelessWidget {
  const _InstructionsTab();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        const _SectionHeader(
          title: 'Getting Started',
          subtitle: 'Follow these simple steps to manage your debts effortlessly.',
        ),
        const SizedBox(height: 12),
        const _StepCard(
          stepNumber: '1',
          icon: Icons.add_circle_outline_rounded,
          title: 'Add a Debt Record',
          description:
              'Tap the "+ Add Debt" button on the home screen. Choose whether "I Owe" someone or money is "Owed to Me", then enter the person\'s name, amount in RM (up to RM 100,000.00), an optional due date, and a note.',
        ),
        const SizedBox(height: 12),
        const _StepCard(
          stepNumber: '2',
          icon: Icons.filter_list_rounded,
          title: 'Track Balances & Filter',
          description:
              'The summary card at the top shows your live Net Position, total You Owe, and total Owed to Me. Use the filter chips (All, I Owe, Owed to Me, Settled) to quickly find specific records.',
        ),
        const SizedBox(height: 12),
        const _StepCard(
          stepNumber: '3',
          icon: Icons.payments_outlined,
          title: 'Record Partial or Full Payments',
          description:
              'Tap any debt card to open its details. Tap "Record Payment" to log partial repayments over time, or tap "Full" inside the payment field to pay off the remaining balance at once. Once paid in full, the debt is automatically marked as Settled.',
        ),
        const SizedBox(height: 12),
        const _StepCard(
          stepNumber: '4',
          icon: Icons.donut_large_rounded,
          title: 'Use the Monthly Plan',
          description:
              'Switch to the "Monthly" tab to visualize debts you owe by due date. View the donut breakdown for This Month, Next Month, and Incoming months, check the forecast bar chart, and review overdue or undated debts.',
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer.withAlpha(140),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: colorScheme.outlineVariant.withAlpha(120),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                color: colorScheme.onSecondaryContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Tip',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSecondaryContainer,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Always add a due date when creating an "I Owe" record so it automatically appears in your Monthly Plan forecast and helps you prepare ahead.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSecondaryContainer,
                            height: 1.4,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AboutTab extends StatelessWidget {
  const _AboutTab();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
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
                color: colorScheme.primary.withAlpha(40),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/icon/app_icon.png',
                  width: 84,
                  height: 84,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'MYR Debt Tracker',
                style: textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.onPrimary.withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Version 1.0.0',
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Simple, private, interest-free debt management in Malaysian Ringgit (MYR).',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onPrimary.withAlpha(225),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: colorScheme.outlineVariant.withAlpha(140),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About This App',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'MYR Debt Tracker is built to help you keep a clear record of personal money you owe and money owed to you — without confusing interest calculations or cloud accounts. Log repayments as you go and stay on top of upcoming monthly commitments.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: colorScheme.outlineVariant.withAlpha(140),
            ),
          ),
          child: const Column(
            children: [
              _FeatureTile(
                icon: Icons.lock_outline_rounded,
                title: '100% Offline & Private',
                subtitle:
                    'All records are saved locally on your device using SQLite. No internet or login required.',
              ),
              Divider(height: 1, indent: 64),
              _FeatureTile(
                icon: Icons.money_off_csred_rounded,
                title: 'Zero Interest Calculations',
                subtitle:
                    'Tracks exact principal balances cleanly for everyday personal borrowing and lending.',
              ),
              Divider(height: 1, indent: 64),
              _FeatureTile(
                icon: Icons.calendar_month_rounded,
                title: 'Monthly Payoff Forecast',
                subtitle:
                    'Visualizes what is due this month, next month, and beyond with charts and alerts.',
              ),
              Divider(height: 1, indent: 64),
              _FeatureTile(
                icon: Icons.dark_mode_outlined,
                title: 'Light & Dark Themes',
                subtitle:
                    'Designed with Material 3 to automatically match your device appearance.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  final String stepNumber;
  final IconData icon;
  final String title;
  final String description;

  const _StepCard({
    required this.stepNumber,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outlineVariant.withAlpha(140),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                stepNumber,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 18, color: colorScheme.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          title,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.45,
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
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withAlpha(160),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: colorScheme.primary, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(subtitle),
      ),
    );
  }
}
