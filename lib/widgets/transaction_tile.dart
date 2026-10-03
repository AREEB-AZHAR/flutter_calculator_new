import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/state.dart';
import '../services/language_service.dart';
import '../utils/constants.dart';
import 'delete_confirmation_dialog.dart';

class TransactionTile extends StatelessWidget {
  final Transaction tx;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final Future<bool> Function()? confirmDelete;

  const TransactionTile({
    super.key,
    required this.tx,
    required this.onTap,
    required this.onDelete,
    this.confirmDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final color = tx.isIncome ? const Color(0xFF10B981) : onSurface;

    return Dismissible(
      key: Key(tx.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        color: Colors.redAccent,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (confirmDelete != null) {
          return await confirmDelete!();
        }
        return await showDeleteConfirmationDialog(
          context: context,
          title: LanguageService.tr('delete_tx_title'),
          message: LanguageService.tr('delete_tx_msg'),
          itemDetail: '${LanguageService.trCategory(tx.title)} • ${tx.isIncome ? '+' : '-'}${AppState.currencyNotifier.value}${tx.amount.toStringAsFixed(0)}',
        );
      },
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: onSurface.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(categoryIcons[tx.category] ?? Icons.category, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(LanguageService.trDynamic(tx.title), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: onSurface)),
                    const SizedBox(height: 4),
                    Text('${formatDate(tx.date)} • ${tx.account}', style: TextStyle(fontSize: 12, color: onSurface.withValues(alpha: 0.6))),
                  ],
                ),
              ),
              ValueListenableBuilder<String>(
                valueListenable: AppState.currencyNotifier,
                builder: (context, cur, _) {
                  return Text(
                    '${tx.isIncome ? '+' : '-'}$cur${tx.amount.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
