import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../main.dart';
import '../../domain/controllers/master_data_controller.dart';
import '../pages/master_management_page.dart';

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
              columns:
                  headers
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
                      .toList()
                    ..add(
                      DataColumn(
                        label: Text(
                          'ACTIONS',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
              rows: items.isEmpty
                  ? [_buildEmptyRow(headers.length + 1)]
                  : items.map((item) => _buildDataRow(item)).toList(),
            ),
          ),
        );
      },
    );
  }

  DataRow _buildEmptyRow(int columnCount) {
    return DataRow(
      cells: List.generate(columnCount, (index) {
        if (index == 0) return const DataCell(Text('No records found'));
        return const DataCell(Text(''));
      }),
    );
  }

  DataRow _buildDataRow(Map<String, dynamic> item) {
    final cells = _getCellsForItem(item);
    return DataRow(
      cells:
          cells
              .map(
                (c) => DataCell(
                  Text(
                    c.toString(),
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              )
              .toList()
            ..add(
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
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
          item['parent_category_id'] ?? '-',
          item['code'] ?? '',
          item['status'] ?? 'active',
        ];
      case MasterModule.taxClass:
        return [
          item['tax_class_name'] ?? '',
          '${item['gst_percentage'] ?? 0}%',
          '${item['cgst']}+${item['sgst']}+${item['igst']}',
          item['inclusive_type'] == true ? 'Inclusive' : 'Exclusive',
          item['status'] ?? 'active',
        ];
      case MasterModule.transactionType:
        return [
          item['name'] ?? '',
          item['mode'] ?? '',
          item['default_ledger_group_id'] ?? '-',
          item['auto_prefix'] ?? '',
          item['status'] ?? 'active',
        ];
      case MasterModule.sundryType:
        return [
          item['sundry_type_name'] ?? '',
          item['type'] ?? '',
          item['tax_applicable'] == true ? 'Yes' : 'No',
          item['status'] ?? 'active',
        ];
      case MasterModule.uom:
        return [
          item['unit_name'] ?? '',
          item['symbol'] ?? '',
          item['allow_decimal'] == true ? 'Yes' : 'No',
          item['status'] ?? 'active',
        ];
      case MasterModule.brand:
        return [
          item['brand_name'] ?? '',
          item['code'] ?? '',
          '-',
          item['status'] ?? 'active',
        ];
      case MasterModule.warehouse:
        return [
          item['warehouse_name'] ?? '',
          item['code'] ?? '',
          item['location'] ?? '',
          item['contact_person'] ?? '',
          item['status'] ?? 'active',
        ];
    }
  }

  List<String> _getHeaders() {
    switch (module) {
      case MasterModule.ledgerGroup:
        return ['Group Name', 'Parent Group', 'Nature', 'GST', 'Status'];
      case MasterModule.hsnCode:
        return ['HSN/SAC', 'Description', 'GST %', 'Type', 'Status'];
      case MasterModule.itemCategory:
        return ['Category Name', 'Parent', 'Code', 'Status'];
      case MasterModule.taxClass:
        return ['Class Name', 'GST %', 'Split', 'Type', 'Status'];
      case MasterModule.transactionType:
        return ['Name', 'Mode', 'Linked Group', 'Prefix', 'Status'];
      case MasterModule.sundryType:
        return ['Name', 'Type', 'Tax Applicability', 'Status'];
      case MasterModule.uom:
        return ['Unit Name', 'Symbol', 'Decimals', 'Status'];
      case MasterModule.brand:
        return ['Brand Name', 'Code', 'Description', 'Status'];
      case MasterModule.warehouse:
        return ['Warehouse Name', 'Code', 'Location', 'Contact', 'Status'];
    }
  }
}
