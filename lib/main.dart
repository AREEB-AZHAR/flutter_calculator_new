import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const BalanceTrackerApp());
}

class BalanceTrackerApp extends StatelessWidget {
  const BalanceTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Balance Tracker',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0E14),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF8B5CF6),
          secondary: Color(0xFF10B981),
          surface: Color(0xFF151A22),
        ),
        useMaterial3: true,
        fontFamily: 'Segoe UI', 
      ),
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class Transaction {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final bool isIncome;
  final String category;
  final String account;
  final String recurrence;

  Transaction({
    String? id,
    required this.title,
    required this.amount,
    required this.date,
    required this.isIncome,
    this.category = 'Other',
    this.account = 'Main',
    this.recurrence = 'None',
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString() + Random().nextInt(1000).toString();

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'amount': amount,
    'date': date.toIso8601String(),
    'isIncome': isIncome,
    'category': category,
    'account': account,
    'recurrence': recurrence,
  };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString() + Random().nextInt(1000).toString(),
    title: json['title'],
    amount: json['amount'].toDouble(),
    date: DateTime.parse(json['date']),
    isIncome: json['isIncome'],
    category: json['category'] ?? 'Other',
    account: json['account'] ?? 'Main',
    recurrence: json['recurrence'] ?? 'None',
  );
}

const Map<String, IconData> categoryIcons = {
  'Food & Dining': Icons.fastfood,
  'Housing & Rent': Icons.home,
  'Transportation': Icons.directions_car,
  'Healthcare': Icons.local_hospital,
  'Entertainment': Icons.movie,
  'Education': Icons.school,
  'Salary': Icons.attach_money,
  'Investments': Icons.trending_up,
  'Shopping': Icons.shopping_cart,
  'Utilities': Icons.lightbulb,
  'Gifts': Icons.card_giftcard,
  'Travel': Icons.flight,
  'Other': Icons.category,
};

// Currency options
const Map<String, String> currencyOptions = {
  'USD (\$)': '\$',
  'EUR (€)': '€',
  'GBP (£)': '£',
  'PKR (₨)': '₨',
  'INR (₹)': '₹',
  'JPY (¥)': '¥',
  'CNY (¥)': '¥',
  'AED (د.إ)': 'د.إ',
  'SAR (﷼)': '﷼',
  'CAD (C\$)': 'C\$',
  'AUD (A\$)': 'A\$',
  'TRY (₺)': '₺',
  'BRL (R\$)': 'R\$',
};

// Global states
String? currentUser;
final ValueNotifier<String> currencyNotifier = ValueNotifier('\$');
final ValueNotifier<List<Transaction>> transactionsNotifier = ValueNotifier([]);
final ValueNotifier<Map<String, double>> budgetsNotifier = ValueNotifier({
  'Food & Dining': 500.0,
  'Housing & Rent': 1500.0,
  'Transportation': 300.0,
  'Entertainment': 200.0,
});

class SavingsGoal {
  final String id;
  final String title;
  final double target;
  double saved;
  final IconData icon;
  final Color color;

  SavingsGoal({
    String? id,
    required this.title,
    required this.target,
    this.saved = 0,
    this.icon = Icons.savings,
    this.color = const Color(0xFF8B5CF6),
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString() + Random().nextInt(1000).toString();

  double get progress => (saved / target).clamp(0.0, 1.0);

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'target': target,
    'saved': saved,
    'iconCode': icon.codePoint,
    'colorValue': color.toARGB32(),
  };

  factory SavingsGoal.fromJson(Map<String, dynamic> json) => SavingsGoal(
    id: json['id'],
    title: json['title'],
    target: json['target'].toDouble(),
    saved: json['saved'].toDouble(),
    icon: IconData(json['iconCode'] ?? Icons.savings.codePoint, fontFamily: 'MaterialIcons'),
    color: Color(json['colorValue'] ?? 0xFF8B5CF6),
  );
}

final ValueNotifier<List<SavingsGoal>> goalsNotifier = ValueNotifier([]);

Future<void> saveGoals(String username, List<SavingsGoal> goals) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('goals_$username', jsonEncode(goals.map((e) => e.toJson()).toList()));
}

Future<List<SavingsGoal>> loadGoals(String username) async {
  final prefs = await SharedPreferences.getInstance();
  final String? data = prefs.getString('goals_$username');
  if (data != null) {
    final List<dynamic> list = jsonDecode(data);
    return list.map((item) => SavingsGoal.fromJson(item)).toList();
  }
  return [];
}

