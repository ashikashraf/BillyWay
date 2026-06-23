class SalesInvoice {
  final String? id;
  final String invoiceNumber;
  final String? poNumber;
  final DateTime date;
  final DateTime dueDate;
  final String customerName;
  final String? mobileNumber;
  final String? gstin;
  final String? billingAddress;
  final String? shippingAddress;
  final List<InvoiceItem> items;
  final double subtotal;
  final double totalTax;
  final double cgst;
  final double sgst;
  final double igst;
  final double totalAmount;
  final String paymentMethod;
  final String status;
  final DateTime? createdAt;

  SalesInvoice({
    this.id,
    required this.invoiceNumber,
    this.poNumber,
    required this.date,
    required this.dueDate,
    required this.customerName,
    this.mobileNumber,
    this.gstin,
    this.billingAddress,
    this.shippingAddress,
    required this.items,
    required this.subtotal,
    required this.totalTax,
    required this.cgst,
    required this.sgst,
    required this.igst,
    required this.totalAmount,
    required this.paymentMethod,
    required this.status,
    this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'invoice_number': invoiceNumber,
      'po_number': poNumber,
      'date': date.toIso8601String(),
      'due_date': dueDate.toIso8601String(),
      'customer_name': customerName,
      'mobile_number': mobileNumber,
      'gstin': gstin,
      'billing_address': billingAddress,
      'shipping_address': shippingAddress,
      'subtotal': subtotal,
      'total_tax': totalTax,
      'cgst': cgst,
      'sgst': sgst,
      'igst': igst,
      'total_amount': totalAmount,
      'payment_method': paymentMethod,
      'status': status,
    };
  }

  factory SalesInvoice.fromJson(Map<String, dynamic> json, List<InvoiceItem> items) {
    return SalesInvoice(
      id: json['id']?.toString(),
      invoiceNumber: json['invoice_number'],
      poNumber: json['po_number'],
      date: DateTime.parse(json['date']),
      dueDate: DateTime.parse(json['due_date']),
      customerName: json['customer_name'],
      mobileNumber: json['mobile_number'],
      gstin: json['gstin'],
      billingAddress: json['billing_address'],
      shippingAddress: json['shipping_address'],
      items: items,
      subtotal: (json['subtotal'] as num).toDouble(),
      totalTax: (json['total_tax'] as num).toDouble(),
      cgst: (json['cgst'] as num).toDouble(),
      sgst: (json['sgst'] as num).toDouble(),
      igst: (json['igst'] as num).toDouble(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      paymentMethod: json['payment_method'],
      status: json['status'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }
}

class InvoiceItem {
  String name;
  String hsn;
  double qty;
  String unit;
  double rate;
  double gstRate;

  InvoiceItem({
    required this.name,
    required this.hsn,
    required this.qty,
    this.unit = 'PCS',
    required this.rate,
    required this.gstRate,
  });

  Map<String, dynamic> toJson(String invoiceId) {
    return {
      'invoice_id': invoiceId,
      'name': name,
      'hsn': hsn,
      'qty': qty,
      'unit': unit,
      'rate': rate,
      'gst_rate': gstRate,
      'total': qty * rate,
    };
  }

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      name: json['name'],
      hsn: json['hsn'],
      qty: (json['qty'] as num).toDouble(),
      unit: json['unit'],
      rate: (json['rate'] as num).toDouble(),
      gstRate: (json['gst_rate'] as num).toDouble(),
    );
  }
}
