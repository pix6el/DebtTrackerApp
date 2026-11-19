import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myr_debt_tracker/models/debt_model.dart';
import 'package:myr_debt_tracker/screens/monthly_plan_screen.dart';

void main() {
  test('Debt remainingAmount and isSettled calculations', () {
    final debt = Debt(
      personName: 'Aiman',
      type: DebtType.owe,
      totalAmount: 100.0,
      paidAmount: 40.0,
      createdAt: DateTime(2026, 1, 1),
    );

    expect(debt.remainingAmount, 60.0);
    expect(debt.isSettled, isFalse);
    expect(debt.progress, 0.4);
  });

  testWidgets('MonthlyPlanScreen shows this month, next month, and incoming', (
    tester,
  ) async {
    final now = DateTime.now();
    final thisMonthDue = DateTime(now.year, now.month, 15);
    final nextMonthDue = DateTime(now.year, now.month + 1, 15);
    final incomingDue = DateTime(now.year, now.month + 2, 15);

    final debts = [
      Debt(
        id: 1,
        personName: 'Bank Loan',
        type: DebtType.owe,
        totalAmount: 500,
        paidAmount: 100,
        dueDate: thisMonthDue,
        createdAt: now,
      ),
      Debt(
        id: 2,
        personName: 'Friend Ali',
        type: DebtType.owe,
        totalAmount: 200,
        dueDate: nextMonthDue,
        createdAt: now,
      ),
      Debt(
        id: 3,
        personName: 'Car Installment',
        type: DebtType.owe,
        totalAmount: 800,
        dueDate: incomingDue,
        createdAt: now,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MonthlyPlanScreen(
            debts: debts,
            onRefresh: () async {},
          ),
        ),
      ),
    );

    expect(find.text('Bank Loan'), findsOneWidget);
    expect(find.text('Monthly Outlook'), findsOneWidget);

    // Switch to Incoming tab
    await tester.tap(find.text('Incoming'));
    await tester.pumpAndSettle();
    expect(find.text('Car Installment'), findsOneWidget);
  });
}