Future<void> saveTransactions(String username, List<Transaction> txs) async {
  final prefs = await SharedPreferences.getInstance();
  final String encodedData = jsonEncode(txs.map((e) => e.toJson()).toList());
  await prefs.setString('tx_$username', encodedData);
}

Future<List<Transaction>> loadTransactions(String username) async {
  final prefs = await SharedPreferences.getInstance();
  final String? encodedData = prefs.getString('tx_$username');
  if (encodedData != null) {
    final List<dynamic> decodedList = jsonDecode(encodedData);
    return decodedList.map((item) => Transaction.fromJson(item)).toList();
  }
  return [];
}

String _formatDate(DateTime date) {
  final List<String> months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[date.month - 1]} ${date.day}';
}

String _formatTime(DateTime date) {
  final hour = date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour);
  final ampm = date.hour >= 12 ? 'PM' : 'AM';
  final min = date.minute.toString().padLeft(2, '0');
  return '$hour:$min $ampm';
}

// ----------------------------------------------------
// Login Screen
// ----------------------------------------------------

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLogin = true;
  String _error = '';
  bool _isLoading = false;

  Future<void> _submit() async {
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text;
    
    if (username.isEmpty || password.isEmpty) {
       setState(() => _error = 'Please fill all fields');
       return;
    }

    setState(() { _isLoading = true; _error = ''; });

    final prefs = await SharedPreferences.getInstance();
    final String? usersStr = prefs.getString('users');
    Map<String, dynamic> users = usersStr != null ? jsonDecode(usersStr) : {};

    if (_isLogin) {
      if (users.containsKey(username) && users[username] == password) {
         currentUser = username;
         transactionsNotifier.value = await loadTransactions(username);
         goalsNotifier.value = await loadGoals(username);
         if (!mounted) return;
         Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainNavScreen()));
      } else {
         setState(() { _error = 'Invalid credentials'; _isLoading = false; });
      }
    } else {
      if (users.containsKey(username)) {
         setState(() { _error = 'User already exists'; _isLoading = false; });
      } else {
         users[username] = password;
         await prefs.setString('users', jsonEncode(users));
         currentUser = username;
         transactionsNotifier.value = [];
         goalsNotifier.value = [];
         if (!mounted) return;
         Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainNavScreen()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
     return Scaffold(
       body: Center(
         child: SingleChildScrollView(
           padding: const EdgeInsets.all(32.0),
           child: ConstrainedBox(
             constraints: const BoxConstraints(maxWidth: 400),
             child: Column(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
               Container(
                 padding: const EdgeInsets.all(20),
                 decoration: BoxDecoration(
                   shape: BoxShape.circle,
                   gradient: RadialGradient(
                     colors: [Theme.of(context).colorScheme.primary.withValues(alpha: 0.2), Colors.transparent],
                   )
                 ),
                 child: Icon(Icons.account_balance_wallet, size: 80, color: Theme.of(context).colorScheme.primary),
               ),
               const SizedBox(height: 20),
               Text(_isLogin ? 'Welcome Back' : 'Create Account', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
               const SizedBox(height: 40),
               TextField(
                 controller: _usernameCtrl,
                 style: const TextStyle(color: Colors.white),
                 decoration: InputDecoration(
                   labelText: 'Username', 
                   labelStyle: const TextStyle(color: Colors.white54),
                   filled: true, 
                   fillColor: Theme.of(context).colorScheme.surface,
                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                 ),
               ),
               const SizedBox(height: 15),
               TextField(
                 controller: _passwordCtrl,
                 obscureText: true,
                 style: const TextStyle(color: Colors.white),
                 decoration: InputDecoration(
                   labelText: 'Password', 
                   labelStyle: const TextStyle(color: Colors.white54),
                   filled: true, 
                   fillColor: Theme.of(context).colorScheme.surface,
                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                 ),
               ),
               if (_error.isNotEmpty) ...[
                 const SizedBox(height: 15),
                 Text(_error, style: const TextStyle(color: Colors.redAccent)),
               ],
               const SizedBox(height: 30),
               _isLoading 
                 ? const CircularProgressIndicator()
                 : ElevatedButton(
                     onPressed: _submit,
                     style: ElevatedButton.styleFrom(
                       minimumSize: const Size(double.infinity, 55), 
                       backgroundColor: Theme.of(context).colorScheme.primary,
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                     ),
                     child: Text(_isLogin ? 'Login' : 'Register', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                   ),
               const SizedBox(height: 15),
               TextButton(
                 onPressed: () => setState(() { _isLogin = !_isLogin; _error = ''; }),
                 child: Text(
                   _isLogin ? 'Need an account? Register' : 'Already have an account? Login',
                   style: const TextStyle(color: Colors.white70),
                 ),
               )
             ],
           ),
           ),
         ),
       ),
     );
  }
}

void showTransactionDialog(BuildContext context, {Transaction? existingTx}) {
  String title = existingTx?.title ?? '';
  String amountStr = existingTx?.amount.toString() ?? '';
  bool isIncome = existingTx?.isIncome ?? false;
  String category = existingTx?.category ?? (isIncome ? 'Salary' : 'Food & Dining');
  String account = existingTx?.account ?? 'Main';
  String recurrence = existingTx?.recurrence ?? 'None';

  showDialog(
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
                    controller: TextEditingController(text: title)..selection = TextSelection.collapsed(offset: title.length),
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
                    onChanged: (val) => title = val,
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: TextEditingController(text: amountStr)..selection = TextSelection.collapsed(offset: amountStr.length),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Amount (\$)',
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
                    onChanged: (val) => amountStr = val,
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
                    items: ['Main', 'Cash', 'Credit Card', 'Digital Wallet'].map((String acc) {
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
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      GestureDetector(
                        onTap: () => setDialogState(() {
                          isIncome = false;
                          if (category == 'Salary' || category == 'Investments') category = 'Food & Dining';
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                      GestureDetector(
                        onTap: () => setDialogState(() {
                          isIncome = true;
                          if (category == 'Food & Dining' || category == 'Housing & Rent') category = 'Salary';
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                  final amount = double.tryParse(amountStr);
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
                    
                    final currentList = List<Transaction>.from(transactionsNotifier.value);
                    if (existingTx != null) {
                      final index = currentList.indexWhere((t) => t.id == existingTx.id);
                      if (index != -1) currentList[index] = newTx;
                    } else {
                      currentList.insert(0, newTx);
                    }
                    
                    transactionsNotifier.value = currentList;
                    if (currentUser != null) {
                      saveTransactions(currentUser!, currentList);
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
        }
      );
    },
  );
}

// ----------------------------------------------------
// Dashboard Screen
// ----------------------------------------------------

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  
  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _showBudgetDialog(BuildContext context) {
    String selectedCategory = 'Food & Dining';
    String limitStr = '';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              title: const Text('Edit Budgets'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    dropdownColor: Theme.of(context).colorScheme.surface,
                    style: const TextStyle(color: Colors.white),
                    items: categoryIcons.keys.map((String cat) {
                      return DropdownMenuItem<String>(value: cat, child: Text(cat));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedCategory = val);
                    },
                    decoration: const InputDecoration(labelText: 'Category'),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Limit Amount (\$)'),
                    keyboardType: TextInputType.number,
                    onChanged: (val) => limitStr = val,
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                TextButton(
                  onPressed: () {
                    final limit = double.tryParse(limitStr);
                    if (limit != null && limit > 0) {
                      final currentBudgets = Map<String, double>.from(budgetsNotifier.value);
                      currentBudgets[selectedCategory] = limit;
                      budgetsNotifier.value = currentBudgets;
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text('Save'),
                ),
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
              transactionsNotifier.value = [];
              if (currentUser != null) {
                saveTransactions(currentUser!, []);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Reset', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _logout() {
    currentUser = null;
    transactionsNotifier.value = [];
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
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
            const CircleAvatar(
              radius: 20,
              backgroundColor: Color(0xFF232833),
              child: Icon(Icons.person, color: Colors.white70),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Welcome back,', style: TextStyle(fontSize: 12, color: Colors.white54)),
                Text(currentUser ?? 'Guest', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.currency_exchange, color: Colors.white70),
            tooltip: 'Currency',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => SimpleDialog(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  title: const Text('Select Currency'),
                  children: currencyOptions.entries.map((entry) {
                    return SimpleDialogOption(
                      onPressed: () {
                        currencyNotifier.value = entry.value;
                        setState(() {});
                        Navigator.pop(ctx);
                      },
                      child: Text(entry.key, style: TextStyle(
                        color: currencyNotifier.value == entry.value ? Theme.of(context).colorScheme.primary : Colors.white,
                        fontWeight: currencyNotifier.value == entry.value ? FontWeight.bold : FontWeight.normal,
                      )),
                    );
                  }).toList(),
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
            icon: const Icon(Icons.logout, color: Colors.white70),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: ValueListenableBuilder<List<Transaction>>(
        valueListenable: transactionsNotifier,
        builder: (context, transactions, child) {
          final totalBalance = transactions.fold(0.0, (sum, item) => item.isIncome ? sum + item.amount : sum - item.amount);
          
          return Stack(
            children: [
              Positioned(
                top: -100,
                right: -100,
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
                    )
                  ),
                ),
              ),
              Positioned(
                bottom: -50,
                left: -100,
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
                    )
                  ),
                ),
              ),
              
              SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    const SizedBox(height: 10),
                    SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0, -0.1), end: Offset.zero)
                          .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                right: -20,
                                top: -20,
                                child: Icon(Icons.account_balance_wallet, size: 120, color: Colors.white.withValues(alpha: 0.1)),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Total Balance',
                                    style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${currencyNotifier.value}${totalBalance.toStringAsFixed(2)}',
                                    style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold, letterSpacing: -1),
                                  ),
                                  const SizedBox(height: 20),
                                  const Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('**** **** **** 4812', style: TextStyle(color: Colors.white70, fontSize: 15, letterSpacing: 2)),
                                      Icon(Icons.contactless, color: Colors.white70, size: 28),
                                    ],
                                  )
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Monthly Budgets',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              IconButton(
                                icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.primary, size: 16),
                                onPressed: () => _showBudgetDialog(context),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ValueListenableBuilder<Map<String, double>>(
                            valueListenable: budgetsNotifier,
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
                                            Text(entry.key, style: const TextStyle(color: Colors.white70)),
                                            Text('${currencyNotifier.value}${spent.toStringAsFixed(0)} / ${currencyNotifier.value}${limit.toStringAsFixed(0)}', style: TextStyle(color: percent > 0.9 ? Colors.redAccent : Colors.white)),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        LinearProgressIndicator(
                                          value: percent,
                                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                                          valueColor: AlwaysStoppedAnimation<Color>(percent > 0.9 ? Colors.redAccent : Theme.of(context).colorScheme.secondary),
                                          minHeight: 6,
                                          borderRadius: BorderRadius.circular(3),
                                        )
                                      ],
                                    ),
                                  );
                                }).toList(),
                              );
                            }
                          )
                        ]
                      )
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current Month Flow',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            height: 100,
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                            ),
                            child: CustomPaint(
                              painter: MonthChartPainter(transactions),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recent Transactions',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const AllTransactionsScreen()));
                            },
                            child: Text('See All', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                          )
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 10),
                    transactions.isEmpty 
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(child: Text("No transactions yet", style: TextStyle(color: Colors.white54))),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: transactions.length > 5 ? 5 : transactions.length, 
                          itemBuilder: (ctx, index) {
                            final tx = transactions[index];
                            return TransactionTile(
                              tx: tx,
                              onTap: () => showTransactionDialog(context, existingTx: tx),
                              onDelete: () {
                                final currentList = List<Transaction>.from(transactionsNotifier.value);
                                currentList.removeWhere((t) => t.id == tx.id);
                                transactionsNotifier.value = currentList;
                                if (currentUser != null) {
                                  saveTransactions(currentUser!, currentList);
                                }
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text('${tx.title} deleted'),
                                  action: SnackBarAction(
                                    label: 'Undo',
                                    onPressed: () {
                                      final restoredList = List<Transaction>.from(transactionsNotifier.value);
                                      restoredList.insert(index, tx);
                                      transactionsNotifier.value = restoredList;
                                      if (currentUser != null) {
                                        saveTransactions(currentUser!, restoredList);
                                      }
                                    },
                                  ),
                                ));
                              },
                            );
                          },
                        ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            ],
          );
        }
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showTransactionDialog(context),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 4, 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}

