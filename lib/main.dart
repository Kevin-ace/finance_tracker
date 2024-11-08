import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const PersonalFinanceTrackerApp());
}

class PersonalFinanceTrackerApp extends StatelessWidget {
  const PersonalFinanceTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personal Finance Tracker',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.green[50],
        textTheme: const TextTheme(
          headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(fontSize: 16),
        ),
      ),
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final List<Map<String, dynamic>> _transactions = [];
  final List<String> _categories = ['Food', 'Transport', 'Entertainment', 'Other'];
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? transactionsString = prefs.getString('transactions');
    if (transactionsString != null) {
      setState(() {
        _transactions.addAll(List<Map<String, dynamic>>.from(json.decode(transactionsString)));
      });
    }
  }

  Future<void> _saveTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('transactions', json.encode(_transactions));
  }

  void _addTransaction(String title, double amount, String category) {
    setState(() {
      _transactions.add({
        'title': title,
        'amount': amount,
        'category': category,
        'date': DateTime.now().toString(),
      });
    });
    _saveTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          DropdownButton<String>(
            value: _selectedCategory,
            items: ['All', ..._categories].map((String category) {
              return DropdownMenuItem<String>(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedCategory = newValue!;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSummaryCard(),
          _buildTransactionList(),
          _buildChart(),
          _buildAnalyticsSection(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddTransactionDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: const [
            Text('Total Balance: \$1000', style: TextStyle(fontSize: 20)),
            SizedBox(height: 8),
            Text('Income: \$2000', style: TextStyle(color: Colors.green)),
            Text('Expenses: \$1000', style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList() {
    final filteredTransactions = _selectedCategory == 'All'
        ? _transactions
        : _transactions.where((transaction) => transaction['category'] == _selectedCategory).toList();

    return Expanded(
      child: ListView.builder(
        itemCount: filteredTransactions.length,
        itemBuilder: (context, index) {
          final transaction = filteredTransactions[index];
          return ListTile(
            leading: const Icon(Icons.fastfood, color: Colors.orange),
            title: Text(transaction['title']),
            subtitle: Text(transaction['date']),
            trailing: Text('-\$${transaction['amount']}', style: TextStyle(color: Colors.red)),
          );
        },
      ),
    );
  }

  Widget _buildChart() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: [
                  FlSpot(0, 1),
                  FlSpot(1, 3),
                  FlSpot(2, 2),
                  FlSpot(3, 5),
                  FlSpot(4, 3),
                ],
                isCurved: true,
                color: Colors.green,
                barWidth: 4,
                belowBarData: BarAreaData(show: false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsSection() {
    double totalIncome = _transactions
        .where((transaction) => transaction['amount'] > 0)
        .fold(0.0, (sum, transaction) => sum + transaction['amount']);
    double totalExpenses = _transactions
        .where((transaction) => transaction['amount'] < 0)
        .fold(0.0, (sum, transaction) => sum + transaction['amount']);
    Map<String, double> categoryTotals = {};
    for (var category in _categories) {
      categoryTotals[category] = _transactions
          .where((transaction) => transaction['category'] == category)
          .fold(0.0, (sum, transaction) => sum + transaction['amount']);
    }

    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Analytics', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('Total Income: \$${totalIncome.toStringAsFixed(2)}', style: TextStyle(color: Colors.green)),
            Text('Total Expenses: \$${totalExpenses.toStringAsFixed(2)}', style: TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            Text('Category Breakdown:', style: Theme.of(context).textTheme.bodyMedium),
            _buildPieChart(categoryTotals),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(Map<String, double> categoryTotals) {
    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sections: categoryTotals.entries.map((entry) {
            final color = _getCategoryColor(entry.key);
            return PieChartSectionData(
              color: color,
              value: entry.value.abs(),
              title: '${entry.key}: \$${entry.value.toStringAsFixed(2)}',
              radius: 50,
              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Food':
        return Colors.orange;
      case 'Transport':
        return Colors.blue;
      case 'Entertainment':
        return Colors.purple;
      case 'Other':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  void _showAddTransactionDialog(BuildContext context) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    String selectedCategory = _categories.first;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Transaction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType: TextInputType.number,
            ),
            DropdownButton<String>(
              value: selectedCategory,
              items: _categories.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedCategory = newValue!;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final title = titleController.text;
              final amount = double.tryParse(amountController.text) ?? 0.0;
              if (title.isNotEmpty && amount != 0.0) {
                _addTransaction(title, amount, selectedCategory);
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
