import 'package:flutter/material.dart';
import '../services/geo_location_service.dart';
import '../services/language_service.dart';
import '../services/notification_service.dart';
import '../services/state.dart';
import '../services/database/app_database.dart';

class CurrencyOption {
  final String symbol;
  final String code;
  final String name;

  const CurrencyOption(this.symbol, this.code, this.name);
}

/// Onboarding configuration dialog shown upon creating a new account.
/// Allows the user to select their regional currency, preferred language,
/// and automatically enables notifications by default.
class NewUserSetupDialog extends StatefulWidget {
  final String username;

  const NewUserSetupDialog({
    super.key,
    required this.username,
  });

  static Future<bool?> show(BuildContext context, {required String username}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => NewUserSetupDialog(username: username),
    );
  }

  @override
  State<NewUserSetupDialog> createState() => _NewUserSetupDialogState();
}

class _NewUserSetupDialogState extends State<NewUserSetupDialog> {
  static const List<CurrencyOption> _currencies = [
    CurrencyOption('\$', 'USD', 'US Dollar (\$)'),
    CurrencyOption('€', 'EUR', 'Euro (€)'),
    CurrencyOption('£', 'GBP', 'British Pound (£)'),
    CurrencyOption('₨', 'PKR', 'Pakistani Rupee (₨)'),
    CurrencyOption('₹', 'INR', 'Indian Rupee (₹)'),
    CurrencyOption('¥', 'JPY', 'Japanese Yen (¥)'),
    CurrencyOption('د.إ', 'AED', 'UAE Dirham (د.إ)'),
    CurrencyOption('﷼', 'SAR', 'Saudi Riyal (﷼)'),
    CurrencyOption('C\$', 'CAD', 'Canadian Dollar (C\$)'),
    CurrencyOption('A\$', 'AUD', 'Australian Dollar (A\$)'),
  ];

  late String _selectedCurrency;
  late String _selectedLanguage;
  bool _enableNotifications = true; // Enabled for everyone as default per user request
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Auto-detect currency based on user device location / country code
    final detectedCur = GeoLocationService.detectedCurrencySymbol;
    if (_currencies.any((c) => c.symbol == detectedCur)) {
      _selectedCurrency = detectedCur;
    } else {
      _selectedCurrency = AppState.currencyNotifier.value;
      if (!_currencies.any((c) => c.symbol == _selectedCurrency)) {
        _selectedCurrency = '\$';
      }
    }
    // Auto-detect preferred supported language based on device locale
    final detectedLang = GeoLocationService.detectedSupportedLanguage;
    _selectedLanguage = detectedLang;
  }

  Future<void> _saveAndContinue() async {
    setState(() => _isSaving = true);
    try {
      // 1. Apply & persist currency
      AppState.currencyNotifier.value = _selectedCurrency;
      final profile = await AppDatabase.instance.loadProfile(widget.username);
      final updatedProfile = profile.copyWith(currency: _selectedCurrency);
      await AppDatabase.instance.saveProfile(updatedProfile);

      // 2. Apply & persist language
      await LanguageService.setLanguage(_selectedLanguage);

      // 3. Configure notifications (enabled by default)
      await NotificationService.instance.setRemindersEnabled(_enableNotifications);
      if (_enableNotifications) {
        await NotificationService.instance.requestPermission();
        final goals = await AppDatabase.instance.loadGoals(widget.username);
        await NotificationService.instance.scheduleGoalReminders(goals, _selectedCurrency);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      debugPrint('NewUserSetupDialog error: $e');
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      canPop: false,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      color: colorScheme.primary,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Welcome to Tally!',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'Customize your preferences to personalize your experience.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 1. Preferred Currency
                Text(
                  'Preferred Currency',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedCurrency,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      items: _currencies.map((c) {
                        return DropdownMenuItem<String>(
                          value: c.symbol,
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  c.symbol.trim(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  c.name,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCurrency = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Preferred Language
                Text(
                  'Preferred Language',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedLanguage,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      items: LanguageService.supportedLanguages.map((l) {
                        return DropdownMenuItem<String>(
                          value: l.code,
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: colorScheme.secondary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  l.code.toUpperCase(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: colorScheme.secondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '${l.englishName} (${l.nativeName})',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedLanguage = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 3. Notifications (Default On)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.notifications_active_rounded,
                        color: colorScheme.primary,
                        size: 26,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Reminders & Smart Alerts',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Get timely goal targets, loan due dates, and daily briefings (Recommended).',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _enableNotifications,
                        activeThumbColor: colorScheme.primary,
                        onChanged: (val) => setState(() => _enableNotifications = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveAndContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Get Started',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