class TransactionTile extends StatelessWidget {
  final Transaction tx;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const TransactionTile({super.key, required this.tx, this.onDelete, this.onTap});

  @override
  Widget build(BuildContext context) {
    Widget tile = Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: tx.isIncome 
                    ? [Colors.greenAccent.withValues(alpha: 0.2), Colors.green.withValues(alpha: 0.2)] 
                    : [Colors.redAccent.withValues(alpha: 0.2), Colors.orangeAccent.withValues(alpha: 0.2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              categoryIcons[tx.category] ?? (tx.isIncome ? Icons.south_west : Icons.north_east),
              color: tx.isIncome ? Colors.greenAccent : Colors.redAccent,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('${tx.category} • ${tx.account}', style: const TextStyle(color: Colors.white54, fontSize: 13)),
                    if (tx.recurrence != 'None') ...[
                      const SizedBox(width: 4),
                      Icon(Icons.repeat, size: 12, color: Theme.of(context).colorScheme.primary),
                    ]
                  ],
                ),
                const SizedBox(height: 2),
                Text('${_formatDate(tx.date)} • ${_formatTime(tx.date)}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          Text(
            '${tx.isIncome ? '+' : '-'}${currencyNotifier.value}${tx.amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: tx.isIncome ? Colors.greenAccent : Colors.white,
            ),
          )
        ],
      ),
    );

    if (onTap != null) {
      tile = GestureDetector(onTap: onTap, child: tile);
    }

    if (onDelete != null) {
      tile = Dismissible(
        key: Key(tx.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDelete!(),
        background: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.redAccent,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        child: tile,
      );
    }
    
    return tile;
  }
}

