import 'dart:math';
import '../models/transaction.dart';
import '../models/loan.dart';
import '../models/savings_goal.dart';

enum TimeHorizon {
  daily,
  weekly,
  monthly,
  yearly,
}

class CategoryInsight {
  final String category;
  final double spent;
  final double budget;
  final double remaining;
  final double percentOfTotal;
  final double percentOfBudget;
  final bool isOverBudget;
  final bool hasBudget;
  final double? suggestedBudget;

  const CategoryInsight({
    required this.category,
    required this.spent,
    required this.budget,
    required this.remaining,
    required this.percentOfTotal,
    required this.percentOfBudget,
    required this.isOverBudget,
    this.hasBudget = true,
    this.suggestedBudget,
  });
}

class Rule503020Insight {
  final double needsSpent;
  final double wantsSpent;
  final double savingsAmount;
  final double totalIncome;
  final double needsPercent;
  final double wantsPercent;
  final double savingsPercent;
  final String assessment;

  const Rule503020Insight({
    required this.needsSpent,
    required this.wantsSpent,
    required this.savingsAmount,
    required this.totalIncome,
    required this.needsPercent,
    required this.wantsPercent,
    required this.savingsPercent,
    required this.assessment,
  });
}

class LoanInsight {
  final double totalPayable;
  final double totalReceivable;
  final double netDebt;
  final double monthlyDebtPayment;
  final double debtToIncomeRatio;
  final String dtiStatus; // 'Healthy', 'Moderate', 'Strained'
  final List<Loan> upcomingDueLoans;
  final String payoffAdvice;

  const LoanInsight({
    required this.totalPayable,
    required this.totalReceivable,
    required this.netDebt,
    required this.monthlyDebtPayment,
    required this.debtToIncomeRatio,
    required this.dtiStatus,
    required this.upcomingDueLoans,
    required this.payoffAdvice,
  });
}

class PaymentTypeInsight {
  final String accountName;
  final double amount;
  final double percentage;

  const PaymentTypeInsight({
    required this.accountName,
    required this.amount,
    required this.percentage,
  });
}

class GoalInsight {
  final double periodStashed;
  final double totalVaultBalance;
  final int activeGoalsCount;
  final int completedGoalsCount;
  final List<SavingsGoal> nearingCompletionGoals;
  final String motivationalSummary;

  const GoalInsight({
    required this.periodStashed,
    required this.totalVaultBalance,
    required this.activeGoalsCount,
    required this.completedGoalsCount,
    required this.nearingCompletionGoals,
    required this.motivationalSummary,
  });
}

class FinancialHealthScore {
  final int score; // 0 - 100
  final String rating; // 'Excellent', 'Strong', 'Moderate', 'Needs Attention'
  final String explanation;

  const FinancialHealthScore({
    required this.score,
    required this.rating,
    required this.explanation,
  });
}

class InsightsReport {
  final TimeHorizon horizon;
  final DateTime startDate;
  final DateTime endDate;
  final String periodLabel;
  final double totalInflow;
  final double totalOutflow;
  final double netSavings;
  final double savingsRate;
  final double dailyVelocity;
  final double previousOutflow;
  final double spendingChangePercent; // positive = increased spending
  final FinancialHealthScore healthScore;
  final String accountantSummary;
  final List<String> accountantKeyActionItems;
  final List<CategoryInsight> categories;
  final Rule503020Insight rule503020;
  final LoanInsight loanInsight;
  final List<PaymentTypeInsight> paymentTypes;
  final GoalInsight goalInsight;
  final double safeToSpendDaily;
  final double safeToSpendWeekly;
  final double projected6MonthSavings;
  final double projected1YearSavings;

  const InsightsReport({
    required this.horizon,
    required this.startDate,
    required this.endDate,
    required this.periodLabel,
    required this.totalInflow,
    required this.totalOutflow,
    required this.netSavings,
    required this.savingsRate,
    required this.dailyVelocity,
    required this.previousOutflow,
    required this.spendingChangePercent,
    required this.healthScore,
    required this.accountantSummary,
    required this.accountantKeyActionItems,
    required this.categories,
    required this.rule503020,
    required this.loanInsight,
    required this.paymentTypes,
    required this.goalInsight,
    required this.safeToSpendDaily,
    required this.safeToSpendWeekly,
    required this.projected6MonthSavings,
    required this.projected1YearSavings,
  });
}

