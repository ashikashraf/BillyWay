import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../main.dart';
import '../../domain/controllers/master_data_controller.dart';
import '../pages/master_management_page.dart';
import 'master_form_modal.dart';

class SmartMasterDropdown extends StatefulWidget {
  final MasterModule module;
  final String label;
  final String? hint;
  final String? value;
  final String Function(Map<String, dynamic>) displayItem;
  final void Function(String?) onChanged;
  final bool isMandatory;

  const SmartMasterDropdown({
    super.key,
    required this.module,
    required this.label,
    required this.displayItem,
    required this.onChanged,
    this.value,
    this.hint,
    this.isMandatory = false,
  });

  @override
  State<SmartMasterDropdown> createState() => _SmartMasterDropdownState();
}

class _SmartMasterDropdownState extends State<SmartMasterDropdown> {
  final FocusNode _focusNode = FocusNode();
  String? _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;
  }

  @override
  void didUpdateWidget(covariant SmartMasterDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _currentValue = widget.value;
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _handleAddNew() async {
    // Open the master form modal and wait for result
    final insertedData = await MasterFormModal.show(context, widget.module);

    if (insertedData != null && mounted) {
      // Optmistically update controller to prevent assertion errors
      final controller = getIt<MasterDataController>();
      final tableName = controller.getTableName(widget.module);
      controller.addRecordOptimistically(tableName, insertedData);

      // Auto-select the newly created item
      final newId = insertedData['id'] as String?;
      if (newId != null) {
        setState(() => _currentValue = newId);
        widget.onChanged(newId);
      }

      // Return focus to the exact cursor position
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = getIt<MasterDataController>();
    final tableName = controller.getTableName(widget.module);

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (node, event) {
        // Detect F1 press to trigger Add New
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.f1) {
          _handleAddNew();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: ValueListenableBuilder<Map<String, List<Map<String, dynamic>>>>(
        valueListenable: controller.masterDataNotifier,
        builder: (context, dataMap, child) {
          final items = dataMap[tableName] ?? [];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(
                    text: TextSpan(
                      text: widget.label,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                        fontFamily: 'Poppins',
                      ),
                      children: widget.isMandatory
                          ? const [
                              TextSpan(
                                text: ' *',
                                style: TextStyle(color: AppColors.error),
                              ),
                            ]
                          : [],
                    ),
                  ),
                  InkWell(
                    onTap: _handleAddNew,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 2.h,
                      ),
                      child: Text(
                        '+ Add New (F1)',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              DropdownButtonFormField<String>(
                initialValue: _currentValue,
                isExpanded: true,
                decoration: InputDecoration(
                  hintText: widget.hint ?? 'Select ${widget.label}',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                ),
                items: items.map((item) {
                  return DropdownMenuItem<String>(
                    value: item['id'] as String,
                    child: Text(
                      widget.displayItem(item),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() => _currentValue = val);
                  widget.onChanged(val);
                },
                validator: widget.isMandatory
                    ? (value) =>
                          value == null ? '${widget.label} is required' : null
                    : null,
              ),
            ],
          );
        },
      ),
    );
  }
}
