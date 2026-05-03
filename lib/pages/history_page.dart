import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/weight_record.dart';
import '../services/weight_api_service.dart';
import 'record_page.dart';

class HistoryPage extends StatefulWidget {
  final String userId;
  final String unit;

  HistoryPage({super.key, required this.userId, this.unit = 'kg'});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final WeightApiService _apiService = WeightApiService();
  List<WeightRecord> _records = [];
  bool _loading = true;
  int _page = 1;
  bool _hasMore = true;
  final int _pageSize = 30;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() => _loading = true);
    try {
      final records = await _apiService.getWeightRecords(
        userId: widget.userId,
        page: _page,
        pageSize: _pageSize,
      );
      setState(() {
        if (_page == 1) {
          _records = records;
        } else {
          _records.addAll(records);
        }
        _hasMore = records.length >= _pageSize;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    _page++;
    await _loadRecords();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('历史记录'),
      ),
      body: _loading && _records.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
              ? const Center(child: Text('暂无记录'))
              : ListView.builder(
                  itemCount: _records.length + (_hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _records.length) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: _loading
                              ? const CircularProgressIndicator()
                              : TextButton(onPressed: _loadMore, child: const Text('加载更多')),
                        ),
                      );
                    }
                    final record = _records[index];
                    return _buildRecordTile(record);
                  },
                ),
    );
  }

  Widget _buildRecordTile(WeightRecord record) {
    final date = DateTime.parse(record.date);
    final weekday = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'][date.weekday - 1];
    // 在 v2 中，record 是单个 period，需要找同日期的另一条
    final sameDateRecords = _records.where((r) => r.date == record.date).toList();
    final hasMorning = sameDateRecords.any((r) => r.period == WeightPeriod.morning);
    final hasEvening = sameDateRecords.any((r) => r.period == WeightPeriod.evening);
    final morningWeight = hasMorning ? sameDateRecords.firstWhere((r) => r.period == WeightPeriod.morning).weight : null;
    final eveningWeight = hasEvening ? sameDateRecords.firstWhere((r) => r.period == WeightPeriod.evening).weight : null;

    // 只显示一次（当是 morning 时，或没有 morning 时）
    if (record.period == WeightPeriod.evening && hasMorning) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(DateFormat('M月d日').format(date), style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(weekday, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
        title: Row(
          children: [
            _weightChip('晨', morningWeight),
            const SizedBox(width: 8),
            _weightChip('晚', eveningWeight),
          ],
        ),
        subtitle: record.note != null && record.note!.isNotEmpty
            ? Text(record.note!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12))
            : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RecordPage(userId: widget.userId, initialDate: record.date, unit: widget.unit),
            ),
          );
          _loadRecords();
        },
      ),
    );
  }

  Widget _weightChip(String label, double? weight) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue.withAlpha(26),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label: ${weight?.toStringAsFixed(1) ?? '--'} ${widget.unit}',
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}