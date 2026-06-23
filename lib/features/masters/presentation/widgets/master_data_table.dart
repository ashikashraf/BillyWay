import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:billy_way/core/theme/app_colors.dart';
import 'package:billy_way/main.dart';
import 'package:billy_way/features/masters/domain/controllers/master_data_controller.dart';
import 'package:billy_way/features/masters/presentation/pages/master_management_page.dart';

class MasterDataTable extends StatelessWidget {
  final MasterModule module;
  const MasterDataTable({super.key, required this.module});

  @override
  Widget build(BuildContext context) {
    final headers = _getHeaders();

    final controller = getIt<MasterDataController>();
    final tableName = controller.getTableName(module);

    return ValueListenableBuilder<Map<String, List<Map<String, dynamic>>>>(
      valueListenable: controller.masterDataNotifier,
      builder: (context, dataMap, child) {
        final items = dataMap[tableName] ?? [];

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: MediaQuery.of(context).size.width - 350.w,
            ),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                AppColors.background.withValues(alpha: 0.5),
              ),
              horizontalMargin: 24.w,
              columnSpacing: 24.w,
              columns: headers
                  .map(
                    (h) => DataColumn(
                      label: Text(
                        h.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              rows: items.map((item) {
                return DataRow(
                  cells:
                      _getCellsForItem(item)
                          .map((cell) => DataCell(Text(cell.toString())))
                          .toList()
                        ..add(
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.edit_outlined,
                                    size: 18.sp,
                                    color: AppColors.primary,
                                  ),
                                  onPressed: () {},
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete_outline,
                                    size: 18.sp,
                                    color: AppColors.error,
                                  ),
                                  onPressed: () {},
                                ),
                              ],
                            ),
                          ),
                        ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  List<String> _getHeaders() {
    switch (module) {
      case MasterModule.ledgerGroup:
        return ['Name', 'Parent Group', 'Nature', 'GST', 'Status', 'Actions'];
      case MasterModule.hsnCode:
        return [
          'HSN Code',
          'Description',
          'GST Rate',
          'Type',
          'Status',
          'Actions',
        ];
      case MasterModule.itemCategory:
        return ['Category', 'HSN/SAC', 'Tax Class', 'Status', 'Actions'];
      case MasterModule.taxClass:
        return ['Tax Class', 'GST %', 'Type', 'Status', 'Actions'];
      case MasterModule.transactionType:
        return ['Type', 'Category', 'Prefix', 'Status', 'Actions'];
      case MasterModule.sundryType:
        return ['Type', 'Nature', 'Account', 'Status', 'Actions'];
      case MasterModule.uom:
        return ['Unit Name', 'Symbol', 'UQC', 'Status', 'Actions'];
      case MasterModule.brand:
        return ['Brand Name', 'Manufacturer', 'Status', 'Actions'];
      case MasterModule.warehouse:
        return ['Warehouse', 'Location', 'Incharge', 'Status', 'Actions'];
    }
  }

  List<dynamic> _getCellsForItem(Map<String, dynamic> item) {
    switch (module) {
      case MasterModule.ledgerGroup:
        return [
          item['group_name'] ?? '',
          item['parent_group_id'] ?? '-',
          item['nature'] ?? '',
          item['gst_applicable'] == true ? 'Yes' : 'No',
          item['status'] ?? 'active',
        ];
      case MasterModule.hsnCode:
        return [
          item['hsn_code'] ?? '',
          item['description'] ?? '',
          '${item['gst_rate'] ?? 0}%',
          item['type'] ?? '',
          item['status'] ?? 'active',
        ];
      case MasterModule.itemCategory:
        return [
          item['category_name'] ?? '',
          item['hsn_sac'] ?? '-',
          item['tax_class'] ?? '-',
          item['status'] ?? 'active',
        ];
      case MasterModule.taxClass:
        return [
          item['class_name'] ?? '',
          '${item['gst_rate'] ?? 0}%',
          item['tax_type'] ?? '-',
          item['status'] ?? 'active',
        ];
      case MasterModule.transactionType:
        return [
          item['type_name'] ?? '',
          item['category'] ?? '-',
          item['prefix'] ?? '-',
          item['status'] ?? 'active',
        ];
      case MasterModule.sundryType:
        return [
          item['sundry_name'] ?? '',
          item['nature'] ?? '-',
          item['account_id'] ?? '-',
          item['status'] ?? 'active',
        ];
      case MasterModule.uom:
        return [
          item['unit_name'] ?? '',
          item['symbol'] ?? '',
          item['uqc_code'] ?? '',
          item['status'] ?? 'active',
        ];
      case MasterModule.brand:
        return [
          item['brand_name'] ?? '',
          item['manufacturer'] ?? '-',
          item['status'] ?? 'active',
        ];
      case MasterModule.warehouse:
        return [
          item['warehouse_name'] ?? '',
          item['location'] ?? '-',
          item['incharge'] ?? '-',
          item['status'] ?? 'active',
        ];
    }
  }
}
