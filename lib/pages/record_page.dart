import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/weight_record.dart';
import '../services/weight_api_service.dart';
import '../utils/error_handler.dart';
import '../utils/widgets.dart';
import 'home_page.dart';
import 'trend_page.dart';
import 'history_page.dart';

class RecordPage extends StatefulWidget {
  final String userId;
  final String? initialDate;
  final WeightPeriod? initialPeriod;
  final String unit;

  RecordPage({super.key, required this.userId, this.initialDate, this.initialPeriod, this.unit = 'kg'});

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  final WeightApiService _apiService = WeightApiService();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  late DateTime _selectedDate;
  WeightPeriod _selectedPeriod = WeightPeriod.morning;
  WeightRecord? _existingRecord;
  bool _loading = true;
  bool _saving = false;
  String? _errorMsg;

  static const _orangeActive = Color(0xFF9B4500);
  static const _bluePrimary = Color(0xFF106399);
  static const _textDark = Color(0xFF191C1D);
  static const _textMuted = Color(0xFF41474F);
  static const _bgGray = Color(0xFFEDEEEF);
  static const _bgPage = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate != null
        ? (DateTime.tryParse(widget.initialDate!) ?? DateTime.now())
        : DateTime.now();
    if (widget.initialPeriod != null) {
      _selectedPeriod = widget.initialPeriod!;
    }
    _loadExistingRecord();
  }

  Future<void> _loadExistingRecord() async {
    final expectedPeriod = _selectedPeriod;
    setState(() => _loading = true);
    try {
      final records = await _apiService.getWeightRecords(
        userId: widget.userId,
        startDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
        endDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
        period: expectedPeriod == WeightPeriod.evening ? 'evening' : 'morning',
        pageSize: 10,
      );
      if (!mounted || expectedPeriod != _selectedPeriod) return;
      final match = records.where((r) => r.period == expectedPeriod).toList();
      if (match.isNotEmpty) {
        _existingRecord = match.first;
        _weightController.text = _existingRecord!.weight.toStringAsFixed(1);
        _noteController.text = _existingRecord!.note ?? '';
        _selectedPeriod = _existingRecord!.period;
      } else {
        _existingRecord = null;
        _weightController.clear();
        _noteController.clear();
        // 保留用户当前选择的 _selectedPeriod
      }
    } catch (e) {
      if (!mounted || expectedPeriod != _selectedPeriod) return;
      _existingRecord = null;
      _weightController.clear();
      _noteController.clear();
      if (mounted) {
        setState(() {
          _errorMsg = '加载已有记录失败：${ErrorHandler.getErrorMessage(e)}';
        });
      }
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked.isBefore(DateTime.now().add(const Duration(days: 1)))) {
      setState(() {
        _selectedDate = picked;
        _existingRecord = null;
        _weightController.clear();
        _noteController.clear();
        _loading = true;
      });
      _loadExistingRecord();
    }
  }

  Future<void> _save() async {
    final weightText = _weightController.text.trim();
    final note = _noteController.text.trim();

    if (weightText.isEmpty) {
      setState(() => _errorMsg = '请输入体重');
      return;
    }

    final weight = double.tryParse(weightText);
    if (weight == null || !weight.isFinite) {
      setState(() => _errorMsg = '体重数值格式不正确');
      return;
    }

    // Convert to kg for validation and storage if unit is lb
    double weightKg = widget.unit == 'lb' ? weight / 2.20462 : weight;
    if (weightKg < 20 || weightKg > 300) {
      setState(() => _errorMsg = '体重需在 20.0~300.0 kg 范围内');
      return;
    }

    if (note.length > 200) {
      setState(() => _errorMsg = '备注最多200字符');
      return;
    }

    setState(() {
      _errorMsg = null;
      _saving = true;
    });

    try {
      await _apiService.createWeightRecord(
        userId: widget.userId,
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
        period: _selectedPeriod,
        weight: weightKg,
        note: note.isEmpty ? null : note,
      );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存成功')),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => HomePage(userId: widget.userId, unit: widget.unit),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorMsg = '保存失败：${ErrorHandler.getErrorMessage(e)}';
      });
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String get _dateDisplay {
    final d = _selectedDate;
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgPage,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.black.withAlpha(13),
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: _textDark, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '体重管理',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: _bluePrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: _textDark),
            onPressed: () => _showRecordOptions(context),
          ),
        ],
      ),
      body: _loading
          ? const AppLoadingIndicator()
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page Title
                  const Text(
                    '记录体重',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w500,
                      color: _textDark,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Input Card
                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFC1C7D1).withAlpha(77)),
                      boxShadow: const [
                        BoxShadow(color: Color(0x145A9BD5), blurRadius: 12, offset: Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Date Selector
                        _buildDateSelector(),
                        const SizedBox(height: 24),

                        // Period Toggle
                        _buildPeriodToggle(),
                        const SizedBox(height: 24),

                        // Weight Input
                        _buildWeightInput(),
                        const SizedBox(height: 24),

                        // Note Textarea
                        _buildNoteInput(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Save Button
                  GestureDetector(
                    onTap: _saving ? null : _save,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: _bluePrimary,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: const [
                          BoxShadow(color: Color(0x33106999), blurRadius: 8, offset: Offset(0, 4)),
                        ],
                      ),
                      child: Center(
                        child: _saving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check, color: Colors.white, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    '保存记录',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),

                  if (_errorMsg != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMsg!,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ],
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '日期',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _textMuted,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
            decoration: BoxDecoration(
              color: _bgGray,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: _textDark),
                const SizedBox(width: 8),
                Text(
                  _dateDisplay,
                  style: const TextStyle(
                    fontSize: 16,
                    color: _textDark,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.arrow_drop_down, color: _textDark),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '时段',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _textMuted,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: _bgGray,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _changePeriod(WeightPeriod.morning),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _selectedPeriod == WeightPeriod.morning
                          ? _orangeActive
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: _selectedPeriod == WeightPeriod.morning
                          ? [
                              BoxShadow(
                                color: Colors.black.withAlpha(13),
                                blurRadius: 1,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.wb_sunny,
                          size: 16.5,
                          color: _selectedPeriod == WeightPeriod.morning
                              ? Colors.white
                              : _textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '早晨',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: _selectedPeriod == WeightPeriod.morning
                                ? Colors.white
                                : _textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => _changePeriod(WeightPeriod.evening),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _selectedPeriod == WeightPeriod.evening
                          ? const Color(0xFF6042D6)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: _selectedPeriod == WeightPeriod.evening
                          ? [
                              BoxShadow(
                                color: Colors.black.withAlpha(13),
                                blurRadius: 1,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.nightlight,
                          size: 13.5,
                          color: _selectedPeriod == WeightPeriod.evening
                              ? Colors.white
                              : _textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '晚上',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: _selectedPeriod == WeightPeriod.evening
                                ? Colors.white
                                : _textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _changePeriod(WeightPeriod period) {
    if (_selectedPeriod == period) return;
    setState(() {
      _selectedPeriod = period;
      _existingRecord = null;
      _weightController.clear();
      _noteController.clear();
      _loading = true;
    });
    _loadExistingRecord();
  }

  Widget _buildWeightInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 42),
          decoration: BoxDecoration(
            color: _bgGray,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: TextField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w600,
                color: _bluePrimary,
                letterSpacing: -0.96,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}')),
              ],
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: '0.0',
                hintStyle: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFC1C7D1),
                  letterSpacing: -0.96,
                ),
                suffixText: '${widget.unit}',
                suffixStyle: TextStyle(
                  fontSize: 16,
                  color: _textMuted,
                ),
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ),
        if (_existingRecord != null) ...[
          const SizedBox(height: 8),
          Text(
            '已有记录，更新将覆盖',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }

  void _showRecordOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_existingRecord != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('删除此记录', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  await _deleteRecord();
                },
              ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('取消'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteRecord() async {
    if (_existingRecord == null) return;
    try {
      await _apiService.deleteWeightRecord(_existingRecord!.id, widget.userId);
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败：${ErrorHandler.getErrorMessage(e)}')),
        );
      }
    }
  }

  Widget _buildNoteInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '备注 (选填)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _textMuted,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.fromLTRB(13, 13, 13, 61),
          decoration: BoxDecoration(
            color: _bgGray,
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _noteController,
            maxLines: null,
            maxLength: 200,
            style: const TextStyle(fontSize: 16, color: _textDark),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: '添加记录备注...',
              hintStyle: TextStyle(fontSize: 16, color: Color(0xFFC1C7D1)),
              counterText: '',
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(230),
        border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: const [
          BoxShadow(color: Color(0x145A9BD5), blurRadius: 6, offset: Offset(0, -4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem('总览', Icons.dashboard_outlined, false, 0),
          _navItem('记录', Icons.edit_note, true, 1),
          _navItem('趋势', Icons.show_chart, false, 2),
          _navItem('动态', Icons.dynamic_feed, false, 3),
        ],
      ),
    );
  }

  Widget _navItem(String label, IconData icon, bool isActive, int index) {
    return Expanded(
      child: InkWell(
        onTap: () {
          if (index == 1) return;
          Navigator.pop(context);
          if (index == 2) {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => TrendPage(userId: widget.userId, unit: widget.unit),
            ));
          } else if (index == 3) {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => HistoryPage(userId: widget.userId, unit: widget.unit),
            ));
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: index == 1 ? 20 : 18,
              color: isActive ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isActive ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
