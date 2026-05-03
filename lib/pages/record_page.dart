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
  final TextEditingController _morningController = TextEditingController();
  final TextEditingController _eveningController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  late DateTime _selectedDate;
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
    if (widget.initialDate == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final records = await _apiService.getWeightRecords(
        userId: widget.userId,
        startDate: widget.initialDate!,
        endDate: widget.initialDate!,
      );
      if (records.isNotEmpty) {
        _existingRecord = records.first;
        _morningController.text = _existingRecord?.morningWeight?.toStringAsFixed(1) ?? '';
        _eveningController.text = _existingRecord?.eveningWeight?.toStringAsFixed(1) ?? '';
        _noteController.text = _existingRecord?.note ?? '';
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
        _morningController.clear();
        _eveningController.clear();
        _noteController.clear();
        _loading = true;
      });
      _loadExistingRecord();
    }
  }

  Future<void> _save() async {
    final morningText = _morningController.text.trim();
    final eveningText = _eveningController.text.trim();
    final note = _noteController.text.trim();

    double? morningWeight;
    double? eveningWeight;

    if (morningText.isNotEmpty) {
      morningWeight = double.tryParse(morningText);
      if (morningWeight == null) {
        setState(() => _errorMsg = '晨重数值格式不正确');
        return;
      }
    }
    if (eveningText.isNotEmpty) {
      eveningWeight = double.tryParse(eveningText);
      if (eveningWeight == null) {
        setState(() => _errorMsg = '晚重数值格式不正确');
        return;
      }
    }

    if (morningWeight == null && eveningWeight == null && note.isEmpty) {
      setState(() => _errorMsg = '请至少填写晨重、晚重或备注中的一项');
      return;
    }

    if (morningWeight != null && (morningWeight < 20 || morningWeight > 300)) {
      setState(() => _errorMsg = '晨重需在 20.0~300.0 kg 范围内');
      return;
    }
    if (eveningWeight != null && (eveningWeight < 20 || eveningWeight > 300)) {
      setState(() => _errorMsg = '晚重需在 20.0~300.0 kg 范围内');
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
        morningWeight: morningWeight,
        eveningWeight: eveningWeight,
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
    _morningController.dispose();
    _eveningController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('体重记录'),
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
                  Text('早晨体重', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _morningController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}')),
                    ],
                    decoration: InputDecoration(
                      hintText: '输入早晨体重',
                      suffixText: widget.unit,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('晚上体重', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _eveningController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}')),
                    ],
                    decoration: InputDecoration(
                      hintText: '输入晚上体重',
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
                      child: _saving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('保存'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}