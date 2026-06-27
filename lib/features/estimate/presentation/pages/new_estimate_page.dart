import 'package:flutter/material.dart';
import 'package:billy_way/core/widgets/app_loading_animation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:billy_way/core/theme/app_colors.dart';
import 'package:billy_way/main.dart';
import 'package:billy_way/features/estimate/domain/controllers/estimate_controller.dart';
import 'package:billy_way/features/estimate/data/models/estimate.dart';
import 'package:go_router/go_router.dart';

class NewEstimatePage extends StatefulWidget {
  final Estimate? estimate;

  const NewEstimatePage({super.key, this.estimate});

  @override
  State<NewEstimatePage> createState() => _NewEstimatePageState();
}

class _ItemRow {
  final TextEditingController particularCtr = TextEditingController();
  final TextEditingController qtyCtr = TextEditingController(text: '1');
  final TextEditingController unitCtr = TextEditingController(text: 'PCS');
  final TextEditingController rateCtr = TextEditingController(text: '0');
  final FocusNode focusNode = FocusNode();
  final FocusNode unitFocusNode = FocusNode();

  void dispose() {
    particularCtr.dispose();
    qtyCtr.dispose();
    unitCtr.dispose();
    rateCtr.dispose();
    focusNode.dispose();
    unitFocusNode.dispose();
  }
}

class _NewEstimatePageState extends State<NewEstimatePage> {
  final _formKey = GlobalKey<FormState>();

  final _estimateNoCtrl = TextEditingController();
  final _customerCtrl = TextEditingController();
  final _oldBalanceCtrl = TextEditingController(text: '0.00');
  final _settledAmountCtrl = TextEditingController(text: '0.00');
  final _customerFocusNode = FocusNode();

  DateTime _date = DateTime.now();
  final List<_ItemRow> _rows = [_ItemRow()];
  bool _isSaving = false;

  String _paymentMode = 'cash';
  final _creditDaysCtrl = TextEditingController(text: '0');

  List<EstimateCustomer> _customers = [];
  List<EstimateProduct> _products = [];

  @override
  void initState() {
    super.initState();
    _date = widget.estimate?.date ?? DateTime.now();

    if (widget.estimate != null) {
      _estimateNoCtrl.text = widget.estimate!.estimateNumber;
      _customerCtrl.text = widget.estimate!.customerName;
      _oldBalanceCtrl.text = widget.estimate!.oldBalance.toStringAsFixed(2);
      _settledAmountCtrl.text = widget.estimate!.settledAmount.toStringAsFixed(
        2,
      );
      _paymentMode = widget.estimate!.paymentMode;
      _creditDaysCtrl.text = widget.estimate!.creditDays.toString();

      _rows.clear();
      for (final item in widget.estimate!.items) {
        final row = _ItemRow();
        row.particularCtr.text = item.particular;
        row.qtyCtr.text = item.qty.toString();
        row.unitCtr.text = item.unit;
        row.rateCtr.text = item.rate.toString();
        _rows.add(row);
      }
      if (_rows.isEmpty) _rows.add(_ItemRow());
      _loadData();
    } else {
      _estimateNoCtrl.text = 'Loading...';
      _fetchNextEstimateNumber();
    }

    _setupFocusListeners();
    if (_rows.isNotEmpty) {
      for (int i = 0; i < _rows.length; i++) {
        _setupRowFocusListener(_rows[i], i);
      }
    }
  }

  Future<void> _fetchNextEstimateNumber() async {
    final controller = getIt<EstimateController>();
    final nextNo = await controller.getNextEstimateNumber();
    if (mounted) {
      setState(() {
        _estimateNoCtrl.text = nextNo;
      });
      _loadData();
    }
  }

  Future<void> _loadData() async {
    final controller = getIt<EstimateController>();
    final customers = await controller.getEstimateCustomers();
    final products = await controller.getEstimateProducts();
    if (mounted) {
      setState(() {
        _customers = customers;
        _products = products;
      });
    }
  }

