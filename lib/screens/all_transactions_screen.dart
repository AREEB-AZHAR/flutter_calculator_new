import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/planned_transaction.dart';
import '../services/state.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/transaction_dialog.dart';
import '../widgets/interactive_chart_card.dart';
import '../widgets/ad_banner_widget.dart';
import '../widgets/planned_transactions_sheet.dart';

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
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final isLight = theme.brightness == Brightness.light;
    final planAccent = isLight ? const Color(0xFFD97706) : const Color(0xFFFBBF24);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'All Transactions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.event_note_rounded, color: planAccent),
            tooltip: 'Planned & Future Sheet',
            onPressed: () => showPlannedTransactionsSheet(context),
          ),
        ],
      ),
      body: ValueListenableBuilder<String>(
        valueListenable: AppState.currencyNotifier,
        builder: (context, currentCurrency, _) {
          return ValueListenableBuilder<List<Transaction>>(
            valueListenable: AppState.transactionsNotifier,
            builder: (context, transactions, child) {
              final filtered = transactions.where((t) {
                bool matchesFilter = true;
                if (_filter == 'Income') matchesFilter = t.isIncome;
                if (_filter == 'Expense') matchesFilter = !t.isIncome;

                bool matchesSearch = _searchQuery.isEmpty ||
                    t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    t.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    t.account.toLowerCase().contains(_searchQuery.toLowerCase());

                return matchesFilter && matchesSearch;
              }).toList();

              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                cacheExtent: 500,
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search Bar
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                          child: TextField(
                            style: TextStyle(color: onSurface),
                            decoration: InputDecoration(
                              hintText: 'Search transactions by title or category...',
                              hintStyle: TextStyle(
                                color: onSurface.withValues(alpha: 0.54),
                                fontSize: 14,
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: onSurface.withValues(alpha: 0.54),
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () => setState(() => _searchQuery = ''),
                                    )
                                  : null,
                              filled: true,
                              fillColor: theme.colorScheme.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: onSurface.withValues(alpha: 0.12),
                                ),
                              ),
                            ),
                            onChanged: (val) => setState(() => _searchQuery = val),
                          ),
                        ),

                        // Filter Chips (All, Income, Expense, Planned Future)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              ...['All', 'Income', 'Expense'].map((type) {
                                final isSelected = _filter == type;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: Text(
                                      type,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: isSelected
                                            ? theme.colorScheme.onPrimary
                                            : onSurface.withValues(alpha: 0.75),
                                      ),
                                    ),
                                    selected: isSelected,
                                    selectedColor: theme.colorScheme.primary,
                                    backgroundColor: theme.colorScheme.surface,
                                    onSelected: (val) {
                                      setState(() {
                                        _filter = type;
                                      });
                                    },
                                  ),
                                );
                              }),
                              ValueListenableBuilder<List<PlannedTransaction>>(
                                valueListenable: AppState.plannedTransactionsNotifier,
                                builder: (context, plans, _) {
                                  return ActionChip(
                                    avatar: Icon(Icons.event_note_rounded, size: 16, color: planAccent),
                                    label: Text(
                                      'Planned Sheet (${plans.length})',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: planAccent),
                                    ),
                                    backgroundColor: planAccent.withValues(alpha: 0.12),
                                    side: BorderSide(color: planAccent.withValues(alpha: 0.3)),
                                    onPressed: () => showPlannedTransactionsSheet(context),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Dynamic Interactive Analytics Chart (Updates with search & filters)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: RepaintBoundary(
                            child: InteractiveChartCard(
                              transactions: filtered,
                              title: _searchQuery.isNotEmpty
                                  ? 'Analytics: "$_searchQuery"'
                                  : (_filter != 'All' ? '$_filter Analytics' : 'Transaction Analytics'),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Ad Banner
                        const RepaintBoundary(
                          child: AdBannerWidget(
                            margin: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                            sponsorCategory: 'Smart Expense Categorization Engine',
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Section Title with Count
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Transactions (${filtered.length})',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: onSurface,
                                ),
                              ),
                              if (_searchQuery.isNotEmpty || _filter != 'All')
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _searchQuery = '';
                                      _filter = 'All';
                                    });
                                  },
                                  child: Text(
                                    'Clear Filters',
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),
                      ],
                    ),
                  ),

                  // Virtualized Transaction List Items or Empty State
                  if (filtered.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 48,
                                color: onSurface.withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'No transactions matching "$_searchQuery"'
                                    : 'No transactions found',
                                style: TextStyle(
                                  color: onSurface.withValues(alpha: 0.6),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, index) {
                            final tx = filtered[index];
                            return RepaintBoundary(
                              key: ValueKey('tx_tile_${tx.id}'),
                              child: TransactionTile(
                                tx: tx,
                                onTap: () => showTransactionDialog(context, existingTx: tx),
                                onDelete: () => AppState.deleteTransactionWithUndo(context, tx),
                              ),
                            );
                          },
                          childCount: filtered.length,
                        ),
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
