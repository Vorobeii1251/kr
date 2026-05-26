import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MoneyVore',
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Colors.teal,
          secondary: Colors.tealAccent,
        ),
      ),
      home: const MoneyVoreHomePage(),
    );
  }
}

// ============================================================================
// МОДЕЛЬ КАТЕГОРИИ
// ============================================================================

class Category {
  final int id;
  final String name;
  final String icon;
  final Color color;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  static const List<Category> defaultCategories = [
    Category(id: 1, name: 'Еда', icon: '🍔', color: Colors.orange),
    Category(id: 2, name: 'Транспорт', icon: '🚗', color: Colors.blue),
    Category(id: 3, name: 'Кафе', icon: '☕', color: Colors.brown),
    Category(id: 4, name: 'Развлечения', icon: '🎬', color: Colors.purple),
    Category(id: 5, name: 'Продукты', icon: '🛒', color: Colors.green),
    Category(id: 6, name: 'Другое', icon: '📦', color: Colors.grey),
  ];
}

// ============================================================================
// МОДЕЛЬ РАСХОДА
// ============================================================================

class Expense {
  final String id;
  final String name;
  final double amount;
  final DateTime date;
  final int categoryId;

  Expense({
    required this.id,
    required this.name,
    required this.amount,
    required this.date,
    required this.categoryId,
  });

  String get formattedDate => DateFormat('dd.MM.yyyy').format(date);

  Category get category {
    return Category.defaultCategories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => Category.defaultCategories.last,
    );
  }
}

// ============================================================================
// ВИДЖЕТ СУММЫ ПО КАТЕГОРИЯМ
// ============================================================================

class CategorySummaryWidget extends StatelessWidget {
  final List<Expense> expenses;

  const CategorySummaryWidget({super.key, required this.expenses});

  Map<String, double> _getCategorySums() {
    final Map<String, double> sums = {};
    for (final expense in expenses) {
      final categoryName = expense.category.name;
      sums[categoryName] = (sums[categoryName] ?? 0) + expense.amount;
    }
    return sums;
  }

