class PurchaseInvoice {
  final String? id;
  final String internalRefNo;
  final String? vendorBillNo;
  final DateTime date;
  final DateTime? dueDate;
  final String vendorName;
  final String? gstin;
  final String supplyType;
  final List<PurchaseInvoiceItem> items;
  final double subtotal;
  final double cgst;
  final double sgst;
  final double igst;
  final double cess;
  final double totalTax;
  final double totalAmount;
  final String status;
  final DateTime? createdAt;
  final String? warehouseId;

  PurchaseInvoice({
    this.id,
    required this.internalRefNo,
    this.vendorBillNo,
    required this.date,
    this.dueDate,
    required this.vendorName,
    this.gstin,
    this.supplyType = 'INTRA_STATE',
    required this.items,
    required this.subtotal,
    required this.cgst,
    required this.sgst,
    required this.igst,
    required this.cess,
    required this.totalTax,
    required this.totalAmount,
    this.status = 'Unpaid',
    this.createdAt,
    this.warehouseId,
  });

  Map<String, dynamic> toJson() {
    return {
      'internal_ref_no': internalRefNo,
      'vendor_bill_no': vendorBillNo,
      'date': date.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
      'vendor_name': vendorName,
      'gstin': gstin,
      'supply_type': supplyType,
      'subtotal': subtotal,
      'cgst': cgst,
      'sgst': sgst,
      'igst': igst,
      'cess': cess,
      'total_tax': totalTax,
      'total_amount': totalAmount,
      'status': status,
      'warehouse_id': warehouseId,
    };
  }

  factory PurchaseInvoice.fromJson(
    Map<String, dynamic> json,
    List<PurchaseInvoiceItem> items,
  ) {
    return PurchaseInvoice(
      id: json['id']?.toString(),
      internalRefNo: json['internal_ref_no'],
      vendorBillNo: json['vendor_bill_no'],
      date: DateTime.parse(json['date']),
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      vendorName: json['vendor_name'],
      gstin: json['gstin'],
      supplyType: json['supply_type'] ?? 'INTRA_STATE',
      items: items,
      subtotal: (json['subtotal'] as num).toDouble(),
      cgst: (json['cgst'] as num).toDouble(),
      sgst: (json['sgst'] as num).toDouble(),
      igst: (json['igst'] as num).toDouble(),
      cess: (json['cess'] as num).toDouble(),
      totalTax: (json['total_tax'] as num).toDouble(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      status: json['status'] ?? 'Unpaid',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      warehouseId: json['warehouse_id']?.toString(),
    );
  }
}

class PurchaseInvoiceItem {
  String productName;
  String? hsnSacCode;
  double qty;
  double rate;
  double gstRate;
  double taxableValue;
  double cgstAmount;
  double sgstAmount;
  double igstAmount;
  double cessAmount;

  PurchaseInvoiceItem({
    required this.productName,
    this.hsnSacCode,
    required this.qty,
    required this.rate,
    required this.gstRate,
    this.taxableValue = 0.0,
    this.cgstAmount = 0.0,
    this.sgstAmount = 0.0,
    this.igstAmount = 0.0,
    this.cessAmount = 0.0,
  });

  Map<String, dynamic> toJson(String purchaseInvoiceId) {
    return {
      'purchase_invoice_id': purchaseInvoiceId,
      'product_name': productName,
      'hsn_sac_code': hsnSacCode,
      'qty': qty,
      'rate': rate,
      'gst_rate': gstRate,
      'taxable_value': taxableValue,
      'cgst_amount': cgstAmount,
      'sgst_amount': sgstAmount,
      'igst_amount': igstAmount,
      'cess_amount': cessAmount,
    };
  }

  factory PurchaseInvoiceItem.fromJson(Map<String, dynamic> json) {
    return PurchaseInvoiceItem(
      productName: json['product_name'],
      hsnSacCode: json['hsn_sac_code'],
      qty: (json['qty'] as num).toDouble(),
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