  void _setupFocusListeners() {
    _customerFocusNode.onKeyEvent = (node, event) {
      if (event is KeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.f1) {
          _showAddCustomerDialog();
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.f2) {
          _showCustomerSearchDialog();
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    };
  }

  void _promptAddCustomer(String val) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Not a Valid Customer'),
        content: Text(
          '"$val" does not exist. Would you like to add it as a new Party?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _customerCtrl.clear());
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showAddCustomerDialog(initialName: val);
            },
            child: const Text('Yes, Add'),
          ),
        ],
      ),
    );
  }

  void _setupRowFocusListener(_ItemRow row, int index) {
    row.focusNode.onKeyEvent = (node, event) {
      if (event is KeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.f1) {
          _showAddProductDialog(index);
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.f2) {
          _showProductSearchDialog(index);
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    };

    row.unitFocusNode.onKeyEvent = (node, event) {
      if (event is KeyDownEvent &&
          event.logicalKey == LogicalKeyboardKey.space) {
        _showUnitSelectionDialog((selectedUnit) {
          setState(() => row.unitCtr.text = selectedUnit);
        });
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    };
  }

  void _promptAddProduct(String val, int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Not a Valid Item'),
        content: Text(
          '"$val" does not exist. Would you like to add it as a new Item?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _rows[index].particularCtr.clear());
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showAddProductDialog(index, initialName: val);
            },
            child: const Text('Yes, Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _showUnitSelectionDialog(Function(String) onSelect) async {
    final units = [
      'PCS',
      'KGS',
      'PAC',
      'NOS',
      'PAIR',
      'BOX',
      'LTR',
      'MTR',
      'SET',
    ];
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select Unit'),
        children: units
            .map(
              (u) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, u),
                child: Text(u, style: TextStyle(fontSize: 14.sp)),
              ),
            )
            .toList(),
      ),
    );
    if (selected != null) {
      onSelect(selected);
    }
  }

  @override
  void dispose() {
    _estimateNoCtrl.dispose();
    _customerCtrl.dispose();
    _oldBalanceCtrl.dispose();
    _settledAmountCtrl.dispose();
    _creditDaysCtrl.dispose();
    _customerFocusNode.dispose();
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  double _rowAmount(_ItemRow row) {
    final qty = double.tryParse(row.qtyCtr.text) ?? 0;
    final rate = double.tryParse(row.rateCtr.text) ?? 0;
    return qty * rate;
  }

  double get _subtotal => _rows.fold(0, (sum, r) => sum + _rowAmount(r));
  double get _oldBalance => double.tryParse(_oldBalanceCtrl.text) ?? 0;
  double get _total => _subtotal + _oldBalance;
  double get _settledAmount => double.tryParse(_settledAmountCtrl.text) ?? 0;
  double get _balance => _total - _settledAmount;

  Future<void> _showAddCustomerDialog({String? initialName}) async {
    final nameCtrl = TextEditingController(text: initialName ?? '');
    final obCtrl = TextEditingController(text: '0');

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('New Estimate Party'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Party Name'),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: obCtrl,
              decoration: const InputDecoration(labelText: 'Old Balance (OB)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty) return;

              final name = nameCtrl.text.trim();
              final exists = _customers.any(
                (c) => c.name.toLowerCase() == name.toLowerCase(),
              );
              if (exists) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Party already exists!'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              final newCustomer = EstimateCustomer(
                name: name,
                ob: double.tryParse(obCtrl.text) ?? 0,
              );
              Navigator.pop(dialogContext);

              try {
                final saved = await getIt<EstimateController>()
                    .createEstimateCustomer(newCustomer);
                if (saved != null && mounted) {
                  setState(() {
                    _customers.add(saved);
                    _customerCtrl.text = saved.name;
                    _oldBalanceCtrl.text = saved.ob.toStringAsFixed(2);
                  });
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error saving party: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddProductDialog(
    int rowIndex, {
    String? initialName,
  }) async {
    final nameCtrl = TextEditingController(text: initialName ?? '');
    final unitCtrl = TextEditingController(text: 'PCS');
    final rateCtrl = TextEditingController(text: '0');

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('New Estimate Product'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Particulars'),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Builder(
              builder: (ctx) {
                final FocusNode unitDialogFocusNode = FocusNode();
                unitDialogFocusNode.onKeyEvent = (node, event) {
                  if (event is KeyDownEvent &&
                      event.logicalKey == LogicalKeyboardKey.space) {
                    _showUnitSelectionDialog((u) => unitCtrl.text = u);
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                };
                return TextFormField(
                  controller: unitCtrl,
                  focusNode: unitDialogFocusNode,
                  decoration: const InputDecoration(
                    labelText: 'Unit (Press Spacebar to select)',
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: rateCtrl,
              decoration: const InputDecoration(labelText: 'Rate'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty) return;

              final name = nameCtrl.text.trim();
              final exists = _products.any(
                (p) => p.particular.toLowerCase() == name.toLowerCase(),
              );
              if (exists) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Item already exists!'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              final newProduct = EstimateProduct(
                particular: name,
                unit: unitCtrl.text,
                rate: double.tryParse(rateCtrl.text) ?? 0,
              );
              Navigator.pop(dialogContext);

              try {
                final saved = await getIt<EstimateController>()
                    .createEstimateProduct(newProduct);
                if (saved != null && mounted) {
                  setState(() {
                    _products.add(saved);
                    _rows[rowIndex].particularCtr.text = saved.particular;
                    _rows[rowIndex].unitCtr.text = saved.unit;
                    _rows[rowIndex].rateCtr.text = saved.rate.toStringAsFixed(
                      2,
                    );
                  });
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error saving product: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCustomerSearchDialog() async {
    final searchCtrl = TextEditingController();
    final filteredNotifier = ValueNotifier<List<EstimateCustomer>>(
      List.from(_customers),
    );

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Search Customers'),
          content: SizedBox(
            width: 400,
            height: 400,
            child: Column(
              children: [
                TextField(
                  controller: searchCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Search...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  autofocus: true,
                  onChanged: (v) {
                    filteredNotifier.value = _customers
                        .where(
                          (c) => c.name.toLowerCase().contains(v.toLowerCase()),
                        )
                        .toList();
                  },
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ValueListenableBuilder<List<EstimateCustomer>>(
                    valueListenable: filteredNotifier,
                    builder: (context, filtered, child) {
                      return ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final c = filtered[index];
                          return ListTile(
                            title: Text(c.name),
                            subtitle: Text('OB: ${c.ob.toStringAsFixed(2)}'),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.edit,
                                size: 18,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: () {
                                Navigator.pop(context); // close search dialog
                                _showEditCustomerDialog(c);
                              },
                            ),
                            onTap: () {
                              setState(() {
                                _customerCtrl.text = c.name;
                                _oldBalanceCtrl.text = c.ob.toStringAsFixed(2);
                              });
                              Navigator.pop(context);
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showProductSearchDialog(int rowIndex) async {
    final searchCtrl = TextEditingController();
    final filteredNotifier = ValueNotifier<List<EstimateProduct>>(
      List.from(_products),
    );

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Search Products'),
          content: SizedBox(
            width: 400,
            height: 400,
            child: Column(
              children: [
                TextField(
                  controller: searchCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Search...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  autofocus: true,
                  onChanged: (v) {
                    filteredNotifier.value = _products
                        .where(
                          (p) => p.particular.toLowerCase().contains(
                            v.toLowerCase(),
                          ),
                        )
                        .toList();
                  },
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ValueListenableBuilder<List<EstimateProduct>>(
                    valueListenable: filteredNotifier,
                    builder: (context, filtered, child) {
                      return ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final p = filtered[index];
                          return ListTile(
                            title: Text(p.particular),
                            subtitle: Text(
                              'Rate: ${p.rate.toStringAsFixed(2)} | Unit: ${p.unit}',
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.edit,
                                size: 18,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: () {
                                Navigator.pop(context); // close search dialog
                                _showEditProductDialog(p);
                              },
                            ),
                            onTap: () {
                              setState(() {
                                _rows[rowIndex].particularCtr.text =
                                    p.particular;
                                _rows[rowIndex].unitCtr.text = p.unit;
                                _rows[rowIndex].rateCtr.text = p.rate
                                    .toStringAsFixed(2);
                              });
                              Navigator.pop(context);
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditCustomerDialog(EstimateCustomer customer) async {
    final nameCtrl = TextEditingController(text: customer.name);
    final obCtrl = TextEditingController(text: customer.ob.toString());

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Party'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Party Name'),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: obCtrl,
              decoration: const InputDecoration(labelText: 'Old Balance (OB)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty) return;
              final name = nameCtrl.text.trim();

              // Check dupes only if name changed
              if (name.toLowerCase() != customer.name.toLowerCase()) {
                final exists = _customers.any(
                  (c) => c.name.toLowerCase() == name.toLowerCase(),
                );
                if (exists) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Party already exists!'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }
              }

              final updatedCustomer = EstimateCustomer(
                id: customer.id,
                name: name,
                ob: double.tryParse(obCtrl.text) ?? 0,
              );
              Navigator.pop(dialogContext);

              try {
                final saved = await getIt<EstimateController>()
                    .updateEstimateCustomer(updatedCustomer);
                if (saved != null && mounted) {
                  setState(() {
                    final index = _customers.indexWhere(
                      (c) => c.id == saved.id,
                    );
                    if (index != -1) {
                      _customers[index] = saved;
                    }
                    if (_customerCtrl.text == customer.name) {
                      _customerCtrl.text = saved.name;
                      _oldBalanceCtrl.text = saved.ob.toStringAsFixed(2);
                    }
                  });
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating party: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditProductDialog(EstimateProduct product) async {
    final nameCtrl = TextEditingController(text: product.particular);
    final unitCtrl = TextEditingController(text: product.unit);
    final rateCtrl = TextEditingController(text: product.rate.toString());

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Particulars'),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Builder(
              builder: (ctx) {
                final FocusNode unitDialogFocusNode = FocusNode();
                unitDialogFocusNode.onKeyEvent = (node, event) {
                  if (event is KeyDownEvent &&
                      event.logicalKey == LogicalKeyboardKey.space) {
                    _showUnitSelectionDialog((u) => unitCtrl.text = u);
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                };
                return TextFormField(
                  controller: unitCtrl,
                  focusNode: unitDialogFocusNode,
                  decoration: const InputDecoration(
                    labelText: 'Unit (Press Spacebar to select)',
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: rateCtrl,
              decoration: const InputDecoration(labelText: 'Rate'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty) return;
              final name = nameCtrl.text.trim();

              if (name.toLowerCase() != product.particular.toLowerCase()) {
                final exists = _products.any(
                  (p) => p.particular.toLowerCase() == name.toLowerCase(),
                );
                if (exists) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Item already exists!'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }
              }

              final updatedProduct = EstimateProduct(
                id: product.id,
                particular: name,
                unit: unitCtrl.text,
                rate: double.tryParse(rateCtrl.text) ?? 0,
              );
              Navigator.pop(dialogContext);

              try {
                final saved = await getIt<EstimateController>()
                    .updateEstimateProduct(updatedProduct);
                if (saved != null && mounted) {
                  setState(() {
                    final index = _products.indexWhere((p) => p.id == saved.id);
                    if (index != -1) {
                      _products[index] = saved;
                    }
                    for (var row in _rows) {
                      if (row.particularCtr.text == product.particular) {
                        row.particularCtr.text = saved.particular;
                        row.unitCtr.text = saved.unit;
                        row.rateCtr.text = saved.rate.toStringAsFixed(2);
                      }
                    }
                  });
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating item: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(Estimate savedEstimate) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success),
            SizedBox(width: 8),
            Text('Estimate Saved'),
          ],
        ),
        content: const Text(
          'Your estimate has been successfully saved. What would you like to do next?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
            },
            child: const Text('Edit'),
          ),
          PopupMenuButton<String>(
            child: TextButton(
              onPressed: null, // Disable default press, let popup handle it
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.print, size: 18),
                  SizedBox(width: 4),
                  Text('Print'),
                  Icon(Icons.arrow_drop_down, size: 18),
                ],
              ),
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'A4', child: Text('Print A4')),
              const PopupMenuItem(value: 'A5', child: Text('Print A5')),
              const PopupMenuItem(value: 'A6', child: Text('Print A6')),
              const PopupMenuItem(
                value: 'POS',
                child: Text('Print POS (Thermal)'),
              ),
            ],
            onSelected: (format) {
              _printEstimate(format, savedEstimate);
            },
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              context.pop(); // Go back to Estimate Page
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _printEstimate(String format, Estimate estimate) {
    Navigator.of(context, rootNavigator: true).pop(); // Force close the dialog

    // Navigate to PDF preview
    context.push(
      '/estimate-preview',
      extra: {
        'estimate': estimate,
        'formatType': format,
        'fromNewEstimate': true,
      },
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final items = _rows
          .where((r) => r.particularCtr.text.isNotEmpty)
          .map(
            (r) => EstimateItem(
              particular: r.particularCtr.text,
              qty: double.tryParse(r.qtyCtr.text) ?? 1,
              unit: r.unitCtr.text,
              rate: double.tryParse(r.rateCtr.text) ?? 0,
              amount: _rowAmount(r),
            ),
          )
          .toList();

      if (items.isEmpty) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please enter at least one item.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final estimate = Estimate(
        id: widget.estimate?.id ?? '',
        estimateNumber: _estimateNoCtrl.text,
        date: _date,
        customerName: _customerCtrl.text,
        items: items,
        subtotal: _subtotal,
        oldBalance: _oldBalance,
        total: _total,
        settledAmount: _settledAmount,
        balance: _balance,
        paymentMode: _paymentMode,
        creditDays: _paymentMode == 'credit'
            ? (int.tryParse(_creditDaysCtrl.text) ?? 0)
            : 0,
        status: _paymentMode == 'credit' ? 'pending' : 'cleared',
      );

      final controller = getIt<EstimateController>();
      final savedEstimate = widget.estimate != null
          ? await controller.updateEstimate(estimate)
          : await controller.saveEstimate(estimate);

      if (mounted) {
        if (savedEstimate != null) {
          _showSuccessDialog(savedEstimate);
        } else {
          // Fallback if save returned null
          _showSuccessDialog(estimate);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24.w),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    SizedBox(height: 24.h),
                    _buildHeaderCard(),
                    SizedBox(height: 16.h),
                    _buildItemsCard(),
                    SizedBox(height: 16.h),
                    _buildSummaryCard(),
                    SizedBox(height: 80.h),
                  ],
                ),
              ),
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/estimates'),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            widget.estimate != null
                ? 'Edit Estimate Bill'
                : 'New Estimate Bill',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCard() {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    final estimateNoField = _labelField('Estimate No.', _estimateNoCtrl);

    final customerField = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            RichText(
              text: TextSpan(
                text: 'Customer Name (M/s)',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
                children: [
                  TextSpan(
                    text: ' *',
                    style: TextStyle(color: AppColors.error),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Press Ctrl+F1 to Create | Ctrl+F2 to List',
                style: TextStyle(fontSize: 10.sp, color: AppColors.primary),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Autocomplete<EstimateCustomer>(
          displayStringForOption: (option) => option.name,
          optionsBuilder: (textEditingValue) {
            if (textEditingValue.text.trim().isEmpty) return _customers;
            return _customers.where(
              (c) => c.name.toLowerCase().contains(
                textEditingValue.text.toLowerCase(),
              ),
            );
          },
          onSelected: (selection) {
            setState(() {
              _customerCtrl.text = selection.name;
              _oldBalanceCtrl.text = selection.ob.toStringAsFixed(2);
            });
          },
          fieldViewBuilder:
              (context, controller, focusNode, onEditingComplete) {
                if (controller.text != _customerCtrl.text) {
                  controller.text = _customerCtrl.text;
                }
                focusNode.onKeyEvent = _customerFocusNode.onKeyEvent;
                return Focus(
                  onFocusChange: (hasFocus) {
                    if (!hasFocus && mounted) {
                      final val = controller.text.trim();
                      if (val.isNotEmpty) {
                        final exists = _customers.any(
                          (c) => c.name.toLowerCase() == val.toLowerCase(),
                        );
                        if (!exists) {
                          _promptAddCustomer(val);
                        }
                      }
                    }
                  },
                  child: TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      hintText: 'Search or type customer...',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.list_alt),
                            onPressed: _showCustomerSearchDialog,
                            tooltip: 'List/Edit Parties (Ctrl+F2)',
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: _showAddCustomerDialog,
                            tooltip: 'Create Party (Ctrl+F1)',
                          ),
                        ],
                      ),
                    ),
                    onChanged: (val) {
                      _customerCtrl.text = val;
                    },
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                );
              },
        ),
      ],
    );

    final dateField = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 8.h),
        InkWell(
          onTap: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: _date,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (d != null) setState(() => _date = d);
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(DateFormat('dd MMM yyyy').format(_date)),
          ),
        ),
      ],
    );

    return Card(
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 20.w : 16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Details',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.h),
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: estimateNoField),
                  SizedBox(width: 16.w),
                  Expanded(flex: 2, child: customerField),
                  SizedBox(width: 16.w),
                  Expanded(child: dateField),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  estimateNoField,
                  SizedBox(height: 16.h),
                  customerField,
                  SizedBox(height: 16.h),
                  dateField,
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 12.w,
                    runSpacing: 8.h,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Items',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Press F1 on Particulars to Create Product',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    final row = _ItemRow();
                    setState(() => _rows.add(row));
                    _setupRowFocusListener(row, _rows.length - 1);
                  },
                  icon: Icon(Icons.add, size: 16.sp),
                  label: const Text('Add Row'),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;

                if (isMobile) {
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _rows.length,
                    itemBuilder: (context, i) {
                      if (_rows[i].focusNode.onKeyEvent == null) {
                        _setupRowFocusListener(_rows[i], i);
                      }
                      return _buildMobileItemCard(i);
                    },
                  );
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: constraints.maxWidth < 800
                          ? 800
                          : constraints.maxWidth,
                    ),
                    child: SizedBox(
                      width: constraints.maxWidth < 800
                          ? 800
                          : constraints.maxWidth,
                      child: Column(
                        children: [
                          _buildTableHeader(),
                          const Divider(height: 1),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _rows.length,
                            separatorBuilder: (_, __) =>
                                Divider(height: 1, color: AppColors.divider),
                            itemBuilder: (_, i) {
                              if (_rows[i].focusNode.onKeyEvent == null) {
                                _setupRowFocusListener(_rows[i], i);
                              }
                              return _buildItemRow(i);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileItemCard(int i) {
    final row = _rows[i];
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Autocomplete<EstimateProduct>(
                  displayStringForOption: (option) => option.particular,
                  optionsBuilder: (textEditingValue) {
                    if (textEditingValue.text.trim().isEmpty) return _products;
                    return _products.where(
                      (p) => p.particular.toLowerCase().contains(
                        textEditingValue.text.toLowerCase(),
                      ),
                    );
                  },
                  onSelected: (selection) {
                    setState(() {
                      row.particularCtr.text = selection.particular;
                      row.unitCtr.text = selection.unit;
                      row.rateCtr.text = selection.rate.toStringAsFixed(2);
                    });
                  },
                  fieldViewBuilder:
                      (context, controller, focusNode, onEditingComplete) {
                        if (controller.text != row.particularCtr.text) {
                          controller.text = row.particularCtr.text;
                        }
                        focusNode.onKeyEvent = row.focusNode.onKeyEvent;
                        return Focus(
                          onFocusChange: (hasFocus) {
                            if (!hasFocus && mounted) {
                              final val = controller.text.trim();
                              if (val.isNotEmpty) {
                                final exists = _products.any(
                                  (p) =>
                                      p.particular.toLowerCase() ==
                                      val.toLowerCase(),
                                );
                                if (!exists) {
                                  _promptAddProduct(val, i);
                                }
                              }
                            }
                          },
                          child: TextFormField(
                            controller: controller,
                            focusNode: focusNode,
                            style: TextStyle(fontSize: 14.sp),
                            decoration: InputDecoration(
                              hintText: 'Search or type...',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 8.h,
                              ),
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.list_alt, size: 18),
                                    onPressed: () =>
                                        _showProductSearchDialog(i),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  SizedBox(width: 8.w),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.add_box_outlined,
                                      size: 18,
                                    ),
                                    onPressed: () => _showAddProductDialog(i),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  SizedBox(width: 4.w),
                                ],
                              ),
                            ),
                            onChanged: (val) {
                              row.particularCtr.text = val;
                              setState(() {});
                            },
                          ),
                        );
                      },
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(
                  Icons.delete_outline,
                  color: AppColors.error,
                  size: 20.sp,
                ),
                onPressed: _rows.length == 1
                    ? null
                    : () => setState(() {
                        _rows[i].dispose();
                        _rows.removeAt(i);
                      }),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: _compactField(
                  row.qtyCtr,
                  'Qty',
                  onChanged: (_) => setState(() {}),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _compactField(
                  row.unitCtr,
                  'Unit',
                  onChanged: (_) => setState(() {}),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _compactField(
                  row.rateCtr,
                  'Rate',
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Amount: ₹ ${_rowAmount(row).toStringAsFixed(2)}',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.07),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Row(
        children: [
          SizedBox(width: 36.w),
          Expanded(flex: 1, child: _headerText('Qty')),
          SizedBox(width: 8.w),
          Expanded(flex: 3, child: _headerText('Particulars')),
          SizedBox(width: 8.w),
          Expanded(flex: 1, child: _headerText('Unit')),
          SizedBox(width: 8.w),
          Expanded(flex: 2, child: _headerText('Rate')),
          SizedBox(width: 8.w),
          Expanded(
            flex: 2,
            child: _headerText('Amount', align: TextAlign.right),
          ),
        ],
      ),
    );
  }

  Widget _headerText(String text, {TextAlign align = TextAlign.left}) {
    return Text(
      text,
      textAlign: align,
      style: TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.bold,
        color: AppColors.secondary,
      ),
    );
  }

  Widget _buildItemRow(int i) {
    final row = _rows[i];
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(minWidth: 28.w, minHeight: 28.w),
            icon: Icon(
              Icons.remove_circle_outline,
              size: 18.sp,
              color: AppColors.error,
            ),
            onPressed: _rows.length == 1
                ? null
                : () => setState(() {
                    _rows[i].dispose();
                    _rows.removeAt(i);
                  }),
          ),
          SizedBox(width: 8.w),
          Expanded(
            flex: 1,
            child: _compactField(
              row.qtyCtr,
              'Qty',
              onChanged: (_) => setState(() {}),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            flex: 3,
            child: Autocomplete<EstimateProduct>(
              displayStringForOption: (option) => option.particular,
              optionsBuilder: (textEditingValue) {
                if (textEditingValue.text.trim().isEmpty) return _products;
                return _products.where(
                  (p) => p.particular.toLowerCase().contains(
                    textEditingValue.text.toLowerCase(),
                  ),
                );
              },
              onSelected: (selection) {
                setState(() {
                  row.particularCtr.text = selection.particular;
                  row.unitCtr.text = selection.unit;
                  row.rateCtr.text = selection.rate.toStringAsFixed(2);
                });
              },
              fieldViewBuilder:
                  (context, controller, focusNode, onEditingComplete) {
                    if (controller.text != row.particularCtr.text) {
                      controller.text = row.particularCtr.text;
                    }

                    focusNode.onKeyEvent = row.focusNode.onKeyEvent;

                    return Focus(
                      onFocusChange: (hasFocus) {
                        if (!hasFocus && mounted) {
                          final val = controller.text.trim();
                          if (val.isNotEmpty) {
                            final exists = _products.any(
                              (p) =>
                                  p.particular.toLowerCase() ==
                                  val.toLowerCase(),
                            );
                            if (!exists) {
                              _promptAddProduct(val, i);
                            }
                          }
                        }
                      },
                      child: TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          hintText: 'Particulars',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 8.h,
                          ),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.list_alt, size: 20),
                                onPressed: () => _showProductSearchDialog(i),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              SizedBox(width: 8.w),
                              IconButton(
                                icon: const Icon(
                                  Icons.add_box_outlined,
                                  size: 20,
                                ),
                                onPressed: () => _showAddProductDialog(i),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              SizedBox(width: 4.w),
                            ],
                          ),
                        ),
                        style: TextStyle(fontSize: 13.sp),
                        onChanged: (val) {
                          row.particularCtr.text = val;
                        },
                      ),
                    );
                  },
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            flex: 1,
            child: TextFormField(
              controller: row.unitCtr,
              focusNode: row.unitFocusNode,
              decoration: InputDecoration(
                hintText: 'Unit',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8.w,
                  vertical: 8.h,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_drop_down),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    _showUnitSelectionDialog(
                      (u) => setState(() => row.unitCtr.text = u),
                    );
                  },
                ),
              ),
              style: TextStyle(fontSize: 13.sp),
              onChanged: (_) => setState(() {}),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            flex: 2,
            child: _compactField(
              row.rateCtr,
              '0.00',
              onChanged: (_) => setState(() {}),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            flex: 2,
            child: Text(
              '₹${_rowAmount(row).toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              constraints: const BoxConstraints(maxWidth: 350),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Subtotal', style: TextStyle(fontSize: 14.sp)),
                      Text(
                        '₹${_subtotal.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Old Balance (OB)',
                        style: TextStyle(fontSize: 14.sp),
                      ),
                      SizedBox(
                        width: 120.w,
                        child: TextField(
                          controller: _oldBalanceCtrl,
                          textAlign: TextAlign.right,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Amount',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '₹${_total.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w900,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Payment Mode', style: TextStyle(fontSize: 14.sp)),
                      DropdownButton<String>(
                        value: _paymentMode,
                        items: const [
                          DropdownMenuItem(value: 'cash', child: Text('Cash')),
                          DropdownMenuItem(
                            value: 'credit',
                            child: Text('Credit'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _paymentMode = val);
                        },
                      ),
                    ],
                  ),
                  if (_paymentMode == 'credit') ...[
                    SizedBox(height: 12.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Credit Days', style: TextStyle(fontSize: 14.sp)),
                        SizedBox(
                          width: 120.w,
                          child: TextField(
                            controller: _creditDaysCtrl,
                            textAlign: TextAlign.right,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Settled Amount (Received)',
                          style: TextStyle(fontSize: 14.sp),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      SizedBox(
                        width: 120.w,
                        child: TextField(
                          controller: _settledAmountCtrl,
                          textAlign: TextAlign.right,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}'),
                            ),
                          ],
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            prefixText: '₹ ',
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'New Balance (OB)',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w900,
                            color: AppColors.error,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '₹${_balance.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w900,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: AppColors.divider)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16.w,
        runSpacing: 16.h,
        children: [
          TextButton(
            onPressed: () => context.go('/estimates'),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? SizedBox(
                    width: 16.sp,
                    height: 16.sp,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(_isSaving ? 'Saving...' : 'Save Estimate'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _labelField(
    String label,
    TextEditingController controller, {
    bool required = false,
    int maxLines = 1,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
            children: [
              if (required)
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: AppColors.error),
                ),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          validator: required
              ? (v) => v == null || v.isEmpty ? 'Required' : null
              : null,
        ),
      ],
    );
  }

  Widget _compactField(
    TextEditingController controller,
    String hint, {
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      ),
      style: TextStyle(fontSize: 13.sp),
      onChanged: onChanged,
    );
  }
}