class MonthChartPainter extends CustomPainter {
  final List<Transaction> transactions;
  
  MonthChartPainter(this.transactions);

  @override
  void paint(Canvas canvas, Size size) {
    if (transactions.isEmpty) {
      final paint = Paint()..color = const Color(0xFF8B5CF6).withValues(alpha: 0.3)..strokeWidth = 3..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(0, size.height/2), Offset(size.width, size.height/2), paint);
      return;
    }
    
    final now = DateTime.now();
    final thisMonthTx = transactions.where((t) => t.date.year == now.year && t.date.month == now.month).toList();
    
    int daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    List<double> dailyBalances = List.filled(daysInMonth, 0.0);
    
    for (var tx in thisMonthTx) {
      int dayIndex = tx.date.day - 1;
      dailyBalances[dayIndex] += tx.isIncome ? tx.amount : -tx.amount;
    }
    
    double current = 0;
    for (int i = 0; i < daysInMonth; i++) {
      current += dailyBalances[i];
      dailyBalances[i] = current;
    }
    
    final paint = Paint()
      ..color = const Color(0xFF8B5CF6)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
      
    final maxBal = dailyBalances.reduce(max);
    final minBal = dailyBalances.reduce(min);
    final range = max(maxBal - minBal, 1.0);
    
    final path = Path();
    final widthStep = size.width / (daysInMonth - 1).clamp(1, 31);
    
