import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/state.dart';
import '../utils/constants.dart';

Future<void> showTransactionDialog(BuildContext context, {Transaction? existingTx}) async {
  final titleCtrl = TextEditingController(text: existingTx?.title ?? '');
  final amountCtrl = TextEditingController(text: existingTx?.amount.toString() ?? '');
  bool isIncome = existingTx?.isIncome ?? false;
  String category = existingTx?.category ?? (isIncome ? 'Salary' : 'Food & Dining');
  List<String> accountsList = AppState.accountsNotifier.value.isNotEmpty ? AppState.accountsNotifier.value : ['Main'];
  String account = existingTx?.account ?? accountsList.first;
  if (!accountsList.contains(account)) {
    account = accountsList.first;
  }
  String recurrence = existingTx?.recurrence ?? 'None';

  try {
    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
              ),
              title: Text(existingTx == null ? 'New Transaction' : 'Edit Transaction', style: const TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Title',
                        labelStyle: const TextStyle(color: Colors.white54),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: amountCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Amount (${AppState.currencyNotifier.value})',
                        labelStyle: const TextStyle(color: Colors.white54),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    dropdownColor: Theme.of(context).colorScheme.surface,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Category',
                      labelStyle: const TextStyle(color: Colors.white54),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    items: categoryIcons.keys.map((String cat) {
                      return DropdownMenuItem<String>(
                        value: cat,
                        child: Row(
                          children: [
                            Icon(categoryIcons[cat], size: 16, color: Colors.white70),
                            const SizedBox(width: 8),
                            Text(cat),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => category = val);
                    },
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    initialValue: account,
                    dropdownColor: Theme.of(context).colorScheme.surface,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Account',
                      labelStyle: const TextStyle(color: Colors.white54),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    items: accountsList.map((String acc) {
                      return DropdownMenuItem<String>(value: acc, child: Text(acc));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => account = val);
                    },
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    initialValue: recurrence,
                    dropdownColor: Theme.of(context).colorScheme.surface,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Recurrence',
                      labelStyle: const TextStyle(color: Colors.white54),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    items: ['None', 'Daily', 'Weekly', 'Monthly'].map((String rec) {
                      return DropdownMenuItem<String>(value: rec, child: Text(rec));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => recurrence = val);
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setDialogState(() => isIncome = false),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: !isIncome ? Colors.redAccent.withValues(alpha: 0.2) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: !isIncome ? Colors.redAccent : Colors.white24,
                              ),
                            ),
                            child: Text('Expense', style: TextStyle(color: !isIncome ? Colors.redAccent : Colors.white70)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setDialogState(() => isIncome = true),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isIncome ? Colors.greenAccent.withValues(alpha: 0.2) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isIncome ? Colors.greenAccent : Colors.white24,
                              ),
                            ),
                            child: Text('Income', style: TextStyle(color: isIncome ? Colors.greenAccent : Colors.white70)),
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                onPressed: () {
                  final title = titleCtrl.text.trim();
                  final amount = double.tryParse(amountCtrl.text.trim());
                  if (title.isNotEmpty && amount != null && amount > 0) {
                    final newTx = Transaction(
                      id: existingTx?.id,
                      title: title,
                      amount: amount,
                      date: existingTx?.date ?? DateTime.now(),
                      isIncome: isIncome,
                      category: category,
                      account: account,
                      recurrence: recurrence,
                    );
                    
                    final currentList = List<Transaction>.from(AppState.transactionsNotifier.value);
                    if (existingTx != null) {
                      final index = currentList.indexWhere((t) => t.id == existingTx.id);
                      if (index != -1) currentList[index] = newTx;
                    } else {
                      currentList.insert(0, newTx);
                    }
                    
                    AppState.transactionsNotifier.value = currentList;
                    if (AppState.currentUser != null) {
                      AppState.saveTransactions(AppState.currentUser!, currentList);
                    }
                    Navigator.of(ctx).pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(existingTx == null ? 'Add' : 'Save', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      );
    },
  );
  } finally {
    titleCtrl.dispose();
    amountCtrl.dispose();
  }
}
