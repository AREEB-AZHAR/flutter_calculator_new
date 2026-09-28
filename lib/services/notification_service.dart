import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/loan.dart';
import '../models/planned_transaction.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  static const String _prefRemindersEnabledKey = 'tally_reminders_enabled';
  static const String _channelId = 'expense_tally_reminders';
  static const String _channelName = 'Expense Tally Reminders';
  static const String _channelDescription = 'Friendly periodic reminders to tally up daily expenses';

  // 20 casual, friendly, conversational check-in prompts between friends
  static const List<String> friendlyMessages = [
    "Hey! Did you grab a coffee or a snack earlier? Don't forget to log it ☕",
    "Quick check-in! Did any money leave your pocket recently? Let's tally it up 👀",
    "Yo! How's your wallet holding up today? Take 10 seconds to add any expenses 💸",
    "Hey friend, just popping in! Any recent spending you want to jot down? 📝",
    "A quick tally now saves a headache later! Logged your latest purchases yet? 🤔",
    "Treat yourself today? Awesome, just make sure to add it to your balance! ✨",
    "Psst... Don't let those small receipts pile up! Quick tally time 🧾",
    "Hey! Just making sure those sneaky impulse buys don't slip past us 😄",
    "Mid-day balance check! Did you pick up lunch or groceries? 🥪",
    "Take a breather and log your latest spend. Future you will thank you! 🙌",
    "Hey buddy! How's the budget looking? Pop in and record your last expense 📊",
    "Did you swipe your card just now? Let's keep that tally crystal clear 💳",
    "Remember that goal you're saving for? Every logged penny counts! 🎯",
    "Quick reminder between friends: got any new expenses to record? 🤝",
    "Drop whatever you're doing for 5 seconds—did you buy anything recently? ⏱️",
    "Hey! Just keeping you honest with your wallet 😉 Any expenses to add?",
    "Coffee, transit, snacks? If money moved, let's tally it! 🚀",
    "Checking in on your budget goals! Any new numbers to plug in? 💡",
    "Hey there! Don't let your wallet do all the talking—track that expense! 🗣️",
    "Quick tap, quick log, and you're good to go. What did you spend recently? 📱",
  ];

  // Active check-in hours: 9:00 AM, 12:00 PM, 3:00 PM, 6:00 PM, 9:00 PM (Quiet hours: 11 PM – 9 AM)
  static const List<int> reminderHours = [9, 12, 15, 18, 21];

  Future<void> init() async {
    if (_isInitialized) return;
    if (kIsWeb) {
      _isInitialized = true;
      return;
    }

    try {
      tz.initializeTimeZones();
    } catch (e) {
      debugPrint('Error initializing timezones: $e');
    }

    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const WindowsInitializationSettings windowsSettings = WindowsInitializationSettings(
      appName: 'Tally Expense Tracker',
      appUserModelId: 'com.example.flutter_calculator_new',
      guid: '9f5e1f0e-36fa-4ec4-bf18-091924b1702d',
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
      windows: windowsSettings,
    );

    try {
      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification tapped with payload: ${response.payload}');
        },
      );
    } catch (e) {
      debugPrint('NotificationService._notificationsPlugin.initialize notice: $e');
    }

    _isInitialized = true;

    // Check if reminders are currently enabled
    final isEnabled = await areRemindersEnabled();
    if (isEnabled) {
      await scheduleAllDailyReminders();
    }
  }

  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    if (Platform.isAndroid) {
      final androidImplementation = _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final granted = await androidImplementation?.requestNotificationsPermission();
      return granted ?? false;
    } else if (Platform.isIOS || Platform.isMacOS) {
      final iosImplementation = _notificationsPlugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      final granted = await iosImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return true;
  }

  Future<bool> areRemindersEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    // Default to enabled (true)
    return prefs.getBool(_prefRemindersEnabledKey) ?? true;
  }

  Future<void> setRemindersEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefRemindersEnabledKey, enabled);

    if (enabled) {
      await requestPermission();
      await scheduleAllDailyReminders();
    } else {
      await cancelAllReminders();
    }
  }

  NotificationDetails _buildNotificationDetails() {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      color: Color(0xFF17493B),
    );

    const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return const NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// Schedules daily 3-hour check-in notifications for 9 AM, 12 PM, 3 PM, 6 PM, 9 PM
  Future<void> scheduleAllDailyReminders() async {
    if (kIsWeb) return;
    await cancelAllReminders();

    final details = _buildNotificationDetails();
    final random = Random();

    for (int i = 0; i < reminderHours.length; i++) {
      final hour = reminderHours[i];
      final notificationId = 100 + i;
      final msg = friendlyMessages[(i * 4 + random.nextInt(4)) % friendlyMessages.length];

      try {
        await _notificationsPlugin.zonedSchedule(
          id: notificationId,
          title: 'Time to Tally! ⏱️',
          body: msg,
          scheduledDate: _nextInstanceOfTime(hour, 0),
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } catch (e) {
        debugPrint('Failed to schedule notification for $hour:00: $e');
      }
    }
  }

  /// Cancels all scheduled reminder notifications
  Future<void> cancelAllReminders() async {
    if (kIsWeb) return;
    try {
      for (int i = 0; i < reminderHours.length; i++) {
        final notificationId = 100 + i;
        await _notificationsPlugin.cancel(id: notificationId);
      }
    } catch (e) {
      debugPrint('NotificationService.cancelAllReminders notice: $e');
    }
  }

  /// Instant test reminder triggered by the hidden dev easter egg (10 toggles)
  Future<void> showInstantFriendlyReminder() async {
    if (kIsWeb) return;
    final random = Random();
    final msg = friendlyMessages[random.nextInt(friendlyMessages.length)];
    final details = _buildNotificationDetails();

    try {
      await _notificationsPlugin.show(
        id: 999,
        title: 'Time to Tally! ⏱️',
        body: msg,
        notificationDetails: details,
      );
    } catch (e) {
      debugPrint('NotificationService.showInstantFriendlyReminder notice: $e');
    }
  }

  int _getLoanNotificationId(String loanId) {
    return (loanId.hashCode.abs() % 50000) + 10000;
  }

  int _getPlanNotificationId(String planId) {
    return (planId.hashCode.abs() % 50000) + 60000;
  }

  /// Schedules a loan reminder notification on the user-defined reminder due date & time
  Future<void> scheduleLoanReminder({
    required Loan loan,
    required String currencySymbol,
  }) async {
    if (kIsWeb) return;
    final notificationId = _getLoanNotificationId(loan.id);
    final details = _buildNotificationDetails();

    final String title;
    final String body;

    if (loan.isReceivable) {
      title = 'Money Received Check 💰';
      body = 'Was $currencySymbol${loan.amount.toStringAsFixed(0)} received from ${loan.personName} for "${loan.title}"?';
    } else {
      title = 'Payment Due Alert ⚠️';
      body = 'Friendly alert: You need to pay ${loan.personName} $currencySymbol${loan.amount.toStringAsFixed(0)} for "${loan.title}" today!';
    }

    try {
      final scheduledTz = tz.TZDateTime.from(loan.dueDate, tz.local);
      final nowTz = tz.TZDateTime.now(tz.local);

      if (scheduledTz.isAfter(nowTz)) {
        await _notificationsPlugin.zonedSchedule(
          id: notificationId,
          title: title,
          body: body,
          scheduledDate: scheduledTz,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      } else {
        await _notificationsPlugin.show(
          id: notificationId,
          title: title,
          body: body,
          notificationDetails: details,
        );
      }
    } catch (e) {
      debugPrint('scheduleLoanReminder notice: $e');
    }
  }

  /// Cancels an active loan reminder
  Future<void> cancelLoanReminder(String loanId) async {
    if (kIsWeb) return;
    final notificationId = _getLoanNotificationId(loanId);
    try {
      await _notificationsPlugin.cancel(id: notificationId);
    } catch (_) {}
  }

  /// Schedules a planned transaction notification on its set date
  Future<void> schedulePlannedTransactionReminder({
    required PlannedTransaction plan,
    required String currencySymbol,
  }) async {
    if (kIsWeb) return;
    final notificationId = _getPlanNotificationId(plan.id);
    final details = _buildNotificationDetails();

    final title = 'Planned Transaction Due 📅';
    final body = 'Your planned ${plan.isIncome ? 'income' : 'expense'} "${plan.title}" of $currencySymbol${plan.amount.toStringAsFixed(0)} is due today!';

    try {
      final scheduledTz = tz.TZDateTime.from(plan.date, tz.local);
      final nowTz = tz.TZDateTime.now(tz.local);

      if (scheduledTz.isAfter(nowTz)) {
        await _notificationsPlugin.zonedSchedule(
          id: notificationId,
          title: title,
          body: body,
          scheduledDate: scheduledTz,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      }
    } catch (e) {
      debugPrint('schedulePlannedTransactionReminder notice: $e');
    }
  }

  /// Cancels a planned transaction reminder
  Future<void> cancelPlannedTransactionReminder(String planId) async {
    if (kIsWeb) return;
    final notificationId = _getPlanNotificationId(planId);
    try {
      await _notificationsPlugin.cancel(id: notificationId);
    } catch (_) {}
  }

  /// Shows an instant notification alert
  Future<void> showInstantAlert({
    required String title,
    required String body,
    int id = 888,
  }) async {
    if (kIsWeb) return;
    final details = _buildNotificationDetails();
    try {
      await _notificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
      );
    } catch (e) {
      debugPrint('showInstantAlert notice: $e');
    }
  }
}