    for (int i = 0; i < now.day; i++) {
      final x = i * widthStep;
      final normalizedY = (dailyBalances[i] - minBal) / range;
      final y = size.height - (normalizedY * size.height * 0.8) - (size.height * 0.1);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(MonthChartPainter oldDelegate) => true;
}

class PieChartPainter extends CustomPainter {
  final double income;
  final double expense;

  PieChartPainter(this.income, this.expense);

  @override
  void paint(Canvas canvas, Size size) {
    final total = income + expense;
    if (total == 0) {
       canvas.drawCircle(Offset(size.width / 2, size.height / 2), min(size.width, size.height) / 2, Paint()..color = Colors.white10..style = PaintingStyle.stroke..strokeWidth = 20);
       return;
    }

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 25; 

    final incomeAngle = (income / total) * 2 * pi;

    final paintIncome = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.butt;

    final paintExpense = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.butt;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2, 2 * pi, false, paintExpense
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2, incomeAngle, false, paintIncome
    );

    void drawAmountLabel(String text, double angle, Color color) {
      final textPainter = TextPainter(
        text: TextSpan(text: text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13, shadows: const [Shadow(blurRadius: 3, color: Colors.black)])),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      final labelRadius = radius + 32; 
      final x = center.dx + labelRadius * cos(angle) - textPainter.width / 2;
      final y = center.dy + labelRadius * sin(angle) - textPainter.height / 2;
      textPainter.paint(canvas, Offset(x, y));
    }

    if (income > 0) {
      drawAmountLabel('+${currencyNotifier.value}${income.toStringAsFixed(0)}', -pi / 2 + incomeAngle / 2, Colors.greenAccent);
    }
    if (expense > 0) {
      drawAmountLabel('-${currencyNotifier.value}${expense.toStringAsFixed(0)}', -pi / 2 + incomeAngle + (2 * pi - incomeAngle) / 2, Colors.redAccent);
    }
  }

  @override
  bool shouldRepaint(PieChartPainter oldDelegate) => true;
}