  @override
  Widget build(BuildContext context) {
    final categorySums = _getCategorySums();
    
    if (categorySums.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'Нет расходов для отображения',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.pie_chart, size: 16, color: Colors.tealAccent),
              SizedBox(width: 8),
              Text(
                'Сумма по категориям',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.tealAccent),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: Category.defaultCategories.map((category) {
              final sum = categorySums[category.name] ?? 0;
              if (sum == 0) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: category.color.withValues(alpha: 0.5), width: 0.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(category.icon, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(
                      '${sum.toStringAsFixed(0)} ₽',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: category.color),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ГЛАВНЫЙ ЭКРАН
// ============================================================================

class MoneyVoreHomePage extends StatefulWidget {
  const MoneyVoreHomePage({super.key});

  @override
  State<MoneyVoreHomePage> createState() => _MoneyVoreHomePageState();
}

class _MoneyVoreHomePageState extends State<MoneyVoreHomePage> {
  // Данные
  List<Expense> _expenses = [];
  List<Expense> _filteredExpenses = [];
  
  // UI контроллеры
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  // Состояния для поиска и сортировки
  String _searchQuery = '';
  String _sortBy = 'date';
  bool _sortAscending = false;
  int? _selectedCategoryId;
  Expense? _editingExpense;

  @override
  void initState() {
    super.initState();
    _expenses = [];
    _applyFiltersAndSort();
  }

  void _applyFiltersAndSort() {
    var filtered = List<Expense>.from(_expenses);
    
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      final double? amountQuery = double.tryParse(_searchQuery.replaceAll(',', '.'));
      
      filtered = filtered.where((e) {
        if (e.name.toLowerCase().contains(query)) return true;
        if (amountQuery != null && e.amount == amountQuery) return true;
        return false;
      }).toList();
    }
    
    if (_selectedCategoryId != null) {
      filtered = filtered.where((e) => e.categoryId == _selectedCategoryId).toList();
    }
    
    filtered.sort((a, b) {
      int comparison;
      switch (_sortBy) {
        case 'amount':
          comparison = a.amount.compareTo(b.amount);
          break;
        case 'name':
          comparison = a.name.compareTo(b.name);
          break;
        default:
          comparison = a.date.compareTo(b.date);
      }
      return _sortAscending ? comparison : -comparison;
    });
    
    setState(() {
      _filteredExpenses = filtered;
    });
  }

  double get _totalAmount {
    return _filteredExpenses.fold(0.0, (sum, item) => sum + item.amount);
  }

  void _showExpenseForm({Expense? expense}) {
    _editingExpense = expense;
    _nameController.text = expense?.name ?? '';
    _amountController.text = expense?.amount.toString() ?? '';
    _selectedCategoryId = expense?.categoryId ?? 1;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(expense == null ? Icons.add_box : Icons.edit, color: Colors.teal),
                const SizedBox(width: 8),
                Text(expense == null ? 'Новый расход' : 'Редактировать'),
              ],
            ),
            content: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Название',
                      prefixIcon: Icon(Icons.shopping_bag_outlined),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Введите название' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                      labelText: 'Сумма',
                      prefixIcon: Icon(Icons.currency_ruble),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Введите сумму';
                      if (double.tryParse(v) == null) return 'Введите число';
                      if (double.parse(v) < 0) return 'Сумма не может быть отрицательной';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: _selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'Категория',
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: Category.defaultCategories.map((c) {
                      return DropdownMenuItem(
                        value: c.id,
                        child: Text('${c.icon} ${c.name}'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        _selectedCategoryId = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Отмена'),
              ),
              FilledButton.icon(
                onPressed: () => _saveExpense(expense),
                icon: Icon(expense == null ? Icons.save : Icons.update),
                label: Text(expense == null ? 'Сохранить' : 'Обновить'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _saveExpense(Expense? existingExpense) {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final amount = double.parse(_amountController.text);
      
      setState(() {
        if (existingExpense != null) {
          final index = _expenses.indexWhere((e) => e.id == existingExpense.id);
          if (index != -1) {
            _expenses[index] = Expense(
              id: existingExpense.id,
              name: name,
              amount: amount,
              date: existingExpense.date,
              categoryId: _selectedCategoryId!,
            );
          }
        } else {
          _expenses.add(Expense(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: name,
            amount: amount,
            date: DateTime.now(),
            categoryId: _selectedCategoryId!,
          ));
        }
        _applyFiltersAndSort();
      });
      
      Navigator.pop(context);
    }
  }

  void _deleteExpense(Expense expense) {
    setState(() {
      _expenses.removeWhere((e) => e.id == expense.id);
      _applyFiltersAndSort();
    });
  }

  void _navigateToReportScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportScreen(expenses: _expenses),
      ),
    );
  }

  void _showCategoriesManager() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.category, color: Colors.teal),
            SizedBox(width: 8),
            Text('Категории'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: Category.defaultCategories.map((c) => ListTile(
              leading: Text(c.icon, style: const TextStyle(fontSize: 28)),
              title: Text(c.name),
              trailing: const Icon(Icons.check_circle, size: 20, color: Colors.teal),
              subtitle: Text('ID: ${c.id}', style: const TextStyle(fontSize: 12)),
            )).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = _totalAmount;
    final totalFormatted = total.toStringAsFixed(2);
    final totalInteger = total.toInt();
    final totalFraction = total - totalInteger;
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.monetization_on, color: Colors.tealAccent),
            const SizedBox(width: 8),
            const Text('MoneyVore'),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.teal.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('🐷 копилка(коптилка)', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showCategoriesManager,
            icon: const Icon(Icons.category),
            tooltip: 'Категории',
          ),
          IconButton(
            onPressed: _navigateToReportScreen,
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Отчёт',
          ),
        ],
      ),
      body: Column(
        children: [
          // Панель поиска и фильтрации
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: '🔍 Поиск по названию или сумме',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      prefixIcon: Icon(Icons.search, size: 20),
                    ),
                    onChanged: (value) {
                      _searchQuery = value;
                      _applyFiltersAndSort();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<int?>(
                  value: _selectedCategoryId,
                  hint: const Text('📂 Все'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('📂 Все категории')),
                    ...Category.defaultCategories.map((c) => DropdownMenuItem(
                      value: c.id,
                      child: Text('${c.icon} ${c.name}'),
                    )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCategoryId = value;
                      _applyFiltersAndSort();
                    });
                  },
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.sort),
                  tooltip: 'Сортировка',
                  onSelected: (value) {
                    setState(() {
                      if (_sortBy == value) {
                        _sortAscending = !_sortAscending;
                      } else {
                        _sortBy = value;
                        _sortAscending = false;
                      }
                      _applyFiltersAndSort();
                    });
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'date', child: Text('📅 По дате')),
                    PopupMenuItem(value: 'amount', child: Text('💰 По сумме')),
                    PopupMenuItem(value: 'name', child: Text('🔤 По названию')),
                  ],
                ),
              ],
            ),
          ),
          
          // ✅ Сумма по категориям (теперь видна!)
          if (_expenses.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: CategorySummaryWidget(expenses: _filteredExpenses),
            ),
          
          const SizedBox(height: 8),
          
          // Список расходов
          Expanded(
            child: _filteredExpenses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          _expenses.isEmpty ? 'Нет записей' : 'Ничего не найдено',
                          style: const TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        if (_expenses.isEmpty)
                          const SizedBox(height: 8),
                        if (_expenses.isEmpty)
                          const Text(
                            'Нажмите + чтобы добавить расход',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 80), // ↓ Добавил отступ снизу
                    itemCount: _filteredExpenses.length,
                    separatorBuilder: (_, __) => const Divider(height: 0, indent: 16, endIndent: 16),
                    itemBuilder: (context, index) {
                      final expense = _filteredExpenses[index];
                      return Dismissible(
                        key: Key(expense.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete_forever, color: Colors.white),
                        ),
                        confirmDismiss: (_) async {
                          return await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Удалить запись?'),
                              content: Text('Вы уверены, что хотите удалить "${expense.name}"?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Отмена'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                                  child: const Text('Удалить'),
                                ),
                              ],
                            ),
                          );
                        },
                        onDismissed: (_) => _deleteExpense(expense),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: expense.category.color.withValues(alpha: 0.2),
                            child: Text(expense.category.icon, style: const TextStyle(fontSize: 20)),
                          ),
                          title: Text(
                            expense.name,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text('${expense.formattedDate} • ${expense.category.name}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${expense.amount.toStringAsFixed(2)} ₽',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                onPressed: () => _showExpenseForm(expense: expense),
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        ),
                      );
                    },
                  ),
          ),
          
          // Нижняя панель с итогом
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(color: Colors.grey.withValues(alpha: 0.2), width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.attach_money, size: 20, color: Colors.tealAccent),
                    SizedBox(width: 8),
                    Text('ИТОГО', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      totalInteger.toString(),
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    if (totalFraction > 0)
                      Padding(
                        padding: const EdgeInsets.only(left: 2, bottom: 4),
                        child: Text(
                          totalFormatted.split('.')[1],
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ),
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 4),
                      child: Text('₽', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      // ✅ Кнопка добавления поднята и не перекрывает сумму!
      floatingActionButton: FloatingActionButton(
        onPressed: _showExpenseForm,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 4,
        tooltip: 'Добавить расход',
        child: const Icon(Icons.add, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
    );
  }
}

// ============================================================================
// СТРАНИЦА ОТЧЁТОВ
// ============================================================================

class ReportScreen extends StatelessWidget {
  final List<Expense> expenses;

  const ReportScreen({super.key, required this.expenses});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthExpenses = expenses.where((e) => e.date.isAfter(monthStart)).toList();
    final monthTotal = monthExpenses.fold(0.0, (s, e) => s + e.amount);

    final Map<String, double> groupedByCategory = {};
    for (final expense in monthExpenses) {
      final categoryName = expense.category.name;
      groupedByCategory[categoryName] = (groupedByCategory[categoryName] ?? 0) + expense.amount;
    }

    final Map<String, double> groupedByDay = {};
    for (final expense in monthExpenses) {
      final dayKey = expense.formattedDate;
      groupedByDay[dayKey] = (groupedByDay[dayKey] ?? 0) + expense.amount;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Отчёты'),
        centerTitle: true,
        backgroundColor: Colors.teal.shade800,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal.shade800, Colors.teal.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    DateFormat('MMMM yyyy', 'ru').format(now).toUpperCase(),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${monthTotal.toStringAsFixed(2)} ₽',
                    style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const Text(
                    'Всего за месяц',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('📂 Расходы по категориям', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              child: groupedByCategory.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: Text('Нет данных за этот месяц')),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: groupedByCategory.entries.length,
                      separatorBuilder: (_, __) => const Divider(height: 0, indent: 16, endIndent: 16),
                      itemBuilder: (context, index) {
                        final entry = groupedByCategory.entries.elementAt(index);
                        final category = Category.defaultCategories.firstWhere(
                          (c) => c.name == entry.key,
                          orElse: () => Category.defaultCategories.last,
                        );
                        return ListTile(
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: category.color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(child: Text(category.icon, style: const TextStyle(fontSize: 24))),
                          ),
                          title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w500)),
                          trailing: Text(
                            '${entry.value.toStringAsFixed(2)} ₽',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.tealAccent),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 24),
            const Text('📅 Расходы по дням', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              child: groupedByDay.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: Text('Нет данных за этот месяц')),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: groupedByDay.entries.length,
                      separatorBuilder: (_, __) => const Divider(height: 0, indent: 16, endIndent: 16),
                      itemBuilder: (context, index) {
                        final entry = groupedByDay.entries.elementAt(index);
                        return ListTile(
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.teal.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(child: Icon(Icons.calendar_today, size: 22, color: Colors.tealAccent)),
                          ),
                          title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w500)),
                          trailing: Text(
                            '${entry.value.toStringAsFixed(2)} ₽',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 24),
            const Text('📋 Все расходы за месяц', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              child: monthExpenses.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: Text('Нет расходов за этот месяц')),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: monthExpenses.length,
                      separatorBuilder: (_, __) => const Divider(height: 0, indent: 16, endIndent: 16),
                      itemBuilder: (context, index) {
                        final expense = monthExpenses[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: expense.category.color.withValues(alpha: 0.2),
                            child: Text(expense.category.icon, style: const TextStyle(fontSize: 18)),
                          ),
                          title: Text(expense.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: Text(expense.formattedDate),
                          trailing: Text(
                            '${expense.amount.toStringAsFixed(2)} ₽',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.tealAccent),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}