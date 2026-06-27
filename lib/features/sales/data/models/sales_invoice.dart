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
  final String invoiceType;
  final String supplyType;
  final String? irn;
  final String? qrCodeData;
  final bool reverseCharge;
  final String? placeOfSupply;
  final DateTime? createdAt;
  final String? warehouseId;

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
    this.invoiceType = 'B2C',
    this.supplyType = 'INTRA_STATE',
    this.irn,
    this.qrCodeData,
    this.reverseCharge = false,
    this.placeOfSupply,
    this.createdAt,
    this.warehouseId,
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
      'invoice_type': invoiceType,
      'supply_type': supplyType,
      'irn': irn,
      'qr_code_data': qrCodeData,
      'reverse_charge': reverseCharge,
      'place_of_supply': placeOfSupply,
      'warehouse_id': warehouseId,
    };
  }

  factory SalesInvoice.fromJson(
    Map<String, dynamic> json,
    List<InvoiceItem> items,
  ) {
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
      invoiceType: json['invoice_type'] ?? 'B2C',
      supplyType: json['supply_type'] ?? 'INTRA_STATE',
      irn: json['irn'],
      qrCodeData: json['qr_code_data'],
      reverseCharge: json['reverse_charge'] ?? false,
      placeOfSupply: json['place_of_supply'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      warehouseId: json['warehouse_id']?.toString(),
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
  double taxableValue;
  double cgstAmount;
  double sgstAmount;
  double igstAmount;
  double cessAmount;

  InvoiceItem({
    required this.name,
    required this.hsn,
    required this.qty,
    this.unit = 'PCS',
    required this.rate,
    required this.gstRate,
    this.taxableValue = 0.0,
    this.cgstAmount = 0.0,
    this.sgstAmount = 0.0,
    this.igstAmount = 0.0,
    this.cessAmount = 0.0,
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
      'taxable_value': taxableValue,
      'cgst_amount': cgstAmount,
      'sgst_amount': sgstAmount,
      'igst_amount': igstAmount,
      'cess_amount': cessAmount,
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
      taxableValue: (json['taxable_value'] as num?)?.toDouble() ?? 0.0,
      cgstAmount: (json['cgst_amount'] as num?)?.toDouble() ?? 0.0,
      sgstAmount: (json['sgst_amount'] as num?)?.toDouble() ?? 0.0,
      igstAmount: (json['igst_amount'] as num?)?.toDouble() ?? 0.0,
      cessAmount: (json['cess_amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
