import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/state.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/transaction_dialog.dart';
import '../widgets/custom_painters.dart';


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
      body: ValueListenableBuilder<List<Transaction>>(
        valueListenable: AppState.transactionsNotifier,
        builder: (context, transactions, child) {
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
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
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
                              decoration: const BoxDecoration(
                                color: Colors.greenAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Total Income',
                              style: TextStyle(
                                color: Colors.white,
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
                              decoration: const BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Total Expense',
                              style: TextStyle(
                                color: Colors.white,
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
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search transactions...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
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
                            color: isSelected ? Colors.white : Colors.white70,
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
              const SizedBox(height: 10),

              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Text(
                          "No transactions found",
                          style: TextStyle(color: Colors.white54),
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
                            onDelete: () {
                              final currentList = List<Transaction>.from(
                                AppState.transactionsNotifier.value,
                              );
                              currentList.removeWhere((t) => t.id == tx.id);
                              AppState.transactionsNotifier.value = currentList;
                              if (AppState.currentUser != null) {
                                AppState.saveTransactions(
                                  AppState.currentUser!,
                                  currentList,
                                );
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${tx.title} deleted'),
                                  action: SnackBarAction(
                                    label: 'Undo',
                                    onPressed: () {
                                      final restoredList =
                                          List<Transaction>.from(
                                            AppState.transactionsNotifier.value,
                                          );
                                      restoredList.add(tx);
                                      restoredList.sort(
                                        (a, b) => b.date.compareTo(a.date),
                                      );
                                      AppState.transactionsNotifier.value =
                                          restoredList;
                                      if (AppState.currentUser != null) {
                                        AppState.saveTransactions(
                                          AppState.currentUser!,
                                          restoredList,
                                        );
                                      }
                                    },
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ----------------------------------------------------
// Insights Screen (Tier 2)
// ----------------------------------------------------
