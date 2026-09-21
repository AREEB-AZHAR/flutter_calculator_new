import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/state.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/transaction_dialog.dart';
import '../widgets/interactive_chart_card.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  String _selectedAccount = 'Overall';

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final accounts = List<String>.from(AppState.accountsNotifier.value);
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              title: const Text('Manage Accounts'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: accounts.length,
                        itemBuilder: (c, i) => ListTile(
                          title: Text(accounts[i], style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () {
                              if (accounts.length > 1) {
                                final removedAcc = accounts.removeAt(i);
                                AppState.accountsNotifier.value = List.from(accounts);
                                if (AppState.currentUser != null) AppState.saveAccounts(AppState.currentUser!, accounts);
                                if (_selectedAccount == removedAcc) {
                                  setState(() => _selectedAccount = 'Overall');
                                }
                                setDialogState(() {});
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add Account'),
                      onPressed: () {
                        String newAcc = '';
                        showDialog(
                          context: context,
                          builder: (innerCtx) => AlertDialog(
                            backgroundColor: Theme.of(context).colorScheme.surface,
                            title: const Text('New Account'),
                            content: TextField(
                              autofocus: true,
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                              onChanged: (v) => newAcc = v,
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(innerCtx), child: const Text('Cancel')),
                              TextButton(
                                onPressed: () {
                                  if (newAcc.isNotEmpty && !accounts.contains(newAcc)) {
                                    accounts.add(newAcc);
                                    AppState.accountsNotifier.value = List.from(accounts);
                                    if (AppState.currentUser != null) AppState.saveAccounts(AppState.currentUser!, accounts);
                                    Navigator.pop(innerCtx);
                                    setDialogState(() {});
                                  }
                                },
                                child: const Text('Add'),
                              )
                            ],
                          )
                        );
                      },
                    )
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done'))
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts & Wallets', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsDialog,
          )
        ],
      ),
      body: ValueListenableBuilder<List<String>>(
        valueListenable: AppState.accountsNotifier,
        builder: (context, accounts, _) {
          return ValueListenableBuilder<List<Transaction>>(
            valueListenable: AppState.transactionsNotifier,
            builder: (context, transactions, _) {
              final allDisplayAccounts = ['Overall', ...accounts];
              if (!allDisplayAccounts.contains(_selectedAccount)) {
                _selectedAccount = 'Overall';
              }
              
              final Map<String, double> balances = {};
              final Map<String, double> spentMap = {};

              double overallIncome = 0;
              double overallExpense = 0;
              for (var t in transactions) {
                if (t.isIncome) {
                  overallIncome += t.amount;
                } else {
                  overallExpense += t.amount;
                }
              }
              balances['Overall'] = overallIncome - overallExpense;
              spentMap['Overall'] = overallExpense;
              
              for (var acc in accounts) {
                final accTxs = transactions.where((t) => t.account == acc).toList();
                final income = accTxs.where((t) => t.isIncome).fold(0.0, (sum, t) => sum + t.amount);
                final expense = accTxs.where((t) => !t.isIncome).fold(0.0, (sum, t) => sum + t.amount);
                balances[acc] = income - expense;
                spentMap[acc] = expense;
              }

              final filteredTxs = _selectedAccount == 'Overall'
                  ? transactions
                  : transactions.where((t) => t.account == _selectedAccount).toList();

              return CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(16.0),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.5,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (ctx, index) {
                          final acc = allDisplayAccounts[index];
                          final isSelected = _selectedAccount == acc;
                          final isOverall = acc == 'Overall';
                          final bal = balances[acc] ?? 0.0;
                          final sp = spentMap[acc] ?? 0.0;
                          final primaryColor = Theme.of(context).colorScheme.primary;
                          
                          return GestureDetector(
                            onTap: () => setState(() => _selectedAccount = acc),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? primaryColor.withValues(alpha: 0.2) 
                                    : Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected 
                                      ? primaryColor 
                                      : (isOverall ? Colors.blueAccent.withValues(alpha: 0.3) : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08)),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          isOverall ? '🌐 All Accounts' : acc,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected ? Theme.of(context).colorScheme.onSurface : (isOverall ? Colors.blueAccent : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (isOverall)
                                        const Icon(Icons.auto_graph, size: 14, color: Colors.blueAccent),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${AppState.currencyNotifier.value}${bal.toStringAsFixed(0)}',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Spent: ${AppState.currencyNotifier.value}${sp.toStringAsFixed(0)}',
                                        style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        childCount: allDisplayAccounts.length,
                      ),
                    ),
                  ),
                  
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: InteractiveChartCard(
                        transactions: transactions,
                        accountFilter: _selectedAccount == 'Overall' ? null : _selectedAccount,
                        title: _selectedAccount == 'Overall' ? 'Overall Analytics (All Wallets)' : 'Analytics: $_selectedAccount',
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Text(
                        _selectedAccount == 'Overall' ? 'All Transactions (Overall)' : 'Transactions: $_selectedAccount',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                      ),
                    ),
                  ),
                  
                  if (filteredTxs.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: Text("No transactions for this account", style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)))),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, index) {
                            final tx = filteredTxs[index];
                            return TransactionTile(
                              tx: tx,
                              onTap: () => showTransactionDialog(context, existingTx: tx),
                              onDelete: () {
                                final currentList = List<Transaction>.from(AppState.transactionsNotifier.value);
                                currentList.removeWhere((t) => t.id == tx.id);
                                AppState.transactionsNotifier.value = currentList;
                                if (AppState.currentUser != null) {
                                  AppState.saveTransactions(AppState.currentUser!, currentList);
                                }
                              },
                            );
                          },
                          childCount: filteredTxs.length,
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        }
      ),
    );
  }
}
