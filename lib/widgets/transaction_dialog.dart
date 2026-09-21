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
            final theme = Theme.of(context);
            final onSurface = theme.colorScheme.onSurface;
            final surface = theme.colorScheme.surface;
            final primary = theme.colorScheme.primary;

            return AlertDialog(
              backgroundColor: surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: onSurface.withValues(alpha: 0.12), width: 1),
              ),
              title: Text(existingTx == null ? 'New Transaction' : 'Edit Transaction', style: TextStyle(fontWeight: FontWeight.bold, color: onSurface)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      style: TextStyle(color: onSurface),
                      decoration: InputDecoration(
                        labelText: 'Title',
                        labelStyle: TextStyle(color: onSurface.withValues(alpha: 0.6)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: onSurface.withValues(alpha: 0.15)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: primary, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: amountCtrl,
                      style: TextStyle(color: onSurface),
                      decoration: InputDecoration(
                        labelText: 'Amount (${AppState.currencyNotifier.value})',
                        labelStyle: TextStyle(color: onSurface.withValues(alpha: 0.6)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: onSurface.withValues(alpha: 0.15)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: primary, width: 2),
                        ),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      dropdownColor: surface,
                      style: TextStyle(color: onSurface),
                      decoration: InputDecoration(
                        labelText: 'Category',
                        labelStyle: TextStyle(color: onSurface.withValues(alpha: 0.6)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: onSurface.withValues(alpha: 0.15)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: primary, width: 2),
                        ),
                      ),
                      items: categoryIcons.keys.map((String cat) {
                        return DropdownMenuItem<String>(
                          value: cat,
                          child: Row(
                            children: [
                              Icon(categoryIcons[cat], size: 16, color: primary),
                              const SizedBox(width: 8),
                              Text(cat, style: TextStyle(color: onSurface)),
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
                      dropdownColor: surface,
                      style: TextStyle(color: onSurface),
                      decoration: InputDecoration(
                        labelText: 'Account',
                        labelStyle: TextStyle(color: onSurface.withValues(alpha: 0.6)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: onSurface.withValues(alpha: 0.15)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: primary, width: 2),
                        ),
                      ),
                      items: accountsList.map((String acc) {
                        return DropdownMenuItem<String>(
                          value: acc,
                          child: Text(acc, style: TextStyle(color: onSurface)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => account = val);
                      },
                    ),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      initialValue: recurrence,
                      dropdownColor: surface,
                      style: TextStyle(color: onSurface),
                      decoration: InputDecoration(
                        labelText: 'Recurrence',
                        labelStyle: TextStyle(color: onSurface.withValues(alpha: 0.6)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: onSurface.withValues(alpha: 0.15)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: primary, width: 2),
                        ),
                      ),
                      items: ['None', 'Daily', 'Weekly', 'Monthly'].map((String rec) {
                        return DropdownMenuItem<String>(
                          value: rec,
                          child: Text(rec, style: TextStyle(color: onSurface)),
                        );
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
                                  color: !isIncome ? Colors.redAccent : onSurface.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Text('Expense', style: TextStyle(color: !isIncome ? Colors.redAccent : onSurface.withValues(alpha: 0.7))),
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
                                  color: isIncome ? Colors.greenAccent : onSurface.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Text('Income', style: TextStyle(color: isIncome ? Colors.greenAccent : onSurface.withValues(alpha: 0.7))),
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
                  child: Text('Cancel', style: TextStyle(color: onSurface.withValues(alpha: 0.6))),
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
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(existingTx == null ? 'Add' : 'Save', style: const TextStyle(fontWeight: FontWeight.bold)),
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
