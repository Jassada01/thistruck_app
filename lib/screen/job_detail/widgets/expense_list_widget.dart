import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart' as AppThemeConfig;
import '../../../provider/font_size_provider.dart';
import '../../../service/api_service.dart';

class ExpenseListWidget extends StatelessWidget {
  final Map<String, dynamic>? tripData;
  final Function()? onExpenseUpdated;

  const ExpenseListWidget({
    super.key,
    required this.tripData,
    this.onExpenseUpdated,
  });

  @override
  Widget build(BuildContext context) {
    if (tripData == null || tripData!['trip_cost'] == null) {
      return _buildEmptyState();
    }

    final costData = tripData!['trip_cost'] as Map<String, dynamic>;
    
    return _buildExpenseList(context, costData);
  }

  Widget _buildEmptyState() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Text(
          'ไม่มีข้อมูลค่าใช้จ่าย',
          style: GoogleFonts.notoSansThai(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseList(BuildContext context, Map<String, dynamic> costData) {
    final colors = AppThemeConfig.AppColorScheme.light();
    
    return Consumer<FontSizeProvider>(
      builder: (context, fontProvider, child) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                offset: Offset(0, 2),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.monetization_on, color: colors.success, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'รายการค่าใช้จ่าย',
                    style: GoogleFonts.notoSansThai(
                      fontSize: fontProvider.getScaledFontSize(14.0),
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              _buildCostItem(context, 'ค่าล่วงเวลา', costData['overtime_fee'], 'overtime_fee'),
              _buildCostItem(context, 'ค่าผ่านท่า', costData['port_charge'], 'port_charge'),
              _buildCostItem(context, 'ค่าผ่านลาน', costData['yard_charge'], 'yard_charge'),
              _buildCostItem(context, 'ค่ารับตู้/คืนตู้', costData['container_return'], 'container_return'),
              _buildCostItem(context, 'ค่าซ่อมตู้', costData['container_cleaning_repair'], 'container_cleaning_repair'),
              _buildCostItem(context, 'ค่าล้างตู้', costData['container_drop_lift'], 'container_drop_lift'),
              _buildCostItem(context, 'ค่าชอร์(SHORE)', costData['expenses_1'], 'expenses_1'),
              if (costData['remark'] != null && costData['remark'].toString().isNotEmpty) ...[
                SizedBox(height: 12),
                Text(
                  'หมายเหตุ:',
                  style: GoogleFonts.notoSansThai(
                    fontSize: fontProvider.getScaledFontSize(12.0),
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  costData['remark'],
                  style: GoogleFonts.notoSansThai(
                    fontSize: fontProvider.getScaledFontSize(11.0),
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildCostItem(BuildContext context, String label, dynamic value, String fieldKey, {bool isTotal = false}) {
    final colors = AppThemeConfig.AppColorScheme.light();
    final amount = value?.toString() ?? '0.00';
    final formattedAmount = _formatExpense(amount);
    
    return Consumer<FontSizeProvider>(
      builder: (context, fontProvider, child) {
        return Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: GoogleFonts.notoSansThai(
                      fontSize: fontProvider.getScaledFontSize(isTotal ? 12.0 : 11.0),
                      color: isTotal ? colors.textPrimary : colors.textSecondary,
                      fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                  if (!isTotal) ...[
                    SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => _updateCostItem(context, label, fieldKey, amount),
                      child: Icon(
                        Icons.edit,
                        size: 16,
                        color: Colors.blue.withOpacity(0.7),
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                formattedAmount,
                style: GoogleFonts.notoSansThai(
                  fontSize: fontProvider.getScaledFontSize(isTotal ? 12.0 : 11.0),
                  color: isTotal ? colors.success : colors.textPrimary,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatExpense(String? expenseStr) {
    if (expenseStr == null || expenseStr.isEmpty) return '-';
    
    try {
      final expense = double.tryParse(expenseStr) ?? 0.0;
      if (expense == 0.0) return '-';
      
      final formatter = NumberFormat('#,##0.00');
      return '${formatter.format(expense)} บาท';
    } catch (e) {
      return expenseStr.isNotEmpty ? '$expenseStr บาท' : '-';
    }
  }

  Future<void> _updateCostItem(BuildContext context, String label, String fieldKey, String currentValue) async {
    String newValue = currentValue;
    
    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'แก้ไข$label',
            style: GoogleFonts.notoSansThai(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: TextEditingController(text: currentValue),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'จำนวนเงิน (บาท)',
              labelStyle: GoogleFonts.notoSansThai(),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              newValue = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'ยกเลิก',
                style: GoogleFonts.notoSansThai(),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(newValue),
              child: Text(
                'บันทึก',
                style: GoogleFonts.notoSansThai(),
              ),
            ),
          ],
        );
      },
    );

    if (result != null && result != currentValue) {
      await _performCostUpdate(context, fieldKey, result);
    }
  }

  Future<void> _performCostUpdate(BuildContext context, String fieldKey, String newValue) async {
    try {
      if (tripData == null) return;

      final tripId = tripData!['id']?.toString();
      if (tripId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่พบ Trip ID')),
        );
        return;
      }

      // สร้าง API request สำหรับอัพเดทค่าใช้จ่าย
      Map<String, String> updateData = {
        fieldKey: newValue,
      };

      final response = await ApiService.updateTripCost(
        tripId: tripId,
        costData: updateData,
      );

      if (response['success'] == true) {
        // อัพเดทข้อมูลใน tripData
        if (tripData!['trip_cost'] != null) {
          tripData!['trip_cost'][fieldKey] = newValue;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'อัพเดทค่าใช้จ่ายเรียบร้อยแล้ว',
              style: GoogleFonts.notoSansThai(),
            ),
            backgroundColor: Colors.green,
          ),
        );

        // เรียก callback เพื่อ refresh UI
        if (onExpenseUpdated != null) {
          onExpenseUpdated!();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message'] ?? 'เกิดข้อผิดพลาดในการอัพเดท',
              style: GoogleFonts.notoSansThai(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error updating cost item: $e');
      
      // อัพเดทข้อมูลใน memory ก่อน (optimistic update)
      if (tripData!['trip_cost'] != null) {
        tripData!['trip_cost'][fieldKey] = newValue;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'อัพเดทเรียบร้อยแล้ว (แต่อาจไม่ซิงค์กับเซิร์ฟเวอร์)',
            style: GoogleFonts.notoSansThai(),
          ),
          backgroundColor: Colors.orange,
        ),
      );

      // เรียก callback เพื่อ refresh UI
      if (onExpenseUpdated != null) {
        onExpenseUpdated!();
      }
    }
  }
}