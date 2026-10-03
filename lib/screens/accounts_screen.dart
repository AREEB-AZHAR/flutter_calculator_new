import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/loan.dart';
import '../services/state.dart';
import '../services/language_service.dart';
import '../services/tour_service.dart';
import '../services/notification_service.dart';
import '../widgets/feature_tour_dialog.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/transaction_dialog.dart';
import '../widgets/interactive_chart_card.dart';
import '../widgets/ad_banner_widget.dart';
import '../widgets/delete_confirmation_dialog.dart';
import '../utils/constants.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  String _activeSegment = 'wallets'; // 'wallets' or 'loans'
  String _selectedAccount = 'Overall';
  String _loanFilter = 'all'; // 'all', 'receivable', 'payable', 'settled'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAccountsTour();
    });
  }

  Future<void> _checkAccountsTour() async {
    if (!mounted) return;
    final tourDone = await TourService.isTourCompleted(TourService.tourAccounts);
    if (!tourDone && mounted) {
      await showAccountsTour(context);
    }
  }

  void _showAddAccountDialog([VoidCallback? onAdded]) {
    final textCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (innerCtx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.add_card_rounded, color: Colors.blueAccent),
            const SizedBox(width: 8),
            Text(LanguageService.tr('new_account_title'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LanguageService.tr('account_name_hint'),
              style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: textCtrl,
              autofocus: true,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: LanguageService.tr('account_name_label'),
                hintText: LanguageService.tr('account_name_hint'),
                hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 13),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(innerCtx),
            child: Text(LanguageService.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              final newAcc = textCtrl.text.trim();
              final accounts = List<String>.from(AppState.accountsNotifier.value);
              if (newAcc.isNotEmpty && !accounts.contains(newAcc)) {
                accounts.add(newAcc);
                AppState.accountsNotifier.value = List.from(accounts);
                if (AppState.currentUser != null) {
                  AppState.saveAccounts(AppState.currentUser!, accounts);
                }
                setState(() => _selectedAccount = newAcc);
                Navigator.pop(innerCtx);
                onAdded?.call();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Account "$newAcc" added successfully!'),
                    backgroundColor: Colors.teal,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(LanguageService.tr('add_account'), style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final accounts = List<String>.from(AppState.accountsNotifier.value);
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(LanguageService.tr('manage_accounts'), style: const TextStyle(fontWeight: FontWeight.bold)),
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
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            tooltip: LanguageService.tr('delete'),
                            onPressed: () async {
                              if (accounts.length > 1) {
                                final accName = accounts[i];
                                final confirmed = await showDeleteConfirmationDialog(
                                    context: context,
                                    title: LanguageService.tr('delete'),
                                    message: LanguageService.tr('delete_budget_msg'),
                                    itemDetail: accName,
                                );
                                if (confirmed && context.mounted) {
                                  final removedAcc = accounts.removeAt(i);
                                  AppState.accountsNotifier.value = List.from(accounts);
                                  if (AppState.currentUser != null) AppState.saveAccounts(AppState.currentUser!, accounts);
                                  if (_selectedAccount == removedAcc) {
                                    setState(() => _selectedAccount = 'Overall');
                                  }
                                  setDialogState(() {});
                                  AppState.showAutoDismissingSnackBar(
                                    context,
                                    SnackBar(
                                      content: Text('Account "$removedAcc" deleted'),
                                      duration: const Duration(seconds: 5),
                                      action: SnackBarAction(
                                        label: LanguageService.tr('undo'),
                                        textColor: Colors.amberAccent,
                                        onPressed: () {
                                          accounts.insert(i, removedAcc);
                                          AppState.accountsNotifier.value = List.from(accounts);
                                          if (AppState.currentUser != null) AppState.saveAccounts(AppState.currentUser!, accounts);
                                        },
                                      ),
                                    ),
                                  );
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('At least one account is required.')),
                                );
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(LanguageService.tr('add_account')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _showAddAccountDialog(() => setDialogState(() {})),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: Text(LanguageService.tr('done')))
              ],
            );
          },
        );
      },
    );
  }

  void _showAddLoanDialog() {
    final titleCtrl = TextEditingController();
    final personCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String loanType = 'receivable'; // 'receivable' or 'payable'
    DateTime dueDate = DateTime.now().add(const Duration(days: 3));
    TimeOfDay dueTime = const TimeOfDay(hour: 12, minute: 0);
    String linkedAccount = AppState.accountsNotifier.value.isNotEmpty ? AppState.accountsNotifier.value.first : 'Main';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);
            final onSurface = theme.colorScheme.onSurface;
            final isReceivable = loanType == 'receivable';
            final themePrimary = theme.colorScheme.primary;
            final isLight = theme.brightness == Brightness.light;
            final positiveColor = isLight ? const Color(0xFF059669) : const Color(0xFF10B981);
            final negativeColor = isLight ? const Color(0xFFDC2626) : const Color(0xFFF87171);

            return AlertDialog(
              backgroundColor: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: [
                  Icon(
                    isReceivable ? Icons.call_received_rounded : Icons.call_made_rounded,
                    color: isReceivable ? positiveColor : negativeColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isReceivable
                        ? '${LanguageService.tr('receivable_short')} (${LanguageService.tr('owed_to_you')})'
                        : '${LanguageService.tr('payable_short')} (${LanguageService.tr('you_owe')})',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: onSurface),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Segmented Type Selector
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setModalState(() => loanType = 'receivable'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: isReceivable ? positiveColor.withValues(alpha: 0.25) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${LanguageService.tr('receivable_short')} (${LanguageService.tr('owed_to_you')})',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isReceivable ? FontWeight.bold : FontWeight.normal,
                                    color: isReceivable ? positiveColor : onSurface.withValues(alpha: 0.6),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setModalState(() => loanType = 'payable'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: !isReceivable ? negativeColor.withValues(alpha: 0.25) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${LanguageService.tr('payable_short')} (${LanguageService.tr('you_owe')})',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: !isReceivable ? FontWeight.bold : FontWeight.normal,
                                    color: !isReceivable ? negativeColor : onSurface.withValues(alpha: 0.6),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Contact / Person Name
                    TextField(
                      controller: personCtrl,
                      style: TextStyle(color: onSurface),
                      decoration: InputDecoration(
                        labelText: isReceivable ? LanguageService.tr('who_owes_you') : LanguageService.tr('who_do_you_owe'),
                        hintText: 'e.g. Alex Morgan or Landlord',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Title / Description
                    TextField(
                      controller: titleCtrl,
                      style: TextStyle(color: onSurface),
                      decoration: InputDecoration(
                        labelText: LanguageService.tr('title_purpose'),
                        hintText: 'e.g. Dinner bill split, Laptop loan',
                        prefixIcon: const Icon(Icons.description_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Amount
                    TextField(
                      controller: amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(color: onSurface),
                      decoration: InputDecoration(
                        labelText: '${LanguageService.tr('tx_amount_label')} (${AppState.currencyNotifier.value})',
                        prefixIcon: const Icon(Icons.attach_money),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Reminder Due Date & Time Picker
                    InkWell(
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: dueDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                        );
                        if (pickedDate != null && context.mounted) {
                          final pickedTime = await showTimePicker(
                            context: context,
                            initialTime: dueTime,
                          );
                          setModalState(() {
                            dueDate = DateTime(
                              pickedDate.year,
                              pickedDate.month,
                              pickedDate.day,
                              pickedTime?.hour ?? dueTime.hour,
                              pickedTime?.minute ?? dueTime.minute,
                            );
                            if (pickedTime != null) dueTime = pickedTime;
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: onSurface.withValues(alpha: 0.15)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.alarm_on_rounded, size: 20, color: themePrimary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(LanguageService.tr('reminder_due_date_time'), style: TextStyle(fontSize: 10, color: onSurface.withValues(alpha: 0.6))),
                                  Text(
                                    '${formatDateWithYear(dueDate)} at ${dueTime.format(context)}',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: onSurface),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.edit_calendar, size: 16, color: onSurface.withValues(alpha: 0.4)),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Notification Alert Info Box
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (isReceivable ? positiveColor : negativeColor).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: (isReceivable ? positiveColor : negativeColor).withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.notifications_active_outlined,
                            size: 18,
                            color: isReceivable ? positiveColor : negativeColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isReceivable
                                  ? 'Notification reminder: "Was this amount received from ${personCtrl.text.isEmpty ? "contact" : personCtrl.text}?"'
                                  : 'Alert notification: "You need to pay ${personCtrl.text.isEmpty ? "contact" : personCtrl.text} this amount on set date."',
                              style: TextStyle(fontSize: 11, color: onSurface.withValues(alpha: 0.75)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(LanguageService.tr('cancel')),
                ),
                ElevatedButton(
                  onPressed: () {
                    final pName = personCtrl.text.trim();
                    final title = titleCtrl.text.trim().isNotEmpty ? titleCtrl.text.trim() : (isReceivable ? 'Receivable' : 'Payable');
                    final amount = double.tryParse(amountCtrl.text.trim());

                    if (pName.isNotEmpty && amount != null && amount > 0) {
                      final newLoan = Loan(
                        title: title,
                        personName: pName,
                        amount: amount,
                        dueDate: dueDate,
                        type: loanType,
                        notes: notesCtrl.text.trim(),
                        account: linkedAccount,
                      );

                      if (AppState.currentUser != null) {
                        AppState.saveLoan(AppState.currentUser!, newLoan);
                      }
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isReceivable ? 'Receivable reminder scheduled for $pName!' : 'Payable alert scheduled for $pName!'),
                          backgroundColor: Colors.teal,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themePrimary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(LanguageService.tr('save_loan'), style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageService.currentLanguageNotifier,
      builder: (context, currentLanguage, _) {
        final theme = Theme.of(context);
        final onSurface = theme.colorScheme.onSurface;
        final primaryColor = theme.colorScheme.primary;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              _activeSegment == 'wallets' ? LanguageService.tr('accounts_title') : LanguageService.tr('loans_and_debts'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: theme.colorScheme.surface,
            elevation: 0,
            actions: [
              if (_activeSegment == 'wallets') ...[
                IconButton(
                  icon: const Icon(Icons.add_card_rounded),
                  tooltip: LanguageService.tr('add_new_account'),
                  onPressed: () => _showAddAccountDialog(),
                ),
                IconButton(
                  icon: const Icon(Icons.help_outline_rounded),
                  tooltip: LanguageService.tr('accounts_tour'),
                  onPressed: () => showAccountsTour(context),
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  tooltip: LanguageService.tr('manage_accounts'),
                  onPressed: _showSettingsDialog,
                ),
              ] else ...[
                IconButton(
                  icon: Icon(Icons.add_circle_outline_rounded, color: theme.colorScheme.primary),
                  tooltip: LanguageService.tr('add_loan_debt'),
                  onPressed: _showAddLoanDialog,
                ),
              ],
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: onSurface.withValues(alpha: 0.08)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _activeSegment = 'wallets'),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            decoration: BoxDecoration(
                              color: _activeSegment == 'wallets' ? theme.colorScheme.surface : Colors.transparent,
                              borderRadius: BorderRadius.circular(11),
                              boxShadow: _activeSegment == 'wallets'
                                  ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 1))]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.account_balance_wallet_outlined, size: 16, color: _activeSegment == 'wallets' ? primaryColor : onSurface.withValues(alpha: 0.6)),
                                const SizedBox(width: 6),
                                Text(
                                  LanguageService.tr('wallets_and_accounts'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: _activeSegment == 'wallets' ? FontWeight.bold : FontWeight.w500,
                                    color: _activeSegment == 'wallets' ? onSurface : onSurface.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _activeSegment = 'loans'),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            decoration: BoxDecoration(
                              color: _activeSegment == 'loans' ? theme.colorScheme.surface : Colors.transparent,
                              borderRadius: BorderRadius.circular(11),
                              boxShadow: _activeSegment == 'loans'
                                  ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 1))]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.handshake_outlined, size: 16, color: _activeSegment == 'loans' ? primaryColor : onSurface.withValues(alpha: 0.6)),
                                const SizedBox(width: 6),
                                Text(
                                  LanguageService.tr('loans_and_debts'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: _activeSegment == 'loans' ? FontWeight.bold : FontWeight.w500,
                                    color: _activeSegment == 'loans' ? onSurface : onSurface.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          body: _activeSegment == 'wallets' ? _buildWalletsTab() : _buildLoansTab(),
          floatingActionButton: _activeSegment == 'loans'
              ? FloatingActionButton.extended(
                  onPressed: _showAddLoanDialog,
                  backgroundColor: primaryColor,
                  foregroundColor: theme.colorScheme.onPrimary,
                  icon: const Icon(Icons.add, size: 20),
                  label: Text(LanguageService.tr('add_loan_debt'), style: const TextStyle(fontWeight: FontWeight.bold)),
                )
              : null,
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Segment 1: Wallets & Accounts View
  // ---------------------------------------------------------------------------
  Widget _buildWalletsTab() {
    return ValueListenableBuilder<String>(
      valueListenable: AppState.currencyNotifier,
      builder: (context, currentCurrency, _) {
        return ValueListenableBuilder<List<String>>(
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
                  physics: const AlwaysScrollableScrollPhysics(),
                  cacheExtent: 500,
                  slivers: [
                    SliverToBoxAdapter(
                      child: RepaintBoundary(
                        child: Container(
                          height: 140,
                          margin: const EdgeInsets.symmetric(vertical: 16),
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: allDisplayAccounts.length,
                          itemBuilder: (ctx, idx) {
                            final accName = allDisplayAccounts[idx];
                            final isSelected = accName == _selectedAccount;
                            final bal = balances[accName] ?? 0.0;
                            final spent = spentMap[accName] ?? 0.0;

                            return GestureDetector(
                              onTap: () => setState(() => _selectedAccount = accName),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                width: 170,
                                margin: const EdgeInsets.only(right: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
                                      : Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
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
                                        Icon(
                                          accName == 'Overall'
                                              ? Icons.dashboard_outlined
                                              : (accName == 'Cash'
                                                  ? Icons.payments_outlined
                                                  : (accName.contains('Credit')
                                                      ? Icons.credit_card
                                                      : Icons.account_balance_wallet_outlined)),
                                          color: isSelected
                                              ? Theme.of(context).colorScheme.primary
                                              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                        ),
                                        if (isSelected)
                                          Icon(Icons.check_circle, size: 16, color: Theme.of(context).colorScheme.primary),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          accName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '$currentCurrency${bal.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: bal >= 0 ? Colors.greenAccent : Colors.redAccent,
                                          ),
                                        ),
                                        Text(
                                          '${LanguageService.tr('spent')}: $currentCurrency${spent.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: RepaintBoundary(
                          child: InteractiveChartCard(
                            transactions: transactions,
                            accountFilter: _selectedAccount == 'Overall' ? null : _selectedAccount,
                            title: _selectedAccount == 'Overall' ? LanguageService.tr('overall_flow_and_analytics') : '${LanguageService.tr('analytics_prefix')}: $_selectedAccount',
                          ),
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(
                      child: RepaintBoundary(
                        child: AdBannerWidget(
                          margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                          sponsorCategory: 'Cloud Multi-Currency Vault',
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Text(
                          _selectedAccount == 'Overall' ? LanguageService.tr('all_transactions_prefix') : '${LanguageService.tr('transactions_prefix')}: $_selectedAccount',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                        ),
                      ),
                    ),

                    if (filteredTxs.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Text(
                            LanguageService.tr('no_tx_for_account'),
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (ctx, index) {
                              final tx = filteredTxs[index];
                              return RepaintBoundary(
                                key: ValueKey('acc_tx_${tx.id}'),
                                child: TransactionTile(
                                  tx: tx,
                                  onTap: () => showTransactionDialog(context, existingTx: tx),
                                  onDelete: () => AppState.deleteTransactionWithUndo(context, tx),
                                ),
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
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Segment 2: Loans & Debts (Receivables & Payables) View
  // ---------------------------------------------------------------------------
  Widget _buildLoansTab() {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;
    final isLight = theme.brightness == Brightness.light;
    final positiveColor = isLight ? const Color(0xFF059669) : const Color(0xFF10B981);
    final negativeColor = isLight ? const Color(0xFFDC2626) : const Color(0xFFF87171);

    return ValueListenableBuilder<String>(
      valueListenable: AppState.currencyNotifier,
      builder: (context, currency, _) {
        return ValueListenableBuilder<List<Loan>>(
          valueListenable: AppState.loansNotifier,
          builder: (context, loans, _) {
            double totalReceivables = 0;
            double totalPayables = 0;

            for (var l in loans) {
              if (!l.isSettled) {
                if (l.isReceivable) {
                  totalReceivables += l.amount;
                } else {
                  totalPayables += l.amount;
                }
              }
            }

            final netLending = totalReceivables - totalPayables;

            // Filter loans list
            final filteredLoans = loans.where((l) {
              if (_loanFilter == 'receivable') return l.isReceivable && !l.isSettled;
              if (_loanFilter == 'payable') return l.isPayable && !l.isSettled;
              if (_loanFilter == 'settled') return l.isSettled;
              return true; // 'all'
            }).toList();

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              cacheExtent: 500,
              slivers: [
                // Top Summary Cards (Receivables, Payables, Net Position)
                SliverToBoxAdapter(
                  child: RepaintBoundary(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: onSurface.withValues(alpha: 0.08)),
                        ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Receivable Card
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: positiveColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.call_received_rounded, size: 16, color: positiveColor),
                                          const SizedBox(width: 4),
                                          Text(
                                            LanguageService.tr('receivable_short'),
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: onSurface.withValues(alpha: 0.7)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '+$currency${totalReceivables.toStringAsFixed(0)}',
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: positiveColor),
                                      ),
                                      Text(
                                        LanguageService.tr('owed_to_you'),
                                        style: TextStyle(fontSize: 10, color: onSurface.withValues(alpha: 0.5)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Payable Card
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: negativeColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.call_made_rounded, size: 16, color: negativeColor),
                                          const SizedBox(width: 4),
                                          Text(
                                            LanguageService.tr('payable_short'),
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: onSurface.withValues(alpha: 0.7)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '-$currency${totalPayables.toStringAsFixed(0)}',
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: negativeColor),
                                      ),
                                      Text(
                                        LanguageService.tr('you_owe'),
                                        style: TextStyle(fontSize: 10, color: onSurface.withValues(alpha: 0.5)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Net Lending Indicator Strip
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: theme.scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(LanguageService.tr('net_lending_position'), style: TextStyle(fontSize: 12, color: onSurface.withValues(alpha: 0.65))),
                                Text(
                                  '${netLending >= 0 ? '+' : ''}$currency${netLending.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: netLending >= 0 ? positiveColor : negativeColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

                // Loan Filter Chips
                SliverToBoxAdapter(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        _loanFilterChip('all', '${LanguageService.tr('filter_all')} (${loans.length})', onSurface),
                        _loanFilterChip('receivable', LanguageService.tr('filter_receivable'), onSurface),
                        _loanFilterChip('payable', LanguageService.tr('filter_payable'), onSurface),
                        _loanFilterChip('settled', LanguageService.tr('filter_settled'), onSurface),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: RepaintBoundary(
                    child: AdBannerWidget(
                      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      sponsorCategory: 'Smart Debt & Cash Flow Reminders',
                    ),
                  ),
                ),

                // Loans List Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${LanguageService.tr('recorded_loans')} (${filteredLoans.length})',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: onSurface),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.add, size: 16),
                          label: Text(LanguageService.tr('new_loan')),
                          onPressed: _showAddLoanDialog,
                        ),
                      ],
                    ),
                  ),
                ),

                // Loans List or Empty State
                if (filteredLoans.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.handshake_outlined, size: 56, color: onSurface.withValues(alpha: 0.25)),
                            const SizedBox(height: 12),
                            Text(
                              LanguageService.tr('no_loans_in_filter'),
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: onSurface),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              LanguageService.tr('track_money_sub'),
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: onSurface.withValues(alpha: 0.6)),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.add, size: 18),
                              label: Text(LanguageService.tr('add_first_loan')),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: _showAddLoanDialog,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 80),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) {
                          final loan = filteredLoans[i];
                          return RepaintBoundary(
                            key: ValueKey('loan_${loan.id}'),
                            child: _buildLoanCard(loan, currency, theme, onSurface),
                          );
                        },
                        childCount: filteredLoans.length,
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _loanFilterChip(String key, String label, Color onSurface) {
    final isSelected = _loanFilter == key;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : onSurface.withValues(alpha: 0.75),
          ),
        ),
        selected: isSelected,
        selectedColor: Theme.of(context).colorScheme.primary,
        backgroundColor: Theme.of(context).colorScheme.surface,
        onSelected: (val) => setState(() => _loanFilter = key),
      ),
    );
  }

  Widget _buildLoanCard(Loan loan, String currency, ThemeData theme, Color onSurface) {
    final isReceivable = loan.isReceivable;
    final isLight = theme.brightness == Brightness.light;
    final positiveColor = isLight ? const Color(0xFF059669) : const Color(0xFF10B981);
    final negativeColor = isLight ? const Color(0xFFDC2626) : const Color(0xFFF87171);
    final warningColor = isLight ? const Color(0xFFD97706) : const Color(0xFFFBBF24);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(loan.dueDate.year, loan.dueDate.month, loan.dueDate.day);
    final daysDiff = due.difference(today).inDays;

    String statusText;
    Color statusColor;

    if (loan.isSettled) {
      statusText = LanguageService.tr('loan_settled');
      statusColor = onSurface.withValues(alpha: 0.5);
    } else if (daysDiff < 0) {
      statusText = '⚠️ ${LanguageService.tr('overdue')} (${daysDiff.abs()} ${LanguageService.tr('per_day').replaceAll('/', '')})';
      statusColor = negativeColor;
    } else if (daysDiff == 0) {
      statusText = '⚠️ ${LanguageService.tr('due_today')}';
      statusColor = warningColor;
    } else if (daysDiff == 1) {
      statusText = LanguageService.tr('due_tomorrow');
      statusColor = theme.colorScheme.primary;
    } else {
      statusText = '${LanguageService.tr('due_in')} $daysDiff ${LanguageService.tr('per_day').replaceAll('/', '')}';
      statusColor = theme.colorScheme.primary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: loan.isSettled
              ? onSurface.withValues(alpha: 0.05)
              : (daysDiff < 0 ? negativeColor.withValues(alpha: 0.3) : onSurface.withValues(alpha: 0.08)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Direction Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (isReceivable ? positiveColor : negativeColor).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isReceivable ? Icons.call_received_rounded : Icons.call_made_rounded,
                  color: isReceivable ? positiveColor : negativeColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Person & Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loan.personName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: onSurface,
                        decoration: loan.isSettled ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    Text(
                      loan.title,
                      style: TextStyle(fontSize: 12, color: onSurface.withValues(alpha: 0.65)),
                    ),
                  ],
                ),
              ),
              // Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isReceivable ? '+' : '-'}$currency${loan.amount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isReceivable ? positiveColor : negativeColor,
                      decoration: loan.isSettled ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Due Date, Account, & Quick Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today_rounded, size: 13, color: onSurface.withValues(alpha: 0.5)),
                  const SizedBox(width: 4),
                  Text(
                    formatDateWithYear(loan.dueDate),
                    style: TextStyle(fontSize: 11, color: onSurface.withValues(alpha: 0.6)),
                  ),
                  const SizedBox(width: 10),
                  Icon(Icons.account_balance_wallet_outlined, size: 13, color: onSurface.withValues(alpha: 0.5)),
                  const SizedBox(width: 4),
                  Text(
                    loan.account,
                    style: TextStyle(fontSize: 11, color: onSurface.withValues(alpha: 0.6)),
                  ),
                ],
              ),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Test / Trigger Instant Notification
                  IconButton(
                    icon: Icon(Icons.notifications_active_outlined, size: 18, color: onSurface.withValues(alpha: 0.6)),
                    tooltip: 'Trigger Reminder Notification',
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      await NotificationService.instance.scheduleLoanReminder(
                        loan: loan,
                        currencySymbol: currency,
                      );
                      if (mounted) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              isReceivable
                                  ? 'Reminder: "Was this received from ${loan.personName}?" sent!'
                                  : 'Alert: "You need to pay ${loan.personName} $currency${loan.amount.toStringAsFixed(0)}" sent!',
                            ),
                            backgroundColor: Colors.teal,
                          ),
                        );
                      }
                    },
                  ),

                  // Toggle Settled Button
                  IconButton(
                    icon: Icon(
                      loan.isSettled ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
                      size: 20,
                      color: loan.isSettled ? positiveColor : onSurface.withValues(alpha: 0.5),
                    ),
                    tooltip: loan.isSettled ? LanguageService.tr('mark_as_unsettled') : LanguageService.tr('mark_as_settled'),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      if (AppState.currentUser != null) {
                        AppState.toggleLoanSettled(AppState.currentUser!, loan);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(loan.isSettled ? 'Loan marked unsettled' : 'Loan marked settled & paid!'),
                            backgroundColor: Colors.teal,
                          ),
                        );
                      }
                    },
                  ),

                  // Delete Loan
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                    tooltip: LanguageService.tr('delete_loan'),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                    onPressed: () async {
                      final confirmed = await showDeleteConfirmationDialog(
                        context: context,
                        title: LanguageService.tr('delete_loan_title'),
                        message: '${LanguageService.tr('delete_loan_confirm')} ${loan.personName}?',
                        itemDetail: '${loan.title} • $currency${loan.amount.toStringAsFixed(0)}',
                      );
                      if (confirmed && mounted && AppState.currentUser != null) {
                        AppState.deleteLoan(AppState.currentUser!, loan.id);
                        AppState.showAutoDismissingSnackBar(
                          context,
                          SnackBar(
                            content: Text(LanguageService.tr('loan_record_deleted')),
                            duration: const Duration(seconds: 5),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