class AllTransactionsScreen extends StatefulWidget {
  const AllTransactionsScreen({super.key});

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  String _filter = 'All'; 
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: ValueListenableBuilder<List<Transaction>>(
        valueListenable: transactionsNotifier,
        builder: (context, transactions, child) {
          
          final double totalIncome = transactions.where((t) => t.isIncome).fold(0, (sum, t) => sum + t.amount);
          final double totalExpense = transactions.where((t) => !t.isIncome).fold(0, (sum, t) => sum + t.amount);
          
          final filtered = transactions.where((t) {
            bool matchesFilter = true;
            if (_filter == 'Income') matchesFilter = t.isIncome;
            if (_filter == 'Expense') matchesFilter = !t.isIncome;
            
            bool matchesSearch = t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                                 t.category.toLowerCase().contains(_searchQuery.toLowerCase());
                                 
            return matchesFilter && matchesSearch;
          }).toList();

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: 180, height: 180,
                      child: CustomPaint(painter: PieChartPainter(totalIncome, totalExpense)),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            const Text('Total Income', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(width: 32),
                        Row(
                          children: [
                            Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            const Text('Total Expense', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    )
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search transactions...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              const SizedBox(height: 15),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: ['All', 'Income', 'Expense'].map((type) {
                    final isSelected = _filter == type;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ChoiceChip(
                        label: Text(type, style: TextStyle(color: isSelected ? Colors.white : Colors.white70)),
                        selected: isSelected,
                        selectedColor: Theme.of(context).colorScheme.primary,
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        onSelected: (val) {
                          setState(() { _filter = type; });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 10),

              Expanded(
                child: filtered.isEmpty
                  ? const Center(child: Text("No transactions found", style: TextStyle(color: Colors.white54)))
                  : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, index) {
                      final tx = filtered[index];
                      return TransactionTile(
                        tx: tx,
                        onTap: () => showTransactionDialog(context, existingTx: tx),
                        onDelete: () {
                          final currentList = List<Transaction>.from(transactionsNotifier.value);
                          currentList.removeWhere((t) => t.id == tx.id);
                          transactionsNotifier.value = currentList;
                          if (currentUser != null) {
                            saveTransactions(currentUser!, currentList);
                          }
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('${tx.title} deleted'),
                            action: SnackBarAction(
                              label: 'Undo',
                              onPressed: () {
                                final restoredList = List<Transaction>.from(transactionsNotifier.value);
                                restoredList.add(tx);
                                restoredList.sort((a, b) => b.date.compareTo(a.date));
                                transactionsNotifier.value = restoredList;
                                if (currentUser != null) {
                                  saveTransactions(currentUser!, restoredList);
                                }
                              },
                            ),
                          ));
                        },
                      );
                    },
                  ),
              )
            ],
          );
        }
      ),
    );
  }
}

