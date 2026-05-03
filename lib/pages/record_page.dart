import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/weight_record.dart';
import '../services/weight_api_service.dart';

class RecordPage extends StatefulWidget {
  final String userId;
  final String? initialDate;
  final String unit;

  RecordPage({super.key, required this.userId, this.initialDate, this.unit = 'kg'});

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

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate != null
        ? DateTime.parse(widget.initialDate!)
        : DateTime.now();
    _loadExistingRecord();
  }

  Future<void> _loadExistingRecord() async {
    setState(() => _loading = true);
    try {
      final records = await _apiService.getWeightRecords(
        userId: widget.userId,
        startDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
        endDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
        period: _selectedPeriod == WeightPeriod.evening ? 'evening' : 'morning',
        pageSize: 1,
      );
      if (records.isNotEmpty) {
        _existingRecord = records.first;
        _weightController.text = _existingRecord!.weight.toStringAsFixed(1);
        _noteController.text = _existingRecord!.note ?? '';
        _selectedPeriod = _existingRecord!.period;
      } else {
        _existingRecord = null;
        _weightController.clear();
        _noteController.clear();
      }
    } catch (_) {}
    setState(() => _loading = false);
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
    if (weight == null) {
      setState(() => _errorMsg = '体重数值格式不正确');
      return;
    }

    if (weight < 20 || weight > 300) {
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
        weight: weight,
        note: note.isEmpty ? null : note,
      );
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _saving = false;
        _errorMsg = '保存失败，请重试';
      });
    }
  }

  Future<void> _delete() async {
    if (_existingRecord == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这条体重记录吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _apiService.deleteWeightRecord(_existingRecord!.id, widget.userId);
        if (mounted) Navigator.pop(context, true);
      } catch (_) {
        setState(() => _errorMsg = '删除失败，请重试');
      }
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('体重记录 - ${_selectedPeriod == WeightPeriod.morning ? '早晨' : '晚上'}'),
        actions: [
          if (_existingRecord != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: Text(DateFormat('yyyy年M月d日').format(_selectedDate)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _selectDate,
                  ),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text('记录时段', style: TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 8),
                  SegmentedButton<WeightPeriod>(
                    segments: const [
                      ButtonSegment(
                        value: WeightPeriod.morning,
                        label: Text('早晨'),
                        icon: Icon(Icons.wb_sunny_outlined),
                      ),
                      ButtonSegment(
                        value: WeightPeriod.evening,
                        label: Text('晚上'),
                        icon: Icon(Icons.nightlight_outlined),
                      ),
                    ],
                    selected: {_selectedPeriod},
                    onSelectionChanged: (Set<WeightPeriod> selected) {
                      setState(() {
                        _selectedPeriod = selected.first;
                        _existingRecord = null;
                        _weightController.clear();
                        _noteController.clear();
                        _loading = true;
                      });
                      _loadExistingRecord();
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _selectedPeriod == WeightPeriod.morning ? '早晨体重' : '晚上体重',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _weightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}')),
                    ],
                    decoration: InputDecoration(
                      hintText: '输入体重',
                      suffixText: widget.unit,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('备注（可选）', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _noteController,
                    maxLines: 3,
                    maxLength: 200,
                    decoration: const InputDecoration(
                      hintText: '添加备注（最多200字符）',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (_errorMsg != null) ...[
                    const SizedBox(height: 8),
                    Text(_errorMsg!, style: const TextStyle(color: Colors.red, fontSize: 14)),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: _saving
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(_existingRecord == null ? '保存' : '更新'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
