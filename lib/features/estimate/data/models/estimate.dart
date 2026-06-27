class Estimate {
  final String? id;
  final String estimateNumber;
  final DateTime date;
  final String customerName;
  final List<EstimateItem> items;
  final double subtotal;
  final double oldBalance;
  final double total;
  final double settledAmount;
  final double balance;
  final String paymentMode;
  final int creditDays;
  final String status;
  final DateTime? createdAt;

  Estimate({
    this.id,
    required this.estimateNumber,
    required this.date,
    required this.customerName,
    required this.items,
    required this.subtotal,
    required this.oldBalance,
    required this.total,
    required this.settledAmount,
    required this.balance,
    this.paymentMode = 'cash',
    this.creditDays = 0,
    this.status = 'cleared',
    this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'estimate_number': estimateNumber,
      'date': date.toIso8601String(),
      'customer_name': customerName,
      'subtotal': subtotal,
      'old_balance': oldBalance,
      'total': total,
      'settled_amount': settledAmount,
      'balance': balance,
      'payment_mode': paymentMode,
      'credit_days': creditDays,
      'status': status,
    };
  }

  factory Estimate.fromJson(Map<String, dynamic> json, List<EstimateItem> items) {
    return Estimate(
      id: json['id']?.toString(),
      estimateNumber: json['estimate_number'],
      date: DateTime.parse(json['date']),
      customerName: json['customer_name'],
      items: items,
      subtotal: (json['subtotal'] as num).toDouble(),
      oldBalance: (json['old_balance'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num).toDouble(),
      settledAmount: (json['settled_amount'] as num?)?.toDouble() ?? 0.0,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      paymentMode: json['payment_mode'] ?? 'cash',
      creditDays: json['credit_days'] ?? 0,
      status: json['status'] ?? 'cleared',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }
}

class EstimateItem {
  final String particular;
  final double qty;
  final String unit;
  final double rate;
  final double amount;

  EstimateItem({
    required this.particular,
    required this.qty,
    this.unit = '',
    required this.rate,
    required this.amount,
  });

  Map<String, dynamic> toJson(String estimateId) => {
        'estimate_id': estimateId,
        'particular': particular,
        'qty': qty,
        'unit': unit,
        'rate': rate,
        'amount': amount,
      };

  factory EstimateItem.fromJson(Map<String, dynamic> json) {
    return EstimateItem(
      particular: json['particular'],
      qty: (json['qty'] as num).toDouble(),
      unit: json['unit'] ?? '',
      rate: (json['rate'] as num).toDouble(),
      amount: (json['amount'] as num).toDouble(),
    );
  }
}

class EstimateCustomer {
  final String? id;
  final String name;
  final double ob;

  EstimateCustomer({this.id, required this.name, required this.ob});

  Map<String, dynamic> toJson() => {
        'name': name,
        'ob': ob,
      };

  factory EstimateCustomer.fromJson(Map<String, dynamic> json) {
    return EstimateCustomer(
      id: json['id']?.toString(),
      name: json['name'],
      ob: (json['ob'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class EstimateProduct {
  final String? id;
  final String particular;
  final String unit;
  final double rate;

  EstimateProduct({this.id, required this.particular, this.unit = '', required this.rate});

  Map<String, dynamic> toJson() => {
        'particular': particular,
        'unit': unit,
        'rate': rate,
      };

  factory EstimateProduct.fromJson(Map<String, dynamic> json) {
    return EstimateProduct(
      id: json['id']?.toString(),
      particular: json['particular'],
      unit: json['unit'] ?? '',
      rate: (json['rate'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
