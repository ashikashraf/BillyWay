class Quotation {
  final String? id;
  final String quotationNumber;
  final DateTime date;
  final DateTime validUntil;
  final String customerName;
  final String? mobileNumber;
  final String? billingAddress;
  final String? shippingAddress;
  final List<QuotationItem> items;
  final double subtotal;
  final String status;
  final String? notes;
  final DateTime? createdAt;

  Quotation({
    this.id,
    required this.quotationNumber,
    required this.date,
    required this.validUntil,
    required this.customerName,
    this.mobileNumber,
    this.billingAddress,
    this.shippingAddress,
    required this.items,
    required this.subtotal,
    required this.status,
    this.notes,
    this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'quotation_number': quotationNumber,
      'date': date.toIso8601String(),
      'valid_until': validUntil.toIso8601String(),
      'customer_name': customerName,
      'mobile_number': mobileNumber,
      'billing_address': billingAddress,
      'shipping_address': shippingAddress,
      'subtotal': subtotal,
      'status': status,
      'notes': notes,
    };
  }

  factory Quotation.fromJson(Map<String, dynamic> json, List<QuotationItem> items) {
    return Quotation(
      id: json['id']?.toString(),
      quotationNumber: json['quotation_number'],
      date: DateTime.parse(json['date']),
      validUntil: DateTime.parse(json['valid_until']),
      customerName: json['customer_name'],
      mobileNumber: json['mobile_number'],
      billingAddress: json['billing_address'],
      shippingAddress: json['shipping_address'],
      items: items,
      subtotal: (json['subtotal'] as num).toDouble(),
      status: json['status'],
      notes: json['notes'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }
}

class QuotationItem {
  String name;
  String hsn;
  double qty;
  String unit;
  double rate;
  double discount;
  double amount;

  QuotationItem({
    required this.name,
    this.hsn = '',
    required this.qty,
    this.unit = 'PCS',
    required this.rate,
    this.discount = 0.0,
    required this.amount,
  });

  double get total => amount;

  Map<String, dynamic> toJson(String quotationId) {
    return {
      'quotation_id': quotationId,
      'name': name,
      'hsn': hsn,
      'qty': qty,
      'unit': unit,
      'rate': rate,
      'discount': discount,
      'amount': amount,
      'total': amount,
    };
  }

  factory QuotationItem.fromJson(Map<String, dynamic> json) {
    return QuotationItem(
      name: json['name'],
      hsn: json['hsn'] ?? '',
      qty: (json['qty'] as num).toDouble(),
      unit: json['unit'] ?? 'PCS',
      rate: (json['rate'] as num).toDouble(),
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      amount: (json['amount'] as num?)?.toDouble() ??
          (json['total'] as num?)?.toDouble() ??
          ((json['qty'] as num).toDouble() * (json['rate'] as num).toDouble()),
    );
  }
}
