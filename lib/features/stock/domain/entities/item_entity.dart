import 'package:equatable/equatable.dart';

class ItemEntity extends Equatable {
  final String id;
  final String name;
  final String hsnCode;
  final String unit;
  final double gstRate;
  final double purchasePrice;
  final double salePrice;
  final double currentStock;

  const ItemEntity({
    required this.id,
    required this.name,
    required this.hsnCode,
    required this.unit,
    required this.gstRate,
    required this.purchasePrice,
    required this.salePrice,
    required this.currentStock,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        hsnCode,
        unit,
        gstRate,
        purchasePrice,
        salePrice,
        currentStock,
      ];
}