class InsightsEngine {
  /// Generates a comprehensive financial intelligence report for the selected horizon and period offset.
  /// [periodOffset]: 0 = current period, -1 = 1 period ago, etc.
  static InsightsReport generateReport({
    required List<Transaction> transactions,
    required List<Loan> loans,
    required Map<String, double> budgets,
    List<SavingsGoal> goals = const [],
    required TimeHorizon horizon,
    int periodOffset = 0,
    DateTime? anchorDate,
  }) {
    final now = anchorDate ?? DateTime.now();
    final periodRange = _calculateDateRange(now, horizon, periodOffset);
    final prevPeriodRange = _calculateDateRange(now, horizon, periodOffset - 1);

    final currentTransactions = transactions.where((t) =>
      t.date.isAfter(periodRange.start.subtract(const Duration(milliseconds: 1))) &&
      t.date.isBefore(periodRange.end.add(const Duration(milliseconds: 1)))
    ).toList();

    final prevTransactions = transactions.where((t) =>
      t.date.isAfter(prevPeriodRange.start.subtract(const Duration(milliseconds: 1))) &&
      t.date.isBefore(prevPeriodRange.end.add(const Duration(milliseconds: 1)))
    ).toList();

    // Inflow, Outflow & Velocity
    final totalInflow = currentTransactions.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);
    final totalOutflow = currentTransactions.where((t) => !t.isIncome).fold(0.0, (s, t) => s + t.amount);
    final netSavings = totalInflow - totalOutflow;
    final savingsRate = totalInflow > 0 ? ((netSavings / totalInflow) * 100).clamp(-100.0, 100.0) : 0.0;

    final daysInPeriod = max(1, periodRange.end.difference(periodRange.start).inDays + 1);
    final dailyVelocity = totalOutflow / daysInPeriod;

    final prevOutflow = prevTransactions.where((t) => !t.isIncome).fold(0.0, (s, t) => s + t.amount);
    final spendingChangePercent = prevOutflow > 0
        ? ((totalOutflow - prevOutflow) / prevOutflow) * 100.0
        : 0.0;

    // Category Breakdown with Prorated Budgets
    final categories = _calculateCategoryInsights(
      currentTransactions: currentTransactions,
      budgets: budgets,
      horizon: horizon,
      totalOutflow: totalOutflow,
      daysInPeriod: daysInPeriod,
    );

    // Loans and Liabilities
    final loanInsight = _calculateLoanInsight(loans, totalInflow, totalOutflow);

    // 50/30/20 Rule & Safe to Spend
    final rule503020 = _calculateRule503020(currentTransactions, totalInflow, totalOutflow);
    final safeToSpendDaily = _calculateSafeToSpendDaily(totalInflow, totalOutflow, daysInPeriod, horizon);
    final safeToSpendWeekly = safeToSpendDaily * 7;

    // Wealth Trajectory
    final monthlyRunRate = horizon == TimeHorizon.yearly
        ? netSavings / 12.0
        : (horizon == TimeHorizon.weekly ? netSavings * 4.33 : (horizon == TimeHorizon.daily ? netSavings * 30 : netSavings));
    final projected6MonthSavings = max(0.0, monthlyRunRate * 6);
    final projected1YearSavings = max(0.0, monthlyRunRate * 12);

    // Payment Types
    final paymentTypes = _calculatePaymentTypes(currentTransactions, totalOutflow);

    // Health Score
    final healthScore = _calculateHealthScore(
      savingsRate: savingsRate,
      categories: categories,
      loanInsight: loanInsight,
      spendingChangePercent: spendingChangePercent,
      hasIncome: totalInflow > 0,
    );

    // Goal Momentum & Savings Vault
    final goalInsight = _calculateGoalInsight(goals, currentTransactions, periodRange);

