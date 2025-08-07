import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart' as AppThemeConfig;
import '../../../provider/font_size_provider.dart';
import '../../../service/api_service.dart';

class ExpenseListWidget extends StatefulWidget {
  final Map<String, dynamic>? tripData;
  final Function()? onExpenseUpdated;

  const ExpenseListWidget({
    super.key,
    required this.tripData,
    this.onExpenseUpdated,
  });

  @override
  State<ExpenseListWidget> createState() => _ExpenseListWidgetState();
}

class _ExpenseListWidgetState extends State<ExpenseListWidget> {
  List<dynamic> additionalExpenses = [];
  bool isLoadingAdditionalExpenses = false;

  @override
  void initState() {
    super.initState();
    _loadAdditionalExpenses();
  }

  @override
  void didUpdateWidget(ExpenseListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tripData != widget.tripData) {
      _loadAdditionalExpenses();
    }
  }

  Future<void> _loadAdditionalExpenses() async {
    if (widget.tripData == null) return;

    final tripId = widget.tripData!['id']?.toString();
    if (tripId == null) return;

    setState(() {
      isLoadingAdditionalExpenses = true;
    });

    try {
      final response = await ApiService.getAdditionalExpensesByTripId(tripId: tripId);
      
      if (response['success'] == true) {
        setState(() {
          additionalExpenses = response['expenses'] ?? [];
        });
      } else {
        print('❌ Failed to load additional expenses: ${response['message']}');
      }
    } catch (e) {
      print('❌ Error loading additional expenses: $e');
    } finally {
      setState(() {
        isLoadingAdditionalExpenses = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tripData == null || widget.tripData!['trip_cost'] == null) {
      return _buildEmptyState();
    }

    final costData = widget.tripData!['trip_cost'] as Map<String, dynamic>;
    
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
                  Spacer(),
                  GestureDetector(
                    onTap: () => _showAddExpenseModal(context),
                    child: Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: colors.success,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 16,
                      ),
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
              
              // รายการค่าใช้จ่ายเพิ่มเติม
              if (additionalExpenses.isNotEmpty) ...[
                SizedBox(height: 16),
                Text(
                  'ค่าใช้จ่ายเพิ่มเติม',
                  style: GoogleFonts.notoSansThai(
                    fontSize: fontProvider.getScaledFontSize(16.0),
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                SizedBox(height: 8),
                ...additionalExpenses.map((expense) => _buildAdditionalExpenseItem(context, expense)),
              ],
              
              if (isLoadingAdditionalExpenses) ...[
                SizedBox(height: 12),
                Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'กำลังโหลดค่าใช้จ่ายเพิ่มเติม...',
                      style: GoogleFonts.notoSansThai(
                        fontSize: fontProvider.getScaledFontSize(14.0),
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
              
              if (costData['remark'] != null && costData['remark'].toString().isNotEmpty) ...[
                SizedBox(height: 12),
                Text(
                  'หมายเหตุ:',
                  style: GoogleFonts.notoSansThai(
                    fontSize: fontProvider.getScaledFontSize(15.0),
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  costData['remark'],
                  style: GoogleFonts.notoSansThai(
                    fontSize: fontProvider.getScaledFontSize(14.0),
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

  Widget _buildAdditionalExpenseItem(BuildContext context, Map<String, dynamic> expense) {
    final colors = AppThemeConfig.AppColorScheme.light();
    final amount = expense['amount']?.toString() ?? '0.00';
    final formattedAmount = _formatExpense(amount);
    final description = expense['expense_description'] ?? 'ไม่ระบุ';
    
    return Consumer<FontSizeProvider>(
      builder: (context, fontProvider, child) {
        return Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        description,
                        style: GoogleFonts.notoSansThai(
                          fontSize: fontProvider.getScaledFontSize(14.0),
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _deleteAdditionalExpense(context, expense),
                      child: Container(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.delete_outline,
                          size: 16,
                          color: Colors.red.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Text(
                formattedAmount,
                style: GoogleFonts.notoSansThai(
                  fontSize: fontProvider.getScaledFontSize(14.0),
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
    // ถ้าค่าเดิมเป็น 0 หรือ 0.00 ให้แสดงช่องว่าง
    String displayValue = '';
    if (currentValue != '0' && currentValue != '0.00' && currentValue.isNotEmpty) {
      displayValue = currentValue;
    }
    
    String newValue = displayValue;
    
    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'แก้ไข$label',
            style: GoogleFonts.notoSansThai(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: TextEditingController(text: displayValue),
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

    if (result != null && result != currentValue && context.mounted) {
      await _performCostUpdate(context, fieldKey, result);
    }
  }

  Future<void> _showAddExpenseModal(BuildContext context) async {
    String selectedExpenseType = '';
    String customExpenseType = '';
    String expenseAmount = '';
    bool isCustomType = false;
    
    final predefinedExpenseTypes = [
      'Over Time (หัก 1%)',
      'ค่าค้างหาง (หัก 1%)',
      'ค่าปฏิบัติงานวันหยุด (หัก 1%)',
      'ค่าฝากตู้หนัก',
      'ค่าฝากตู้เปล่า',
    ];

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'เพิ่มค่าใช้จ่ายเพิ่มเติม',
                style: GoogleFonts.notoSansThai(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ประเภทค่าใช้จ่าย',
                      style: GoogleFonts.notoSansThai(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedExpenseType.isEmpty ? null : selectedExpenseType,
                          hint: Text(
                            'เลือกประเภทค่าใช้จ่าย',
                            style: GoogleFonts.notoSansThai(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                          isExpanded: true,
                          items: [
                            ...predefinedExpenseTypes.map((String type) {
                              return DropdownMenuItem<String>(
                                value: type,
                                child: Text(
                                  type,
                                  style: GoogleFonts.notoSansThai(fontSize: 14),
                                ),
                              );
                            }).toList(),
                            DropdownMenuItem<String>(
                              value: 'custom',
                              child: Text(
                                'อื่นๆ (ระบุเอง)',
                                style: GoogleFonts.notoSansThai(
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedExpenseType = newValue ?? '';
                              isCustomType = newValue == 'custom';
                              if (!isCustomType) {
                                customExpenseType = '';
                              }
                            });
                          },
                        ),
                      ),
                    ),
                    if (isCustomType) ...[
                      SizedBox(height: 16),
                      Text(
                        'ระบุประเภทค่าใช้จ่าย',
                        style: GoogleFonts.notoSansThai(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'กรุณาระบุประเภทค่าใช้จ่าย',
                          hintStyle: GoogleFonts.notoSansThai(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        ),
                        style: GoogleFonts.notoSansThai(fontSize: 14),
                        onChanged: (value) {
                          customExpenseType = value;
                        },
                      ),
                    ],
                    SizedBox(height: 16),
                    Text(
                      'จำนวนเงิน',
                      style: GoogleFonts.notoSansThai(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        hintStyle: GoogleFonts.notoSansThai(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                        suffixText: 'บาท',
                        suffixStyle: GoogleFonts.notoSansThai(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                      style: GoogleFonts.notoSansThai(fontSize: 14),
                      onChanged: (value) {
                        expenseAmount = value;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'ยกเลิก',
                    style: GoogleFonts.notoSansThai(color: Colors.grey.shade600),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    final finalExpenseType = isCustomType ? customExpenseType : selectedExpenseType;
                    
                    if (finalExpenseType.isEmpty || expenseAmount.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'กรุณากรอกข้อมูลให้ครบถ้วน',
                            style: GoogleFonts.notoSansThai(),
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    Navigator.of(context).pop({
                      'expense_type': finalExpenseType,
                      'amount': expenseAmount,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppThemeConfig.AppColorScheme.light().success,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    'บันทึก',
                    style: GoogleFonts.notoSansThai(),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null && context.mounted) {
      await _saveAdditionalExpense(context, result['expense_type']!, result['amount']!);
    }
  }

  Future<void> _deleteAdditionalExpense(BuildContext context, Map<String, dynamic> expense) async {
    final expenseId = expense['id']?.toString();
    final description = expense['expense_description'] ?? 'ไม่ระบุ';
    
    if (expenseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ไม่สามารถระบุรายการค่าใช้จ่ายได้'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // แสดง confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'ยืนยันการลบ',
            style: GoogleFonts.notoSansThai(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'คุณต้องการลบรายการ "$description" หรือไม่?',
            style: GoogleFonts.notoSansThai(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'ยกเลิก',
                style: GoogleFonts.notoSansThai(color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'ลบ',
                style: GoogleFonts.notoSansThai(),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      try {
        final response = await ApiService.deleteAdditionalExpense(expenseId: expenseId);
        
        if (response['success'] == true) {
          // รีเฟรชรายการ
          await _loadAdditionalExpenses();
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'ลบรายการค่าใช้จ่ายเรียบร้อยแล้ว',
                  style: GoogleFonts.notoSansThai(),
                ),
                backgroundColor: Colors.green,
              ),
            );

            // เรียก callback เพื่อ refresh UI
            if (widget.onExpenseUpdated != null) {
              widget.onExpenseUpdated!();
            }
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  response['message'] ?? 'เกิดข้อผิดพลาดในการลบ',
                  style: GoogleFonts.notoSansThai(),
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        print('❌ Error deleting additional expense: $e');
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'เกิดข้อผิดพลาดในการลบค่าใช้จ่าย',
                style: GoogleFonts.notoSansThai(),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _saveAdditionalExpense(BuildContext context, String expenseType, String amount) async {
    try {
      if (widget.tripData == null) return;

      final tripId = widget.tripData!['id']?.toString();
      if (tripId == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ไม่พบ Trip ID')),
          );
        }
        return;
      }

      print('📤 Saving additional expense: $expenseType, amount: $amount');

      // เรียกใช้ API function f=15
      final response = await ApiService.saveAdditionalExpense(
        tripId: tripId,
        expenseType: expenseType,
        amount: amount,
      );

      print('📦 Save additional expense response: $response');

      if (!context.mounted) return;

      if (response['success'] == true) {
        // รีเฟรชรายการค่าใช้จ่ายเพิ่มเติม
        await _loadAdditionalExpenses();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'บันทึกค่าใช้จ่ายเพิ่มเติมเรียบร้อยแล้ว',
              style: GoogleFonts.notoSansThai(),
            ),
            backgroundColor: Colors.green,
          ),
        );

        // เรียก callback เพื่อ refresh UI
        if (widget.onExpenseUpdated != null) {
          widget.onExpenseUpdated!();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message'] ?? 'เกิดข้อผิดพลาดในการบันทึก',
              style: GoogleFonts.notoSansThai(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Error saving additional expense: $e');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'เกิดข้อผิดพลาดในการบันทึกค่าใช้จ่าย',
              style: GoogleFonts.notoSansThai(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _performCostUpdate(BuildContext context, String fieldKey, String newValue) async {
    try {
      if (widget.tripData == null) return;

      final tripId = widget.tripData!['id']?.toString();
      if (tripId == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ไม่พบ Trip ID')),
          );
        }
        return;
      }

      // สร้าง API request สำหรับอัพเดทค่าใช้จ่าย
      Map<String, String> updateData = {
        fieldKey: newValue,
      };

      print('📤 Updating cost for trip $tripId, field: $fieldKey, value: $newValue');

      final response = await ApiService.updateTripCost(
        tripId: tripId,
        costData: updateData,
      );

      print('📦 Update response: $response');

      if (!context.mounted) return;

      if (response['success'] == true) {
        // อัพเดทข้อมูลใน tripData
        if (widget.tripData!['trip_cost'] != null) {
          widget.tripData!['trip_cost'][fieldKey] = newValue;
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
        if (widget.onExpenseUpdated != null) {
          widget.onExpenseUpdated!();
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
      print('❌ Error updating cost item: $e');
      
      // อัพเดทข้อมูลใน memory ก่อน (optimistic update)
      if (widget.tripData!['trip_cost'] != null) {
        widget.tripData!['trip_cost'][fieldKey] = newValue;
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'อัพเดทเรียบร้อยแล้ว (แต่อาจไม่ซิงค์กับเซิร์ฟเวอร์)',
              style: GoogleFonts.notoSansThai(),
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }

      // เรียก callback เพื่อ refresh UI
      if (widget.onExpenseUpdated != null) {
        widget.onExpenseUpdated!();
      }
    }
  }
}