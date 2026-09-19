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
  String _selectedAccount = 'Main';

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
                          title: Text(accounts[i], style: const TextStyle(color: Colors.white)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () {
                              if (accounts.length > 1) {
                                final removedAcc = accounts.removeAt(i);
                                AppState.accountsNotifier.value = List.from(accounts);
                                if (AppState.currentUser != null) AppState.saveAccounts(AppState.currentUser!, accounts);
                                if (_selectedAccount == removedAcc) {
                                  setState(() => _selectedAccount = accounts[0]);
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
                              style: const TextStyle(color: Colors.white),
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
              if (!accounts.contains(_selectedAccount) && accounts.isNotEmpty) {
                _selectedAccount = accounts.first;
              }
              
              final Map<String, double> balances = {};
              final Map<String, double> spentMap = {};
              
              for (var acc in accounts) {
                final accTxs = transactions.where((t) => t.account == acc).toList();
                final income = accTxs.where((t) => t.isIncome).fold(0.0, (sum, t) => sum + t.amount);
                final expense = accTxs.where((t) => !t.isIncome).fold(0.0, (sum, t) => sum + t.amount);
                balances[acc] = income - expense;
                spentMap[acc] = expense;
              }

              final filteredTxs = transactions.where((t) => t.account == _selectedAccount).toList();

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
                          final acc = accounts[index];
                          final isSelected = _selectedAccount == acc;
                          final bal = balances[acc] ?? 0.0;
                          final sp = spentMap[acc] ?? 0.0;
                          
                          return GestureDetector(
                            onTap: () => setState(() => _selectedAccount = acc),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2) : Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: isSelected ? Theme.of(context).colorScheme.primary : Colors.white.withValues(alpha: 0.05)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(acc, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('${AppState.currencyNotifier.value}${bal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                      const SizedBox(height: 2),
                                      Text('Spent: ${AppState.currencyNotifier.value}${sp.toStringAsFixed(0)}', style: const TextStyle(fontSize: 10, color: Colors.white54)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        childCount: accounts.length,
                      ),
                    ),
                  ),
                  
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: InteractiveChartCard(
                        transactions: transactions,
                        accountFilter: _selectedAccount,
                        title: 'Analytics: $_selectedAccount',
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Text('Transactions: $_selectedAccount', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                  
                  if (filteredTxs.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: Text("No transactions for this account", style: TextStyle(color: Colors.white54))),
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
