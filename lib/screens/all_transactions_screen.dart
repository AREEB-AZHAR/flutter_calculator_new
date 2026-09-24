import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/state.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/transaction_dialog.dart';
import '../widgets/custom_painters.dart';
import '../widgets/ad_banner_widget.dart';

class AllTransactionsScreen extends StatefulWidget {
  const AllTransactionsScreen({super.key});

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  String _filter = 'All';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'All Transactions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: ValueListenableBuilder<String>(
        valueListenable: AppState.currencyNotifier,
        builder: (context, currentCurrency, _) {
          return ValueListenableBuilder<List<Transaction>>(
            valueListenable: AppState.transactionsNotifier,
            builder: (context, transactions, child) {
          final theme = Theme.of(context);
          final onSurface = theme.colorScheme.onSurface;
          final isLight = theme.brightness == Brightness.light;
          final incomeColor = isLight
              ? const Color(0xFF0F766E)
              : const Color(0xFF10B981);
          final expenseColor = theme.colorScheme.primary;

          final double totalIncome = transactions
              .where((t) => t.isIncome)
              .fold(0, (sum, t) => sum + t.amount);
          final double totalExpense = transactions
              .where((t) => !t.isIncome)
              .fold(0, (sum, t) => sum + t.amount);

          final filtered = transactions.where((t) {
            bool matchesFilter = true;
            if (_filter == 'Income') matchesFilter = t.isIncome;
            if (_filter == 'Expense') matchesFilter = !t.isIncome;

            bool matchesSearch =
                t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                t.category.toLowerCase().contains(_searchQuery.toLowerCase());

            return matchesFilter && matchesSearch;
          }).toList();

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 30,
                  horizontal: 20,
                ),
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: onSurface.withValues(alpha: 0.08)),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: 180,
                      height: 180,
                      child: RepaintBoundary(
                        child: CustomPaint(
                          painter: PieChartPainter(
                            totalIncome,
                            totalExpense,
                            currencySymbol: AppState.currencyNotifier.value,
                            incomeColor: incomeColor,
                            expenseColor: expenseColor,
                            emptyColor: onSurface.withValues(alpha: 0.12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: incomeColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Total Income',
                              style: TextStyle(
                                color: onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 32),
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: expenseColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Total Expense',
                              style: TextStyle(
                                color: onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search transactions...',
                    hintStyle: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.54),
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.54),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.12),
                      ),
                    ),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              const SizedBox(height: 15),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: ['All', 'Income', 'Expense'].map((type) {
                    final isSelected = _filter == type;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ChoiceChip(
                        label: Text(
                          type,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: Theme.of(context).colorScheme.primary,
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        onSelected: (val) {
                          setState(() {
                            _filter = type;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 6),
              const AdBannerWidget(
                margin: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                sponsorCategory: 'Smart Expense Categorization Engine',
              ),
              const SizedBox(height: 4),

              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          "No transactions found",
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, index) {
                          final tx = filtered[index];
                          return TransactionTile(
                            tx: tx,
                            onTap: () =>
                                showTransactionDialog(context, existingTx: tx),
                            onDelete: () => AppState.deleteTransactionWithUndo(context, tx),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      );
    },
  ),
    );
  }
}

// ----------------------------------------------------
// Insights Screen (Tier 2)
// ----------------------------------------------------