    // Executive Accountant Commentary & Recommendations
    final commentary = _generateAccountantCommentary(
      totalInflow: totalInflow,
      totalOutflow: totalOutflow,
      netSavings: netSavings,
      savingsRate: savingsRate,
      spendingChangePercent: spendingChangePercent,
      categories: categories,
      loanInsight: loanInsight,
      goalInsight: goalInsight,
      healthScore: healthScore,
      horizon: horizon,
    );

    return InsightsReport(
      horizon: horizon,
      startDate: periodRange.start,
      endDate: periodRange.end,
      periodLabel: _formatPeriodLabel(periodRange.start, periodRange.end, horizon, periodOffset),
      totalInflow: totalInflow,
      totalOutflow: totalOutflow,
      netSavings: netSavings,
      savingsRate: savingsRate,
      dailyVelocity: dailyVelocity,
      previousOutflow: prevOutflow,
      spendingChangePercent: spendingChangePercent,
      healthScore: healthScore,
      accountantSummary: commentary.summary,
      accountantKeyActionItems: commentary.actionItems,
      categories: categories,
      rule503020: rule503020,
      loanInsight: loanInsight,
      paymentTypes: paymentTypes,
      goalInsight: goalInsight,
      safeToSpendDaily: safeToSpendDaily,
      safeToSpendWeekly: safeToSpendWeekly,
      projected6MonthSavings: projected6MonthSavings,
      projected1YearSavings: projected1YearSavings,
    );
  }

  static _DateRange _calculateDateRange(DateTime anchor, TimeHorizon horizon, int offset) {
    switch (horizon) {
      case TimeHorizon.daily:
        final targetDate = anchor.add(Duration(days: offset));
        final start = DateTime(targetDate.year, targetDate.month, targetDate.day, 0, 0, 0);
        final end = DateTime(targetDate.year, targetDate.month, targetDate.day, 23, 59, 59, 999);
        return _DateRange(start, end);

      case TimeHorizon.weekly:
        // Week starts Monday (weekday = 1)
        final adjustedAnchor = anchor.add(Duration(days: offset * 7));
        final monday = adjustedAnchor.subtract(Duration(days: adjustedAnchor.weekday - 1));
        final start = DateTime(monday.year, monday.month, monday.day, 0, 0, 0);
        final sunday = monday.add(const Duration(days: 6));
        final end = DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59, 999);
        return _DateRange(start, end);

      case TimeHorizon.monthly:
        var year = anchor.year;
        var month = anchor.month + offset;
        while (month < 1) {
          month += 12;
          year -= 1;
        }
        while (month > 12) {
          month -= 12;
          year += 1;
        }
        final start = DateTime(year, month, 1, 0, 0, 0);
        final lastDay = DateTime(year, month + 1, 0).day;
        final end = DateTime(year, month, lastDay, 23, 59, 59, 999);
        return _DateRange(start, end);

      case TimeHorizon.yearly:
        final targetYear = anchor.year + offset;
        final start = DateTime(targetYear, 1, 1, 0, 0, 0);
        final end = DateTime(targetYear, 12, 31, 23, 59, 59, 999);
        return _DateRange(start, end);
    }
  }

  static String _formatPeriodLabel(DateTime start, DateTime end, TimeHorizon horizon, int offset) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    if (offset == 0) {
      switch (horizon) {
        case TimeHorizon.daily:
          return 'Today (${months[start.month - 1]} ${start.day})';
        case TimeHorizon.weekly:
          return 'This Week (${months[start.month - 1]} ${start.day} – ${months[end.month - 1]} ${end.day})';
        case TimeHorizon.monthly:
          return 'This Month (${months[start.month - 1]} ${start.year})';
        case TimeHorizon.yearly:
          return 'This Year (${start.year})';
      }
    } else if (offset == -1) {
      switch (horizon) {
        case TimeHorizon.daily:
          return 'Yesterday (${months[start.month - 1]} ${start.day})';
        case TimeHorizon.weekly:
          return 'Last Week (${months[start.month - 1]} ${start.day} – ${months[end.month - 1]} ${end.day})';
        case TimeHorizon.monthly:
          return 'Last Month (${months[start.month - 1]} ${start.year})';
        case TimeHorizon.yearly:
          return 'Last Year (${start.year})';
      }
    } else {
      switch (horizon) {
        case TimeHorizon.daily:
          return '${months[start.month - 1]} ${start.day}, ${start.year}';
        case TimeHorizon.weekly:
          return '${months[start.month - 1]} ${start.day} – ${months[end.month - 1]} ${end.day}';
        case TimeHorizon.monthly:
          return '${months[start.month - 1]} ${start.year}';
        case TimeHorizon.yearly:
          return '${start.year}';
      }
    }
  }

  static List<CategoryInsight> _calculateCategoryInsights({
    required List<Transaction> currentTransactions,
    required Map<String, double> budgets,
    required TimeHorizon horizon,
    required double totalOutflow,
    required int daysInPeriod,
  }) {
    final Map<String, double> spending = {};
    for (var t in currentTransactions.where((t) => !t.isIncome)) {
      spending[t.category] = (spending[t.category] ?? 0.0) + t.amount;
    }

    // Prorate factor based on monthly default budgets
    double prorateFactor;
    switch (horizon) {
      case TimeHorizon.daily:
        prorateFactor = 1.0 / 30.0;
        break;
      case TimeHorizon.weekly:
        prorateFactor = 7.0 / 30.0;
        break;
      case TimeHorizon.monthly:
        prorateFactor = 1.0;
        break;
      case TimeHorizon.yearly:
        prorateFactor = 12.0;
        break;
    }

    // Include categories with either spending or an allocated budget
    final allCats = <String>{...spending.keys, ...budgets.keys};
    final List<CategoryInsight> result = [];

    for (var cat in allCats) {
      final spent = spending[cat] ?? 0.0;
      final monthlyBudget = budgets[cat] ?? 0.0;
      final periodBudget = monthlyBudget * prorateFactor;
      final hasBudget = periodBudget > 0;
      final remaining = hasBudget ? periodBudget - spent : 0.0;
      final pctOfTotal = totalOutflow > 0 ? (spent / totalOutflow) * 100.0 : 0.0;
      final pctOfBudget = hasBudget ? (spent / periodBudget) * 100.0 : 0.0;
      final isOverBudget = hasBudget && spent > periodBudget;
      final double? suggestedBudget = !hasBudget && spent > 0
          ? ((spent * 1.25) / 10).ceil() * 10.0
          : null;

      result.add(CategoryInsight(
        category: cat,
        spent: spent,
        budget: periodBudget,
        remaining: remaining,
        percentOfTotal: pctOfTotal,
        percentOfBudget: pctOfBudget,
        isOverBudget: isOverBudget,
        hasBudget: hasBudget,
        suggestedBudget: suggestedBudget,
      ));
    }

    // Sort by highest spending first
    result.sort((a, b) => b.spent.compareTo(a.spent));
    return result;
  }

  static LoanInsight _calculateLoanInsight(List<Loan> loans, double totalInflow, double totalOutflow) {
    double payableTotal = 0.0;
    double receivableTotal = 0.0;
    final List<Loan> upcoming = [];

    final now = DateTime.now();

    for (var loan in loans) {
      if (!loan.isSettled) {
        if (loan.isPayable) {
          payableTotal += loan.amount;
          if (loan.dueDate.isAfter(now.subtract(const Duration(days: 1)))) {
            upcoming.add(loan);
          }
        } else if (loan.isReceivable) {
          receivableTotal += loan.amount;
        }
      }
    }

    upcoming.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    // Approximate monthly debt payment obligation (due in next 60 days or 10% amortized)
    final monthlyDebtPayment = payableTotal > 0 ? min(payableTotal, payableTotal * 0.1) : 0.0;
    final estimatedMonthlyIncome = totalInflow > 0 ? totalInflow : 1.0;
    final dti = totalInflow > 0 ? (monthlyDebtPayment / estimatedMonthlyIncome) * 100.0 : 0.0;

    String dtiStatus = 'Healthy';
    if (dti > 43) {
      dtiStatus = 'Strained';
    } else if (dti >= 36) {
      dtiStatus = 'Moderate';
    }

    String payoffAdvice;
    if (payableTotal == 0) {
      payoffAdvice = 'Zero active debt detected! Allocate your cash flow towards wealth accumulation and high-yield investments.';
    } else if (upcoming.length > 1) {
      payoffAdvice = 'Debt Avalanche Recommended: Target your highest-balance loan while making minimums on others to minimize interest drag and achieve debt freedom faster.';
    } else {
      payoffAdvice = 'Prioritize settling your outstanding payable of \$${payableTotal.toStringAsFixed(0)} to eliminate liabilities and improve borrowing capacity.';
    }

    return LoanInsight(
      totalPayable: payableTotal,
      totalReceivable: receivableTotal,
      netDebt: payableTotal - receivableTotal,
      monthlyDebtPayment: monthlyDebtPayment,
      debtToIncomeRatio: dti.clamp(0.0, 100.0),
      dtiStatus: dtiStatus,
      upcomingDueLoans: upcoming,
      payoffAdvice: payoffAdvice,
    );
  }

  static Rule503020Insight _calculateRule503020(List<Transaction> transactions, double totalInflow, double totalOutflow) {
    const needsCategories = {'Housing & Rent', 'Utilities', 'Healthcare', 'Transportation'};

    double needs = 0.0;
    double wants = 0.0;

    for (var t in transactions.where((t) => !t.isIncome)) {
      if (needsCategories.contains(t.category)) {
        needs += t.amount;
      } else {
        wants += t.amount;
      }
    }

    final netSavings = max(0.0, totalInflow - totalOutflow);
    final denom = totalInflow > 0 ? totalInflow : max(totalOutflow, 1.0);

    final needsPct = (needs / denom) * 100.0;
    final wantsPct = (wants / denom) * 100.0;
    final savingsPct = totalInflow > 0 ? (netSavings / totalInflow) * 100.0 : 0.0;

    String assessment;
    if (needsPct <= 55 && wantsPct <= 35 && savingsPct >= 15) {
      assessment = 'Outstanding balance! Your budget aligns closely with the golden 50/30/20 standard.';
    } else if (needsPct > 55) {
      assessment = 'Fixed needs exceed 50% of income. Look for opportunities to renegotiate utilities or reduce fixed recurring overhead.';
    } else if (wantsPct > 35) {
      assessment = 'Discretionary wants account for over 35% of cash flow. Trimming leisure and non-essential shopping will boost your wealth building.';
    } else {
      assessment = 'Boost savings towards 20% by putting windfalls and leftover cash directly into high-yield reserves.';
    }

    return Rule503020Insight(
      needsSpent: needs,
      wantsSpent: wants,
      savingsAmount: netSavings,
      totalIncome: totalInflow,
      needsPercent: needsPct.clamp(0.0, 100.0),
      wantsPercent: wantsPct.clamp(0.0, 100.0),
      savingsPercent: savingsPct.clamp(0.0, 100.0),
      assessment: assessment,
    );
  }

  static double _calculateSafeToSpendDaily(double totalInflow, double totalOutflow, int daysInPeriod, TimeHorizon horizon) {
    if (totalInflow <= 0) {
      return max(0.0, 50.0); // Baseline placeholder when no income logged
    }
    final remainingNet = totalInflow - totalOutflow;
    if (remainingNet <= 0) return 0.0;
    return remainingNet / max(1, daysInPeriod);
  }

  static List<PaymentTypeInsight> _calculatePaymentTypes(List<Transaction> currentTransactions, double totalOutflow) {
    final Map<String, double> accountSpend = {};
    for (var t in currentTransactions.where((t) => !t.isIncome)) {
      accountSpend[t.account] = (accountSpend[t.account] ?? 0.0) + t.amount;
    }

    final List<PaymentTypeInsight> list = [];
    accountSpend.forEach((acc, amount) {
      final pct = totalOutflow > 0 ? (amount / totalOutflow) * 100.0 : 0.0;
      list.add(PaymentTypeInsight(accountName: acc, amount: amount, percentage: pct));
    });

    list.sort((a, b) => b.amount.compareTo(a.amount));
    return list;
  }

  static FinancialHealthScore _calculateHealthScore({
    required double savingsRate,
    required List<CategoryInsight> categories,
    required LoanInsight loanInsight,
    required double spendingChangePercent,
    required bool hasIncome,
  }) {
    // 100 Points Model:
    // 35 pts: Savings rate
    // 25 pts: Budget discipline
    // 25 pts: Debt load & DTI
    // 15 pts: Spending stability

    double score = 50.0; // Baseline

    if (hasIncome) {
      if (savingsRate >= 25) {
        score += 35;
      } else if (savingsRate >= 15) {
        score += 25;
      } else if (savingsRate >= 5) {
        score += 15;
      } else if (savingsRate < 0) {
        score -= 20;
      }
    }

    // Budget adherence
    final overBudgetCount = categories.where((c) => c.isOverBudget).length;
    if (overBudgetCount == 0 && categories.isNotEmpty) {
      score += 15;
    } else if (overBudgetCount > 2) {
      score -= 15;
    }

    // Debt health
    if (loanInsight.totalPayable == 0) {
      score += 15;
    } else if (loanInsight.dtiStatus == 'Healthy') {
      score += 10;
    } else if (loanInsight.dtiStatus == 'Strained') {
      score -= 15;
    }

    // Spending stability
    if (spendingChangePercent <= 0) {
      score += 10;
    } else if (spendingChangePercent > 30) {
      score -= 10;
    }

    final finalScore = score.round().clamp(15, 100);

    String rating;
    String explanation;
    if (finalScore >= 80) {
      rating = 'Excellent';
      explanation = 'Strong financial discipline with healthy cash flow margins and low debt exposure.';
    } else if (finalScore >= 65) {
      rating = 'Strong';
      explanation = 'Solid money habits. Maintain steady savings and avoid discretionary category creep.';
    } else if (finalScore >= 45) {
      rating = 'Moderate';
      explanation = 'Adequate runway, but high debt or budget overruns are dampening your capital accumulation.';
    } else {
      rating = 'Needs Attention';
      explanation = 'Cash outflow is exceeding safe limits. Immediate spending reduction and debt containment advised.';
    }

    return FinancialHealthScore(
      score: finalScore,
      rating: rating,
      explanation: explanation,
    );
  }

  static GoalInsight _calculateGoalInsight(
    List<SavingsGoal> goals,
    List<Transaction> currentTransactions,
    _DateRange periodRange,
  ) {
    double periodStashed = 0.0;
    for (final goal in goals) {
      for (final entry in goal.entries) {
        if (entry.date.isAfter(periodRange.start.subtract(const Duration(milliseconds: 1))) &&
            entry.date.isBefore(periodRange.end.add(const Duration(milliseconds: 1)))) {
          periodStashed += entry.amount;
        }
      }
    }
    // Also include transactions with category 'Savings Goal' if any weren't captured via entries
    final txSavings = currentTransactions
        .where((t) => t.category == 'Savings Goal' && !t.isIncome)
        .fold(0.0, (s, t) => s + t.amount);
    if (periodStashed == 0.0 && txSavings > 0) {
      periodStashed = txSavings;
    }

    final totalVaultBalance = goals.where((g) => !g.isArchived).fold(0.0, (s, g) => s + g.saved);
    final activeGoals = goals.where((g) => !g.isArchived && !g.isCompleted && !g.isFailed).toList();
    final completedGoalsCount = goals.where((g) => g.isCompleted).length;
    final nearingCompletion = activeGoals.where((g) => g.target > 0 && (g.saved / g.target) >= 0.70).toList();

    String motivationalSummary;
    if (periodStashed > 0) {
      if (nearingCompletion.isNotEmpty) {
        motivationalSummary = 'You locked away \$${periodStashed.toStringAsFixed(0)} this period! ${nearingCompletion.length} goal(s) are over 70% funded and close to completion.';
      } else {
        motivationalSummary = 'You locked away \$${periodStashed.toStringAsFixed(0)} into your Savings Vault this period! Consistent contributions build long-term freedom.';
      }
    } else if (activeGoals.isNotEmpty) {
      motivationalSummary = 'You have ${activeGoals.length} active goal(s) with \$${totalVaultBalance.toStringAsFixed(0)} saved. Stash a small amount today to keep pacing on track.';
    } else {
      motivationalSummary = 'Set a savings goal with a target deadline to automate your wealth-building pacing.';
    }

    return GoalInsight(
      periodStashed: periodStashed,
      totalVaultBalance: totalVaultBalance,
      activeGoalsCount: activeGoals.length,
      completedGoalsCount: completedGoalsCount,
      nearingCompletionGoals: nearingCompletion,
      motivationalSummary: motivationalSummary,
    );
  }

  static _AccountantCommentary _generateAccountantCommentary({
    required double totalInflow,
    required double totalOutflow,
    required double netSavings,
    required double savingsRate,
    required double spendingChangePercent,
    required List<CategoryInsight> categories,
    required LoanInsight loanInsight,
    required GoalInsight goalInsight,
    required FinancialHealthScore healthScore,
    required TimeHorizon horizon,
  }) {
    final topCategory = categories.isNotEmpty && categories.first.spent > 0
        ? categories.first
        : null;

    final overBudgetCats = categories.where((c) => c.isOverBudget).toList();

    String summary;
    final List<String> actionItems = [];

    if (totalInflow == 0 && totalOutflow == 0) {
      summary = 'Welcome to your Executive Wealth Intelligence suite. Record your daily cash flow and loans to unlock custom CPA-level analysis.';
      if (goalInsight.nearingCompletionGoals.isNotEmpty) {
        final goal = goalInsight.nearingCompletionGoals.first;
        final pct = (goal.progress * 100).toStringAsFixed(0);
        actionItems.add('Goal Momentum: "${goal.title}" is within reach at $pct% funded. Allocate extra surplus to complete this target!');
      } else {
        actionItems.add('Log your regular income sources and recurring bills to calibrate your personal burn rate.');
      }
      actionItems.add('Set monthly category budgets to receive automated overrun protection warnings.');
      return _AccountantCommentary(summary, actionItems);
    }

    if (netSavings >= 0) {
      summary = 'Your cash flow is in positive territory with a ${savingsRate.toStringAsFixed(0)}% savings rate. Net surplus for this period is healthy.';
    } else {
      summary = 'Outflow exceeded income by \$${netSavings.abs().toStringAsFixed(0)}. Deficit spending weakens long-term liquidity.';
    }

    if (topCategory != null) {
      summary += ' "${topCategory.category}" was your primary expenditure driver, consuming ${topCategory.percentOfTotal.toStringAsFixed(0)}% of total outflows.';
      if (topCategory.percentOfTotal > 35) {
        actionItems.add('Cap discretionary outlays in ${topCategory.category} by setting an automated envelope limit.');
      }
    }

    if (overBudgetCats.isNotEmpty) {
      final names = overBudgetCats.take(2).map((c) => c.category).join(', ');
      actionItems.add('Budget Alert: Overruns detected in $names. Restrict non-essential expenses in these areas for the next 7 days.');
    }

    // Goal momentum advice
    if (goalInsight.nearingCompletionGoals.isNotEmpty) {
      final goal = goalInsight.nearingCompletionGoals.first;
      final pct = (goal.progress * 100).toStringAsFixed(0);
      actionItems.add('Goal Momentum: "${goal.title}" is within reach at $pct% funded. Allocate extra surplus to complete this target!');
    } else if (goalInsight.periodStashed > 0) {
      actionItems.add('Savings Vault: Stashed \$${goalInsight.periodStashed.toStringAsFixed(0)} this period. Keep your scheduled pacing cadence active.');
    }

    if (loanInsight.totalPayable > 0) {
      actionItems.add('Liabilities: Allocate \$${min(loanInsight.totalPayable, 150.0).toStringAsFixed(0)} towards your highest-priority loan to accelerate your debt-free milestone.');
    } else {
      actionItems.add('Wealth Accelerator: Direct at least 15% of your surplus into emergency reserves or diversified index investments.');
    }

    if (spendingChangePercent > 20) {
      actionItems.add('Velocity Warning: Outflow accelerated by ${spendingChangePercent.toStringAsFixed(0)}% compared to the prior period. Audit recent transactions for impulse purchases.');
    }

    return _AccountantCommentary(summary, actionItems);
  }
}

class _DateRange {
  final DateTime start;
  final DateTime end;
  _DateRange(this.start, this.end);
}

class _AccountantCommentary {
  final String summary;
  final List<String> actionItems;
  _AccountantCommentary(this.summary, this.actionItems);
}
