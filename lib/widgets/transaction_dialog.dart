import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/state.dart';
import '../utils/constants.dart';
import 'delete_confirmation_dialog.dart';

Future<void> showTransactionDialog(BuildContext context, {Transaction? existingTx}) async {
  await showDialog(
    context: context,
    builder: (ctx) => _TransactionDialog(existingTx: existingTx),
  );
}

class _TransactionDialog extends StatefulWidget {
  final Transaction? existingTx;
  const _TransactionDialog({this.existingTx});

  @override
  State<_TransactionDialog> createState() => _TransactionDialogState();
}

class _TransactionDialogState extends State<_TransactionDialog> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _amountCtrl;
  late bool _isIncome;
  late String _category;
  late DateTime _selectedDate;
  late List<String> _accountsList;
  late String _account;
  late String _recurrence;

  @override
  void initState() {
    super.initState();
    final tx = widget.existingTx;
    _titleCtrl = TextEditingController(text: tx?.title ?? '');
    _amountCtrl = TextEditingController(text: tx != null ? tx.amount.toString() : '');
    _isIncome = tx?.isIncome ?? false;
    _category = tx?.category ?? (_isIncome ? 'Salary' : 'Food & Dining');
    _selectedDate = tx?.date ?? DateTime.now();

    _accountsList = AppState.accountsNotifier.value.isNotEmpty
        ? AppState.accountsNotifier.value
        : ['Main'];
    _account = tx?.account ?? _accountsList.first;
    if (!_accountsList.contains(_account)) {
      _account = _accountsList.first;
    }
    _recurrence = tx?.recurrence ?? 'None';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      title: Text(
        widget.existingTx == null ? 'New Transaction' : 'Edit Transaction',
        style: TextStyle(fontWeight: FontWeight.bold, color: onSurface),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleCtrl,
              style: TextStyle(color: onSurface),
              decoration: InputDecoration(
                labelText: 'Title',
                hintText: 'Default: $_category',
                hintStyle: TextStyle(color: onSurface.withValues(alpha: 0.4), fontSize: 13),
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
              controller: _amountCtrl,
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
            // Transaction Date Picker Field
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                  builder: (pickerCtx, child) {
                    return Theme(
                      data: theme.copyWith(
                        colorScheme: theme.colorScheme.copyWith(
                          primary: primary,
                          surface: surface,
                          onSurface: onSurface,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  setState(() {
                    _selectedDate = DateTime(
                      picked.year,
                      picked.month,
                      picked.day,
                      _selectedDate.hour,
                      _selectedDate.minute,
                    );
                  });
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: onSurface.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 18, color: primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Transaction Date', style: TextStyle(fontSize: 11, color: onSurface.withValues(alpha: 0.6))),
                          const SizedBox(height: 2),
                          Text(
                            formatDateWithYear(_selectedDate),
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: onSurface),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.edit_calendar_rounded, size: 18, color: onSurface.withValues(alpha: 0.5)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _category,
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
                if (val != null) setState(() => _category = val);
              },
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _account,
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
              items: _accountsList.map((String acc) {
                return DropdownMenuItem<String>(
                  value: acc,
                  child: Text(acc, style: TextStyle(color: onSurface)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _account = val);
              },
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _recurrence,
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
                if (val != null) setState(() => _recurrence = val);
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _isIncome = false;
                      if (_category == 'Salary') {
                        _category = 'Food & Dining';
                      }
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: !_isIncome ? Colors.redAccent.withValues(alpha: 0.2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: !_isIncome ? Colors.redAccent : onSurface.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text('Expense', style: TextStyle(color: !_isIncome ? Colors.redAccent : onSurface.withValues(alpha: 0.7))),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _isIncome = true;
                      _category = 'Salary';
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _isIncome ? Colors.greenAccent.withValues(alpha: 0.2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isIncome ? Colors.greenAccent : onSurface.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text('Income', style: TextStyle(color: _isIncome ? Colors.greenAccent : onSurface.withValues(alpha: 0.7))),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
      actions: [
        if (widget.existingTx != null)
          TextButton.icon(
            icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
            label: const Text('Delete', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            onPressed: () async {
              final tx = widget.existingTx!;
              final confirmed = await showDeleteConfirmationDialog(
                context: context,
                title: 'Delete Transaction?',
                message: 'Are you sure you want to delete this transaction?',
                itemDetail: '${tx.title} • ${tx.isIncome ? '+' : '-'}${AppState.currencyNotifier.value}${tx.amount.toStringAsFixed(0)}',
              );
              if (confirmed && context.mounted) {
                Navigator.of(context).pop();
                AppState.deleteTransactionWithUndo(context, tx);
              }
            },
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: TextStyle(color: onSurface.withValues(alpha: 0.6))),
        ),
        ElevatedButton(
          onPressed: () {
            final enteredTitle = _titleCtrl.text.trim();
            // If user leaves title empty, save category name as the title
            final effectiveTitle = enteredTitle.isNotEmpty ? enteredTitle : _category;
            final amount = double.tryParse(_amountCtrl.text.trim());
            if (amount != null && amount > 0) {
              final newTx = Transaction(
                id: widget.existingTx?.id,
                title: effectiveTitle,
                amount: amount,
                date: _selectedDate,
                isIncome: _isIncome,
                category: _category,
                account: _account,
                recurrence: _recurrence,
              );

              final currentList = List<Transaction>.from(AppState.transactionsNotifier.value);
              if (widget.existingTx != null) {
                final index = currentList.indexWhere((t) => t.id == widget.existingTx!.id);
                if (index != -1) currentList[index] = newTx;
              } else {
                currentList.insert(0, newTx);
              }

              // Keep list strictly ordered by transaction date descending
              currentList.sort((a, b) => b.date.compareTo(a.date));

              AppState.transactionsNotifier.value = currentList;
              if (AppState.currentUser != null) {
                AppState.saveTransactions(AppState.currentUser!, currentList);
              }
              Navigator.of(context).pop();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: theme.colorScheme.onPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(widget.existingTx == null ? 'Add' : 'Save', style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
