import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/state.dart';
import '../utils/constants.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/transaction_dialog.dart';
import '../widgets/interactive_chart_card.dart';
import 'all_transactions_screen.dart';
import '../widgets/tally_brand_painters.dart';
import '../services/tour_service.dart';
import '../widgets/feature_tour_dialog.dart';
import '../widgets/ad_banner_widget.dart';
import '../widgets/delete_confirmation_dialog.dart';
import '../widgets/planned_transactions_sheet.dart';
import '../utils/image_helper.dart';
import '../services/biometric_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  /// Tracks if the initial cold-boot intro animation has completed.
  /// Subsequent tab switches render immediately to eliminate animation jitter.
  static bool hasAnimatedIntro = false;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  
  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    if (!DashboardScreen.hasAnimatedIntro) {
      DashboardScreen.hasAnimatedIntro = true;
      _animController.forward();
    } else {
      _animController.value = 1.0;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPostLoginPrompts();
    });
  }

  Future<void> _checkPostLoginPrompts() async {
    if (!mounted) return;

    // Interactive step-by-step Home / Dashboard Tour for new users
    final homeTourCompleted = await TourService.isTourCompleted(TourService.tourHome);
    if (!homeTourCompleted && mounted) {
      await showHomeDashboardTour(context);
    }

    if (!mounted) return;

    // Easy biometric / screen lock setup prompt for accounts that have not configured it yet
    final currentUser = AppState.currentUser;
    if (currentUser != null && currentUser.isNotEmpty && !BiometricService.biometricPromptCheckedThisSession) {
      BiometricService.biometricPromptCheckedThisSession = true;
      final supported = await BiometricService.isDeviceSupported();
      final enabled = await BiometricService.isBiometricEnabled(username: currentUser);
      if (supported && !enabled && mounted) {
        final hasPrompted = await BiometricService.hasPromptedUser(currentUser);
        if (!hasPrompted && mounted) {
          await BiometricService.markUserPrompted(currentUser);
          if (!mounted) return;
          final configure = await BiometricService.showBiometricSetupPrompt(context);
          if (configure == true && mounted) {
            final authSuccess = await BiometricService.authenticate(
              reason: 'Confirm screen lock or biometric unlock for $currentUser',
            );
            if (authSuccess) {
              await BiometricService.setBiometricEnabled(true, username: currentUser);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Screen lock unlock configured for $currentUser!'),
                    backgroundColor: Colors.teal,
                  ),
                );
              }
            }
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _showBudgetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final budgets = Map<String, double>.from(AppState.budgetsNotifier.value);
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Manage Budgets', style: TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: Icon(Icons.add_circle, color: Theme.of(context).colorScheme.primary),
                    onPressed: () {
                      String newCat = '';
                      String newLimit = '';
                      showDialog(
                        context: context,
                        builder: (innerCtx) => AlertDialog(
                          backgroundColor: Theme.of(context).colorScheme.surface,
                          title: const Text('Add Budget'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              DropdownButtonFormField<String>(
                                initialValue: categoryIcons.keys.first,
                                dropdownColor: Theme.of(context).colorScheme.surface,
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                                items: categoryIcons.keys
                                    .where((cat) => !budgets.containsKey(cat))
                                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                                    .toList(),
                                onChanged: (val) { if (val != null) newCat = val; },
                                decoration: const InputDecoration(labelText: 'Category'),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                                decoration: const InputDecoration(labelText: 'Limit Amount'),
                                keyboardType: TextInputType.number,
                                onChanged: (v) => newLimit = v,
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(innerCtx), child: const Text('Cancel')),
                            TextButton(
                              onPressed: () {
                                final limit = double.tryParse(newLimit);
                                if (newCat.isNotEmpty && limit != null && limit > 0) {
                                  budgets[newCat] = limit;
                                  AppState.budgetsNotifier.value = Map.from(budgets);
                                  if (AppState.currentUser != null) AppState.saveBudgets(AppState.currentUser!, budgets);
                                  Navigator.pop(innerCtx);
                                  setDialogState(() {});
                                }
                              },
                              child: const Text('Add'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: budgets.isEmpty
                    ? Center(child: Text('No budgets set', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))))
                    : ListView(
                        shrinkWrap: true,
                        children: budgets.entries.map((entry) {
                          return ListTile(
                            dense: true,
                            leading: Icon(categoryIcons[entry.key] ?? Icons.category, color: Theme.of(context).colorScheme.primary, size: 20),
                            title: Text(entry.key, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14)),
                            subtitle: Text('${AppState.currencyNotifier.value}${entry.value.toStringAsFixed(0)}', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, size: 18, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                                  onPressed: () {
                                    String newLimit = entry.value.toString();
                                    showDialog(
                                      context: context,
                                      builder: (innerCtx) => AlertDialog(
                                        backgroundColor: Theme.of(context).colorScheme.surface,
                                        title: Text('Edit ${entry.key}'),
                                        content: TextField(
                                          controller: TextEditingController(text: entry.value.toStringAsFixed(0)),
                                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                                          decoration: const InputDecoration(labelText: 'New Limit'),
                                          keyboardType: TextInputType.number,
                                          onChanged: (v) => newLimit = v,
                                        ),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(innerCtx), child: const Text('Cancel')),
                                          TextButton(
                                            onPressed: () {
                                              final limit = double.tryParse(newLimit);
                                              if (limit != null && limit > 0) {
                                                budgets[entry.key] = limit;
                                                AppState.budgetsNotifier.value = Map.from(budgets);
                                                if (AppState.currentUser != null) AppState.saveBudgets(AppState.currentUser!, budgets);
                                                Navigator.pop(innerCtx);
                                                setDialogState(() {});
                                              }
                                            },
                                            child: const Text('Save'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                  onPressed: () async {
                                    final catName = entry.key;
                                    final budgetVal = entry.value;
                                    final confirmed = await showDeleteConfirmationDialog(
                                      context: context,
                                      title: 'Delete Budget?',
                                      message: 'Are you sure you want to remove the budget cap for $catName?',
                                      itemDetail: '$catName • ${AppState.currencyNotifier.value}${budgetVal.toStringAsFixed(0)}',
                                    );
                                    if (confirmed && context.mounted) {
                                      budgets.remove(catName);
                                      AppState.budgetsNotifier.value = Map.from(budgets);
                                      if (AppState.currentUser != null) AppState.saveBudgets(AppState.currentUser!, budgets);
                                      setDialogState(() {});
                                      AppState.showAutoDismissingSnackBar(
                                        context,
                                        SnackBar(
                                          content: Text('Budget for "$catName" deleted'),
                                          duration: const Duration(seconds: 5),
                                          action: SnackBarAction(
                                            label: 'Undo',
                                            textColor: Colors.amberAccent,
                                            onPressed: () {
                                              budgets[catName] = budgetVal;
                                              AppState.budgetsNotifier.value = Map.from(budgets);
                                              if (AppState.currentUser != null) AppState.saveBudgets(AppState.currentUser!, budgets);
                                            },
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done')),
              ],
            );
          },
        );
      },
    );
  }

  void _resetData() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Reset All?'),
        content: const Text('This will clear all transactions and reset your balance to zero.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              AppState.transactionsNotifier.value = [];
              if (AppState.currentUser != null) {
                AppState.saveTransactions(AppState.currentUser!, []);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Reset', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    await AppState.logout(context);
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
          title: Row(
          children: [
            GestureDetector(
              onTap: () => AppState.activeTabNotifier.value = 4,
              child: ValueListenableBuilder<String?>(
                valueListenable: AppState.profilePhotoNotifier,
                builder: (context, photoPath, _) {
                  return ValueListenableBuilder<Color>(
                    valueListenable: AppState.customPrimaryColorNotifier,
                    builder: (context, primaryColor, _) {
                      final imageProvider = getProfileImageProvider(photoPath);
                      return CircleAvatar(
                        radius: 20,
                        backgroundColor: primaryColor.withValues(alpha: 0.3),
                        backgroundImage: imageProvider,
                        child: imageProvider == null
                            ? ValueListenableBuilder<String>(
                                valueListenable: AppState.displayNameNotifier,
                                builder: (context, dispName, _) {
                                  final name = dispName.isNotEmpty ? dispName : (AppState.currentUser ?? 'U');
                                  return Text(
                                    name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'U',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
                                  );
                                },
                              )
                            : null,
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => AppState.activeTabNotifier.value = 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome back,', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                  ValueListenableBuilder<String>(
                    valueListenable: AppState.displayNameNotifier,
                    builder: (context, dispName, _) {
                      final name = dispName.isNotEmpty ? dispName : (AppState.currentUser ?? 'Guest');
                      return Text(
                        name,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.currency_exchange, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
            tooltip: 'Currency',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => ValueListenableBuilder<String>(
                  valueListenable: AppState.currencyNotifier,
                  builder: (context, activeCurrency, _) {
                    return SimpleDialog(
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      title: const Text('Select Currency'),
                      children: currencyOptions.entries.map((entry) {
                        final isSelected = activeCurrency == entry.value;
                        return SimpleDialogOption(
                          onPressed: () {
                            AppState.setCurrency(entry.value);
                            Navigator.pop(ctx);
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                entry.key,
                                style: TextStyle(
                                  color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              if (isSelected)
                                Icon(Icons.check, size: 18, color: Theme.of(context).colorScheme.primary),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.redAccent),
            tooltip: 'Reset All',
            onPressed: _resetData,
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: ValueListenableBuilder<String>(
        valueListenable: AppState.currencyNotifier,
        builder: (context, currentCurrency, _) {
          return ValueListenableBuilder<List<Transaction>>(
            valueListenable: AppState.transactionsNotifier,
            builder: (context, transactions, child) {
          final totalBalance = transactions.fold(0.0, (sum, item) => item.isIncome ? sum + item.amount : sum - item.amount);
          
          return Stack(
            children: [
              Positioned(
                top: -100,
                right: -100,
                child: RepaintBoundary(
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                          Colors.transparent,
                        ],
                        stops: const [0.3, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -50,
                left: -100,
                child: RepaintBoundary(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                          Colors.transparent,
                        ],
                        stops: const [0.3, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              
              SafeArea(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    const SizedBox(height: 10),
                    SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0, -0.1), end: Offset.zero)
                          .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: RepaintBoundary(
                          child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.surface,
                                Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // Background Brand Watermark Logo
                              Positioned(
                                right: -15,
                                top: -15,
                                child: IgnorePointer(
                                  child: Opacity(
                                    opacity: 0.12,
                                    child: CustomPaint(
                                      size: const Size(130, 130),
                                      painter: TallyIconPainter(
                                        bgColor: Colors.transparent,
                                        strokeColor: Theme.of(context).colorScheme.onSurface,
                                        slashColor: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Total Balance',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      // Official Tally Logo Badge on Card
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10),
                                          color: Theme.of(context).scaffoldBackgroundColor,
                                          border: Border.all(
                                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.1),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: CustomPaint(
                                            painter: TallyIconPainter(
                                              bgColor: Theme.of(context).scaffoldBackgroundColor,
                                              strokeColor: Theme.of(context).colorScheme.secondary,
                                              slashColor: Theme.of(context).colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${AppState.currencyNotifier.value}${totalBalance.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface,
                                      fontSize: 42,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -1,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.shield_outlined, size: 15, color: Theme.of(context).colorScheme.primary),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Tally Encrypted Vault',
                                            style: TextStyle(
                                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 6,
                                              height: 6,
                                              decoration: BoxDecoration(
                                                color: Theme.of(context).colorScheme.primary,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'ACTIVE',
                                              style: TextStyle(
                                                color: Theme.of(context).colorScheme.primary,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    ),
                    
                    const SizedBox(height: 20),
                    RepaintBoundary(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Monthly Budgets',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                                ),
                                IconButton(
                                  icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.primary, size: 16),
                                  onPressed: () => _showBudgetDialog(context),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ValueListenableBuilder<Map<String, double>>(
                              valueListenable: AppState.budgetsNotifier,
                              builder: (context, budgets, _) {
                                final now = DateTime.now();
                                final monthTx = transactions.where((t) => t.date.year == now.year && t.date.month == now.month && !t.isIncome).toList();
                                
                                return Column(
                                  children: budgets.entries.map((entry) {
                                    final spent = monthTx.where((t) => t.category == entry.key).fold(0.0, (sum, t) => sum + t.amount);
                                    final limit = entry.value;
                                    final percent = (spent / limit).clamp(0.0, 1.0);
                                    
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(entry.key, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
                                              Text('${AppState.currencyNotifier.value}${spent.toStringAsFixed(0)} / ${AppState.currencyNotifier.value}${limit.toStringAsFixed(0)}', style: TextStyle(color: percent > 0.9 ? Colors.redAccent : Theme.of(context).colorScheme.onSurface)),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          LinearProgressIndicator(
                                            value: percent,
                                            backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
                                            valueColor: AlwaysStoppedAnimation<Color>(percent > 0.9 ? Colors.redAccent : Theme.of(context).colorScheme.secondary),
                                            minHeight: 6,
                                            borderRadius: BorderRadius.circular(3),
                                          )
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: RepaintBoundary(
                        child: InteractiveChartCard(
                          transactions: transactions,
                          title: 'Financial Flow & Analytics',
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    const RepaintBoundary(
                      child: AdBannerWidget(
                        margin: EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
                        sponsorCategory: 'YieldMax High-Yield Savings (5.2% APY)',
                      ),
                    ),

                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Transactions',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.event_note_rounded, size: 20, color: Colors.amberAccent),
                                tooltip: 'Planned & Future Sheet',
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                padding: EdgeInsets.zero,
                                onPressed: () => showPlannedTransactionsSheet(context),
                              ),
                              const SizedBox(width: 4),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AllTransactionsScreen()));
                                },
                                child: Text('See All', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 10),
                    transactions.isEmpty 
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Center(child: Text("No transactions yet", style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)))),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: transactions.take(5).map((tx) {
                              return RepaintBoundary(
                                child: TransactionTile(
                                  tx: tx,
                                  onTap: () => showTransactionDialog(context, existingTx: tx),
                                  onDelete: () => AppState.deleteTransactionWithUndo(context, tx),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            ],
          );
        },
      );
    },
  ),
      floatingActionButton: Builder(
        builder: (context) {
          final fabBg = Theme.of(context).colorScheme.primary;
          final fabFg = fabBg.computeLuminance() > 0.5 ? const Color(0xFF152A22) : Colors.white;
          return FloatingActionButton(
            onPressed: () => showTransactionDialog(context),
            backgroundColor: fabBg,
            foregroundColor: fabFg,
            elevation: 4, 
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Icon(Icons.add, color: fabFg, size: 28),
          );
        },
      ),
    );
  }
}