// ----------------------------------------------------
// Insights Screen (Tier 2)
// ----------------------------------------------------

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Insights', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: ValueListenableBuilder<List<Transaction>>(
        valueListenable: transactionsNotifier,
        builder: (context, transactions, _) {
          if (transactions.isEmpty) {
            return const Center(child: Text('Add some transactions to see insights!', style: TextStyle(color: Colors.white54)));
          }

          final now = DateTime.now();
          final thisMonth = transactions.where((t) => t.date.year == now.year && t.date.month == now.month).toList();
          final lastMonth = transactions.where((t) => t.date.year == now.year && t.date.month == now.month - 1).toList();

          final thisMonthExpense = thisMonth.where((t) => !t.isIncome).fold(0.0, (s, t) => s + t.amount);
          final lastMonthExpense = lastMonth.where((t) => !t.isIncome).fold(0.0, (s, t) => s + t.amount);
          final thisMonthIncome = thisMonth.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);

          final daysElapsed = now.day;
          final dailyAvg = daysElapsed > 0 ? thisMonthExpense / daysElapsed : 0.0;

          final biggestExpense = thisMonth.where((t) => !t.isIncome).toList()
            ..sort((a, b) => b.amount.compareTo(a.amount));

          final savingsRate = thisMonthIncome > 0 ? ((thisMonthIncome - thisMonthExpense) / thisMonthIncome * 100).clamp(-100.0, 100.0) : 0.0;

          final spendingChange = lastMonthExpense > 0 ? ((thisMonthExpense - lastMonthExpense) / lastMonthExpense * 100) : 0.0;

          // Category breakdown
          final Map<String, double> catSpending = {};
          for (var t in thisMonth.where((t) => !t.isIncome)) {
            catSpending[t.category] = (catSpending[t.category] ?? 0) + t.amount;
          }
          final sortedCats = catSpending.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Cards Row
                Row(
                  children: [
                    Expanded(child: _insightCard(context, 'Daily Avg', '${currencyNotifier.value}${dailyAvg.toStringAsFixed(0)}', Icons.calendar_today, const Color(0xFF3B82F6))),
                    const SizedBox(width: 12),
                    Expanded(child: _insightCard(context, 'Savings Rate', '${savingsRate.toStringAsFixed(0)}%', Icons.savings, savingsRate >= 0 ? Colors.greenAccent : Colors.redAccent)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _insightCard(context, 'This Month', '${currencyNotifier.value}${thisMonthExpense.toStringAsFixed(0)}', Icons.shopping_bag, Colors.orangeAccent)),
                    const SizedBox(width: 12),
                    Expanded(child: _insightCard(context, 'vs Last Month', '${spendingChange >= 0 ? '+' : ''}${spendingChange.toStringAsFixed(0)}%', Icons.trending_up, spendingChange <= 0 ? Colors.greenAccent : Colors.redAccent)),
                  ],
                ),

                const SizedBox(height: 24),
                const Text('Top Expense', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 10),
                if (biggestExpense.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF1E1B4B), Color(0xFF312E81)]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(categoryIcons[biggestExpense.first.category] ?? Icons.receipt, color: Colors.redAccent, size: 32),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(biggestExpense.first.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                              Text(biggestExpense.first.category, style: const TextStyle(color: Colors.white54)),
                            ],
                          ),
                        ),
                        Text('-${currencyNotifier.value}${biggestExpense.first.amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),
                const Text('Category Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 10),
                ...sortedCats.map((entry) {
                  final pct = thisMonthExpense > 0 ? entry.value / thisMonthExpense : 0.0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(children: [
                              Icon(categoryIcons[entry.key] ?? Icons.category, size: 16, color: Colors.white70),
                              const SizedBox(width: 8),
                              Text(entry.key, style: const TextStyle(color: Colors.white70)),
                            ]),
                            Text('${currencyNotifier.value}${entry.value.toStringAsFixed(0)} (${(pct * 100).toStringAsFixed(0)}%)', style: const TextStyle(color: Colors.white)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: pct,
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _insightCard(BuildContext context, String label, String value, IconData icon, Color accent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 24),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: accent)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// Goals & Savings Tracker (Tier 2)
// ----------------------------------------------------

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  void _showAddGoalDialog(BuildContext context) {
    String title = '';
    String targetStr = '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('New Savings Goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Goal Name'),
              onChanged: (v) => title = v,
            ),
            const SizedBox(height: 15),
            TextField(
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Target Amount (\$)'),
              keyboardType: TextInputType.number,
              onChanged: (v) => targetStr = v,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final target = double.tryParse(targetStr);
              if (title.isNotEmpty && target != null && target > 0) {
                final goals = List<SavingsGoal>.from(goalsNotifier.value);
                goals.add(SavingsGoal(title: title, target: target));
                goalsNotifier.value = goals;
                if (currentUser != null) saveGoals(currentUser!, goals);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showAddFundsDialog(BuildContext context, SavingsGoal goal) {
    String amountStr = '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text('Add to "${goal.title}"'),
        content: TextField(
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(labelText: 'Amount (\$)'),
          keyboardType: TextInputType.number,
          onChanged: (v) => amountStr = v,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final amount = double.tryParse(amountStr);
              if (amount != null && amount > 0) {
                final goals = List<SavingsGoal>.from(goalsNotifier.value);
                final idx = goals.indexWhere((g) => g.id == goal.id);
                if (idx != -1) {
                  goals[idx].saved = (goals[idx].saved + amount).clamp(0, goals[idx].target);
                  goalsNotifier.value = List.from(goals);
                  if (currentUser != null) saveGoals(currentUser!, goals);
                }
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings Goals', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: ValueListenableBuilder<List<SavingsGoal>>(
        valueListenable: goalsNotifier,
        builder: (context, goals, _) {
          if (goals.isEmpty) {
            return const Center(child: Text('No goals yet. Tap + to create one!', style: TextStyle(color: Colors.white54)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: goals.length,
            itemBuilder: (ctx, index) {
              final goal = goals[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          const Icon(Icons.flag, color: Color(0xFF8B5CF6)),
                          const SizedBox(width: 10),
                          Text(goal.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        ]),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                          onPressed: () {
                            final g = List<SavingsGoal>.from(goalsNotifier.value);
                            g.removeWhere((x) => x.id == goal.id);
                            goalsNotifier.value = g;
                            if (currentUser != null) saveGoals(currentUser!, g);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Progress ring
                    Center(
                      child: SizedBox(
                        width: 120, height: 120,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 120, height: 120,
                              child: CircularProgressIndicator(
                                value: goal.progress,
                                strokeWidth: 10,
                                backgroundColor: Colors.white.withValues(alpha: 0.1),
                                valueColor: AlwaysStoppedAnimation<Color>(goal.progress >= 1.0 ? Colors.greenAccent : const Color(0xFF8B5CF6)),
                              ),
                            ),
                            Text('${(goal.progress * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${currencyNotifier.value}${goal.saved.toStringAsFixed(0)} saved', style: const TextStyle(color: Colors.greenAccent)),
                        Text('${currencyNotifier.value}${goal.target.toStringAsFixed(0)} target', style: const TextStyle(color: Colors.white54)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: goal.progress >= 1.0 ? null : () => _showAddFundsDialog(context, goal),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: goal.progress >= 1.0 ? Colors.greenAccent : const Color(0xFF8B5CF6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(goal.progress >= 1.0 ? '🎉 Goal Reached!' : 'Add Funds', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddGoalDialog(context),
        backgroundColor: Theme.of(context).colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// ----------------------------------------------------
// Accounts Screen (Tier 2)
// ----------------------------------------------------

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  String _selectedAccount = 'Main';

  @override
  Widget build(BuildContext context) {
    final accounts = ['Main', 'Cash', 'Credit Card', 'Digital Wallet'];
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts & Wallets', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: ValueListenableBuilder<List<Transaction>>(
        valueListenable: transactionsNotifier,
        builder: (context, transactions, _) {
          
          Map<String, double> balances = {};
          Map<String, double> spent = {};
          
          for (var acc in accounts) {
            final accTxs = transactions.where((t) => t.account == acc).toList();
            final income = accTxs.where((t) => t.isIncome).fold(0.0, (sum, t) => sum + t.amount);
            final expense = accTxs.where((t) => !t.isIncome).fold(0.0, (sum, t) => sum + t.amount);
            balances[acc] = income - expense;
            spent[acc] = expense;
          }

          final filteredTxs = transactions.where((t) => t.account == _selectedAccount).toList();

          return Column(
            children: [
              SizedBox(
                height: 130,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: accounts.length,
                  itemBuilder: (ctx, index) {
                    final acc = accounts[index];
                    final isSelected = _selectedAccount == acc;
                    final bal = balances[acc] ?? 0.0;
                    final sp = spent[acc] ?? 0.0;
                    
                    return GestureDetector(
                      onTap: () => setState(() => _selectedAccount = acc),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(16),
                        width: 170,
                        decoration: BoxDecoration(
                          color: isSelected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2) : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isSelected ? Theme.of(context).colorScheme.primary : Colors.white.withValues(alpha: 0.05)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(acc, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.white70)),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${currencyNotifier.value}${bal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                const SizedBox(height: 4),
                                Text('Spent: ${currencyNotifier.value}${sp.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: Colors.white54)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text('Transactions: $_selectedAccount', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              
              Expanded(
                child: filteredTxs.isEmpty
                  ? const Center(child: Text("No transactions for this account", style: TextStyle(color: Colors.white54)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: filteredTxs.length,
                      itemBuilder: (ctx, index) {
                        final tx = filteredTxs[index];
                        return TransactionTile(
                          tx: tx,
                          onTap: () => showTransactionDialog(context, existingTx: tx),
                          onDelete: () {
                            final currentList = List<Transaction>.from(transactionsNotifier.value);
                            currentList.removeWhere((t) => t.id == tx.id);
                            transactionsNotifier.value = currentList;
                            if (currentUser != null) {
                              saveTransactions(currentUser!, currentList);
                            }
                          },
                        );
                      },
                    ),
              )
            ],
          );
        },
      ),
    );
  }
}

// ----------------------------------------------------
// Main Navigation Shell (Bottom Nav)
// ----------------------------------------------------

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});
  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    InsightsScreen(),
    GoalsScreen(),
    AccountsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: Theme.of(context).colorScheme.surface,
        indicatorColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.insights), label: 'Insights'),
          NavigationDestination(icon: Icon(Icons.flag), label: 'Goals'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet), label: 'Accounts'),
        ],
      ),
    );
  }
}
